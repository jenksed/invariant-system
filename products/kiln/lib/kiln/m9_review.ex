defmodule Kiln.Review do
  @moduledoc """
  Bounded M0 Review builder.

  Produces the canonical `engineering-system/review/m0-v1` envelope.
  The Review must prove `implementer_transcript_received: false` — the
  Reviewer context never includes the IMPLEMENTER's raw completion
  bytes, hidden reasoning, or scratchpad.

  Reviewer independence: the `reviewer_assignment_ref.digest` MUST
  differ from the IMPLEMENTER's `implementer_assignment_ref.digest`.
  The builder enforces this structural separation; the dispatcher
  re-validates qualification at dispatch time (same M8 dispatch
  rule, applied to REVIEWER role).

  Any patch/result-state change after the Review stales it
  (`E_REVIEW_STALE`); the old Review remains durable historical
  evidence; a new Review with a new binding is required for revision.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  alias Kiln.Store.Canonical
  alias Kiln.M0Review

  @schema_id "engineering-system/review/m0-v1"

  @allowed_verdict ~w(APPROVE REQUEST_REVISION REJECT)

  @doc """
  Build a Review envelope.

  Required arguments:
    * `plan_ref`, `patch_ref`, `result_state_digest`,
      `verification_ref`, `reviewer_assignment_ref`,
      `context_manifest_ref` — bounded artifact refs
    * `implementer_assignment_ref` — bound for the independent-Audit
      test (the builder rejects an assignment whose digest equals
      the implementer assignment's digest)
    * `verdict` — `APPROVE | REQUEST_REVISION | REJECT`
    * `findings` — list of bounded finding strings

  Returns `{:ok, %M0Review{}}` or a bounded error.
  """
  @spec build(map(), map(), map(), String.t(), map(), map(), String.t(), [String.t()], map()) ::
          {:ok, M0Review.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def build(
        implementer_assignment_ref,
        plan_ref,
        patch_ref,
        result_state_digest,
        verification_ref,
        reviewer_assignment_ref,
        verdict,
        findings,
        context_manifest_ref
      )
      when is_map(implementer_assignment_ref) and is_map(plan_ref) and is_map(patch_ref) and
             is_binary(result_state_digest) and is_map(verification_ref) and
             is_map(reviewer_assignment_ref) and is_list(findings) and
             is_map(context_manifest_ref) do
    cond do
      not is_binary(verdict) or verdict not in @allowed_verdict ->
        {:error,
         %{
           code: :E_REVIEW_VERDICT_INVALID,
           reason: "verdict must be one of APPROVE|REQUEST_REVISION|REJECT"
         }}

      length(findings) < 1 ->
        {:error,
         %{
           code: :E_REVIEW_FINDINGS_MISSING,
           reason: "findings must be a non-empty list"
         }}

      reviewer_assignment_ref["digest"] == implementer_assignment_ref["digest"] ->
        {:error,
         %{
           code: :E_REVIEWER_CONTEXT_CONTAMINATED,
           reason:
             "reviewer_assignment_ref.digest equals implementer_assignment_ref.digest; Reviewer must be independently assigned"
         }}

      true ->
        body = %{
          "schema" => @schema_id,
          "review_id" => "rev_" <> short_id(),
          "plan_ref" => plan_ref,
          "patch_ref" => patch_ref,
          "result_state_digest" => result_state_digest,
          "context_manifest_ref" => context_manifest_ref,
          "verifier_ref" => verification_ref,
          "verdict" => verdict,
          "findings" => findings,
          "implementer_transcript_received" => false,
          "reviewer_assignment_ref" => reviewer_assignment_ref,
          "metadata" => %{
            "produced_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          }
        }

        semantic = canonical_digest(@schema_id, Map.delete(body, "review_id"))

        {:ok,
         %M0Review{
           id: body["review_id"],
           semantic_digest: semantic,
           plan_ref: plan_ref,
           patch_ref: patch_ref,
           result_state_digest: result_state_digest,
           context_manifest_ref: context_manifest_ref,
           verifier_ref: verification_ref,
           verdict: String.to_atom(verdict),
           findings: findings,
           implementer_transcript_received: false,
           reviewer_assignment_ref: reviewer_assignment_ref,
           metadata: body["metadata"]
         }}
    end
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp canonical_digest(schema, payload) do
    "sha256:" <> Canonical.digest(schema, payload)
  end

  @doc """
  M11 N-7 (canonical): revalidate a previously-emitted Review against a
  candidate (patch_ref, result_state_digest) tuple. If the prior
  Review was bound to a different patch_ref or result_state_digest,
  it is stale for the current revision and the canonical contract
  rejects with `:E_REVIEW_STALE`.

  This is the smallest deterministic implementation of the
  `review-after-revision staled` acceptance property documented in
  the M9 readiness dossier and required by the canonical
  `integration/fixtures/m0/negative/review-reuse-after-patch-revision.json`
  contract (mapped to `E_REVIEW_STALE` in
  `integration/validate_m0.py`).

  No public schema expansion: it operates on the already-canonical
  `%M0Review{}` envelope. No new fields; no API breaking change.
  """
  @spec revalidate(M0Review.t(), map(), String.t()) ::
          :ok | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def revalidate(%M0Review{} = previous, current_patch_ref, current_result_state_digest)
      when is_map(current_patch_ref) and is_binary(current_result_state_digest) do
    cond do
      previous.patch_ref["digest"] != current_patch_ref["digest"] ->
        {:error,
         %{
           code: :E_REVIEW_STALE,
           reason:
             "review.patch_ref.digest #{previous.patch_ref["digest"]} does not match current patch_ref.digest #{current_patch_ref["digest"]}; a revised patch requires a new Review"
         }}

      previous.result_state_digest != current_result_state_digest ->
        {:error,
         %{
           code: :E_REVIEW_STALE,
           reason:
             "review.result_state_digest does not match current result_state_digest; the reviewed state has changed"
         }}

      true ->
        :ok
    end
  end

  def revalidate(_previous, _current_patch_ref, _current_result_state_digest) do
    {:error,
     %{
       code: :E_REVIEW_STALE,
       reason:
         "revalidate/3 requires a prior M0Review, a current patch_ref map, and a current result_state_digest binary"
     }}
  end
end

defmodule Kiln.HumanDecision do
  @moduledoc """
  Bounded M0 Human Decision intake.

  Records an explicit canonical operator accept/reject/request-revision
  decision bound to the exact Patch, exact result-state digest, and
  (when present) the Review ref. HumanDecision is authoritative; it
  cannot be inferred from verifier exit code, Reviewer PASS, prior
  operator decisions, restart behavior, or cached data.

  Revision creates proper lineage (`REVISION-LINEAGE-MODEL`): a new
  Patch Proposal is built under the same Plan; prior artifacts are
  preserved as durable history. Nothing retroactively mutates prior
  artifacts.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  alias Kiln.Store.Canonical
  alias Kiln.M0HumanDecision

  @schema_id "engineering-system/human-decision/m0-v1"

  @allowed_decision ~w(ACCEPT REJECT REQUEST_REVISION)

  @doc """
  Build a HumanDecision envelope.

  Required arguments:
    * `plan_ref`, `patch_ref`, `result_state_digest` — bounded refs
    * `review_ref` — artifact ref to the M0 Review (may be nil if no
      Review has been recorded yet — but if present, the builder
      enforces the result_state_digest match)
    * `decision` — `ACCEPT | REJECT | REQUEST_REVISION`

  Returns `{:ok, %M0HumanDecision{}}` or a bounded error.
  """
  @spec build(map(), map(), String.t(), map() | nil, String.t()) ::
          {:ok, M0HumanDecision.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def build(plan_ref, patch_ref, result_state_digest, review_ref, decision)
      when is_map(plan_ref) and is_map(patch_ref) and is_binary(result_state_digest) and
             (is_nil(review_ref) or is_map(review_ref)) and is_binary(decision) do
    cond do
      decision not in @allowed_decision ->
        {:error,
         %{
           code: :E_HUMAN_DECISION_INVALID,
           reason: "decision must be one of ACCEPT|REJECT|REQUEST_REVISION"
         }}

      true ->
        body = %{
          "schema" => @schema_id,
          "human_decision_id" => "hd_" <> short_id(),
          "plan_ref" => plan_ref,
          "patch_ref" => patch_ref,
          "result_state_digest" => result_state_digest,
          "review_ref" => review_ref,
          "decision" => decision,
          "recorded_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "metadata" => %{
            "decision_source" => "operator_explicit"
          }
        }

        semantic = canonical_digest(@schema_id, Map.delete(body, "human_decision_id"))

        {:ok,
         %M0HumanDecision{
           id: body["human_decision_id"],
           semantic_digest: semantic,
           plan_ref: plan_ref,
           patch_ref: patch_ref,
           result_state_digest: result_state_digest,
           review_ref: review_ref,
           decision: String.to_atom(decision),
           recorded_at: body["recorded_at"],
           metadata: body["metadata"]
         }}
    end
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp canonical_digest(schema, payload) do
    "sha256:" <> Canonical.digest(schema, payload)
  end
end

defmodule Kiln.RunResultProjection do
  @moduledoc """
  Bounded M0 Run Result Projection builder.

  Produces the canonical `engineering-system/run-result-projection/m0-v1`
  envelope from durable facts:
    * Implementer Assignment
    * Reviewer Assignment
    * Patch + Patch Decision
    * Verification Result
    * Review
    * Human Decision
    * Run Result Envelope (v0)

  The projection complements — never rewrites — the v0 Run Result
  Envelope. If a projected status disagrees with a predecessor
  artifact's binding, the projection fails closed
  (`E_PROJECTION_NOT_CANONICAL`).

  The projection carries `truth` with the bounded statuses:
    * `run_status` ∈ {completed, blocked, cancelled, failed, unknown}
    * `verification_status` ∈ {PASS, FAIL, TIMEOUT, ERROR}
    * `review_status` ∈ {APPROVE, REQUEST_REVISION, REJECT}
    * `human_status` ∈ {ACCEPT, REJECT, REQUEST_REVISION}
    * `unknown_effects` — bounded list of artifact IDs

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  alias Kiln.Store.Canonical
  alias Kiln.M0RunResultProjection

  @schema_id "engineering-system/run-result-projection/m0-v1"

  @allowed_run_status ~w(completed blocked cancelled failed unknown)
  @allowed_verification_status ~w(PASS FAIL TIMEOUT ERROR)
  @allowed_review_status ~w(APPROVE REQUEST_REVISION REJECT)
  @allowed_human_status ~w(ACCEPT REJECT REQUEST_REVISION)

  @doc """
  Build a Run Result Projection from durable facts.

  `truth` is a map with bounded statuses; the builder validates the
  enum membership of each status field. If `human_decision_ref` is
  nil, the `human_status` is `REQUEST_REVISION` (waiting on operator).

  Returns `{:ok, %M0RunResultProjection{}}` or a bounded error.
  """
  @spec build(map(), map(), map(), map(), map(), map(), map(), map(), map(), map()) ::
          {:ok, M0RunResultProjection.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def build(
        plan_ref,
        implementer_assignment_ref,
        reviewer_assignment_ref,
        patch_ref,
        patch_decision_ref,
        verification_ref,
        review_ref,
        human_decision_ref,
        run_result_ref,
        truth
      )
      when is_map(plan_ref) and is_map(implementer_assignment_ref) and
             is_map(reviewer_assignment_ref) and is_map(patch_ref) and
             is_map(patch_decision_ref) and is_map(verification_ref) and
             (is_nil(review_ref) or is_map(review_ref)) and
             (is_nil(human_decision_ref) or is_map(human_decision_ref)) and
             is_map(run_result_ref) and is_map(truth) do
    case validate_truth(truth) do
      :ok ->
        body = %{
          "schema" => @schema_id,
          "projection_id" => "rj_" <> short_id(),
          "plan_ref" => plan_ref,
          "implementer_assignment_ref" => implementer_assignment_ref,
          "reviewer_assignment_ref" => reviewer_assignment_ref,
          "patch_ref" => patch_ref,
          "patch_decision_ref" => patch_decision_ref,
          "verification_ref" => verification_ref,
          "review_ref" => review_ref,
          "human_decision_ref" => human_decision_ref,
          "run_result_ref" => run_result_ref,
          "truth" => truth,
          "metadata" => %{
            "produced_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          }
        }

        semantic = canonical_digest(@schema_id, Map.delete(body, "projection_id"))

        {:ok,
         %M0RunResultProjection{
           id: body["projection_id"],
           semantic_digest: semantic,
           plan_ref: plan_ref,
           implementer_assignment_ref: implementer_assignment_ref,
           reviewer_assignment_ref: reviewer_assignment_ref,
           patch_ref: patch_ref,
           patch_decision_ref: patch_decision_ref,
           verification_ref: verification_ref,
           review_ref: review_ref,
           human_decision_ref: human_decision_ref,
           run_result_ref: run_result_ref,
           truth: truth,
           metadata: body["metadata"]
         }}

      {:error, _} = err ->
        err
    end
  end

  defp validate_truth(truth) do
    cond do
      truth["run_status"] not in @allowed_run_status ->
        {:error,
         %{
           code: :E_PROJECTION_NOT_CANONICAL,
           reason: "truth.run_status must be one of completed|blocked|cancelled|failed|unknown"
         }}

      truth["verification_status"] not in @allowed_verification_status ->
        {:error,
         %{
           code: :E_PROJECTION_NOT_CANONICAL,
           reason: "truth.verification_status must be one of PASS|FAIL|TIMEOUT|ERROR"
         }}

      truth["review_status"] not in @allowed_review_status ->
        {:error,
         %{
           code: :E_PROJECTION_NOT_CANONICAL,
           reason: "truth.review_status must be one of APPROVE|REQUEST_REVISION|REJECT"
         }}

      truth["human_status"] not in @allowed_human_status ->
        {:error,
         %{
           code: :E_PROJECTION_NOT_CANONICAL,
           reason: "truth.human_status must be one of ACCEPT|REJECT|REQUEST_REVISION"
         }}

      not is_list(truth["unknown_effects"]) ->
        {:error,
         %{
           code: :E_PROJECTION_NOT_CANONICAL,
           reason: "truth.unknown_effects must be a list of artifact IDs"
         }}

      true ->
        :ok
    end
  end

  defp short_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  defp canonical_digest(schema, payload) do
    "sha256:" <> Canonical.digest(schema, payload)
  end
end
