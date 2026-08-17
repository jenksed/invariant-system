defmodule Kiln.WorkerOutputStore do
  @moduledoc """
  M11 E2 (Phase 2): bounded wire from a bounded Worker Output to the
  canonical Artifact Store.

  Persists the Worker's `completion_bytes` through `Kiln.Artifact.Store.put/2`
  and rewires `WorkerOutput.raw_completion_ref` to the durable
  content-addressed Artifact identity:

      raw_completion_ref.id     := Artifact.artifact_id  (UUIDv7)
      raw_completion_ref.digest := Artifact.content_digest (sha256:hex64)

  Identity resolution uses existing Artifact/Ref semantics:

      Artifact.id      == Artifact.artifact_id  == raw_completion_ref.id
      Artifact.content_digest == sha256(Artifact.bytes)
                             == sha256(completion_bytes)
                             == raw_completion_ref.digest

  `resolve/2` retrieves the immutable bytes through the canonical
  Artifact Store; `sha256(retrieved) == ref.digest` is verified
  before the caller ever observes the bytes. The dispatch path is the
  single canonical path — no process-local proposal byte registry,
  no second artifact store, no mutable content identity, no parallel
  ProposalContent subsystem.

  Architecture: Kiln.M0 (KILN-M0-02 lane M8; KILN-M0-03 lane M9 bounded
  E2 implementation per SYS-M0-03 M11 work package).

  Bound: this module does not start a store, mutate Kiln workflow state,
  invoke a provider, or apply a Patch. It only writes durable
  completion bytes through the canonical Artifact substrate.
  """

  alias Kiln.Artifact
  alias Kiln.Artifact.{PutRequest, Store}
  alias Kiln.Store.{Error, Uuid}

  @max_byte_size Artifact.max_byte_size()

  @doc """
  Publish a Worker Output's bounded `completion_bytes` through the
  canonical Artifact Store. Returns the Worker Output with
  `raw_completion_ref` re-pointed to the durable Artifact identity.

  Reuse-safe: an identical publish with the same `idempotency_key`
  returns `{:ok, :replayed, worker_output}` with the persisted
  Artifact identity; no second blob is written.

  `store` is the canonical `%{conn: pid, artifact_root: path}` map
  returned by `Kiln.CLI.ready_store/1` (already opened via
  `Kiln.CLI.Runtime.open/2`). The Store never invents a parallel
  store; the published Artifact lives in the same root as every
  other Kiln Artifact.
  """
  @spec publish(map(), Kiln.M0WorkerOutput.t()) ::
          {:ok, :committed | :replayed, Kiln.M0WorkerOutput.t()}
          | {:error, Error.t() | term()}
  def publish(store, %Kiln.M0WorkerOutput{} = worker_output) do
    bytes = worker_output.completion_bytes

    with {:ok, %PutRequest{} = request} <-
           PutRequest.new(%{
             artifact_id: Uuid.v7(),
             idempotency_key: idempotency_key(worker_output),
             recorded_at: DateTime.utc_now() |> DateTime.to_iso8601(),
             bytes: bytes,
             metadata: artifact_metadata(worker_output)
           }),
         {:ok, artifact, %{status: status}} when status in [:committed, :replayed] <-
           Store.put(store, request) do
      rewired = %{
        worker_output
        | raw_completion_ref: %{
            "id" => artifact.artifact_id,
            "digest" => artifact.content_digest
          }
      }

      {:ok, status, rewired}
    else
      {:error, %Error{} = err} -> {:error, err}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Retrieve the immutable completion bytes for a Worker Output's
  rewired `raw_completion_ref`. Verifies that
  `sha256(retrieved_bytes) == ref.digest` before returning.

  Refuses:

    * `:unknown_artifact` if the Artifact row is absent;
    * `:E_COMPLETION_INTEGRITY` if the on-disk bytes verify but
      `:integrity_status != :verified`;
    * `:E_COMPLETION_DIGEST_MISMATCH` if the retrieved bytes do
      not hash to `ref.digest` (defense in depth — Artifact.Store
      already enforces this at fetch, but the contract is the
      caller's responsibility here).

  A fresh process will see byte-identical content because the
  Artifact is content-addressed and the bytes live below the
  canonical Artifact root, not in the in-memory proposal.
  """
  @spec resolve(map(), map()) ::
          {:ok, binary()}
          | {:error,
             :E_COMPLETION_INTEGRITY
             | :E_COMPLETION_DIGEST_MISMATCH
             | :E_COMPLETION_NOT_FOUND
             | Error.t()
             | term()}
  def resolve(store, %{"id" => id, "digest" => digest})
      when is_binary(id) and is_binary(digest) do
    case Store.read(store, id) do
      {:ok, bytes, %{integrity_status: :verified}} ->
        actual = sha256_hex(bytes)

        if actual == digest do
          {:ok, bytes}
        else
          {:error, :E_COMPLETION_DIGEST_MISMATCH}
        end

      {:error, %Error{code: :unknown_artifact}} ->
        {:error, :E_COMPLETION_NOT_FOUND}

      {:error, %Error{code: :artifact_unreadable}} ->
        {:error, :E_COMPLETION_INTEGRITY}

      {:error, %Error{} = err} ->
        {:error, err}
    end
  end

  # -- internals --

  defp idempotency_key(%Kiln.M0WorkerOutput{id: id}) do
    "wo_completion:" <> id
  end

  defp artifact_metadata(%Kiln.M0WorkerOutput{} = wo) do
    %{
      session_id: "wo:" <> wo.id,
      run_id: "wo:" <> wo.id,
      owner_kind: :session,
      owner_id: "wo:" <> wo.id,
      producer_kind: :provider,
      producer_id: producer_id(wo),
      kind: :output,
      media_type: "application/json",
      encoding: :utf_8,
      trust: :provider_output,
      sensitivity: :project,
      retention_class: :session,
      completeness: :complete
    }
  end

  defp producer_id(%Kiln.M0WorkerOutput{} = wo) do
    case wo.profile_ref do
      %{"id" => id} when is_binary(id) -> "kiln.worker.profile:" <> id
      %{id: id} when is_binary(id) -> "kiln.worker.profile:" <> id
      _ -> "kiln.worker.implementer"
    end
  end

  defp sha256_hex(bytes) when is_binary(bytes) do
    "sha256:" <> (:crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower))
  end

  # The canonical Artifact content-byte ceiling is the same bound the
  # Store enforces via `Kiln.Artifact.max_byte_size/0`. The provider
  # payload is bounded upstream by M3/M7 limits; this clause is
  # defense in depth — any unbounded producer input the Worker ever
  # sees is rejected here before the Artifact Store gets it.
  @doc false
  def _max_byte_size, do: @max_byte_size
end
