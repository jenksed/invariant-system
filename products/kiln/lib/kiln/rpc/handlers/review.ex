defmodule Kiln.RPC.Handlers.Review do
  @moduledoc """
  WP-09 Lane 1: bounded RPC handler for `review.propose`.

  Wraps the canonical `Kiln.Review.build/9` (m9_review.ex:48) which
  emits the `engineering-system/review/m0-v1` envelope.

  Reviewer independence (CRITICAL): the builder enforces structural
  separation between IMPLEMENTER and REVIEWER assignment digests
  (m9_review.ex reviewer_assignment_ref["digest"] != implementer_
  assignment_ref["digest"]). This handler must NOT bypass that check
  — the RPC layer adapts to existing domain ownership.

  Review is evidence, NOT authority. APPROVE does not auto-accept;
  a separate `human.decide` invocation is required for an
  authoritative transition (WP-09 contract freeze §5 + §11).

  Required params:
    implementer_assignment_ref — bounded %{id, digest}
    plan_ref                    — bounded %{id, digest}
    patch_ref                   — bounded %{id, digest}
    result_state_digest         — sha256:<64hex>
    verification_ref            — bounded %{id, digest}
    reviewer_assignment_ref     — bounded %{id, digest} (MUST differ from implementer)
    verdict                     — APPROVE | REQUEST_REVISION | REJECT
    findings                    — non-empty list of strings
    context_manifest_ref        — bounded %{id, digest}

  Optional:
    idempotency_key             — idem_<32hex>
    request_digest              — sha256:<64hex>
    session_id                  — ses_<32hex>
    run_id                      — run_<32hex>

  Scope (router.ex): review:write

  Bounded error codes:
    E_MISSING_FIELDS, E_INVALID_FIELD, E_INVALID_DIGEST,
    E_REVIEW_VERDICT_INVALID, E_REVIEW_FINDINGS_MISSING,
    E_REVIEWER_CONTEXT_CONTAMINATED, E_REVIEW_BUILD_FAILED
  """

  alias Kiln.Review

  @required_param_keys [
    "implementer_assignment_ref",
    "plan_ref",
    "patch_ref",
    "result_state_digest",
    "verification_ref",
    "reviewer_assignment_ref",
    "verdict",
    "findings",
    "context_manifest_ref"
  ]

  @doc "Dispatch `review.propose`."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom()}}
  def handle("review.propose", params, opts) when is_map(params) and is_list(opts) do
    with :ok <- require_all(params, @required_param_keys),
         {:ok, implementer_ref} <- require_artifact_ref(params["implementer_assignment_ref"], "implementer_assignment_ref"),
         {:ok, plan_ref} <- require_artifact_ref(params["plan_ref"], "plan_ref"),
         {:ok, patch_ref} <- require_artifact_ref(params["patch_ref"], "patch_ref"),
         {:ok, digest} <- require_digest(params["result_state_digest"], "result_state_digest"),
         {:ok, verification_ref} <- require_artifact_ref(params["verification_ref"], "verification_ref"),
         {:ok, reviewer_ref} <- require_artifact_ref(params["reviewer_assignment_ref"], "reviewer_assignment_ref"),
         {:ok, context_ref} <- require_artifact_ref(params["context_manifest_ref"], "context_manifest_ref"),
         {:ok, verdict} <- require_verdict(params["verdict"]),
         {:ok, findings} <- require_findings(params["findings"]) do
      build_and_emit(
        implementer_ref,
        plan_ref,
        patch_ref,
        digest,
        verification_ref,
        reviewer_ref,
        verdict,
        findings,
        context_ref,
        opts
      )
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- build + emit --

  defp build_and_emit(
         implementer_ref,
         plan_ref,
         patch_ref,
         result_state_digest,
         verification_ref,
         reviewer_ref,
         verdict,
         findings,
         context_ref,
         opts
       ) do
    case Review.build(
           implementer_ref,
           plan_ref,
           patch_ref,
           result_state_digest,
           verification_ref,
           reviewer_ref,
           verdict,
           findings,
           context_ref
         ) do
      {:ok, review} ->
        {:ok,
         %{
           "review_id" => review.id,
           "semantic_digest" => review.semantic_digest,
           "verdict" => review.verdict,
           "findings" => review.findings,
           "reviewer_assignment_ref" => review.reviewer_assignment_ref,
           "plan_ref" => review.plan_ref,
           "patch_ref" => review.patch_ref,
           "verifier_ref" => review.verifier_ref,
           "result_state_digest" => review.result_state_digest,
           "context_manifest_ref" => review.context_manifest_ref,
           "implementer_transcript_received" => review.implementer_transcript_received
         }}

      {:error, %{code: :E_REVIEW_VERDICT_INVALID} = err} ->
        {:error, err}

      {:error, %{code: :E_REVIEW_FINDINGS_MISSING} = err} ->
        {:error, err}

      {:error, %{code: :E_REVIEWER_CONTEXT_CONTAMINATED} = err} ->
        {:error, err}

      {:error, %{code: _} = err} ->
        {:error, err}
    end
  end

  # -- validators (mirrors handlers/verify.ex exactly) --

  defp require_all(params, keys) do
    missing = Enum.filter(keys, fn k -> not Map.has_key?(params, k) end)

    case missing do
      [] -> :ok
      _ -> {:error, %{code: :E_MISSING_FIELDS, reason: "missing required fields", fields: missing}}
    end
  end

  defp require_digest(value, field) when is_binary(value) do
    if Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value) do
      {:ok, value}
    else
      {:error, %{code: :E_INVALID_DIGEST, reason: "#{field} must be sha256:<64hex>"}}
    end
  end

  defp require_digest(_, field) do
    {:error, %{code: :E_INVALID_FIELD, reason: "#{field} must be a sha256:<64hex> string"}}
  end

  defp require_artifact_ref(%{} = ref, field) do
    cond do
      not is_binary(ref["id"]) or byte_size(ref["id"]) == 0 ->
        {:error, %{code: :E_INVALID_FIELD, reason: "#{field}.id must be a non-empty string"}}

      not is_binary(ref["digest"]) or byte_size(ref["digest"]) == 0 ->
        {:error, %{code: :E_INVALID_FIELD, reason: "#{field}.digest must be a non-empty string"}}

      true ->
        {:ok, ref}
    end
  end

  defp require_artifact_ref(_, field) do
    {:error, %{code: :E_INVALID_FIELD, reason: "#{field} must be a %{id, digest} map"}}
  end

  defp require_verdict(v) when v in ~w(APPROVE REQUEST_REVISION REJECT), do: {:ok, v}

  defp require_verdict(_) do
    {:error, %{code: :E_REVIEW_VERDICT_INVALID, reason: "verdict must be one of APPROVE|REQUEST_REVISION|REJECT"}}
  end

  defp require_findings(list) when is_list(list) and length(list) >= 1 do
    if Enum.all?(list, &is_binary/1) do
      {:ok, list}
    else
      {:error, %{code: :E_REVIEW_FINDINGS_MISSING, reason: "findings must be a non-empty list of strings"}}
    end
  end

  defp require_findings(_) do
    {:error, %{code: :E_REVIEW_FINDINGS_MISSING, reason: "findings must be a non-empty list of strings"}}
  end
end
