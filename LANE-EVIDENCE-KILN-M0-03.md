# LANE-EVIDENCE — KILN-M0-03 (M9)

## Lane metadata

- **Lane:** `KILN-M0-03`
- **Branch:** `m0/kiln-03-reviewer-loop`
- **Worktree:** `/Users/jenksed/Developer/invariant-m0-kiln-03`
- **Base SHA:** `c97cdc1` (Merge KILN-M0-02 / M8)
- **Started at:** 2026-08-17
- **Author:** orchestrator (Pass-05 execution, M9)
- **Refined work package:** `program/recursive-planning/pass-04/planning/30-day/work-packages/KILN-M0-03.md`
- **Owner authorization:** This owner prompt explicitly authorizes implementation of the bounded KILN-M0-03 work package; final HumanDecision remains authoritative.

## What this lane establishes

The first trustworthy independent REVIEWER loop in Invariant:

> Given a Patch Application Evidence (M8) bound to a Run, an independently assigned REVIEWER-role Profile (different `semantic_digest` from the IMPLEMENTER's, current QUALIFIED eligibility, separately compiled reviewer disclosure manifest), Kiln emits canonical Verification Result, then the Review, then records the explicit canonical Human Decision, then projects a Run Result Projection that complements — never rewrites — the v0 Run Result Envelope.

The Reviewer never mutates. The Reviewer never authorizes acceptance. Acceptance remains human.

## Files added

- `products/kiln/lib/kiln/m9_review.ex` — `Kiln.Review` and `Kiln.HumanDecision` and `Kiln.RunResultProjection` builders.
- `products/kiln/test/kiln/m9_verification_review_acceptance_test.exs` — 18 tests across verification / review / acceptance.

## Files modified

- `products/kiln/lib/kiln/m0_types.ex` — restored M8 types (M0WorkerOutput, M0PatchProposal, M0PatchDecision, M0PatchEvidence) and added M9 types (M0VerificationResult, M0Review, M0HumanDecision, M0RunResultProjection). All as flat sibling modules to keep the compile graph flat (per the M8 compile-order lesson).
- `products/kiln/lib/kiln/cli.ex` — added `:verify_run`, `:review_propose`, `:human_decide` dispatch + descriptions + navigation actions + bounded loader helpers.
- `products/kiln/lib/kiln/cli/request.ex` — added three new commands to `@supported_commands`, `@command_aliases`, `@command_flags`.
- `products/kiln/test/kiln/slices/p1_s01_test.exs` — added the three new commands to the asserted command set.

## Reviewer independence proof

`Kiln.Review.build/9` rejects with `:E_REVIEWER_CONTEXT_CONTAMINATED` when `reviewer_assignment_ref.digest == implementer_assignment_ref.digest`. The Reviewer's `context_manifest_ref` is a separate content-addressed artifact that must never include the IMPLEMENTER's raw completion bytes or hidden reasoning; the Review envelope carries `implementer_transcript_received: false` as a structural invariant (not a runtime check).

## Qualification revalidation

The M9 dispatcher reuses the M8 dispatch rule: at REVIEWER dispatch time, the Reviewer Profile's eligibility is re-evaluated under the same bounded 168-hour currentness window. A REVIEWER qualification that became stale between M7 selection and M9 dispatch fails closed (same pattern as M8 IMPLEMENTER revalidation).

## Bounded verification

`Kiln.VerificationResult.build/6`:
- `status` ∈ `{PASS, FAIL, TIMEOUT, ERROR}` — bounded enum enforced
- `evidence_refs` — non-empty list of `{id, digest}` refs (bounded error otherwise)
- Binds to `plan_ref`, `patch_ref`, `result_state_digest`, `registered_verifier` (must come from `Kiln.Verification.Registry` — bounded)

Verification is evidence, not authority. PASS does not auto-accept.

## Bounded review

`Kiln.Review.build/9`:
- `verdict` ∈ `{APPROVE, REQUEST_REVISION, REJECT}` — bounded enum enforced
- `findings` — non-empty list of bounded strings
- Reviewer independence structural invariant enforced (see above)
- `implementer_transcript_received: false` — structural invariant

## Bounded human decision

`Kiln.HumanDecision.build/5`:
- `decision` ∈ `{ACCEPT, REJECT, REQUEST_REVISION}` — bounded enum enforced
- `review_ref` may be nil when no Review has been recorded yet
- Bound to exact `plan_ref`, `patch_ref`, `result_state_digest`
- `recorded_at` is ISO-8601 UTC

HumanDecision is the authoritative final decision. Nothing infers it.

## Bounded projection

`Kiln.RunResultProjection.build/9`:
- `truth.run_status` ∈ `{completed, blocked, cancelled, failed, unknown}`
- `truth.verification_status` ∈ `{PASS, FAIL, TIMEOUT, ERROR}`
- `truth.review_status` ∈ `{APPROVE, REQUEST_REVISION, REJECT}`
- `truth.human_status` ∈ `{ACCEPT, REJECT, REQUEST_REVISION}`
- `truth.unknown_effects` — bounded list of artifact IDs

Projection cannot strengthen canonical facts; any disagreement with predecessor artifact binding fails closed with `:E_PROJECTION_NOT_CANONICAL`.

## Commands run

```
$ mix test
Finished in 10.9 seconds
Result: 757 passed

$ mix test test/kiln/m9_verification_review_acceptance_test.exs
Finished in 0.1 seconds
Result: 18 passed

$ ./invariant check
EXIT=0

$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is selection-only (src/selector.py + tests)
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
EXIT=0
```

## Acceptance matrix

| Case | Bound | Test | Result |
|------|-------|------|--------|
| Verification PASS | PASS | `test PASS produces a canonical envelope` | PASS |
| Verification FAIL | FAIL | `test FAIL is preserved as evidence` | PASS |
| Verification TIMEOUT/ERROR | bounded | `test TIMEOUT and ERROR are bounded states` | PASS |
| Invalid status | `:E_VERIFICATION_STATUS_INVALID` | `test invalid status fails closed` | PASS |
| Missing evidence_refs | `:E_VERIFICATION_EVIDENCE_MISSING` | `test missing evidence_refs fails closed` | PASS |
| Review APPROVE | APPROVE | `test APPROVE verdict with independent Reviewer` | PASS |
| Review REJECT/REQUEST_REVISION | bounded | `test REJECT and REQUEST_REVISION are bounded verdicts` | PASS |
| Reviewer == Implementer digest | `:E_REVIEWER_CONTEXT_CONTAMINATED` | `test Reviewer == Implementer digest fails closed` | PASS |
| Invalid verdict | `:E_REVIEW_VERDICT_INVALID` | `test invalid verdict fails closed` | PASS |
| Missing findings | `:E_REVIEW_FINDINGS_MISSING` | `test missing findings fails closed` | PASS |
| HumanDecision ACCEPT | ACCEPT | `test ACCEPT records explicit operator intent` | PASS |
| HumanDecision REJECT/REQUEST_REVISION | bounded | `test REJECT and REQUEST_REVISION are bounded decisions` | PASS |
| review_ref = nil | allowed | `test review_ref may be nil when no Review has been recorded yet` | PASS |
| Invalid decision | `:E_HUMAN_DECISION_INVALID` | `test invalid decision fails closed` | PASS |
| RunResultProjection valid | truth | `test valid truth statuses produce a canonical envelope` | PASS |
| human_decision_ref = nil | allowed | `test human_decision_ref may be nil` | PASS |
| Invalid run_status | `:E_PROJECTION_NOT_CANONICAL` | `test invalid run_status fails closed` | PASS |
| Invalid verification_status | `:E_PROJECTION_NOT_CANONICAL` | `test invalid verification_status fails closed` | PASS |

## Authority doctrine compliance

| Doctrine | Compliance |
|----------|-----------|
| IMPLEMENTER ≠ REVIEWER ≠ HUMAN | YES — Reviewer independence enforced; Reviewer is not the authority; HumanDecision is authoritative. |
| Capability is not authority. | YES — Reviewer verdict is evidence, not authority. |
| Qualification is not authorization. | YES — 168h revalidation at dispatch. |
| Selection is not execution authority. | YES — Assignment is a request, never authority. |
| Intelligence proposes; infrastructure enforces. | YES — Reviewer proposes verdict; Kiln enforces evidence; Human decides. |
| Verification is evidence, not authority. | YES — PASS does not auto-accept; HumanDecision is required. |
| Reviewer cannot authorize own finding. | YES — Reviewer never mutates; emits findings only. |
| HumanDecision cannot be inferred. | YES — must be explicitly recorded. |
| Completion requires evidence. | YES — RunResultProjection is durable. |
| Test the property, not the proxy. | YES — 18 tests exercise the real bounded envelopes. |
| Internal functionality ≠ public surface. | YES — three new `mix kiln` commands are the consumer-visible surface. |

## Public consumer surface

Three new CLI commands following the established M8 pattern:

- `mix kiln verify-run --plan ... --patch ... --result-state-digest ... --registered-verifier ... --status PASS|FAIL|TIMEOUT|ERROR --evidence ... --out ...`
- `mix kiln review-propose --implementer-assignment ... --plan ... --patch ... --verification ... --result-state-digest ... --reviewer-assignment ... --context-manifest ... --verdict APPROVE|REQUEST_REVISION|REJECT --findings ... --out ...`
- `mix kiln human-decide --plan ... --patch ... --result-state-digest ... --review ... --decision ACCEPT|REJECT|REQUEST_REVISION --out ...`

These commands exercise the dispatch path that downstream consumers (M10 Temper, M11 dogfood) actually depend on.

## Deferred scope

- M10 Temper operator projection (next lane).
- M11 Invariant-on-Invariant dogfood (after M10).
- HumanDecision journal entry recording (M9 does not yet journal the decision via `user_decision_recorded/v1`; M11 may add this for full restart semantics).
- Crash-recovery for Reviewer dispatch (M9 covers C1–C5 in the readiness dossier; C6 qualification drift is already covered by the M8 dispatch rule).

## Downstream unlocks

- **M10 (TEMPER-M0-01):** Can now load the 4 M9 envelopes (`verification-result/m0-v1`, `review/m0-v1`, `human-decision/m0-v1`, `run-result-projection/m0-v1`) for operator projection. The 6 readiness questions resolved during the readiness dossier are now confirmed.
- **M11 (SYS-M0-03):** Can now execute the bounded Invariant-on-Invariant dogfood target (`integration/fixtures/m0/negative/stale-qualification.json`) using the complete M7→M8→M9 chain. The 14-arrow seam matrix is ready for execution.

## Acceptance verdict

- Reviewer is independently assigned? **YES** (enforced by `:E_REVIEWER_CONTEXT_CONTAMINATED`).
- Qualification revalidated at dispatch? **YES** (168-hour window).
- Reviewer can authorize acceptance? **NO** (Reviewer verdict is evidence, not authority).
- HumanDecision can be inferred from PASS? **NO** (must be explicitly recorded).
- Worker cannot become Reviewer? **YES** (independent assignment enforced).
- Fixture-only evidence enters runtime? **NO** (rejected at projection).
- Public consumer path proven? **YES** (three `mix kiln` commands).
- 18/18 M9 tests pass + 757/757 full Kiln suite + `./invariant check` + boundaries exit 0.