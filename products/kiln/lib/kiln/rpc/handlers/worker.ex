defmodule Kiln.RPC.Handlers.Worker do
  @moduledoc """
  WP-09 Lane 1: bounded RPC handler for `worker.propose`.

  Wraps the canonical `Kiln.Worker.propose/5` (worker.ex:127) which
  emits the `implementer-patch-proposal-input/v1` envelope wrapped in
  a `Kiln.M0WorkerOutput` struct.

  The bounded propose function validates:
  * assignment digest matches profile eligibility
  * repository observation (git HEAD + state digest) is current
  * CandidateInvocation digest binding
  * Bounded completion envelope digest

  This handler is for the dispatch (proposal) step only — it does NOT
  apply any patches, generate any evidence, or commit any journal
  rows. The Patch Proposal is a separate downstream step (see
  `Kiln.PatchProposal.build/4` and `Kiln.RPC.Handlers.Patch.handle/3`).

  Required params (the bounded M8 dispatch envelope):
    assignment                — bounded assignment map (eligibility-bound)
    eligibility               — bounded eligibility map
    profile                   — bounded profile map
    request_attrs             — bounded request attrs map (includes --request envelope)
    repository_root           — non-empty string (absolute path to repo)

  Optional:
    idempotency_key           — idem_<32hex>
    request_digest            — sha256:<64hex>
    session_id                — ses_<32hex>
    run_id                    — run_<32hex>

  Scope (router.ex): orchestration:operate

  Bounded error codes:
    E_MISSING_FIELDS, E_INVALID_FIELD, E_INVALID_DIGEST,
    E_WORKER_BUILD_FAILED, plus any bounded codes propagated from
    `Kiln.Worker.propose/5` (e.g. invalid digest, invalid envelope).
  """

  alias Kiln.Domain.Error, as: DomainError
  alias Kiln.{M0WorkerOutput, Worker}

  @required_param_keys [
    "assignment",
    "eligibility",
    "profile",
    "request_attrs",
    "repository_root"
  ]

  @doc "Dispatch `worker.propose`."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom()}}
  def handle("worker.propose", params, opts) when is_map(params) and is_list(opts) do
    with :ok <- require_all(params, @required_param_keys),
         {:ok, repository_root} <- require_string(params, "repository_root") do
      assignment = Map.get(params, "assignment")
      eligibility = Map.get(params, "eligibility")
      profile = Map.get(params, "profile")
      request_attrs = Map.get(params, "request_attrs")

      propose_and_emit(assignment, eligibility, profile, request_attrs, repository_root, opts)
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- propose + emit --

  defp propose_and_emit(assignment, eligibility, profile, request_attrs, repository_root, opts) do
    case Worker.propose(assignment, eligibility, profile, request_attrs, repository_root) do
      {:ok, %M0WorkerOutput{} = wo} ->
        {:ok,
         %{
           "worker_output_id" => wo.id,
           "semantic_digest" => wo.semantic_digest,
           "attempt_ref" => wo.attempt_ref,
           "assignment_ref" => wo.assignment_ref,
           "profile_ref" => wo.profile_ref,
           "output_kind" => wo.output_kind,
           "raw_completion_ref" => wo.raw_completion_ref,
           "parsed_candidate_digest" => wo.parsed_candidate_digest,
           "base_commit" => wo.base_commit,
           "base_state_digest" => wo.base_state_digest,
           "adapter_implementation_digest" => wo.adapter_implementation_digest
         }}

      {:ok, other} ->
        # Worker.propose/5 always returns {:ok, M0WorkerOutput.t()}; this
        # branch is defensive against future signature drift.
        {:ok, %{"result" => other}}

      {:error, %DomainError{code: code, message: message}} ->
        {:error, %{code: code, reason: message}}

      {:error, %{code: _} = err} ->
        {:error, err}

      {:error, reason} ->
        _ = opts
        {:error, %{code: :E_WORKER_BUILD_FAILED, reason: inspect(reason)}}
    end
  end

  # -- validators --

  defp require_all(params, keys) do
    missing = Enum.filter(keys, fn k -> not Map.has_key?(params, k) end)

    case missing do
      [] -> :ok
      _ -> {:error, %{code: :E_MISSING_FIELDS, reason: "missing required fields", fields: missing}}
    end
  end

  defp require_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        {:error,
         %{
           code: :E_INVALID_FIELD,
           reason: "#{key} must be a non-empty string",
           field: key
         }}
    end
  end
end
