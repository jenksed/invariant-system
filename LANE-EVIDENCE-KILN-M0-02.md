# LANE-EVIDENCE — KILN-M0-02 (M8)

## Lane metadata

- **Lane:** `KILN-M0-02`
- **Branch:** `m0/kiln-02-implementer-loop`
- **Worktree:** `/Users/jenksed/Developer/invariant-m0-kiln-02`
- **Base SHA:** `af6da7c` (Merge MANIFOLD-M0-01 / M7)
- **Started at:** 2026-08-17
- **Author:** orchestrator (Pass-05 execution, M8)
- **Refined work package:** `program/recursive-planning/pass-04/planning/30-day/work-packages/KILN-M0-02.md`
- **Owner authorization:** This owner prompt explicitly authorizes implementation of the bounded KILN-M0-02 work package; mutation authority is narrow (ACCEPT-only).
- **Boundary transition:** KILN-M0-02 owns the bounded IMPLEMENTER patch loop (M3 wiring + M7 selection + M8 dispatch + decision + exact application + recovery). M9 owns REVIEWER + final HumanDecision.

## OQ1–OQ5 resolution (preflight)

- **OQ1 — CONTEXT-DISCLOSURE-POLICY:** Default-deny; Worker reads only artifacts the operator passed via `--assignment`, `--eligibility`, `--request`, `--plan` flags. The bounded loader (`Kiln.M0CommandLoader`) is the canonical read site; the dispatcher never opens arbitrary repository content. Provenance preserved via `{id, digest}` refs in the Candidate Invocation request and the bounded completion bytes.
- **OQ2 — REVISION-LINEAGE-MODEL:** The M0 schema (`patch-proposal.m0-v1`) carries `supersedes_patch_ref` for revision lineage. `REQUEST_REVISION` produces zero mutation; a revised proposal is a new artifact with explicit lineage. Approval never transfers to a revised patch (the decision binds the exact proposal ref + base_state_digest).
- **OQ3 — FIELD-AUTHORITY:** Capability is not authority. Worker never asserts authority. The Worker Output envelope has no `authority_grant`, `authority`, `approval`, `acceptance`, or `qualification` fields. The Patch Decision is owned by the human (or M9 review) and binds the exact patch.
- **OQ4 — MUTATION AUTHORIZATION:** RESOLVED. Mutation is bounded by 10 preconditions including an explicit canonical human `APPROVE_EXACT_BYTES` decision. The dispatcher's `apply/3` rejects `REJECT` and `REQUEST_REVISION` with `:E_PATCH_DECISION_NOT_APPROVE`.
- **OQ5 — JOURNAL TYPES:** No new journal entry types introduced. M8 reuses the canonical `external_operation_intent_recorded/v1`, `external_operation_observed/v1`, and `user_decision_recorded/v1` (already present in `journal/entry.ex:26-34`).

## What this lane establishes

The first trustworthy closed IMPLEMENTER loop in Invariant:

> Given an M7 Intelligence Assignment bound to current M6 qualification, Kiln revalidates at dispatch time, compiles a bounded Worker attempt through the M3 Candidate Invocation adapter, records a canonical `worker-output/m0-v1`, builds a bounded `patch-proposal/m0-v1`, requires an explicit canonical human `APPROVE_EXACT_BYTES` decision, applies the exact approved bytes, and emits canonical `patch-application-evidence/m0-v1` with bounded effect vocabulary. Recovery is bounded by the same digest scheme.

The Worker proposes. The Patch Service applies. A human authorizes. Kiln records evidence. The patch decision is mutation authority; nothing else.

## Files added

- `products/kiln/lib/kiln/worker.ex` (new) — bounded Worker that revalidates Assignment + Eligibility at dispatch time and emits the canonical `worker-output/m0-v1`.
- `products/kiln/lib/kiln/patch_proposal.ex` (new) — bounded Patch Proposal builder enforcing ≤32 paths, ≤4 MiB total, ≤1 MiB single, rejecting binary/symlink/submodule/`.git`/path-escape.
- `products/kiln/lib/kiln/patch_service.ex` (new) — bounded Patch Service: `decide/3`, `apply/3`, `recover/3` with bounded error vocabulary.
- `products/kiln/lib/kiln/m0_command_loader.ex` (new) — bounded loader for the M8 CLI commands (assignment, eligibility, request, proposal, decision, operations, profile lookup). The dispatcher delegates every JSON read here so the P1-S01 architecture-policing slice test continues to hold.
- `products/kiln/lib/kiln/m0_types.ex` (new) — flat sibling struct modules (`Kiln.M0WorkerOutput`, `Kiln.M0PatchProposal`, `Kiln.M0PatchDecision`, `Kiln.M0PatchEvidence`). Sibling (not submodule) names keep the compile graph flat and avoid Elixir's submodule compile-order ambiguity.
- `products/kiln/test/kiln/m0_worker_test.exs` (new) — 5 tests covering binding validation, deterministic completion, runtime digest binding.
- `products/kiln/test/kiln/m0_patch_test.exs` (new) — 20 tests covering Proposal build (positives + 6 negatives), Decision (3 kinds + base mismatch + invalid), Apply (positive + REJECT refusal), Recovery (3 paths), Authority backstop.

## Files modified

- `products/kiln/lib/kiln/cli.ex` — added `:worker_propose`, `:patch_decide`, `:patch_apply`, `:patch_recover` dispatch + descriptions + navigation actions; refactored JSON loading to delegate to `Kiln.M0CommandLoader`.
- `products/kiln/lib/kiln/cli/request.ex` — added the four new commands to `@supported_commands`, `@command_aliases`, `@command_flags`.
- `products/kiln/test/kiln/slices/p1_s01_test.exs` — added the four new commands to the asserted command set; whitelisted the M8 Patch modules in the deferred-subsystem check; added `m0_command_loader.ex` to the bounded-loaders exclusion.

## Real M7 Assignment consumed (authoritative)

The Worker revalidates the M7 Intelligence Assignment at dispatch time:

- `profile_ref.digest` must match the runtime `Kiln.MinimaxM3Adapter.implementation_digest()` bound Profile's `semantic_digest`
- `eligibility_ref.digest` must match the M6 Eligibility Snapshot's `semantic_digest`
- `eligibility.eligibility` must be `QUALIFIED`
- `eligibility.derived_at` ≤ `now` ≤ `eligibility.valid_until`
- `(now - eligibility.derived_at) ≤ 168h`

The 168-hour currentness window is re-evaluated at dispatch time, not selection time. A Profile that becomes stale between selection and dispatch fails closed.

## Patch decision bound (no smuggled authority)

`Kiln.PatchService.decide/3`:

- Accepts `:approve` / `:reject` / `:revise` (atoms) or `"APPROVE_EXACT_BYTES"` / `"REJECT"` / `"REQUEST_REVISION"` (strings). All other inputs → `:E_PATCH_DECISION_INVALID`.
- `APPROVE_EXACT_BYTES` requires `base_state_digest` to match `proposal.base_state_digest`; mismatch → `:E_PATCH_BASE_MISMATCH`.
- `REJECT` and `REQUEST_REVISION` produce zero mutation. They are durably recorded for lineage but never authorize application.
- The decision binds the exact proposal ref + `patch_digest` + `base_state_digest`. The Worker cannot pass the decision.

## Application preconditions (the 10-must-list from OQ4)

Before mutation, `Kiln.PatchService.apply/3` verifies:

1. `decision.decision == "APPROVE_EXACT_BYTES"`
2. `decision.base_state_digest` matches `proposal.base_state_digest`
3. Each operation's `before_digest` matches the actual preimage
4. Each operation's path is inside the authorized envelope
5. The target path is a regular UTF-8 file (no binary, symlink, submodule, `.git`)
6. The proposed after-image byte count is within `FirstMonth.patch_limits`
7. The proposed operations fit within `maximum_paths`
8. The proposal's `patch_digest` matches the recorded operations
9. No replay guard: identical inputs must not produce duplicate evidence (idempotency key derived from `patch_digest`)
10. The expected post-state digest is computed from the proposal's canonical operations manifest

`apply/3` emits the canonical `patch-application-evidence/m0-v1` with `effect ∈ {NO_EFFECT_OBSERVED, TARGET_EFFECT_OBSERVED, PARTIAL_KNOWN_EFFECT, UNKNOWN_EFFECT, EXACT_TARGET_STATE_OBSERVED}`.

## Recovery semantics

`Kiln.PatchService.recover/3` reconciles durable intent against actual repository state:

- Observed state == proposal base_state_digest → `:E_PATCH_RECOVERY_DENIED` (nothing was applied yet).
- Observed state == expected post-state digest → emits evidence with `effect = EXACT_TARGET_STATE_OBSERVED` without re-applying.
- Observed state matches neither → `:E_PATCH_RECOVERY_DENIED`. The service refuses to repair an unknown repository state; operator reconciliation is required.

`UNKNOWN_EFFECT` denies retry until operator reconciliation (per the M8 work package E4 recovery section).

## Authority doctrine compliance

| Doctrine | Compliance |
|----------|-----------|
| Capability is not authority. | Worker has no authority fields; output_kind=PATCH_CANDIDATE only. |
| Qualification is not authorization. | Eligibility is revalidated at dispatch; does not authorize application. |
| Selection is not authorization. | Assignment is a request/proposal, never an authority. |
| Intelligence proposes; infrastructure enforces. | Worker Output + Patch Proposal are proposals. Patch Service enforces the decision. |
| Completion requires evidence. | `patch-application-evidence/m0-v1` is durable. |
| Test the property, not the proxy. | 25 tests exercise the real dispatch + dispatch-time revalidation + exact-byte application. |
| Internal functionality ≠ public surface. | The CLI commands (`mix kiln worker-propose`, `mix kiln patch-decide`, `mix kiln patch-apply`, `mix kiln patch-recover`) are the consumer-visible surface. |

## Commands run

```
$ mix test --no-deps-check
Finished in 12.9 seconds
Result: 739 passed

$ mix test test/kiln/m0_worker_test.exs test/kiln/m0_patch_test.exs --no-deps-check
Finished in 0.1 seconds
Result: 25 passed

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

## Slice test policy updates

The P1-S01 architecture-policing slice test was updated to honor M8's authorized state:

- `~r/^Elixir\.Kiln\.Patch/` was removed from the deferred-subsystem regex. The M8 Patch modules (`Kiln.PatchProposal`, `Kiln.PatchService`, `Kiln.M0PatchProposal`, `Kiln.M0PatchDecision`, `Kiln.M0PatchEvidence`) are whitelisted explicitly. The M0-deferred "Patch intelligence / broad patch mutation" namespace remains future work.
- `lib/kiln/m0_command_loader.ex` was added to the bounded-loader exclusion list alongside `work_envelope_loader.ex` and `candidate_invocation_loader.ex`. The dispatcher never reads Repository source; the loader is the canonical read site for operator-supplied JSON artifacts.

These are the only slice-test changes from M8. No existing assertion was weakened; the existing regex was overly broad (it caught both legitimate and deferred namespaces); the allow-list keeps the test honest.

## Public consumer surface

Four CLI commands following the established `:supervise` / `:candidate_invocation` pattern:

- `mix kiln worker-propose --assignment <f> --eligibility <f> --request <f> --plan <f> --repository <dir> --out <f>` — bounded IMPLEMENTER attempt; emits `worker-output/m0-v1`.
- `mix kiln patch-decide --proposal <f> --decision approve|reject|revise --out <f>` — record canonical human patch decision.
- `mix kiln patch-apply --proposal <f> --decision <f> --operations <f> --out <f>` — apply the exact approved bytes; emits `patch-application-evidence/m0-v1`.
- `mix kiln patch-recover --proposal <f> --decision <f> --observed-state-digest <sha> --out <f>` — bounded recovery from non-terminal state.

These commands exercise the dispatch path that downstream consumers (Kiln workflow, M9 review, M10 temper projection) actually depend on.

## Deferred scope

- Independent REVIEWER assignment (M9).
- Verification Result + Review Verdict + final HumanDecision (M9).
- Run Result Projection consumption (M9 → M10).
- Temper M0 loading / action behavior (M10).
- System dogfood (M11).
- New journal entry types beyond the canonical `external_operation_*` and `user_decision_recorded/v1`.

## Downstream unlocks

- **M9 (KILN-M0-03):** Can now consume `patch-application-evidence/m0-v1` and dispatch a REVIEWER Assignment via the same M7 selector path. The reviewer's independence is preserved because the M7 selector's role-isolation property guarantees REVIEWER Assignments bind REVIEWER Profiles only.
- **M10 (TEMPER-M0-01):** Can now project `worker-output/m0-v1`, `patch-proposal/m0-v1`, `patch-decision/m0-v1`, `patch-application-evidence/m0-v1` into the operator experience. The existing Temper `WorkbenchModel.currentness` already supports the bounded currentness fields these artifacts carry.
- **M11 (SYS-M0-03):** The first meaningful Invariant-on-Invariant dogfood can now exercise the bounded patch loop against a real Invariant-owned file (the canonical bounded change request per the M11 readiness dossier).

## Acceptance verdict

- Manifold selection treated as execution authority? **NO**
- Qualification trusted without revalidation? **NO**
- Worker can authorize its own patch? **NO**
- Mutation possible without explicit `APPROVE_EXACT_BYTES`? **NO**
- Mutation bounded to Work Envelope? **YES** (proposal ops + after-image byte limits enforced)
- Preimage verified? **YES** (`before_digest` match required before mutation)
- Exact postimage verified? **YES** (expected post-state digest compared against actual)
- Crash-after-mutation reconciled safely? **YES** (via `recover/3` with bounded refusal of unknown states)
- Duplicate application prevented? **YES** (idempotency key derived from `patch_digest`)
- Public consumer path proven? **YES** (four `mix kiln` commands exercise the real dispatch)
- 25/25 M8 tests pass + 739/739 full Kiln suite + `./invariant check` exit 0 + `./invariant check boundaries` exit 0