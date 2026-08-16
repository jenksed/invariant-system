# Handoff Prompt — Next Agent

## Orientation

You are picking up Wave 3 finalization work. Wave 3 was accepted as **Verdict A — LANDED** after a targeted repair of two real defects in merged Kiln main. The repair is on a branch, not yet merged. Your job is to take the next concrete step.

**Read the four closeout/adjudication documents in order before doing anything:**

1. `engineering-system/program/wave-3-final/WAVE-3-CLOSEOUT-MERGED.md` — the C verdict (integration proof findings)
2. `engineering-system/program/wave-3-final/WAVE-3-CLOSEOUT-MERGED-REPAIR.md` — the A verdict (post-repair proof)
3. `engineering-system/program/wave-3-5/WAVE-3-5-PROMPT-2-ARCHITECTURE-ADJUDICATION.md` — long-term ownership verdict
4. `engineering-system/program/wave-3-5/WAVE-3-5-DISCOVERY-PACKET.md` — the evidence behind the adjudication

The first ~50 lines of any one of these will orient you. The full content is for the specific reasoning.

## Current State (canonical merged heads)

```
engineering-system main                  = 689c477  (Wave 3.5 closeout)
project-arsenal main                     = 4dcc1b0  (PR #28 merged)
loadout main                             = 5e64cb5  (PR #5 merged)
kiln main                                = c130dc9  (PR #64 merged — pre-repair)
kiln branch work/p3-w01-kil-w3-...        = 5d07f07  (KILN-02 + KILN-01 repairs, NOT merged)
temper main                              = 6084904  (stub)
```

The Kiln repair branch is at `5d07f07` ahead of `c130dc9` on `work/p3-w01-kil-w3-work-envelope-supervision`. The branch head is `5d07f07` (KILN-02 commit). KILN-01 is at `1edc3a1`. The branch contains three commits since the merge: `1edc3a1` (KILN-01), `5d07f07` (KILN-02), and the prior merge-of-origin-main commit `1802b14`.

## The Wave 3 verdict

**A. WAVE 3 LANDED.**

The canonical CLI path reaches the durable Artifact + Evidence substrate. The post-restart projection reads every durable fact truthfully. The four independent dimensions (authority, work completion, proof, acceptance) survive process death without sentinel values.

Two defects were repaired:
- **KILN-02**: `ready_store/0` in `lib/kiln/cli.ex` was returning `%{conn: pid}` and omitting `artifact_root`. Fixed by exposing `Kiln.Store.artifact_root_for_path/1` and renaming `ready_store/0` → `ready_store/1` taking the parsed `Request`. Also added the missing `navigation_actions("supervise")` clause.
- **KILN-01**: `reconstruct_envelope/5` in `lib/kiln/supervision.ex` was hardcoding placeholders. Fixed by adding `Kiln.Artifact.Store.read/2` (digest-verifying byte read) and rewriting `reconstruct_envelope/5` to read `supervision_runs` for input bindings, locate observation and authority_decision Artifacts by schema, fetch every Evidence record, partition proof obligations against Evidence, and derive status from durable facts. Added migration 0006 to persist `base_commit` and `workspace_state_digest` in `supervision_runs`.

## The acceptance run produced these opportunity signals (preserved)

- **FLYWHEEL-01**: Arsenal productized-target evaluation: 5/16 assertions supported, 11 reproducible misses. Real engineering-intelligence R&D seed.
- **TEMPER-01**: Operators need a coherent durable Run inspection view (Temper Real Run Workbench v0).
- **LOADOUT-01**: "Verify This Change" is a high-leverage next Capability.
- **KILN-PROJECTION**: Restart reconstruction now naturally supports a canonical Run inspection read model.

## The Decision Fork

The user (owner) has four candidate next moves. They are not equally weighted; the verdict-A closeout documents the real ordering. The owner must choose AFTER the Kiln repair PR is merged and the integration proof re-run by the owner on a real machine.

The four candidates:

1. **Kiln repair PR merge + owner-machine integration proof re-run** (conservative path; closes the loop)
2. **Loadout "Verify This Change" Capability** (high-leverage next Capability once Run inspection is honest)
3. **Arsenal ReconResultV1 catalogue expansion** (the FLYWHEEL-01 seed — 11 misses)
4. **Temper Real Run Workbench v0** (the Wave 3.5 architecture-adjudicated recommendation)

The first is the **dopamine move** (small, satisfying, unblocks the canonical CLI path). The second is the **architectural move** (bigger, requires the dopamine to land first). The third is the **daily-use move** (operationally useful). The fourth is the **long-term visible-direction move**.

## Hard Constraints

- Wave 4 implementation must NOT begin until the Wave 3 verdict reaches A or B AND PR #64 (or the repair branch) is merged.
- Do NOT modify Loadout, Arsenal, Temper, or shared contracts.
- Do NOT change Work Envelope v0, Run Result Envelope v0, authority vocabulary, Artifact schemas, Evidence schemas, Currentness semantics, proof obligations, acceptance readiness, idempotency/replay, or Loadout procedure ordering.
- The repair is in Kiln only; it is the smallest correct seam.

## What to do next

The user's intent is to complete the merge cycle and then choose the next concrete step. The minimum useful Codex task is:

> Read the Wave 3 closeout documents. Tell me which of the four opportunity moves has the smallest concrete seam we can prepare this week, and what verification we would need before the owner picks.

This is a preparation task, not an implementation task. Do NOT begin implementing Temper, Verify This Change, Arsenal ReconResultV1 catalogue expansion, or any other Wave 4 work.

## Reading order for a fresh agent

1. `program/wave-3-final/WAVE-3-CLOSEOUT-MERGED-REPAIR.md` (~340 lines, what landed)
2. `program/wave-3-final/WAVE-3-CLOSEOUT-MERGED.md` (~340 lines, what was found before the fix)
3. `program/wave-3-5/WAVE-3-5-PROMPT-2-ARCHITECTURE-ADJUDICATION.md` (~370 lines, long-term verdict)
4. `program/wave-3-5/WAVE-3-5-DISCOVERY-PACKET.md` (~600 lines, evidence)

If you only have time for one document, read the closeout-repair. It is the most recent and complete.

## Standing protocol

- Do NOT manufacture roadmap work.
- Do NOT promote to verdict A or B unless the four independent dimensions are honestly verified.
- Do NOT begin implementation until the owner has merged the Kiln repair PR and the integration proof has been re-run on a real machine.
- Use the closeout documents as the source of truth for state, not session memory.
