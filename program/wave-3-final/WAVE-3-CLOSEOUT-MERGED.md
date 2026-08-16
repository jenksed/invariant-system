# Wave 3 Final Closeout — Merged Mains Acceptance

**Date:** 2026-08-13
**Status:** HOLD — TARGETED REPAIR REQUIRED

The Wave 3 acceptance proof executed against the actual merged system (not PR branches). The agent was honest: it surfaced two real defects in merged Kiln main and refused to promote to A or B. Wave 3 has **not failed** — Wave 3 has **not landed**. Two repair-class seams block the canonical CLI path and the durability proof.

---

# PART I — WAVE 3 ACCEPTANCE

## Canonical merged SHAs

```
ARSENAL_MAIN          = 4dcc1b0fe5c6a198c62b4b130fc9ff7c0e1b15e6   (PR #28)
LOADOUT_MAIN          = 5e64cb589951be38940dc4372295f2e8ff44bb4e   (PR #5)
KILN_MAIN             = c130dc9c73765a1cc7a1fd38886ec260d54f9d24   (PR #64)
TEMPER_MAIN           = 6084904510e3569191e9074fef8c9998f6a2e5ed   (stub)
ENGINEERING_SYSTEM_MAIN = a286bf31235c59df77a8c0bb47b3b6d285e4fa9b
```

## Product-by-product verdict

| Product | Merged main SHA | Verification | Integration proof | Verdict |
|---|---|---|---|---|
| Arsenal | `4dcc1b0...1b15e6` | PASS | Arsenal evaluation corpus ran against Loadout's productized repository-recon via the `loadout-runtime` adapter. 3 cases, 16 assertions, `run_digest sha256:5e66a6da...242a`, `conclusion=experimental`, 5/16 supported, `qualification_gap=experimental-to-experimental`. | READY |
| Loadout | `5e64cb5...44bb4e` | PASS | Plan v0 produced and bound to real Kiln boundary. Tampered plan rejected at integrity. Simulate-bound plan refused kiln execution. Simulated runs visibly simulated. | READY |
| Kiln | `c130dc9...4f9d24` | MIXED | Real supervision succeeded end-to-end when driven via `Kiln.Supervision.supervise/2` with a hand-built store map. `mix kiln supervise` CLI path currently crashes because `ready_store/0` forgets `artifact_root`. Restart recovers run_id, work_id, artifact_ids, evidence_id, proof_obligations, and acceptance_ready — but loses authority.granted/requested/denied, final_state.commit, and input_state.base_commit because `reconstruct_envelope/5` hardcodes placeholders instead of parsing the persisted authority_decision and repository_observation artifacts. | **HOLD** |
| Temper | `6084904...2e5ed` | STUB | Doc-only per the Wave 3 integration agreement. | NOT IN SCOPE |

## Captured system values (no normalization)

```
PLAN_ID                    = sha256:444e19bf8d741d39da1fe87e8867ec3e94425ff5cb0e9097b9654983eee2caf6
WORK_ENVELOPE_DIGEST       = sha256:b458bae189cb38a3c337f282e0e7a39912dbe8df9855fc785a3860d23591f0b0
WORK_ID                    = ba939712-c0d0-4e34-b44a-5f1aac332560
METHOD_ID                  = repository-recon/fixture-method
METHOD_VERSION             = 0.0.0-fixture
PROCEDURE_INTERFACE_DIGEST = sha256:343afb756f116bd00b2fb6ed9aef11326a21e3e86cd99160df39a2f18de05f43
TARGET_BASE_COMMIT         = 2b88c58435ac8db2d9d10238dee9307633e260be

KILN_RUN_ID                = 019ffb4f-2bfe-7935-9b34-667d382e68c8
AUTHORITY_REQUESTED        = ["git.read"]
AUTHORITY_GRANTED          = ["git.read"]
AUTHORITY_DENIED           = []
ARTIFACT_COUNT             = 2
ARTIFACT_IDS               = [019ffb50-d518-7a01-80e1-e34f8ba3aba9, 019ffb50-d520-7f36-a5b1-614a4324dfd8]
ARTIFACT_INTEGRITY         = durable .so content_digest + repository_state_digest persisted; authority_decision content includes run_id, work_id, granted_scope, reason_code
EVIDENCE_ID                = 019ffb50-d523-7afa-a5c3-3831e27727c5
EVIDENCE_CRITERION         = repo-state-observed
EVIDENCE_RESULT            = pass (subject_kind=repository, repository_state_digest=sha256:b4ca5ccaa...)
EVIDENCE_COMPLETENESS      = complete
EVIDENCE_FRESHNESS         = same_repository_state
EVIDENCE_CONTRADICTION     = (none)
RUN_LIFECYCLE_STATUS       = supervision_runs.run_state = "active"   (NOT "completed")
PROOF_OBLIGATIONS_SATISFIED    = ["repo-state-observed"]
PROOF_OBLIGATIONS_UNSATISFIED  = []
ACCEPTANCE_READINESS       = false
ACCEPTANCE_READINESS_REASONS   = ["Wave 3 v0 envelopes never claim user acceptance"]
UNKNOWNS                   = [
  "Kiln-observed repository_state_digest is not claimed to equal the producer workspace_state_digest",
  "producer input_state preserved separately from kiln repository_state_digest"
]

POST_RESTART_AUTHORITY_GRANTED = []         # projection defect
POST_RESTART_FINAL_COMMIT      = nil        # projection defect
POST_RESTART_BASE_COMMIT       = "0000000000000000000000000000000000000000"   # projection defect
POST_RESTART_RUN_ID_MATCH      = true
POST_RESTART_WORK_ID_MATCH     = true
POST_RESTART_ARTIFACT_MATCH    = true (count + ids)
POST_RESTART_EVIDENCE_MATCH    = true (count + id)
POST_RESTART_PROOF_SATISFIED   = ["repo-state-observed"]
POST_RESTART_PROOF_UNSATISFIED = []
POST_RESTART_ACCEPTANCE_READY  = false
```

## Findings

### W3-ACCEPT-01 — Kiln restart reconstruction is incomplete

**Classification:** PRODUCT DEFECT in merged Kiln main (or KILN — VISIBILITY / PROJECTION DEFECT).

`lib/kiln/supervision.ex` `reconstruct_envelope/5` hardcodes empty authority, `nil` commit, `"sha256:restored"` digest, and `"0000…0000"` base_commit. It never reads `artifacts.content`. The durable data exists in the artifact store but the projection doesn't reconstruct it.

After restart, run_id, work_id, artifact ids, evidence id, proof-obligation state, and acceptance-readiness all survived. But authority.granted/requested/denied, final_state.commit, and input_state.base_commit did NOT survive.

**Real bug. Real repair required.**

### W3-ACCEPT-02 — Loadout reported an impossible current project state (6bb5e65…)

**Classification:** TEST-HARNESS / EVIDENCE CONTAMINATION.

With isolated repos (`isolated-R0`, `isolated-R1`, `isolated-R0-fresh`) all observers (`git rev-parse HEAD`, `snapshotRepo()`, `runRepositoryRecon()`) agreed on every fixture. The contradiction cannot be reproduced. The contaminated target-repo was not safe evidence.

**Not a product defect. Not a blocker.**

### OPPORTUNITY-D — `ready_store/0` in `lib/kiln/cli.ex` (NEW finding during Phase 5)

**Classification:** PRODUCT DEFECT in merged Kiln main.

`ready_store/0` returns `%{conn: pid}` and forgets `artifact_root`. `mix kiln supervise` crashes inside `Kiln.Artifact.Store.put/2` with a FunctionClauseError. Real supervision succeeds only when the supervision path is invoked directly with a hand-built store map.

**Real bug. Real repair required.**

## Delight signals (preserve)

- **DELIGHT-01**: Authority, work completion, proof, and acceptance remained four independent dimensions in the original envelope.
- **DELIGHT-02**: After restart, run_id, work_id, artifact ids, evidence id, proof-obligation state, and acceptance-readiness all survived.
- **DELIGHT-03**: Execution-boundary binding is real — kiln-bound plans refused simulation, simulated plans refused kiln, tampered plans were rejected at integrity, simulated runs stayed visibly simulated.

## Wave 3 final verdict

**C — HOLD — TARGETED CLASIFICATION / REPAIR REQUIRED.**

Wave 3 has not failed. The architecture worked exactly as intended on the parts that exercised the four independent dimensions. Wave 3 has not landed either: two repair-class seams (ready_store bug, reconstruct_envelope projection defect) block the canonical CLI path and the durability proof until fixed.

Owners must:
1. Repair `ready_store/0` so the CLI path returns a store map including `artifact_root`.
2. Repair `reconstruct_envelope/5` to parse the persisted `kiln.authority.decision/v1` and `kiln.repository_observation/v1` artifacts.
3. Re-run Phase 5 through the repaired CLI path (not by bypassing ready_store) and Phase 7 to confirm the post-restart fields above are filled.

---

# PART II — OPPORTUNITY DISCOVERY

This is product research, not evidentiary. The primary acceptance produced the material; this section interprets it.

## User value observations

- Was the Loadout Plan actually useful to read? Yes — embedded recon output with environment, architecture, constraints, unknowns.
- Did the operator immediately need to manually inspect the repo anyway? Partially — the Run Result Envelope is useful but the post-restart projection drops authority, final commit, and base commit. The operator can't fully trust the restart view.
- Was important information present but buried? Yes — the `reconstruct_envelope/5` defect silently drops authority/comment. A user would not know without reading the source.

## Natural next question

After reading the Run Result Envelope, the operator's natural question is: "What authority did Kiln actually grant, and what artifact was bound to the granted scope?" The agent's evidence shows this is exactly what `reconstruct_envelope/5` cannot answer.

## Friction log

| Step | Observation | Severity | Manual work required | Owner | Possible opportunity |
|---|---|---|---|---|---|
| 4 — Loadout Plan | Worked cleanly | — | — | — | — |
| 5 — Real execution | Crashed at `Kiln.Artifact.Store.put/2` because `ready_store/0` forgot `artifact_root` | S3 | Reroute via direct `Kiln.Supervision.supervise/2` invocation with a hand-built store map | Kiln | Repair `ready_store/0` |
| 6 — Capture durable truth | Projection defect in `reconstruct_envelope/5` lost authority, final_commit, base_commit | S3 | Operators must read raw artifacts to recover authority; the envelope is not self-sufficient | Kiln | Repair `reconstruct_envelope/5` |
| 7 — Restart durability | run_id, work_id, artifact ids, evidence id, proof-obligation state, acceptance-readiness all survived; the durable four independent dimensions held | — | — | — | — |
| 8 — Negative matrix | Worked as designed once the driver was correct | — | — | — | — |
| 9 — Arsenal productized target | Worked correctly via the `loadout-runtime` adapter; catalog mismatch (5 supported, 11 failed) was honest and observable | — | — | — | — |
| 10 — Dogfood | Not yet executed | — | — | — | — |

## Delight log

- **DELIGHT-01**: Authority, work completion, proof, and acceptance were correctly maintained as four independent dimensions. `acceptance_readiness.ready = false` did **not** mask a failure; it accurately reported "not yet accepted by user."
- **DELIGHT-02**: After restart, the truly durable core identities survived — run_id, work_id, artifact ids, evidence id, proof-obligation state, acceptance-readiness. Wave 3's durability hypothesis is partially proved.
- **DELIGHT-03**: Execution-boundary binding is real. Kiln-bound plans refused simulation; simulated plans refused kiln invocation; tampered plans were rejected at integrity; simulated runs stayed visibly simulated. The "can't silently substitute" invariant holds.
- **DELIGHT-04**: The four-product constitutional split held. Arsenal/Loadout/Kiln each produced only what they owned. No cross-product contamination of authority.

## Important misses

- **Miss-01**: `reconstruct_envelope/5` lost authority, final commit, and base commit on restart. The post-restart envelope is not self-sufficient. The durable data exists in the artifact store, but the projection that presents it is broken.
- **Miss-02**: `ready_store/0` forgot `artifact_root`. The CLI path crashes. Operators would have to hand-build the store map. This is the highest-confidence blocker.
- **Miss-03**: The catalog mismatch between Arsenal's canonical corpus and Loadout's `ReconResultV1` is genuine — 5 supported, 11 failed. Arsenal's qualification_gap is "experimental-to-experimental" because the categories Loadout doesn't catalog aren't Loadout's fault. The graduation gap is honest.

## Natural next questions

- "What authority did Kiln grant?" — currently cannot be answered from the envelope after restart.
- "What commit was observed when the evidence was bound?" — currently cannot be answered from the envelope after restart.
- "What exactly did the supervisor DO, beyond creating durable records?" — the four independent dimensions are correctly preserved but the projections are incomplete.

## Arsenal method opportunities

The body of phases 4–9 produced Arsenal evaluation cases that could enter the **flywheel**:

```
DOGFOOD OBSERVATION
    (catalog mismatch: 5/16 supported)
        ↓
ARSENAL EVALUATION CASE
    (miss: Arsenal paths Loadout does not catalogue)
        ↓
POTENTIAL METHOD CHANGE
    (expand ReconResultV1 catalogue OR add a fact-mapping-extractor)
        ↓
EXPECTED LOADOUT IMPACT
    (cleaner recon output)
        ↓
KILN PROOF IMPACT
    (more Evidence produced = more proof available)
```

Not implementable yet — the catalog mismatch is itself data that should drive the next method change, not a pre-emptive fix.

## Loadout product opportunities

- **Loadout-01**: The current Plan/Run/Result presentation is correct under the kiln boundary, but the post-restart path drops authority. The next major Loadout feature would be "verify this change" or "review this Run," both of which require reading the missing authority back. This is a real Capability gap, not a fix.

## Kiln truth / acceptance opportunities

- **Kiln-01** (CRITICAL): The `reconstruct_envelope/5` projection defect means Kiln's most important claim — "I can answer what actually happened" — is partially false. The durable data exists. The projection that presents it does not read it. This is the highest-impact Kiln repair.
- **Kiln-02** (CRITICAL): The `ready_store/0` integration defect means the canonical CLI path is broken. Operators must hand-build the store map. This blocks the entire user-facing CLI experience.
- **Kiln-03**: The `reconstruct_envelope/5` placeholder approach (`"sha256:restored"`, `"0000…0000"`) is a code smell. The honest fix is to read the artifacts and reconstruct from authoritative data.

## Temper visibility opportunities

Each of these repeated lookups is a candidate Temper projection:

- **Temper-01**: "What authority did Kiln grant, and what scope?" — currently requires reading raw artifacts and reconstructing capability vocabulary manually.
- **Temper-02**: "What commit was observed when the evidence was bound?" — currently requires reading the repository_observation artifact.
- **Temper-03**: "What was the original Run Result Envelope?" — currently requires reconstructing from artifact store manually.

All three are the SAME question: "Why can't the post-restart envelope self-describe?" The answer is `reconstruct_envelope/5`. Temper must not build this projection until Kiln's projection is correct.

## Integration / transport opportunities

- **Integration-01**: `mix kiln supervise` is broken in production. The supervisor path is correct. The CLI stitching is broken. This is a LOCAL TRANSPORT IMPROVEMENT — the CLI needs to thread the right store map.

## Contract opportunities

- **Contract-01**: The QMR / adapter identity drift is real. Arsenal's artifact `provenance.adapter` records adapter module/path, but the QMR itself does not bind to any specific adapter. The graduation gap is documented at `docs/arsenal-method-evaluation.md`. Not a blocker today. Real block is when a non-fixture QMR promotion is desired.

## Flywheel candidate

The dogfood has not yet completed (Phase 10 was deferred). But the structural ingredients are present:

1. **DOGFOOD OBSERVATION**: 5/16 supported across 3 contexts. Arsenal's qualification gap is "experimental-to-experimental."
2. **ARSENAL EVALUATION CASE**: The 11 misses are stable across runs. They are reproducible.
3. **POTENTIAL METHOD CHANGE**: Either expand ReconResultV1 catalogue OR add a fact-mapping step in the adapter.
4. **EXPECTED LOADOUT IMPACT**: Cleaner recon output. Better unknown surfacing.
5. **KILN PROOF IMPACT**: More evidence produced per run. More proof obligations satisfied.

This is a real flywheel candidate. The agent that ran the proof identified the case. The next Method change is a response to that case.

---

# TOP OPPORTUNITIES (ranked)

### 1. **Kiln-01 — Repair `reconstruct_envelope/5` projection defect**

- **Observed evidence**: After restart, authority.granted/requested/denied, final_state.commit, and input_state.base_commit are hardcoded placeholders. The durable data exists in the artifact store but is not read.
- **Owner**: Kiln
- **User value**: 5/5 — the restart view becomes trustworthy. Without this fix, the restart durability claim is partially false.
- **Architectural leverage**: 5/5 — affects every restart query, every Temper projection, every "what happened" question.
- **Effort**: 2 — replace placeholder reconstruction with `artifacts.content` parsing for the two known artifact kinds.
- **Risk**: 1 — preserves durable data; only changes the projection.
- **Why now**: This is the single largest gap between "durable" and "useful." Without it, Wave 3 cannot honestly claim restart durability.
- **What NOT to build**: A new Run Result Envelope contract version. The fix is implementation-only.

### 2. **Kiln-02 — Repair `ready_store/0` in CLI**

- **Observed evidence**: `mix kiln supervise` crashes inside `Kiln.Artifact.Store.put/2` because `ready_store/0` returns `%{conn: pid}` without `artifact_root`. CLI path is broken.
- **Owner**: Kiln
- **User value**: 5/5 — operators cannot use the application boundary without hand-building the store map.
- **Architectural leverage**: 3/5 — fixes the canonical CLI path, but the fix is local to the CLI/store layer.
- **Effort**: 1 — one-liner addition of `artifact_root` to the store map.
- **Risk**: 1 — does not touch the supervisor or the durable substrate.
- **Why now**: This is the simplest fix in the queue. It enables the canonical CLI path to actually work.
- **What NOT to build**: A new CLI surface. The fix is to make the existing CLI honest.

### 3. **OPPORTUNITY-D — Kiln-01+02 combined repair**

- The above two are both Kiln and both required for `mix kiln supervise` to honestly work end-to-end. They should ship together.

### 4. **Loadout-01 — Implement "Verify This Change" / "Review This Run" Capability**

- **Observed evidence**: After restart, the operator cannot read authority or committed commit from the envelope. A review feature would need exactly this information.
- **Owner**: Loadout
- **User value**: 3/5 — important, but blocked by Kiln-01.
- **Architectural leverage**: 4/5 — turns the rebuilt Run into a navigable workflow primitive.
- **Effort**: 4 — new Capability, new Pack, new fixtures, new tests.
- **Risk**: 2 — must not contaminate the existing "Execute" Capability.
- **Why now**: It is the natural next Capability after the Run is honestly inspectable.
- **What NOT to build**: A general PR review system. The first Capability is narrow: "Verify this change."

### 5. **Arsenal — Improve ReconResultV1 catalogue coverage**

- **Observed evidence**: The dogfood-yielded 5/16 supported with 11 misses are reproducible. Arsenal's qualification gap is "experimental-to-experimental."
- **Owner**: Arsenal
- **User value**: 3/5 — depends on whether the new catalog hits more useful anchors.
- **Architectural leverage**: 3/5 — improves the body of cases Arsenal can evaluate.
- **Effort**: 2 — new adapter / catalogue mapping.
- **Risk**: 2 — must not break the v0 closed vocabulary.
- **Why now**: The Wave 3 acceptance produced the actual evaluation case. The next method change is a response to that case.
- **What NOT to build**: An LLM-based free-form extraction. The catalogue should be a deterministic extension.

### 6. **Temper-01 — Real Run Workbench v0**

- **Observed evidence**: The acceptance run produced many "I need to see this Run" moments. Each is a Temper projection candidate.
- **Owner**: Temper
- **User value**: 4/5 — makes the system legible.
- **Architectural leverage**: 4/5 — enables future review/verify Capabilities.
- **Effort**: 4 — new TUI (NODE 20) build.
- **Risk**: 3 — must not invent canonical truth. Must only display real Kiln facts.
- **Why now**: After Kiln-01, the Run facts are honestly displayable. Before Kiln-01, Temper would be a facade.
- **What NOT to build**: A chat. A fleet. A workflow engine. A configuration UI.

---

# RECOMMENDED NEXT MOVE

**NEXT DOPAMINE MOVE:** Kiln-01 + Kiln-02 combined repair (two small, surgical Kiln changes that close the Wave 3 acceptance loop).

**NEXT ARCHITECTURAL MOVE:** Loadout-01 — Implement "Verify This Change" Capability once Kiln-01 + Kiln-02 are merged and the restart envelope is honestly displayable.

**NEXT DAILY-USE MOVE:** Arsenal catalog expansion — once the dogfood completes, the 11 misses are the seed list for the next Method change.

These are **three distinct items**, not the same:

- **Dopamine** is the immediate repair. Small, satisfying, unblocks the canonical CLI path.
- **Architectural** is the next major Capability. Bigger, requires the dopamine to land first.
- **Daily-use** is the operationally-useful Method change. Lower priority, but produces a real flywheel.

---

# WAVE 4 DECISION

**F. TARGETED WAVE 3 REPAIR REQUIRED.**

- The architecture worked exactly as intended on the parts that exercised the four independent dimensions.
- Two real defects in merged Kiln main block the canonical CLI path and the durability proof.
- Wave 4 Temper implementation must NOT begin until the Wave 3 verdict reaches A or B.
- After Kiln-01 + Kiln-02 land and Phase 5/7 re-pass, the verdict can be re-evaluated.

---

# FINAL PRINCIPLE

The acceptance run was not only asking "Did Wave 3 work?" It was also asking "Now that it works, what is the system trying to become?"

The system worked. It exposed two real defects. The defects are small, classified, and owned. The next wave is not "build more" — it is "fix the two leaks, then continue."

The opportunity-extraction pass found a real flywheel candidate (the 5/16 dogfood case), three real high-impact Kiln improvements, and a clear next major Capability. The architecture is honest. The work is grounded. The roadmap is reactive to evidence, not manufactured.

Do not implement Wave 4 until the verdict is A or B.
