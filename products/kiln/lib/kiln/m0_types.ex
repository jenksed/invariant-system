defmodule Kiln.M0WorkerOutput do
  @moduledoc """
  Bounded Worker Output envelope emitted by `Kiln.Worker.propose/5`.
  Carries the parsed candidate digest plus a reference to the raw
  completion artifact; the Patch Proposal builder consumes both.

  Module name is `Kiln.M0WorkerOutput` (sibling of `Kiln.Worker`, not
  nested) to keep the compile graph flat — the bounded envelope is
  a distinct artifact kind.

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  defstruct [
    :id,
    :semantic_digest,
    :attempt_ref,
    :assignment_ref,
    :profile_ref,
    :output_kind,
    :raw_completion_ref,
    :parsed_candidate_digest,
    :completion_bytes,
    :base_commit,
    :base_state_digest,
    :adapter_implementation_digest
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          attempt_ref: map(),
          assignment_ref: map(),
          profile_ref: map(),
          output_kind: String.t(),
          raw_completion_ref: map(),
          parsed_candidate_digest: String.t(),
          completion_bytes: binary(),
          base_commit: String.t() | nil,
          base_state_digest: String.t(),
          adapter_implementation_digest: String.t()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = output) do
    Map.from_struct(output)
    |> Map.update!(:completion_bytes, &Base.encode16(&1, case: :lower))
  end
end

defmodule Kiln.M0PatchProposal do
  @moduledoc """
  Canonical Patch Proposal envelope emitted by `Kiln.PatchProposal.build/4`.
  The Patch Service consumes this envelope + the corresponding Worker
  Output to apply the approved bytes only after explicit ACCEPT.

  Architecture: Kiln.M0 (KILN-M0-02, lane M8).
  """

  defstruct [
    :id,
    :semantic_digest,
    :plan_ref,
    :attempt_ref,
    :repository,
    :base_commit,
    :base_state_digest,
    :operations,
    :patch_digest,
    :metadata,
    :supersedes_patch_ref
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          plan_ref: map(),
          attempt_ref: map(),
          repository: String.t(),
          base_commit: String.t() | nil,
          base_state_digest: String.t(),
          operations: [map()],
          patch_digest: String.t(),
          metadata: map(),
          supersedes_patch_ref: map() | nil
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = proposal) do
    Map.from_struct(proposal)
  end
end

defmodule Kiln.M0PatchDecision do
  @moduledoc "Canonical Patch Decision envelope (m0-v1)."
  defstruct [
    :id,
    :semantic_digest,
    :patch_ref,
    :base_state_digest,
    :decision,
    :proposal
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          patch_ref: map(),
          base_state_digest: String.t(),
          decision: String.t(),
          proposal: Kiln.M0PatchProposal.t()
        }
end

defmodule Kiln.M0PatchEvidence do
  @moduledoc "Canonical Patch Application Evidence envelope (m0-v1)."
  defstruct [
    :id,
    :semantic_digest,
    :patch_ref,
    :decision_ref,
    :pre_state_digest,
    :post_state_digest,
    :effect
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          patch_ref: map(),
          decision_ref: map(),
          pre_state_digest: String.t(),
          post_state_digest: String.t(),
          effect: String.t()
        }
end

defmodule Kiln.M0VerificationResult do
  @moduledoc """
  Canonical M0 Verification Result envelope (`engineering-system/verification-result/m0-v1`).

  Binds a registered verifier's outcome to the exact post-mutation
  state, the exact patch ref, and the registered verifier identity.
  Verification is evidence, not authority. PASS/FAIL/TIMEOUT/ERROR
  status never auto-fails the Run into a human decision; the human
  decides via `Kiln.HumanDecision` on the bounded dispatch surface.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  defstruct [
    :id,
    :semantic_digest,
    :plan_ref,
    :patch_ref,
    :result_state_digest,
    :registered_verifier,
    :status,
    :evidence_refs,
    :metadata
  ]

  @type status :: :PASS | :FAIL | :TIMEOUT | :ERROR

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          plan_ref: map(),
          patch_ref: map(),
          result_state_digest: String.t(),
          registered_verifier: map(),
          status: :PASS | :FAIL | :TIMEOUT | :ERROR,
          evidence_refs: [map()],
          metadata: map()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = vr), do: Map.from_struct(vr)
end

defmodule Kiln.M0Review do
  @moduledoc """
  Canonical M0 Review envelope (`engineering-system/review/m0-v1`).

  Emitted by an independently assigned, separately qualified Reviewer
  Profile after the IMPLEMENTER's patch has been verified. The Review
  binds to the exact Patch, result state, registered verification
  evidence, reviewer assignment, and a content-addressed reviewer
  disclosure manifest. The Review must prove
  `implementer_transcript_received: false` — the Reviewer context
  never includes the IMPLEMENTER's raw completion or hidden reasoning.

  Any patch/result-state change after the Review stales it
  (`E_REVIEW_STALE`); the old Review remains durable historical
  evidence; a new Review with a new binding is required for revision.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  defstruct [
    :id,
    :semantic_digest,
    :plan_ref,
    :patch_ref,
    :result_state_digest,
    :context_manifest_ref,
    :verifier_ref,
    :verdict,
    :findings,
    :implementer_transcript_received,
    :reviewer_assignment_ref,
    :metadata
  ]

  @type verdict :: :APPROVE | :REQUEST_REVISION | :REJECT

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          plan_ref: map(),
          patch_ref: map(),
          result_state_digest: String.t(),
          context_manifest_ref: map(),
          verifier_ref: map(),
          verdict: verdict(),
          findings: [String.t()],
          implementer_transcript_received: false,
          reviewer_assignment_ref: map(),
          metadata: map()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = review), do: Map.from_struct(review)
end

defmodule Kiln.M0HumanDecision do
  @moduledoc """
  Canonical M0 Human Decision envelope (`engineering-system/human-decision/m0-v1`).

  Records an explicit canonical human accept/reject/request-revision
  decision bound to the exact Patch, exact result-state digest, and
  (when present) the Review ref. HumanDecision is authoritative — it
  cannot be inferred from verifier exit code, Reviewer PASS, prior
  operator decisions, restart behavior, or cached data.

  Revision creates proper lineage (`REVISION-LINEAGE-MODEL`): a new
  Patch Proposal is built under the same Plan; prior artifacts are
  preserved as durable history. Nothing retroactively mutates prior
  artifacts.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  defstruct [
    :id,
    :semantic_digest,
    :plan_ref,
    :patch_ref,
    :result_state_digest,
    :review_ref,
    :decision,
    :recorded_at,
    :metadata
  ]

  @type decision_kind :: :ACCEPT | :REJECT | :REQUEST_REVISION

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          plan_ref: map(),
          patch_ref: map(),
          result_state_digest: String.t(),
          review_ref: map() | nil,
          decision: decision_kind(),
          recorded_at: String.t(),
          metadata: map()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = hd), do: Map.from_struct(hd)
end

defmodule Kiln.M0RunResultProjection do
  @moduledoc """
  Canonical M0 Run Result Projection envelope (`engineering-system/run-result-projection/m0-v1`).

  Projects durable truth from canonical artifacts:
    * Assignment (implementer + reviewer)
    * Patch + Patch Decision
    * Verification Result
    * Review
    * Human Decision
    * Run Result Envelope (v0)

  The projection complements — never rewrites — the v0 Run Result
  Envelope. The projection cannot strengthen canonical facts; if a
  status disagree with a predecessor artifact's binding, the
  projection fails closed.

  Architecture: Kiln.M0 (KILN-M0-03, lane M9).
  """

  defstruct [
    :id,
    :semantic_digest,
    :plan_ref,
    :implementer_assignment_ref,
    :reviewer_assignment_ref,
    :patch_ref,
    :patch_decision_ref,
    :verification_ref,
    :review_ref,
    :human_decision_ref,
    :run_result_ref,
    :truth,
    :metadata
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          semantic_digest: String.t(),
          plan_ref: map(),
          implementer_assignment_ref: map(),
          reviewer_assignment_ref: map(),
          patch_ref: map(),
          patch_decision_ref: map(),
          verification_ref: map(),
          review_ref: map() | nil,
          human_decision_ref: map() | nil,
          run_result_ref: map(),
          truth: map(),
          metadata: map()
        }

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = p), do: Map.from_struct(p)
end

defmodule Kiln.VerificationResult do
  @moduledoc """
  Bounded Verification Result builder.

  Produces the canonical `engineering-system/verification-result/m0-v1`
  envelope from a registered verifier invocation against the exact
  post-mutation state. The verifier must be registered in
  `Kiln.Verification.Registry`; unregistered or stale verifiers fail
  closed.
  """

  alias Kiln.Store.Canonical
  alias Kiln.M0VerificationResult

  @schema_id "engineering-system/verification-result/m0-v1"

  @allowed_status ~w(PASS FAIL TIMEOUT ERROR)

  @doc """
  Build a Verification Result envelope.

  Arguments:
    * `plan_ref` — artifact ref to the canonical Plan
    * `patch_ref` — artifact ref to the Patch Proposal
    * `result_state_digest` — `sha256:...` of the post-mutation state
    * `registered_verifier` — `%{id, digest}` from the Registry
    * `status` — one of `PASS|FAIL|TIMEOUT|ERROR`
    * `evidence_refs` — non-empty list of artifact refs

  Returns `{:ok, %M0VerificationResult{}}` or a bounded error.
  """
  @spec build(map(), map(), String.t(), map(), String.t(), [map()]) ::
          {:ok, M0VerificationResult.t()}
          | {:error, %{required(:code) => atom(), required(:reason) => String.t()}}
  def build(plan_ref, patch_ref, result_state_digest, registered_verifier, status, evidence_refs)
      when is_map(plan_ref) and is_map(patch_ref) and is_binary(result_state_digest) and
             is_map(registered_verifier) and is_list(evidence_refs) do
    cond do
      not is_binary(status) or status not in @allowed_status ->
        {:error,
         %{
           code: :E_VERIFICATION_STATUS_INVALID,
           reason: "status must be one of PASS|FAIL|TIMEOUT|ERROR"
         }}

      length(evidence_refs) < 1 ->
        {:error,
         %{
           code: :E_VERIFICATION_EVIDENCE_MISSING,
           reason: "evidence_refs must be a non-empty list"
         }}

      true ->
        body = %{
          "schema" => @schema_id,
          "verification_id" => "ver_" <> short_id(),
          "plan_ref" => plan_ref,
          "patch_ref" => patch_ref,
          "result_state_digest" => result_state_digest,
          "registered_verifier" => registered_verifier,
          "status" => status,
          "evidence_refs" => evidence_refs,
          "metadata" => %{
            "produced_at" => DateTime.utc_now() |> DateTime.to_iso8601()
          }
        }

        semantic = canonical_digest(@schema_id, Map.delete(body, "verification_id"))

        {:ok,
         %M0VerificationResult{
           id: body["verification_id"],
           semantic_digest: semantic,
           plan_ref: plan_ref,
           patch_ref: patch_ref,
           result_state_digest: result_state_digest,
           registered_verifier: registered_verifier,
           status: String.to_atom(status),
           evidence_refs: evidence_refs,
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
