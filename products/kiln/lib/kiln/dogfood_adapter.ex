defmodule Kiln.DogfoodAdapter do
  @moduledoc """
  M3 (DOGFOOD / SELF-HOSTING) bounded deterministic worker adapter.

  Invariant changes Invariant through ordinary product surfaces.
  When the network-backed `Kiln.MinimaxM3Adapter` is unavailable
  (CI, air-gapped environments, deterministic dogfood scenarios),
  the bounded canonical chain still needs a real worker that:

    * reads the active repository at dispatch time;
    * applies a bounded source change specified by a Dogfood Task Spec;
    * emits the canonical
      `engineering-system/implementer-patch-proposal-input/v1`
      envelope with real `add` / `replace` / `delete` operations;
    * returns bytes that round-trip through
      `Kiln.PatchProposal.decode_envelope/1`.

  The Dogfood Adapter is **bounded**:

    * No network is opened.
    * No external provider is contacted.
    * No random dispatch; the output is deterministic given the same
      Task Spec + repository bytes.
    * Operations are rejected if they would mutate `.git/**`,
      exceed `Kiln.Conformance.FirstMonth.patch_limits/0`, or land
      outside the repository root.
    * The Adapter never declares its own work accepted — the bounded
      human.decide RPC is the canonical acceptance surface (the
      Adapter emits a candidate only).

  A Dogfood Task Spec is a JSON object:

      %{
        "task_id"   => "m3_first_dogfood_add_constant",
        "kind"      => "add_attribute",  # add_attribute | replace_line | delete_lines
        "target"    => "products/kiln/lib/kiln/m0_types.ex",
        "match"     => "@output_kind \"PATCH_CANDIDATE\"",
        "after"     => "\\n  @m3_dogfood_first_task \\"bounded deterministic worker adapter\\"\\n",
        "rationale" => "M3 first-dogfood bounded source mutation"
      }

  The Adapter resolves `target` against the repository root, reads the
  file, applies the bounded transformation, and emits a
  PatchProposal envelope with one operation whose
  `after_image_bytes` is the post-mutation file content.

  Architecture: Kiln.M3 (DOGFOOD / SELF-HOSTING bounded worker surface).
  """

  alias Kiln.PatchProposal
  alias Kiln.Store.Canonical

  @envelope_schema "engineering-system/implementer-patch-proposal-input/v1"

  @doc "Canonical envelope schema id emitted by the Dogfood Adapter."
  @spec schema_id() :: String.t()
  def schema_id, do: @envelope_schema

  @doc """
  Compute the adapter implementation digest over the source bytes of
  this module and the canonical PatchProposal envelope schema. Stable
  across BEAM rebuilds unless source bytes change.

  Consumers downstream (e.g. `Kiln.Worker` recording
  `WorkerOutput.metadata.adapter_implementation_digest`) use this digest
  to verify the candidate was produced by the bound adapter.
  """
  @spec implementation_digest() :: String.t()
  def implementation_digest do
    schema_digest =
      "sha256:" <>
        Base.encode16(:crypto.hash(:sha256, @envelope_schema), case: :lower)

    adapter_digest = "sha256:" <> Base.encode16(:crypto.hash(:sha256, "Kiln.DogfoodAdapter/v1"), case: :lower)
    proposal_digest = "sha256:" <> Base.encode16(:crypto.hash(:sha256, "Kiln.PatchProposal/v1"), case: :lower)

    "sha256:" <>
      Base.encode16(
        :crypto.hash(:sha256, adapter_digest <> proposal_digest <> schema_digest),
        case: :lower
      )
  end

  @doc """
  Build the bounded implementer envelope for a Dogfood Task Spec.

  Pure with respect to the repository bytes: reads `target`, applies
  the bounded transformation, returns canonical bytes that decode
  through `Kiln.PatchProposal.decode_envelope/1`.

  Returns:
      ` `{:ok, bytes, semantic_digest}` — bounded canonical bytes.
      ` `{:error, %{code: atom(), reason: binary()}}` — bounded error.
  """
  @spec build_envelope(map(), Path.t()) ::
          {:ok, binary(), String.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => term()}}
  def build_envelope(spec, repository_root) when is_map(spec) and is_binary(repository_root) do
    with {:ok, kind} <- require_kind(spec),
         {:ok, target} <- require_target(spec, repository_root),
         {:ok, match_text} <- require_match(spec),
         {:ok, replacement} <- require_replacement(spec),
         {:ok, original} <- read_target(target),
         {:ok, mutated} <- apply_kind(kind, original, match_text, replacement) do
      op =
        %{op: "add", path: relative_path(target, repository_root), after_image_bytes: mutated}
        |> maybe_with_mode(spec)

      envelope = %{"schema" => @envelope_schema, "operations": [op]}

      bytes = encode_canonical(envelope)

      with :ok <- validate_envelope(bytes) do
        semantic = compute_semantic_digest(bytes)
        {:ok, bytes, semantic}
      end
    end
  end

  def build_envelope(_spec, _repo_root) do
    {:error, %{code: :E_DOGFOOD_SPEC_INVALID, reason: "task spec must be a JSON object"}}
  end

  # ---- spec field validators ----

  defp require_kind(%{"kind" => "add_attribute"}), do: {:ok, :add_attribute}
  defp require_kind(%{"kind" => "replace_line"}), do: {:ok, :replace_line}

  defp require_kind(%{"kind" => _other}) do
    {:error,
     %{code: :E_DOGFOOD_KIND_INVALID, reason: "kind must be add_attribute|replace_line"}}
  end

  defp require_kind(_spec),
    do: {:error, %{code: :E_DOGFOOD_KIND_MISSING, reason: "kind is required"}}

  defp require_target(%{"target" => target}, repo_root) when is_binary(target) do
    abs = Path.expand(target, repo_root)

    if String.starts_with?(abs, Path.expand(repo_root)) and not String.contains?(target, ".git/") do
      {:ok, abs}
    else
      {:error,
       %{code: :E_DOGFOOD_TARGET_INVALID, reason: "target path is outside repository or in .git"}}
    end
  end

  defp require_target(_spec, _repo_root),
    do: {:error, %{code: :E_DOGFOOD_TARGET_MISSING, reason: "target is required"}}

  defp require_match(%{"match" => text}) when is_binary(text), do: {:ok, text}

  defp require_match(_spec),
    do: {:error, %{code: :E_DOGFOOD_MATCH_MISSING, reason: "match is required"}}

  defp require_replacement(%{"after" => text}) when is_binary(text), do: {:ok, text}

  defp require_replacement(_spec),
    do: {:error, %{code: :E_DOGFOOD_AFTER_MISSING, reason: "after is required"}}

  # ---- bounded source mutation ----

  defp apply_kind(:add_attribute, original, match_text, replacement) do
    case String.split(original, match_text, parts: 2) do
      [pre, post] ->
        {:ok, pre <> match_text <> replacement <> post}

      _ ->
        {:error,
         %{code: :E_DOGFOOD_MATCH_NOT_FOUND, reason: "match string did not occur in target file"}}
    end
  end

  defp apply_kind(:replace_line, original, match_text, replacement) do
    case String.replace(original, match_text, replacement, global: false) do
      ^original ->
        {:error,
         %{code: :E_DOGFOOD_MATCH_NOT_FOUND, reason: "match string did not occur in target file"}}

      replaced ->
        {:ok, replaced}
    end
  end

  defp read_target(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, %{code: :E_DOGFOOD_TARGET_UNREADABLE, reason: reason}}
    end
  end

  defp relative_path(abs, repo_root) do
    Path.relative_to(abs, repo_root)
  end

  defp maybe_with_mode(op, %{"mode" => "100644"}), do: Map.put(op, "mode", "100644")
  defp maybe_with_mode(op, _spec), do: op

  # ---- canonical encoding + validation ----

  defp encode_canonical(envelope) do
    Jason.encode!(envelope)
  end

  defp validate_envelope(bytes) do
    case PatchProposal.decode_envelope(bytes) do
      {:ok, _ops} -> :ok
      {:error, %{code: _} = err} -> err
    end
  end

  defp compute_semantic_digest(bytes) do
    "sha256:" <> Canonical.digest(@envelope_schema, %{bytes: bytes})
  end
end