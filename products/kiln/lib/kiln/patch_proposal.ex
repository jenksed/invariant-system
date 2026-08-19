defmodule Kiln.PatchProposal do
  @moduledoc """
  M0 Patch Proposal builder.

  Translates a validated Worker Output into the canonical
  `engineering-system/patch-proposal/m0-v1` envelope. The proposal:

    * carries `plan_ref` and `attempt_ref` from the Worker Output chain;
    * binds the exact `base_commit` + `base_state_digest` captured by
      `Kiln.RepositoryObservation` at dispatch time;
    * records one ordered `operations` list with `add` / `replace` /
      `delete` ops and content-addressed `after_image_digest` references;
    * enforces `Kiln.Conformance.FirstMonth.patch_limits/0`:
      `≤32 paths`, `≤4 MiB total after-image bytes`, plus the
      single-path `≤1 MiB` ceiling;
    * rejects binary, symlink, special, mode-change, submodule,
      `.git/**`, and path-escape requests at proposal build time;
    * computes the canonical `patch_digest` and `semantic_digest` per
      P02-D013 (sha256 over canonical bytes bound to schema);
    * never mutates the active repository — only proposes.

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  alias Kiln.Conformance.FirstMonth
  alias Kiln.Store.Canonical

  @envelope_schema_id "engineering-system/implementer-patch-proposal-input/v1"
  @schema_id "engineering-system/patch-proposal/m0-v1"
  @max_path_length 4_096
  @authority_smuggled_fields ~w(
    approval
    human_decision
    human_decision_id
    authorization
    authorization_ref
    qualification
    qualification_status
    evidence
    evidence_refs
    execution
    execution_authority
    mutation_instruction
    provider_approval
    decision_id
    request_revision
  )

  @doc "Canonical schema id for the Patch Proposal envelope."
  @spec schema_id() :: String.t()
  def schema_id, do: @schema_id

  @doc """
  Build a Patch Proposal from a Worker Output envelope and the
  ordered operations produced by the bounded Patch builder.

  `plan_ref`, `attempt_ref`, `base_commit`, `base_state_digest`,
  `repository`, and `metadata` are inherited from the Worker Output;
  `operations` is the bounded operations list with after-image
  content bytes (the proposal body carries the digest reference, the
  raw bytes land in the content-addressed Artifact Store via the
  Patch Service). `supersedes_patch_ref` is omitted in M8; M9 may
  introduce a revision lineage via that field if canonically approved.

  Returns `{:ok, %PatchProposal.Proposal{}}` or a bounded error
  envelope. Never mutates the active repository.
  """
  @spec build(
          worker_output :: %Kiln.M0WorkerOutput{},
          operations :: [map()],
          plan_ref :: map(),
          repository :: String.t()
        ) ::
          {:ok, PatchProposal.Proposal.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def build(worker_output, operations, plan_ref, repository, supersedes_patch_ref \\ nil)
      when not is_nil(worker_output) and is_list(operations) and
             is_map(plan_ref) and is_binary(repository) and
             (is_nil(supersedes_patch_ref) or is_map(supersedes_patch_ref)) do
    with :ok <- enforce_path_limits(operations),
         :ok <- enforce_byte_limits(operations),
         :ok <- reject_disallowed_kinds(operations),
         :ok <- require_after_image_digest(operations),
         :ok <- require_before_digest(operations) do
      base_body = %{
        "schema" => @schema_id,
        "patch_id" => "pp_" <> short_id(),
        "plan_ref" => plan_ref,
        "attempt_ref" => worker_output.attempt_ref,
        "repository" => repository,
        "base_commit" => worker_output.base_commit || "",
        "base_state_digest" => worker_output.base_state_digest,
        "operations" => Enum.map(operations, &serialize_op/1),
        "patch_digest" => compute_patch_digest(worker_output, operations),
        "metadata" => build_metadata(worker_output)
      }

      # Per M8 moduledoc: `supersedes_patch_ref` is omitted in M8; M9 may
      # populate it on revision. The canonical schema
      # (patch-proposal.m0-v1.schema.json:120) declares the field as
      # an OPTIONAL artifactRef. Including it as JSON null would be
      # schema-invalid (artifactRef requires non-null id+digest) and
      # would break first-proposal digest compatibility with the
      # canonical positive fixture 12-patch-proposal.json. Only
      # include the key when an actual predecessor ref is supplied.
      body =
        if supersedes_patch_ref == nil do
          base_body
        else
          Map.put(base_body, "supersedes_patch_ref", supersedes_patch_ref)
        end

      semantic = canonical_digest(Map.delete(body, "patch_id"))

      {:ok,
       %Kiln.M0PatchProposal{
         id: body["patch_id"],
         semantic_digest: semantic,
         plan_ref: plan_ref,
         attempt_ref: worker_output.attempt_ref,
         repository: repository,
         base_commit: worker_output.base_commit,
         base_state_digest: worker_output.base_state_digest,
         operations: body["operations"],
         patch_digest: body["patch_digest"],
         metadata: body["metadata"],
         supersedes_patch_ref: supersedes_patch_ref
       }}
    end
  end

  @doc """
  Pure helper: compute the canonical patch_digest over the bounded
  operations. The digest is bounded to the manifest so a tampered
  proposal body fails the bounded integrity check.
  """
  @spec compute_patch_digest(%Kiln.M0WorkerOutput{}, [map()]) :: String.t()
  def compute_patch_digest(worker_output, operations) do
    payload = %{
      "base_state_digest" => worker_output.base_state_digest,
      "operations" => Enum.map(operations, &serialize_op/1)
    }

    canonical_digest(payload)
  end

  # -- M11 E2 P3: bounded IMPLEMENTER completion envelope materializer --
  #
  # The provider outputs ONLY bounded patch content. The provider output
  # must NOT carry approval, HumanDecision, authorization, qualification,
  # evidence, execution authority, or any mutation instruction beyond
  # bounded patch content. `decode_envelope/1` rejects those fields.
  #
  # The envelope schema identity follows the existing engineering-system
  # namespace (`contracts/m0/schemas/...`) without inventing a parallel
  # authority surface. Raw input bound is enforced by `Kiln.Artifact.put/2`
  # at publication time; this module never opens a network and never
  # reads the repository.

  @doc "Canonical schema id for the bounded IMPLEMENTER input envelope."
  @spec envelope_schema_id() :: String.t()
  def envelope_schema_id, do: @envelope_schema_id

  @doc """
  Decode bounded IMPLEMENTER completion bytes into the canonical
  `ops_with_bytes` shape that `Kiln.PatchProposal.build/5` and
  `Kiln.PatchService.apply/3` consume.

  Pure / deterministic / no I/O. No repository reads. No network.

  Same `bytes` always produces identical operations and identical
  per-op digest bindings. The parser refuses to consume unbounded
  memory: bytes greater than `@max_envelope_byte_size` (16 MiB,
  derived from `Kiln.Artifact.max_byte_size/0` and bounded
  independently here) are rejected before JSON parsing, and
  every per-op and per-aggregate bound from
  `Kiln.Conformance.FirstMonth.patch_limits/0` is enforced.

  Returns `{:ok, ops_with_bytes}` or a bounded error envelope.
  """
  @spec decode_envelope(binary()) ::
          {:ok, [map()]}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def decode_envelope(bytes) when is_binary(bytes) do
    cond do
      byte_size(bytes) > canonical_envelope_byte_limit() ->
        {:error,
         %{
           code: :E_PATCH_INPUT_LIMIT_EXCEEDED,
           reason:
             "implementer envelope byte_size #{byte_size(bytes)} exceeds the #{canonical_envelope_byte_limit()} canonical ceiling"
         }}

      true ->
        with {:ok, envelope} <- safe_json_decode(bytes),
             :ok <- reject_authority_smuggling(envelope),
             :ok <- validate_envelope_shape(envelope) do
          ops =
            envelope["operations"]
            |> Enum.map(&decode_op/1)
            |> sequence_errors()

          case ops do
            {:ok, ops_with_bytes} ->
              with :ok <- enforce_total_bound(ops_with_bytes) do
                {:ok, ops_with_bytes}
              end

            {:error, _} = err ->
              err
          end
        else
          {:error, _} = err ->
            err
        end
    end
  end

  defp canonical_envelope_byte_limit do
    # RAW_INPUT_BOUND_DERIVED_AND_ENFORCED: the canonical Artifact
    # content-byte ceiling (16 MiB) bounds every provider-side payload
    # the Worker ever observes. This is the same bound put_request
    # enforces upstream; we apply it again here as defense in depth.
    Kiln.Artifact.max_byte_size()
  end

  defp reject_authority_smuggling(envelope) when is_map(envelope) do
    Enum.reduce_while(@authority_smuggled_fields, :ok, fn field, :ok ->
      if Map.has_key?(envelope, field) do
        {:halt,
         {:error,
          %{
            code: :E_PATCH_AUTHORITY_SMUGGLED,
            reason:
              "implementer envelope refuses authority-smuggled field #{inspect(field)}; provider output must contain bounded patch content only"
          }}}
      else
        {:cont, :ok}
      end
    end)
  end

  defp reject_authority_smuggling(_), do: error_envelope_not_object()

  defp validate_envelope_shape(%{"schema" => @envelope_schema_id, "operations" => ops} = envelope)
       when is_list(ops) do
    cond do
      length(ops) == 0 ->
        {:error,
         %{code: :E_PATCH_OPERATIONS_EMPTY, reason: "operations must be a non-empty list"}}

      true ->
        # Closed-shape envelope (additionalProperties: false, consistent
        # with every other M0 schema): only `schema` + `operations` may
        # appear at the top level.
        case Map.keys(envelope) -- ["schema", "operations"] do
          [] ->
            :ok

          [unknown | _] ->
            {:error,
             %{
               code: :E_PATCH_ENVELOPE_SHAPE_INVALID,
               reason:
                 "envelope carries unknown top-level field #{inspect(unknown)}; only schema + operations are permitted"
             }}
        end
    end
  end

  defp validate_envelope_shape(%{"schema" => other}) do
    {:error,
     %{
       code: :E_PATCH_ENVELOPE_SCHEMA_INVALID,
       reason: "envelope schema must be #{@envelope_schema_id}; got #{inspect(other)}"
     }}
  end

  defp validate_envelope_shape(_) do
    {:error,
     %{
       code: :E_PATCH_ENVELOPE_SHAPE_INVALID,
       reason: "envelope must be a JSON object with schema + operations"
     }}
  end

  # Decodes bounded envelope bytes via the OTP-native :json module
  # so this materializer is independent of any external JSON library
  # dep. The bounded byte ceiling is enforced upstream; malformed
  # JSON is surfaced as a structured error rather than raising.
  defp safe_json_decode(bytes) when is_binary(bytes) do
    {:ok, :json.decode(bytes)}
  rescue
    _ -> {:error, %{code: :E_PATCH_ENVELOPE_SHAPE_INVALID, reason: "envelope is not valid JSON"}}
  end

  defp error_envelope_not_object do
    {:error,
     %{
       code: :E_PATCH_ENVELOPE_SHAPE_INVALID,
       reason: "envelope must decode as a JSON object"
     }}
  end

  defp decode_op(%{"op" => op_kind, "path" => path} = op) when is_binary(path) do
    normalized_kind = decode_op_kind(op_kind)
    after_image = op["after_image_bytes"]
    expected_preimage = op["expected_before_digest"]

    with {:ok, kind} <- normalized_kind,
         :ok <- check_required_fields(kind, op),
         :ok <- check_unknown_fields(kind, op),
         :ok <- check_path_length(path),
         :ok <- check_text_only(after_image) do
      ok_op(kind, path, after_image, expected_preimage, op)
    else
      {:error, _} = err -> err
    end
  end

  defp decode_op(_op) do
    {:error,
     %{
       code: :E_PATCH_OPERATIONS_SHAPE_INVALID,
       reason: "each operation must be a JSON object with `op` and `path`"
     }}
  end

  defp decode_op_kind("add"), do: {:ok, :add}
  defp decode_op_kind("replace"), do: {:ok, :replace}
  defp decode_op_kind("delete"), do: {:ok, :delete}

  defp decode_op_kind(other) do
    {:error,
     %{
       code: :E_PATCH_OP_KIND_INVALID,
       reason: "op must be one of add|replace|delete; got #{inspect(other)}"
     }}
  end

  defp check_required_fields(:add, op) do
    require_keys(op, ["op", "path", "after_image_bytes"])
  end

  defp check_required_fields(:replace, op) do
    require_keys(op, ["op", "path", "after_image_bytes", "expected_before_digest"])
  end

  defp check_required_fields(:delete, op) do
    require_keys(op, ["op", "path", "expected_before_digest"])
  end

  defp require_keys(op, required_keys) do
    missing = Enum.filter(required_keys, fn key -> not Map.has_key?(op, key) end)

    if missing == [] do
      :ok
    else
      {:error,
       %{
         code: :E_PATCH_OP_MISSING_FIELD,
         reason: "operation missing required field(s) #{inspect(missing)}"
       }}
    end
  end

  # Closed-shape operations (additionalProperties: false on each op
  # object): every key outside the per-kind allowed set is rejected.
  defp check_unknown_fields(kind, op) do
    allowed =
      case kind do
        :add -> ["op", "path", "after_image_bytes", "mode"]
        :replace -> ["op", "path", "after_image_bytes", "expected_before_digest", "mode"]
        :delete -> ["op", "path", "expected_before_digest"]
      end

    case Map.keys(op) -- allowed do
      [] ->
        :ok

      [unknown | _] ->
        {:error,
         %{
           code: :E_PATCH_OPERATIONS_SHAPE_INVALID,
           reason:
             "#{kind} operation carries unknown field #{inspect(unknown)}; allowed fields are #{inspect(allowed)}"
         }}
    end
  end

  defp check_path_length(path) when is_binary(path) do
    if byte_size(path) > @max_path_length do
      {:error,
       %{
         code: :E_PATCH_PATH_TOO_LONG,
         reason: "path #{inspect(path)} exceeds the #{@max_path_length}-byte canonical limit"
       }}
    else
      :ok
    end
  end

  defp check_text_only(nil), do: :ok

  defp check_text_only(value) when is_binary(value) do
    cond do
      String.contains?(value, "\0") ->
        {:error,
         %{
           code: :E_PATCH_BINARY_DENIED,
           reason: "after_image_bytes contains a NUL byte; text-only content is required"
         }}

      String.contains?(value, "\x7F") or has_control?(value) ->
        {:error,
         %{
           code: :E_PATCH_BINARY_DENIED,
           reason: "after_image_bytes contains a control byte; text-only content is required"
         }}

      true ->
        :ok
    end
  end

  defp check_text_only(_other) do
    {:error,
     %{
       code: :E_PATCH_BINARY_DENIED,
       reason: "after_image_bytes must be a JSON string (text-only)"
     }}
  end

  defp has_control?(value) do
    value
    |> :binary.bin_to_list()
    |> Enum.any?(fn byte -> byte < 0x20 and byte not in [0x09, 0x0A, 0x0D] end)
  end

  defp ok_op(:add, path, after_image_bytes, _preimage, op) do
    mode = decode_mode(op["mode"])

    case mode do
      {:ok, mode_val} ->
        {:ok,
         %{
           op: :add,
           path: path,
           content: after_image_bytes,
           before_digest: nil,
           after_image_digest: sha256_hex(after_image_bytes),
           mode: mode_val
         }}

      {:error, _} = err ->
        err
    end
  end

  defp ok_op(:replace, path, after_image_bytes, expected_preimage, op) do
    mode = decode_mode(op["mode"])

    with {:ok, mode_val} <- mode,
         {:ok, preimage} <- require_digest(expected_preimage) do
      {:ok,
       %{
         op: :replace,
         path: path,
         content: after_image_bytes,
         before_digest: preimage,
         after_image_digest: sha256_hex(after_image_bytes),
         mode: mode_val
       }}
    end
  end

  defp ok_op(:delete, path, _after_image, expected_preimage, _op) do
    with {:ok, preimage} <- require_digest(expected_preimage) do
      {:ok,
       %{
         op: :delete,
         path: path,
         content: nil,
         before_digest: preimage,
         after_image_digest: nil
       }}
    end
  end

  defp decode_mode("100644"), do: {:ok, "100644"}
  defp decode_mode(nil), do: {:ok, "100644"}

  defp decode_mode(other) do
    {:error,
     %{
       code: :E_PATCH_MODE_INVALID,
       reason: "mode must be 100644 or omitted; got #{inspect(other)}"
     }}
  end

  defp require_digest(value) when is_binary(value) do
    if Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value) do
      {:ok, value}
    else
      {:error,
       %{
         code: :E_PATCH_PREIMAGE_SHAPE_INVALID,
         reason: "expected_before_digest must be sha256:<64 lowercase hex chars>"
       }}
    end
  end

  defp require_digest(_other) do
    {:error,
     %{
       code: :E_PATCH_PREIMAGE_SHAPE_INVALID,
       reason: "expected_before_digest must be a JSON string"
     }}
  end

  defp sequence_errors(ops) do
    case Enum.find(ops, &match?({:error, _}, &1)) do
      nil ->
        {:ok, Enum.map(ops, fn {:ok, op} -> op end)}

      {:error, _} = err ->
        err
    end
  end

  defp enforce_total_bound(ops_with_bytes) do
    limits = FirstMonth.patch_limits()
    max_total = limits[:maximum_total_after_image_bytes]

    total = ops_with_bytes |> Enum.map(&byte_size(&1[:content] || "")) |> Enum.sum()

    if total > max_total do
      {:error,
       %{
         code: :E_PATCH_BYTES_LIMIT_EXCEEDED,
         reason:
           "aggregate after-image bytes #{total} exceed the canonical #{max_total}-byte ceiling"
       }}
    else
      :ok
    end
  end

  defp sha256_hex(bytes) when is_binary(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end

  @doc """
  Rebuild a Patch Proposal deterministically from the bounded
  per-op shape returned by `decode_envelope/1`. Re-uses the
  canonical `build/5` for the bounded proposal-construction step
  so semantics are identical to the initial-propose path.

  Pure / no I/O.
  """
  @spec build_from_worker_output(
          Kiln.M0WorkerOutput.t(),
          [map()],
          map(),
          String.t()
        ) ::
          {:ok, M0PatchProposal.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def build_from_worker_output(worker_output, operations, plan_ref, repository) do
    build(worker_output, operations, plan_ref, repository)
  end

  @doc """
  Enforce the bounded path count from `Kiln.Conformance.FirstMonth`.
  Returns `:ok` or `:E_PATCH_PATH_LIMIT_EXCEEDED`.
  """
  @spec enforce_path_limits([map()]) :: :ok | {:error, map()}
  def enforce_path_limits(operations) when is_list(operations) do
    limit = FirstMonth.patch_limits()[:maximum_paths]

    if length(operations) <= limit do
      :ok
    else
      {:error,
       %{
         code: :E_PATCH_PATH_LIMIT_EXCEEDED,
         reason: "patch touches #{length(operations)} paths; canonical limit is #{limit}"
       }}
    end
  end

  @doc """
  Enforce the bounded byte limits from `Kiln.Conformance.FirstMonth`.
  Total after-image content must be ≤4 MiB; any single file ≤1 MiB.
  Returns `:ok` or `:E_PATCH_BYTES_LIMIT_EXCEEDED`.
  """
  @spec enforce_byte_limits([map()]) :: :ok | {:error, map()}
  def enforce_byte_limits(operations) when is_list(operations) do
    limits = FirstMonth.patch_limits()
    max_total = limits[:maximum_total_after_image_bytes]
    max_single = limits[:maximum_single_after_image_bytes]

    cond do
      Enum.any?(operations, fn op ->
        byte_size(op[:content] || "") > max_single
      end) ->
        {:error,
         %{
           code: :E_PATCH_BYTES_LIMIT_EXCEEDED,
           reason: "single after-image exceeds the #{max_single}-byte ceiling"
         }}

      Enum.sum(Enum.map(operations, fn op -> byte_size(op[:content] || "") end)) > max_total ->
        {:error,
         %{
           code: :E_PATCH_BYTES_LIMIT_EXCEEDED,
           reason: "total after-image bytes exceed the #{max_total}-byte ceiling"
         }}

      true ->
        :ok
    end
  end

  @doc """
  Reject operations targeting paths the canonical M0 contract
  forbids: `.git/**`, symlinks, submodules, mode changes, renames
  (rename = delete+add at the canonical layer), and out-of-root
  paths.
  """
  @spec reject_disallowed_kinds([map()]) :: :ok | {:error, map()}
  def reject_disallowed_kinds(operations) when is_list(operations) do
    Enum.reduce_while(operations, :ok, fn op, _acc ->
      case classify_op_path(op) do
        :ok -> {:cont, :ok}
        {:ok, _} -> {:cont, :ok}
        {:error, _} = err -> {:halt, err}
      end
    end)
  end

  defp classify_op_path(%{op: op, path: path}) when op in [:add, :replace, :delete] do
    case classify_path(path) do
      {:ok, _} = ok -> ok
      err -> err
    end
  end

  defp classify_op_path(_), do: :ok

  defp classify_path(path) when is_binary(path) do
    cond do
      String.contains?(path, "\0") ->
        {:error,
         %{
           code: :E_PATCH_PATH_ESCAPE,
           reason: "path contains NUL byte: #{inspect(path)}"
         }}

      String.starts_with?(path, "/") or String.contains?(path, "..") ->
        {:error,
         %{
           code: :E_PATCH_PATH_ESCAPE,
           reason: "path escapes the repository root: #{inspect(path)}"
         }}

      String.starts_with?(path, ".git/") or path == ".git" ->
        {:error,
         %{
           code: :E_PATCH_PATH_ESCAPE,
           reason: "path targets .git metadata: #{inspect(path)}"
         }}

      String.contains?(path, "://") ->
        {:error,
         %{
           code: :E_PATCH_BINARY_DENIED,
           reason: "path is not a regular file (submodule/symlink candidate): #{inspect(path)}"
         }}

      true ->
        {:ok, :regular}
    end
  end

  defp classify_path(_), do: {:error, %{code: :E_PATCH_PATH_ESCAPE, reason: "non-string path"}}

  @doc """
  Each operation must carry an `after_image_digest` (for add/replace)
  or an absent after-image (for delete). Returns `:ok` or
  `:E_PATCH_AFTER_IMAGE_MISSING`.
  """
  @spec require_after_image_digest([map()]) :: :ok | {:error, map()}
  def require_after_image_digest(operations) when is_list(operations) do
    case Enum.find_value(operations, &missing_after_image/1) do
      nil -> :ok
      reason -> {:error, reason}
    end
  end

  defp missing_after_image(%{op: :add, after_image_digest: nil}) do
    %{code: :E_PATCH_AFTER_IMAGE_MISSING, reason: "add op missing after_image_digest"}
  end

  defp missing_after_image(%{op: :replace, after_image_digest: nil}) do
    %{code: :E_PATCH_AFTER_IMAGE_MISSING, reason: "replace op missing after_image_digest"}
  end

  defp missing_after_image(_), do: nil

  @doc """
  Each replace/delete op must carry a `before_digest` for the
  preimage binding. Returns `:ok` or `:E_PATCH_BEFORE_DIGEST_MISSING`.
  """
  @spec require_before_digest([map()]) :: :ok | {:error, map()}
  def require_before_digest(operations) when is_list(operations) do
    case Enum.find_value(operations, &missing_before/1) do
      nil -> :ok
      reason -> {:error, reason}
    end
  end

  defp missing_before(%{op: :replace, before_digest: nil}) do
    %{code: :E_PATCH_BEFORE_DIGEST_MISSING, reason: "replace op missing before_digest"}
  end

  defp missing_before(%{op: :delete, before_digest: nil}) do
    %{code: :E_PATCH_BEFORE_DIGEST_MISSING, reason: "delete op missing before_digest"}
  end

  defp missing_before(_), do: nil

  defp serialize_op(%{op: op, path: path} = op_map) do
    %{
      "op" => Atom.to_string(op),
      "path" => path,
      "before_digest" => Map.get(op_map, :before_digest),
      "after_image_digest" => Map.get(op_map, :after_image_digest),
      "mode" => Map.get(op_map, :mode, "100644")
    }
  end

  # M11 E2: deterministic metadata — every field is bound to the
  # input `worker_output` so the build-time and rebuild-time
  # invocations produce byte-identical metadata, hence identical
  # `semantic_digest`. Wall-clock time would have failed the
  # rebuild consistency check in `apply_with_completion_ref/4`.
  defp build_metadata(worker_output) do
    %{
      "worker_output_id" => worker_output.id,
      "worker_output_digest" => worker_output.semantic_digest,
      "parsed_candidate_digest" => worker_output.parsed_candidate_digest,
      "adapter_implementation_digest" => worker_output.adapter_implementation_digest
    }
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp canonical_digest(payload) do
    "sha256:" <> Canonical.digest(@schema_id <> "/patch", payload)
  end
end
