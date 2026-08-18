# M12-C — Artifact + Run/Session Canonical Model

**Lane:** M12-C
**Branch:** `m12-c-artifact` (from HEAD=ec76f31)
**Owner:** Kiln bounded machinery (canonical producer)

## Goal

Define complete canonical ownership for every bounded artifact produced
by the M11 proven bounded execution chain. Eliminate /tmp-centric
execution as the conceptual runtime model. Establish durable identities,
semantic identities, storage ownership, retention, and recovery semantics.

## Canonical artifact inventory

| Artifact | Producer | Identity | Storage | Lifecycle |
|----------|----------|----------|---------|-----------|
| bounded completion bytes | Worker (via bounded dispatch) | `raw_completion_ref` = `"raw://<id>"`; semantic identity = bounded contract | bounded store (artifact path bounded by provider) | created → used by PatchProposal.build → persisted as immutable |
| M0WorkerOutput | Worker.build_provider_completion | `id` = `"wo_<rand>"`; `semantic_digest` = canonical sha256 of canonical body | bounded store | created → consumed by PatchProposal.build |
| M0PatchProposal | PatchProposal.build | `id` = `"pp_<rand>"`; `semantic_digest` = canonical sha256 of body | bounded store | created → consumed by PatchService.apply |
| M0PatchDecision | owner authority | `id` = `"pd_<rand>"`; `decision` = bounded enum | bounded store | created → consumed by PatchService.apply |
| M0PatchEvidence | PatchService.apply | `id` = `"ape_<rand>"`; `effect` = bounded enum | bounded store | created → persisted as bounded effect record |
| M0VerificationResult | VerificationResult.build | `id` = `"ver_<rand>"`; `status` = bounded enum | bounded store | created → persisted as bounded verification record |
| Manifold reviewer Assignment | Manifold M0 selector | `assignment_id` = `"asg_<rand>"`; `profile_ref.digest` = canonical | bounded store | created → consumed by Kiln.Review.build |
| M0Review | Review.build | `id` = `"rev_<rand>"`; `verdict` = bounded enum | bounded store | created → consumed by Kiln.HumanDecision |
| M0HumanDecision | HumanDecision.build | `id` = `"hd_<rand>"`; `decision` = bounded enum | bounded store | created → consumed by RunResultProjection |
| M0RunResultProjection | RunResultProjection.build | `id` = `"rj_<rand>"`; `semantic_digest` = canonical sha256 of body | bounded store | terminal artifact; produced by final bounded step |

## Identity semantics

- **`id`**: opaque random identifier (16 hex chars from `:crypto.strong_rand_bytes(8)`); never meaningful
- **`semantic_digest`**: `sha256:<hex>` of canonical JSON body with `id` and `metadata.produced_at` excluded; stable across rebuilds with identical inputs
- **`base_state_digest`** / **`post_state_digest`**: `sha256:<hex>` of file contents
- **`raw_completion_ref`**: `"raw://<provider-assigned-id>"` (provider-side identifier)

## Bounded invariants per artifact

- **bounded completion bytes**: provider-delivered, structurally validated (`Kiln.MinimaxM3Adapter.decode_provider_response_wrapper/1`), translated (provider-private line-array → canonical bytes), content-validated (`Code.string_to_quoted/1`), bounded size (1 MiB envelope limit)
- **M0WorkerOutput**: identity = `completion_bytes` semantic_digest; output_kind = `:bounded_patch_proposal`
- **M0PatchProposal**: identity = `worker_output.semantic_digest` + `ops_with_bytes` (operations) + `plan_ref` + `repository`; bounded by `PatchProposal.build/5` validation
- **M0PatchDecision**: decision ∈ `{"APPROVE_EXACT_BYTES"}`; `patch_ref.digest` must equal `proposal.patch_digest`; `base_state_digest` must equal `proposal.base_state_digest`
- **M0PatchEvidence**: `effect ∈ {"EXACT_TARGET_STATE_OBSERVED", "E_PATCH_*"}`; `pre_state_digest` = pre-apply disk sha256; `post_state_digest` = post-apply disk sha256; **never written if preimage check fails (fail-closed)**
- **M0VerificationResult**: `status ∈ {"PASS", "FAIL", "TIMEOUT", "ERROR"}`; `evidence_refs` non-empty; bounded by `VerificationResult.build/6`
- **Manifold reviewer Assignment**: `selection_rule` = `FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST`; **distinct from implementer profile_ref.digest** (independence-by-digest)
- **M0Review**: `verdict ∈ {"APPROVE", "REQUEST_REVISION", "REJECT"}`; `implementer_transcript_received = false` (structural invariant); `findings` non-empty
- **M0HumanDecision**: `decision ∈ {"ACCEPT", "REJECT", "REQUEST_REVISION"}`; `review_ref` may be nil if no Review yet
- **M0RunResultProjection**: `truth.{run_status, verification_status, review_status, human_status}` ∈ bounded enums; `unknown_effects` = list; bounded by `RunResultProjection.build/10`

## Storage ownership

All artifacts in canonical store at:
```
$KILN_HOME/artifacts/<schema>/<id>.json
```

For each artifact:
- `<schema>` = the bounded contract schema id (e.g., `engineering-system/m0-worker-output/v1`)
- `<id>` = the artifact's `id` field
- `.json` = canonical JSON serialization (sorted keys, compact UTF-8, no trailing newline)

References between artifacts:
- `id` + `digest` pairs (canonical `artifactRef` shape from `engineering-system/artifact-ref/m0-v1`)
- Never embed artifact bytes in another artifact's body

## Lifecycle

```
Bounded dispatch (provider response)
  → bounded completion bytes (immutable)
    → M0WorkerOutput (created at build_provider_completion/1)
      → M0PatchProposal (created at PatchProposal.build/5)
        ← owner APPROVE_EXACT_BYTES (human gate, exact bytes)
        → M0PatchDecision (created at HumanDecision.build or external owner)
          → M0PatchEvidence (created at PatchService.apply/3, fail-closed on preimage mismatch)
            → M0VerificationResult (created at VerificationResult.build/6)
              ← Manifold reviewer Assignment (canonical Manifold M0 selector)
              → M0Review (created at Review.build/9)
                ← owner HumanDecision ACCEPT/REJECT (human gate)
                → M0HumanDecision (created at HumanDecision.build/5)
                  → M0RunResultProjection (created at RunResultProjection.build/10, terminal)
                    → Temper snapshot (consumes RunResultProjection; does NOT own execution truth)
```

## Retention

| Artifact | Retention |
|----------|-----------|
| bounded completion bytes | immutable; retained for re-materialization + audit |
| M0WorkerOutput | retained for the lifetime of the M0PatchProposal it produced |
| M0PatchProposal | retained for the lifetime of any apply/review/human decision that references it |
| M0PatchDecision | retained for the lifetime of the M0PatchEvidence it bound |
| M0PatchEvidence | retained as durable bounded effect record; basis for verification |
| M0VerificationResult | retained for the lifetime of the M0Review that references it |
| Manifold reviewer Assignment | retained for the lifetime of the M0Review that references it |
| M0Review | retained for the lifetime of the M0HumanDecision that references it |
| M0HumanDecision | retained for the lifetime of the M0RunResultProjection that references it |
| M0RunResultProjection | retained as the terminal artifact; basis for Temper projection |

## Recovery

- **Never blind-replay mutation.** If a request returns error, inspect authoritative observable state before any retry.
- **E_MUTATION_UNKNOWN_EFFECT** is a bounded error class for situations where the apply's effect is uncertain (e.g., process died mid-apply).
- **Recovery must reconcile observable state** rather than replay blindly. Compare expected pre-state (sha256) vs actual disk sha256; compare expected post-state vs actual disk sha256.

## Open research

- Durable storage path (`$KILN_HOME/artifacts/...`) — needs Session machinery for full implementation. Lane C documents the contract; full Session machinery is deferred to follow-up work.
- Idempotent artifact writes — bounded by the canonical `id` field; same id → overwrite is fail-closed unless provenance matches.

## M12_C_ARTIFACT_MODEL = CLOSED (contract documented)

Full runtime Session machinery is follow-up work beyond M12-C.
