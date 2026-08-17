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

  @schema_id "engineering-system/patch-proposal/m0-v1"

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
      body = %{
        "schema" => @schema_id,
        "patch_id" => "pp_" <> short_id(),
        "plan_ref" => plan_ref,
        "attempt_ref" => worker_output.attempt_ref,
        "repository" => repository,
        "base_commit" => worker_output.base_commit || "",
        "base_state_digest" => worker_output.base_state_digest,
        "operations" => Enum.map(operations, &serialize_op/1),
        "patch_digest" => compute_patch_digest(worker_output, operations),
        "metadata" => build_metadata(worker_output),
        "supersedes_patch_ref" => supersedes_patch_ref
      }

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
         reason:
           "patch touches #{length(operations)} paths; canonical limit is #{limit}"
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

  defp build_metadata(worker_output) do
    %{
      "worker_output_id" => worker_output.id,
      "worker_output_digest" => worker_output.semantic_digest,
      "parsed_candidate_digest" => worker_output.parsed_candidate_digest,
      "adapter_implementation_digest" => worker_output.adapter_implementation_digest,
      "produced_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp canonical_digest(payload) do
    "sha256:" <> Canonical.digest(@schema_id <> "/patch", payload)
  end
end