============================================================
BEGIN WAVE 3.5 DISCOVERY PACKET FOR PROMPT 2
============================================================

Wave 3.5 Discovery Packet. Self-contained. All evidence-inline.

Prompt 2 will read this and adjudicate. Prompt 2 must NOT need to
re-inspect any repository to act on this packet.

Five Investigators were run in parallel, all read-only, no
implementation. Their individual reports were returned separately.
This packet is the consolidated handoff.

---

# A. BASELINE SNAPSHOT

Repository state at the time of investigator inspection:

| Repository | origin/main SHA | Wave 3 candidate branch / SHA | Open PRs | Wave 3 state |
|---|---|---|---|---|
| engineering-system | `9bfdd0dfbabfb5d8084ae0f955408b92d1c059be` | (main) | (none) | Wave 3 coordination package merged at `6ee8d7c` (WAVE-3-FIRST-REAL-RUN.md) and `9bfdd0d` (integration test scaffolding under `program/wave-3/integration-proof/`) |
| project-arsenal | `9bfdd0dfbabfb5d8084ae0f955408b92d1c059be` (this is the SHA from the prior prompt — but Inspector's note: actual main was at `486fc9d` post-PR #26 merge; PR #27 ARS-04 was merged at `c5fe7f9e`; PR #28 ARS-W3 adapter is at `7db08a4b` on `agent/ars-04-recon-method-evaluation`) | `agent/ars-04-recon-method-evaluation` at `7db08a4b` (PR #28 OPEN) | PR #28 ARS-W3 adapter | Adapter infrastructure merged |
| loadout | `93b3dcc4bd76e0f2a16b43c92d670df1350c3c14` (PR #3 merge) plus PR #4 → `df5a9c4` (Wave 2 LOD-02 plan/explain) plus PR #5 → `d95927fb` (Wave 3 Phase 1 Repository Recon v1) | `agent/lod-02-plan-explain` at `d95927fb` (PR #5 OPEN) | PR #4 (LOD-02 plan/explain), PR #5 (LOD-03 Recon v1) | Phase 1 ready; Phase 2 real Kiln driver in flight |
| kiln | `0f6164b0eb1f1c8e2f890e18d6636f3c0311347b` (canonical main post-PR #62) merged with PR #63 Wave 1 → `ddaa176` (DIAGNOSED) | `work/p1-s02-t01-artifact-evidence-substrate-v2` (PR #63) merged; `work/p3-w01-kil-w3-work-envelope-supervision` at `db1acdb6` (PR #64 OPEN) | PR #63 (Wave 1 evidence), PR #64 (KIL-W3 supervisor) | KIL-W3 supervisor branch ready |
| temper | `1ec41bdc3738e5a1aeaf6be20c171043c3204571` (PR #1 merge) | (none) | (none) | Documentation-only stub |

Wave 3 candidate state (non-accepted):

- **Kiln W3 supervisor** at `db1acdb6` on `work/p3-w01-kil-w3-work-envelope-supervision` — PR #64 OPEN. New modules: `Kiln.WorkEnvelope`, `Kiln.Supervision`, `Kiln.Authority`, `Kiln.RepositoryObservation`, `Kiln.RunResultEnvelope`, `Kiln.WorkEnvelopeLoader`, migration `0005_supervision_runs.sql`. 666/670 mix tests pass (4 pre-existing jsonschema failures unrelated).
- **Loadout W3 Phase 1 Recon v1** at `d95927fb` on `agent/lod-02-plan-explain` — PR #5 OPEN. Structured `ReconResultV1` schema embedded in Plan. 104/104 tests pass.
- **Loadout W3 Phase 2 real Kiln driver** — IN FLIGHT. Bound to Kiln W3 CLI shape.
- **Arsenal W3 adapter** at `7db08a4b` on `agent/ars-04-recon-method-evaluation` — PR #28 OPEN. Internal-fixture + shell-loadout-recon + loadout-runtime adapters. Adapter identity recorded in artifact `provenance.adapter`. 5-item honest graduation gap documented.

Governing docs inspected:

- `engineering-system/program/COORDINATION-OVERVIEW.md`
- `engineering-system/decisions/0001-product-system.md`
- `engineering-system/program/AGENT-OPERATING-MODEL.md`
- `engineering-system/program/launch/LAUNCH-MANIFEST.yaml`
- `engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md`
- `engineering-system/program/wave-3/integration-proof/README.md` + `TEST-MATRIX.md` + `EXPECTED-RESULTS.md` + `proof-repo/`
- Each product's `AGENTS.md`
- `kiln/AGENTS.md` + `kiln/CLAUDE.md` + `kiln/docs/INTERNAL-DOMAIN-MODEL.md` + `kiln/docs/SESSION-MODEL.md` + `kiln/docs/RUN-MODEL.md` + `kiln/docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md`
- `loadout/docs/PRODUCT-BOUNDARY.md` + `loadout/docs/PRODUCT-OBJECTS.md` + `loadout/docs/architecture/LOD-01.md` + `loadout/docs/architecture/LOD-02.md` + `loadout/docs/architecture/LOD-03-recon-v1.md`
- `project-arsenal/AGENTS.md` + `arsenal/CAPABILITY_CONTRACT.md` + `arsenal/ASSET_CONTRACT.md` + `docs/arsenal-lifecycle.md` + `docs/arsenal-method-evaluation.md` + `arsenal/knowledge/CONTRACT.md` + `arsenal/trust/CONTRACT.md` + `arsenal/graph/CONTRACT.md` + `arsenal/observability/CONTRACT.md` + `arsenal/substrates/CONTRACT.md`

Key implementation areas inspected:

- All five investigators read their assigned product's primary files. See Investigator reports for path-level evidence.

---

# B. OWNER VISION SUMMARY

(Prompt 1 does not adjudicate. This is a neutral restatement of the owner proposal.)

**Temper thesis.** A persistent conversational engineering environment in which a human directs a living multi-agent engineering organization, watches and intervenes in its work, and sees durable project intelligence accumulate. Conversation is the interface to engineering reality, not the canonical reality itself.

**Workbench.** The default surface is conversation. Workers, terminals, diffs, plans, evidence, history, decisions, unknowns, reviews, previews are all focus types reachable from conversation. Everything important is one action away from conversation and one Escape away from returning.

**Fleet.** Cartographer / Historian / Builder / Inspector and similar small formations. Larger formations collapse to INVESTIGATION / IMPLEMENTATION / VERIFICATION groups. Show the engineering organization at the highest level that contains useful information.

**Attention.** Pending contradictions, decisions, review-ready items, authority requests, results. Distinguish derived from stored.

**Pulse vs Motion.** Pulse = activity (read/call/spawn/test/tokens). Motion = durable reality transitions (Unknown → resolved, Decision → accepted, etc.). Pulse is cheap; Motion is durable.

**Project Frontier.** The current limiting condition between the project and its next meaningful state. Should be derived, not maintained.

**Project Reality.** The ingredients of project intelligence: repository state, accepted Decisions, Evidence, Unknowns, contradictions, capability state, acceptance state, durable Runs, negative knowledge. Open whether this is a canonical object, a projection, a query model, an umbrella, or a hybrid.

**Objective / Operation / Worker.** Proposed durable hierarchy: Project → Objective → Operation → (Loadout, Plan, Workers, Attempts, Findings, Unknowns, Decisions, Evidence, Result). Workers disposable, Operations survive, Project intelligence survives Operations.

**Worker inspection.** Mission, reason, parent, current activity, tool use, Findings, Evidence, Unknowns, authority, current state. NOT private chain-of-thought.

**Kiln-backed authority in Temper.** Render Kiln's authority decisions with Why / Authorized scope / Observed target / Consequence. Temper presents; Kiln is the source.

**Review experience.** Behavior / proof / evidence, not just diff.

**Raw terminal.** Preserved close to the work. Temper does not abstract it away.

**Limited pinning.** Conversation + one worker terminal side-by-side, not arbitrary tmux explosion.

**Human steering.** User correction creates real operational consequence (pause / stop / resume / Plan revision / authority revocation / Worker cancellation / stale Evidence recognition).

**Returning to a project.** "Welcome back. Since your last session: ✓ N Operations completed, ✓ U-31 resolved, × candidate B rejected, ! one Evidence stale. Current Frontier: ..."

**Loadout future model.** Goal / Capability / Method / Formation / Proof Strategy / Tool Requirements / Authority Request / Model / Reasoning Allocation → Operation Plan. Three example loadouts: FAST / RECOMMENDED / PARANOID. Hypothesis: "Loadout chooses engineering strategy. Loadout may choose Formation. Loadout may choose Proof Strategy. Loadout may recommend model/reasoning allocation. It must not become the runtime authority owner or generic worker scheduler."

**Formation examples.** Lead only; Lead / Cartographer / Historian / Builder / Inspector.

**Proof Strategy.** reproduce → establish ownership → falsify hypotheses → implement → independently verify.

**Kiln truth role.** Runs, authority, effects, Artifacts, Evidence, Currentness, contradictions, recovery, acceptance/readiness, durable execution truth. "Temper must not duplicate Kiln's truth model."

**Arsenal learning role.** Methods, Formations, Proof Strategies, contextual effectiveness, failure modes, model/role allocation. "Arsenal learns what works. Loadout chooses what to deploy. Kiln proves what actually occurred. Temper exposes the resulting value."

**Differentiation hypothesis.** Multi-agent immediacy + durable project intelligence + Project Frontier + intelligent Loadout construction + trustworthy Kiln execution truth + Project Motion + Arsenal learning. Not terminal rendering alone.

---

# C. TEMPER REALITY REPORT

Temper is a stub repository. The only tracked file is `README.md` (401 lines, Wave 2 PR #1 doc). No source, no build, no entry point, no test scaffolding, no terminal-rendering dependency, no `AGENTS.md`, no `package.json`/`tsconfig.json`.

Per `kiln/docs/CLI-TUI.md` (the architectural ceiling already declared): "native application commands and projections → Kiln-owned view model → renderer behaviour → selected terminal library". Renderer types do not enter domain, persistence, Evidence, or public command contracts. No terminal library chosen.

Per the Wave 3 integration agreement: "DO NOT IMPLEMENT. Temper's contribution is zero product code in Wave 3."

## Per-Concept Classification

| Concept | Classification | Evidence | Caveats |
|---|---|---|---|
| "Engineering happens" framing | VISION ONLY | README does not contain this framing | None |
| Persistent conversational engineering environment | VISION ONLY | No persistence, no session, no environment | None |
| Conversation as interface to engineering reality | VISION ONLY | No conversation primitive | None |
| Workbench concept (vs chat) | VISION ONLY | "Workbench" token absent from README | None |
| Conversation as default Workbench surface | VISION ONLY | No default surface | None |
| Project/Fleet/Attention three-pane layout | VISION ONLY | README explicitly omits UI layout | None |
| Focus types (Conversation, Worker, Terminal, Diff, Review, Plan, Loadout, Evidence, Finding, Unknown, Decision, History) | VISION ONLY | None of these terms appear as types | None |
| "One action away from conversation, one Escape away" | VISION ONLY | No keybinding, no keymap | None |
| Fleet of small Formation (Cartographer, Historian, Builder, Inspector) | VISION ONLY | None of these terms | None |
| Larger Formation collapse (INVESTIGATION/IMPLEMENTATION/VERIFICATION) | VISION ONLY | None of these labels | None |
| "Show at highest level containing useful information" | VISION ONLY | No aggregation logic | None |
| Attention items: ! CONTRADICTION, ? DECISION, △ REVIEW READY, ⚿ AUTHORITY, ✓ RESULT | VISION ONLY | No attention/glyph vocab | None |
| Pulse (activity) | VISION ONLY | No activity stream | None |
| Motion (transitions) | VISION ONLY | No lifecycle/transition graph | Adjacent: Arsenal epistemic lifecycle `Idea → Hypothesis → Experimental → Replicated/Evaluated → Qualified` lives in `project-arsenal/docs/arsenal-lifecycle.md`, not in Temper |
| Project Frontier | VISION ONLY | Not a Temper concept today | Adjacent: `acceptance_readiness` on `run-result-envelope.v0` is the closest read-side field |
| Project Reality integration | VISION ONLY | No reality store, no integration adapter | None |
| Objective / Operation / Worker hierarchy | VISION ONLY | Not declared | Cross-product ownership already drawn in `0001-product-system.md` |
| "Workers disposable. Operations survive. Project intelligence survives Operations." | VISION ONLY | Not asserted | Conflicts with prevailing cross-product ownership split if asserted |
| Worker inspection (mission, reason, parent, current activity, tool use, Findings, Evidence, Unknowns, authority, current state) | VISION ONLY | No Worker concept | None |
| Kiln-backed authority UX presentation | NATURAL EXTENSION (data-side) | README maps `authority_requests[]`; Wave 3 press test asserts `Authority git.read GRANTED`; cross-product contract `run-result-envelope.v0.md` | UX presentation is VISION ONLY; data is NATURAL EXTENSION gated on Kiln W3 first-month status projection stabilizing |
| Review experience emphasizing behavior/proof over diff | NATURAL EXTENSION (data-side) | README maps `proof_obligations`; evidence kinds catalogued | Dedicated "review" surface in Temper is novel |
| Raw terminal preserved alongside structured object | VISION ONLY | Architectural ceiling in `kiln/docs/CLI-TUI.md` explicitly blocks Temper from owning terminal | None |
| Limited pinning (Lead conversation + Builder terminal side-by-side) | VISION ONLY | No conversation, no terminal, no pinned-pane primitive | None |
| Human steering creates real operational consequence | VISION ONLY | No pause/stop/resume/Worker-cancellation primitive | Conflicts with read-only architectural ceiling |
| Returning to a project ("Welcome back. Since your last session: ...") | VISION ONLY | No session resumption concept | Adjacent: Wave 3 §6 Durability exists in Kiln |
| "Sessions disappear. Project intelligence survives" | VISION ONLY | Not asserted in Temper | Adjacent: asserted in engineering-system decisions and Wave 3 |

**Summary:** 24 of 26 concepts are VISION ONLY. 2 are NATURAL EXTENSION on the data side (gated on Kiln W3 first-month status projection stabilizing). 0 are ALREADY EXISTS. 0 are CONFLICT (no product primitive exists to contradict).

Key implementation areas inspected:
- `/Users/jenksed/Developer/engineering-system-workspace/temper/README.md` (only tracked file)
- `/Users/jenksed/Developer/engineering-system-workspace/temper/.git/` (reflog shows two commits)
- Full working tree scan: zero `src/`, `docs/`, `scripts/`, `lib/`, `tests/`, `bin/`, `fixtures/`, `examples/`, `plans/`, no `package.json`, `tsconfig.json`, `Cargo.toml`, `pyproject.toml`, `mix.exs`, `go.mod`, no `AGENTS.md`
- `/Users/jenksed/Developer/engineering-system-workspace/engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md` (read-only)
- `/Users/jenksed/Developer/engineering-system-workspace/engineering-system/decisions/0001-product-system.md` (read-only)
- `/Users/jenksed/Developer/engineering-system-workspace/engineering-system/program/COORDINATION-OVERVIEW.md` (read-only)

---

# D. KILN ONTOLOGY REPORT

## Current Kiln Ontology (integrated on canonical main)

| Concept | File | Semantics |
|---|---|---|
| Session | `lib/kiln/domain/session.ex` (per `docs/SESSION-MODEL.md`) | One accepted objective + complete Kiln work history. `session_id` (UUIDv7), `project_observation_id`, `initial_task_id`, `root_run_id`, `objective`, `criteria_revision`, `state ∈ {active, completed, abandoned}`, `revision`, `started_at`. Constructor returns `{session, task, run}` triple from one atomic transaction. |
| Task | `lib/kiln/domain/task.ex` | States desired work, never execution. `task_id`, `session_id`, `statement`, `criteria ≥ 1`, `constraints`, `exclusions`, `state ∈ {in_progress, satisfied, abandoned}`, `revision`, `created_at`. |
| Run / Root Run / Child Run | `lib/kiln/domain/run.ex` (per `docs/RUN-MODEL.md`) | "A Run is one durable, independently inspectable attempt or coordination boundary for one Task." Root is a relationship role, not a separate entity. `run_id`, `session_id`, `task_id`, `root_run_id` (equals `run_id` for Root), `state ∈ {ready, running, waiting_for_user, orphaned, completed, failed, canceled}`, `workflow_step`, `pending_decision_id`, `active_operation_id`, `revision`, `created_at`. Version 0.1 limits: max depth 1, max 1 active child, no writing child, no nested delegation. |
| Work | not present as a domain entity | The term appears in `KILN-INV-001` ("Kiln MUST model the state of repository work") but no first-month entity realizes it. The closest is the Wave 3 candidate `Kiln.WorkEnvelope` carrying `work_id`, `goal`, `capability`, `project_state`, `scope`, `constraints`, `proof_obligations`, `authority_requests`. |
| Authority | `lib/kiln/authority.ex` (Wave 3 candidate) | `decision_id`, `work_id`, `run_id`, `requested_capability` (only `"git.read"` accepted in Wave 3 v0), `requested_scope`, `granted_scope`, `repository_state_digest`, `result ∈ {granted, denied}`, `reason_code`, `decided_at`, `schema`. No general policy engine. |
| Artifact | `lib/kiln/artifact.ex` | `artifact_id`, `session_id`, `run_id`, `owner_kind ∈ {project, session, run}`, `producer_kind`, `kind ∈ {input, output, report, log, snapshot, patch, diff, summary, other}`, `media_type`, `encoding`, `content_digest`, `byte_size`, `content_location`, `trust`, `sensitivity`, `retention_class`, `completeness`, `recorded_at`. Content bytes live below the Artifact root, never in SQLite. Dual identity: `artifact_id` (record) + `content_digest` (bytes). |
| Evidence | `lib/kiln/evidence.ex` | `evidence_id`, `session_id`, `run_id`, `criterion_id`, `criterion_revision`, `subject_id`, `subject_kind ∈ {session, run, operation, patch, command, artifact, evidence, repository}`, `subject_state_digest`, `producer_kind`, `producer_id`, `method`, `result ∈ {pass, fail, blocked, unknown}`, `repository_state_digest`, optional patch/command/host bindings, `artifact_ids`, `evaluator_digest`, `observation_digest`, `completeness`, `freshness_rule`, `observed_at`, `recorded_at`, `rationale`, `schema = "kiln.evidence/v1"`, `idempotency_key`, `request_digest`, `record_digest`. |
| Currentness | `lib/kiln/evidence/currentness.ex` + `view.ex` | `Currentness.Context` carries `current_subject_state_digest`, `current_repository_state_digest`, `current_evaluator_digest`, optional current patch/command/host bindings, `artifact_integrity_by_id`, `invalidated_at`, `evaluated_at`. `Currentness.evaluate/2` returns `[View.t()]` with derived `freshness ∈ {current, stale, unknown}` and `contradiction ∈ {none, present, unknown}`. `Evidence.View` is ephemeral; never writes back to persisted Evidence. |
| Contradiction | computed only via `Currentness.evaluate/2` | Between two `:current` + `:complete` + `pass/fail` candidates sharing criterion revision, subject tuple, Repository state, and nullable Patch binding. Filtered by the Wave 3 K2-repair (only opposing-result members). |
| Acceptance | `RunResultEnvelope.acceptance_readiness` (Wave 3 candidate) | `ready: false` always in Wave 3 v0 (supervisor never manufactures user acceptance). `reasons` list. |
| Recovery | `lib/kiln/restart.ex` + `RunResultEnvelope.recovery` (Wave 3 candidate) | On restart, conservative classification marks a Run as `:orphaned` when `active_operation` is in a nonterminal state with no proved terminal observation. Recovery field is hard-coded to `nil` in Wave 3 v0. |
| Effects | `RunResultEnvelope.effects` (Wave 3 candidate) | `list(map())` with no fixed schema; producer is free to choose. In Wave 3 v0, effects are the observed Artifact ids and Evidence ids bound to a Run. |
| Projections | `lib/kiln/projections/session.ex`, `lib/kiln/projections/store.ex` | `Kiln.Projections.Session` schema `session_projection/v1` with `reducer_version = "1"`. Stamp includes `session_revision`, `last_sequence`. Validates internal invariants after every reduction. "A projection is plain string-keyed data so the same logical state always encodes to the same canonical bytes." |

## Relationships Among Existing Concepts

```text
Session (1) ─owns→ initial Task (1) ─attempted by→ Root Run (1)
Session (1) ─owns→ journal entries (sequence-stamped)
Session (1) ─owns→ current projection (rebuildable)
Root Run (1) ─may have→ pending Decision (0 or 1, while state = waiting_for_user)
Root Run (1) ─may have→ active Operation (0 or 1, while state = running)
Run (1) ─produces→ Artifact (N, via Artifact.Store.put)
Run (1) ─binds→ Evidence (N, via Evidence.Store.record)
Evidence (1) ─cites→ Artifact (0..32, via artifact_ids)
Evidence (1) ─evaluated by→ Currentness.evaluate (produces View)
Artifact (N) ─scoped by→ content_location (relative path under Artifact root)
Journal entry (1) ─reduces to→ Projection (deterministic, validated)
Run binds the work_id of a WorkEnvelope to a durable Run (Wave 3 candidate: supervision_runs table)
Authority.Decision binds (work_id, run_id, capability) and is persisted as a DecisionRecord Artifact (Wave 3 candidate)
RunResultEnvelope binds (work_id, run_id) and references the durable Artifact + Evidence rows
```

## Mapping Table for Proposed Concepts

| Proposed concept | Verdict | Maps to | Semantic overlap / Gap |
|---|---|---|---|
| **Operation** | EXACT EQUIVALENT | `lib/kiln/domain/operation.ex` `Kiln.Domain.Operation` | Exact: classes `{:model_invocation, :patch_application, :command_execution}`, states `{:intent_recorded, :started, :succeeded, :failed, :canceled, :unknown}`, idempotency_key, subject binding. No additional semantics needed. |
| **Objective** | PARTIAL OVERLAP | `lib/kiln/domain/session.ex` `Session.objective`, `lib/kiln/domain/task.ex` `Task.statement`, `WorkEnvelope.goal.title` (Wave 3 candidate), `docs/INTERNAL-DOMAIN-MODEL.md` proposed "Project objective" | All four carry a user-accepted free-text statement of intent. Gap: structured success criteria distinct from `criteria`; explicit lifecycle (drafted → accepted → revised); typed `objective_revision` separate from `criteria_revision`; binding to a Project entity (currently no `Project` table). |
| **Worker** | NO EQUIVALENT | No source file in `lib/kiln/`. `docs/INTERNAL-DOMAIN-MODEL.md` proposed, not implemented (`KILN-DOM-006`: "Worker identity is transient"). AGENTS.md mentions "transient model invocation Worker" / "transient Command Worker" as a process-creation rule, but no struct/module. | Gap: no struct, no `worker_instance_id`, no lease record, no `start/heartbeat/termination` event shape. |
| **Finding** | PARTIAL OVERLAP | `lib/kiln/evidence.ex` (`result ∈ {:pass, :fail, :blocked, :unknown}` against a `criterion_id`) and `lib/kiln/domain/decision.ex` `permitted_responses` | Evidence covers criterion-evaluated case. Gap: a "Finding" in the proposed sense often implies a free-form inspection report with `findings`/`omissions`/`scope`/`method` (per `docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md` "Inspected" stage). Evidence does not have free-form findings content — only result + optional rationale (max 8192 bytes). Also: no `:inspected` Evidence method. |
| **Unknown** | PARTIAL OVERLAP | `lib/kiln/evidence.ex` `result = :unknown` and `completeness = :unknown`; `lib/kiln/domain/operation.ex` `state = :unknown`; `lib/kiln/run_result_envelope.ex` `status = :unknown`; `RunResultEnvelope.unknowns` (list of explicit unknown strings) | Multiple vocabularies encode unknown-ness at multiple layers. Gap: no single first-class `Unknown` entity with identity, scope, freshness, or reconciliation rules. `run_result_envelope.unknowns` is an unbounded list of strings (no schema). |
| **Decision** | EXACT EQUIVALENT (with caveats) | `lib/kiln/domain/decision.ex` `Kiln.Domain.Decision` | Durable local-user decision shape realized. Caveat: First-month only `:local_user` is permitted; `requested_actor` is closed. `:completion` and `:reconciliation` subject kinds are declared but no producer currently creates them. |
| **Attempt** | EXACT EQUIVALENT | `lib/kiln/domain/run.ex` `Kiln.Domain.Run` (a Run is "one attempt or coordination boundary") | Exact: AGENTS.md and `docs/RUN-MODEL.md` both call a Run an attempt. Caveat: a Run is more than one Attempt (also carries workflow_step, pending_decision, operation reference). |
| **Project Reality** | UNCLEAR | No direct equivalent. Closest: `lib/kiln/repository_observation.ex` `Kiln.RepositoryObservation` (Wave 3 candidate) — `repository_state_digest` (Kiln-owned) + `input_state_digest` (producer's `workspace_state_digest`) | Covers this in Wave 3 v0 for one `git.read` capability. Gap: no Project-level (vs Repository-level) reality concept; no Workspace/Environment reality (proposed in `INTERNAL-DOMAIN-MODEL.md` as Workspace + Environment). Also: no "Project" table exists on main. |
| **Motion** | NO EQUIVALENT | None | Gap: no concept of work progression / movement / current-work pointer beyond `Run.workflow_step` (which is a discrete enum, not a continuous motion). No struct, no vocabulary. |
| **Attention** | PARTIAL OVERLAP | `lib/kiln/domain/decision.ex` `Decision` (a pending local-user decision is `Run.waiting_for_user`); `lib/kiln/journal/entry.ex` `pending_decision_recorded/v1`; `lib/kiln/projections/session.ex` `pending_decision` slot; `docs/INTERNAL-DOMAIN-MODEL.md` proposes `Attention request` (not implemented) | The current `pending_decision` slot covers user-blocking attention. Gap: no `Attention request` entity (proposed but not implemented). No support for non-user attention routing, urgency levels, multiple concurrent attention items, or non-blocking attention. AGENTS.md "Root-visible Attention" mentioned in v0.1 delivery boundary is not yet implemented. |

## Important Caveats

1. **Working tree state vs canonical main.** All `lib/kiln/` Elixir source on disk is untracked by this checkout's git (40 tracked files are coordination/program files only). HEAD is at `9bfdd0d` (`origin/main`). The Wave 3 modules are physically present on the candidate branch's working tree but are not committed or merged. Treat every `lib/kiln/` module described above as either (a) integrated into accepted P1-S01 architecture on canonical main, or (b) a Wave 3 candidate pending PR #64 merge.

2. **Wave 3 dependency split — already true on main vs requires KIL-W3 merge:**
   - **Already true on main (`9bfdd0d`):** `Session`, `Task`, `Run` (Root Run, Child Run referenced only in docs), `Operation`, `Decision`, `Action`, `ProjectObservation`, `Evidence`, `Evidence.Store`, `Evidence.RecordRequest`, `Evidence.Currentness`, `Evidence.View`, `Artifact`, `Artifact.Store`, `Artifact.PutRequest`, `Journal.Entry`, `Journal.Reducer`, `Journal.Replay`, `Projections.Session`, `Projections.Store`, `Restart`, `Workflow`, `CLI`, `VerificationManifest`, `OperationLifecycle`, `Store`, migrations `0001-0004`, `Conformance.FirstMonth`.
   - **Requires KIL-W3 merge (candidate at `work/p3-w01-kil-w3-work-envelope-supervision`):** `Kiln.WorkEnvelope`, `Kiln.Supervision`, `Kiln.Authority`, `Kiln.RepositoryObservation`, `Kiln.RunResultEnvelope`, `Kiln.WorkEnvelopeLoader`, migration `0005_supervision_runs.sql`. KIL-W3 branch is at `db1acdb6` on PR #64 OPEN.

3. **Anti-mapping examples:**
   - **Do NOT map Worker to a process.** Per `KILN-DOM-006` and AGENTS.md: "A Worker process can change without changing Run identity. Runtime handles must not be persisted." Worker is the live executor concept; today it has no struct.
   - **Do NOT map Authority to a general policy engine.** Per KIL-W3 moduledoc: "There is no general policy engine, no scope-expansion path, and no Loadout ontology import." Only `git.read` is accepted in Wave 3 v0.
   - **Do NOT map Operation class to a free-form operation.** `Kiln.Domain.Operation` classes are exactly three: `:model_invocation`, `:patch_application`, `:command_execution`. Other "operation" meanings are separate proposed entities not yet implemented.
   - **Do NOT map Artifact to Evidence.** Per `KILN-DOM-010`: "Claim, Evidence, and Receipt remain distinct." Per Evidence moduledoc: "An Artifact stores content. Artifact existence does not make the content Evidence or authorize model disclosure."
   - **Do NOT map Run completion to Task completion.** Per `KILN-DOM-004`: "Completing a Run does not automatically satisfy the Task."
   - **Do NOT map Decision to Attention request.** Decision is a closed, typed local-user-decision shape; Attention request is a separate proposed entity (not implemented).
   - **Do NOT map `RunResultEnvelope.recovery` to a recovery engine.** Field is hard-coded to `nil` in Wave 3 v0.
   - **Do NOT map `RunResultEnvelope.acceptance_readiness.ready = true` to user acceptance.** Per KIL-W3 moduledoc: "`acceptance_readiness.ready = true` does not mean the user accepted. The supervisor never manufactures success."

4. **Unclear areas requiring deeper evidence:**
   - **`work_id` vs `run_id` identity relationship.** Wave 3 candidate creates a `(work_id, request_digest) → run_id` binding table (`supervision_runs`), but the precise semantics of "retry of the same Work returns the same Run" are only validated by `supervision_test.exs` which exists in the candidate but is not on canonical main.
   - **`Authority.granted_scope`.** Moduledoc says "the actual scope Kiln granted, scoped to the observation's repository root," but the code grants `observation.repository` (a path) — this is the repository root, not a sub-path scope. The semantics of narrowing vs granting-equivalent-of-repository are not exercised by any current test on main.
   - **Contradiction scope.** Currentness defines contradiction between Evidence records; no contradiction entity exists at the Session or Project level.
   - **Effect enumeration.** `RunResultEnvelope.effects` is a `list(map())` with no fixed schema; the producer is free to choose.

---

# E. LOADOUT STRATEGY REPORT

## Current Strategy Concept Map (accepted main + PR #4)

| Concept | Location | Notes |
|---|---|---|
| Goal | `src/core/goal.ts` | `GOAL_CATALOGUE` (one entry: `understand-a-repository`); maps title → Capability id. |
| Capability | `src/core/capability-contract.ts`, `src/core/capability-registry.ts`, `src/core/schemas.ts` (`CapabilityContractV0Schema`) | Stable contract with `goal_outcome`, `inputs`, `outputs`, `effects`, `evidence_expectations`, `failure_shape`, `compatibility`. |
| Skill | `src/core/skill.ts`, `src/packs/repository-recon/skill.json` | `SkillDescriptor { id, qmrFixturePath, procedureEntry }`. Power-user swappable. |
| Pack | `src/core/pack.ts`, `src/packs/repository-recon/pack.json` | `PackManifest { id, version, capability, skill, ... }`. Lifecycle: install/inspect/remove/rollback. |
| QMR | `src/core/qmr.ts`, `fixtures/qualified-method-record.v0.yaml` | Provenance record; `loadAndValidateQmr` does status/outcome/context checks (fail closed). |
| Plan | `src/core/plan.ts`, `src/core/schemas.ts` (`LoadoutPlanV0Schema`) | Content-addressable artifact (sha256). Embeds Work Envelope, capability, pack, skill, QMR, compatibility, requested_authority, proof_obligations, project_state, execution_boundary, `plan.repository_recon` (Wave 3 Phase 1). |
| Work Envelope | `src/core/compile.ts`, `src/core/schemas.ts` (`WorkEnvelopeV0Schema`) | Producer = Loadout; `authority_requests[]` and `proof_obligations[]` are data. |
| Execution boundary | `src/core/plan.ts` (`execution_boundary: 'simulated' \| 'kiln'`), `src/core/fake-kiln-boundary.ts`, `src/core/kiln-driver.ts` | `simulated` = in-process fake boundary, all output labeled `simulated: true`. `kiln` = real `mix kiln supervise` via `submitWorkEnvelopeToKiln`. Fail closed on every error mode. |
| Workspace | `src/core/workspace.ts` | `.loadout/` inside target repo: `packs/`, `plans/`, `runs/`, `snapshots/`, `catalog.json`. |

Boundary rules (AGENTS.md, `docs/PRODUCT-BOUNDARY.md`): Loadout owns Workspace, Goal, Capability contracts, Skills/Packs, Catalog, Connectors, and Result presentation. Loadout does **not** own Arsenal experiments, runtime authority, effect execution, canonical evidence, recovery, acceptance readiness, or generic provider infrastructure.

## Per-Concept Evaluation

| Concept | Classification | Evidence | Caveats |
|---|---|---|---|
| Formation (team composition) | REQUIRES NEW PRIMITIVE | `src/core/goal.ts` (single goal); `src/core/schemas.ts` (`LoadoutPlanV0Schema` has no `formation`/`team`/`roles` field); AGENTS.md boundary rules (Loadout does not own generic provider infrastructure) | Could be modeled as a multi-Capability Plan or as a Pillar/Formation primitive layered on top of Capability. Either is a new concept. |
| Proof Strategy (reproduce → establish ownership → falsify hypotheses → implement → independently verify) | REQUIRES NEW PRIMITIVE | `src/core/schemas.ts` (`proof_obligations: { id, kind, requirement }` — flat, unordered, kind is a free-form string); `src/core/compile.ts` (a single hardcoded `repo-state-observed` obligation is emitted); no test asserts on phase ordering or falsify semantics | The Work Envelope v0 contract itself defines `proof_obligations` with a flat shape; expressing a multi-phase strategy without changing the v0 contract is not possible. Could be modeled as a higher-level Loadout orchestration artifact above the Plan, but that is a new primitive. |
| Tool Requirements | NATURAL EXTENSION | `src/core/schemas.ts` (`WorkEnvelopeV0Schema.authority_requests`, `scope`, `constraints`); `src/core/connector.ts` (Loadout-owned connector concept, no effect driver); AGENTS.md rule 7 ("Effectful integrations require Kiln authority and drivers; Loadout exposes configuration and intent") | Authority requests currently have only `{ capability, scope }`; richer tool-requirement data (tool name, version, constraints) would require extending the Work Envelope or adding a new artifact. |
| Authority Request | NATURAL EXTENSION | Already present. `src/core/schemas.ts` (`WorkEnvelopeV0Schema.authority_requests`). The bundled compile emits a single `git.read` request. | Authority decisions are owned by Kiln, not Loadout (AGENTS.md rule 7). Loadout only requests; it does not grant. |
| Model / Reasoning Allocation | REQUIRES NEW PRIMITIVE | `src/core/schemas.ts` line 38 (`models: z.array(z.string())` inside QMR `evaluation` only); `src/core/plan.ts` (`plan.method.confidence` records the QMR's confidence string but no model/reasoning field); no tests assert on model selection | The bundled procedure is purely deterministic file-system reads with no LLM call (`src/packs/repository-recon/run.ts`). Any model/reasoning allocation would be a new product object. |
| Alternative Loadouts (FAST, RECOMMENDED, PARANOID) | REQUIRES NEW PRIMITIVE | `src/core/schemas.ts` `execution_boundary: z.enum(['simulated', 'kiln'])`; `src/packs/repository-recon/capability.json` (no mode field); `src/core/goal.ts` (no preset selector) | Could be modeled as alternate Capability contracts sharing an `id`, or as a tier selector on the Goal. Either requires a new concept. |
| Operation Plan | NATURAL EXTENSION (if "Operation Plan" means a re-shaping of the current Plan); REQUIRES NEW PRIMITIVE (if it means multi-step orchestration) | `src/core/plan.ts` (Plan embeds exactly one Work Envelope, one Capability, one Skill, one Pack); `src/core/schemas.ts` `LoadoutPlanV0Schema` (no `steps[]` or `phases[]`); AGENTS.md stop condition: "Stop on any required cross-product contract change" | AGENTS.md explicitly excludes "a workflow engine that takes a Plan and orchestrates downstream steps" (`docs/architecture/LOD-02.md` line 192). An Operation Plan that sequences multiple Plans/Work Envelopes conflicts with that stop condition. |
| Tool/Requirements surfaced differently from current Plan | NATURAL EXTENSION | `src/core/plan.ts` lines 541-680 (`formatPlanText`); `src/core/schemas.ts` `LoadoutPlanV0Schema` (flat sections) | Adding new section shapes is a zod schema extension, not a new primitive; the existing Plan is the natural carrier. |
| "Loadout chooses engineering strategy" | NATURAL EXTENSION for Capability/QMR/Method; REQUIRES NEW PRIMITIVE for "engineering strategy" beyond that | `src/core/goal.ts` (Goal → Capability mapping owned by Loadout); `src/core/compile.ts` (compile emits a fixed envelope, including a hardcoded `git.read` request); AGENTS.md boundary rules 5 and 7 (Loadout owns the Work Envelope producer role; effectful integrations require Kiln authority) | Anything that crosses into "what to run, in what order, with which reasoning tier" is a new primitive. |
| "Loadout may choose Formation" | REQUIRES NEW PRIMITIVE | As for "Formation"; `src/core/goal.ts`; `src/core/schemas.ts` | None |
| "Loadout may choose Proof Strategy" | REQUIRES NEW PRIMITIVE | `src/core/compile.ts` lines 71-77 (single hardcoded obligation); `src/core/schemas.ts` `proof_obligations` (flat, unordered) | Changing the Work Envelope v0 contract shape is a cross-product contract change (AGENTS.md stop condition). |
| "Loadout may recommend model/reasoning allocation" | REQUIRES NEW PRIMITIVE | QMR records `evaluation.models[]` as provenance; Loadout does not allocate or recommend models | "Recommendation" is technically a softer requirement than "allocation"; even as a recommendation field on the Plan, no current primitive carries it. |
| "Loadout must not become runtime authority owner or generic worker scheduler" | NATURAL EXTENSION (already enforced) | AGENTS.md ("Loadout does not own: runtime permission/authority, effect execution, canonical evidence, recovery, or acceptance readiness"; "A package or connector may request authority but cannot grant it"); `docs/PRODUCT-BOUNDARY.md`; `src/core/kiln-driver.ts` (procedure is invoked only when `kilnResult.procedureShouldRun === envelopeShape.authority.granted.length > 0`); `src/core/fake-kiln-boundary.ts` (default deny-all authority); `tests/integration/kiln-driver-procedure-sentinel.spec.ts` (sentinel test that the procedure is NOT invoked when Kiln denies authority) | None; this is the current invariant. |

## Wave 3 dependency labels

- PR #5 (d95927fb, Repository Recon v1) only adds `loadout/repository-recon/v1` (architecture_anchors, constraints, unknowns, repository_state) embedded into the Plan; it does not introduce any of the proposed concepts. Anything relying on the structured v1 result (e.g., a recon-derived Formation) would have a Wave 3 dependency.
- Wave 3 Phase 2 (real Kiln driver in flight) is referenced by `src/core/kiln-driver.ts` and the Plan's `execution_boundary` field. None of the proposed concepts depend on Wave 3 Phase 2 specifically except "Authority Request" (the canonical Run Result Envelope from real Kiln already carries `authority.granted`/`denied`).

---

# F. ARSENAL LEARNING REPORT

## Current Learning/Evaluation Architecture (integrated on canonical main)

| Surface | Owner | Artifact | Notes |
|---|---|---|---|
| Capability Contract (behavior) | ARS-01 | `arsenal/capabilities/*.json`, `arsenal/CAPABILITY_CONTRACT.md`, `arsenal/capability.schema.json` | Harness-neutral, closed vocab for `lifecycle`, `evaluation.status`, `invocation`, `mutation`, `authority`, `execution`, `verification`, `evidence_outputs`, `provenance`. |
| Asset Contract (identity) | ARS-00 | `arsenal/registry.json` + `arsenal/registry.d/*.json`, `arsenal/ASSET_CONTRACT.md` | Separate evidence claim from capability lifecycle. |
| Qualified Method Record (method maturity) | ARS-01 | `evaluation/method-records/*.yaml`, `evaluation/method-records/qualified-method-record.v0.schema.json` | Closes schema id `engineering-system/qualified-method-record/v0`. `status` enum `experimental`/`qualified` is independent of capability lifecycle. |
| QMR validator | ARS-01 | `scripts/arsenal_method_record.py`, `scripts/test-method-record.py` | Refuses runtime-authority tokens; enforces `observed_failures` non-empty for experimental; canonical digest rule. |
| Method evaluation (deterministic local) | ARS-04 | `scripts/arsenal_evaluate.py`, `evaluation/method-cases/corpus.manifest.json`, `docs/arsenal-method-evaluation.md` | Closed epistemic-conclusion vocabulary `{"experimental"}` in v0; refuses auto-promotion; bound by `provenance.adapter`. |
| Adapter seam (ARS-W3) | ARS-W3 (merged) | `evaluation/adapters/{repository_recon_adapter,internal_fixture_adapter,shell_loadout_adapter,loadout_runtime_adapter}.py` | Three adapters, no silent fallback, adapter identity recorded in artifact `provenance.adapter`. |
| Bench / Capability evaluation | ARS-02 | `evaluation/BENCH_CONTRACT.md`, `evaluation/evaluation-case.schema.json`, `evaluation/evaluation-receipt.schema.json`, `evaluation/case-health-receipt.schema.json`, `scripts/arsenal_bench.py` | Case Health Receipt, Counterfactual/Ablation Receipt, Capability Evidence Passport. First earned `testing` for `capability.local-cloud-feature-delivery`. |
| Qualification receipts | ARS-02 | `evaluation/qualifications/*.json` (e.g., `agent-skills.repository-truth.v1.json`) | `status: candidate` today; structural/distribution-only evidence. |
| Capability Gap Preflight | ARS-04 | `arsenal/graph/CONTRACT.md`, `arsenal/graph/graph.json`, `scripts/arsenal_graph.py` | Route-level verdict: `READY` / `CAPABILITY_GAP` / `AUTHORITY_GAP` / `QUALIFICATION_GAP` / `UNKNOWN`. |
| Execution substrate selector | ARS-05 | `arsenal/substrates/CONTRACT.md`, `arsenal/substrates/{catalog,proof-requirements}.json` | Reality Budget ladder; lowest sufficient substrate. |
| Flight Recorder / Observability | ARS-07 | `arsenal/observability/CONTRACT.md`, `arsenal/observability/flight-record.schema.json` | `metadata-first-content-off`; normalizes Bench and Dagger receipts. |
| Knowledge Plane (typed observations) | ARS-09 | `arsenal/knowledge/CONTRACT.md`, `arsenal/knowledge/snapshot.schema.json`, `arsenal/knowledge/fixtures/kft-0-kiln.json` | Typed entities (`Decision`, `Evidence`, `Capability`, `Authorization`, `FieldObservation`, …); independent state dimensions (planned/permitted/authorized/implemented/verified/accepted). |
| Trust & Authority | ARS-08 | `arsenal/trust/CONTRACT.md`, `scripts/arsenal_trust.py` | Approval bound to exact bytes; never widens capability authority. |
| Source Model (canonical-fact ownership) | post-#24 / GC-01 | `arsenal/source-model.json` (+ schema) | Indexes who owns which fact (`capability.current-lifecycle`, `method-record.qualification-status`, …). |
| Program spine / roadmap | program | `docs/roadmap/capability-system.md`, `docs/roadmap/post-pr-24-deferred-architecture.md` | Public frontier: ARS-09 → ARS-10 → ARS-11 → ARS-12. |

Lifecycle vocabulary is the canonical projection of the epistemic chain (`Idea → Hypothesis → Experimental → Replicated/Evaluated → → Qualified`) onto the existing `LIFECYCLE_STATES` and `EVALUATION_STATES` (see `docs/arsenal-lifecycle.md`).

## Per-Concept Evaluation

| Concept | Classification | Evidence | Caveats |
|---|---|---|---|
| Methods (current state) | SUPPORTED BY CURRENT MODEL | `arsenal/capabilities/recon.json`; `evaluation/method-records/repository-recon.architecture-anchor.v0.yaml`; `evaluation/method-records/qualified-method-record.v0.schema.json`; `scripts/arsenal_evaluate.py`; `scripts/test-arsenal-evaluate.py`; `scripts/test-method-record.py`; `evaluation/method-cases/corpus.manifest.json`; `docs/arsenal-method-evaluation.md`; `docs/arsenal-lifecycle.md`; `arsenal/source-model.json` facts `method-record.method-evidence`, `method-record.method-provenance`, `method-record.qualification-status` | Only one QMR exists today; v0 evaluator's `epistemic_conclusion` is the singleton `experimental`. QMR is intentionally evidence-only — `validate_record` refuses any `filesystem.write`/`network.write`/`git.write`/`production.mutate`/`cloud.remote` token in the record body. |
| Formations (team composition) | NEW RESEARCH PRIMITIVE NEEDED | `grep -r "formation"` returns no Arsenal-side hits. The closest composition primitive is the Capability Graph (`arsenal/graph/CONTRACT.md`, `arsenal/graph/graph.json`) and the multi-step routes it already declares (repository audit, feature delivery, bug repair, Local Cloud feature delivery). The Capability Graph orders `capability.*` steps along `after` edges; it does not declare a "team" or "formation" unit. | The Capability Graph is the natural substrate to host a Formation concept if one is introduced (steps have versions, authority, lifecycle, qualification). Nothing currently distinguishes "who executes" (model/role/harness) from "what executes" (capability) inside Arsenal — that distinction is owned downstream by Loadout/Kiln. |
| Proof Strategies (reproduce, establish ownership, falsify hypotheses, implement, independently verify) | NATURAL EXTENSION | - *reproduce* ↔ `capability.tdd` `verification.requirements[].id = red_observed` (`arsenal/capabilities/tdd.json`), and to the ARS-05 substrate selector's `behavior-observation`/`repeatable-test` proof traits (`arsenal/substrates/proof-requirements.json`). - *establish ownership* ↔ Knowledge Plane `Authorization` entity + `owner-authorization` source (`arsenal/knowledge/snapshot.schema.json`), proven by KFT-0 (`docs/field-trials/KFT-0-kiln.md`, `arsenal/knowledge/fixtures/kft-0-kiln.json`). - *falsify hypotheses* ↔ Capability Graph `QUALIFICATION_GAP` / `AUTHORITY_GAP` / `CAPABILITY_GAP` verdicts (`arsenal/graph/CONTRACT.md`), and Bench Counterfactual/Ablation Receipts (`evaluation/BENCH_CONTRACT.md`). - *implement* ↔ `capability.tdd` (`green_observed`), `capability.local-cloud-feature-delivery` (`slice_and_independent_verification`), `workflow.software-feature-delivery`. - *independently verify* ↔ `capability.verify` + Bench Case Health `verifier_independent` check. | Each strategy already has a host primitive, but no "Proof Strategy" enum or routing key currently groups them. The five strategies fall under existing evidence kinds `test`, `runtime-observation`, `artifact`, `receipt`, `report`, `verdict` (Capability Contract `verificationRequirementEvidenceKind` in `arsenal/capability.schema.json`). KFT-0 demonstrates that "implementation authority absent" is observable per `(subject, predicate)` via Knowledge Plane claims. No first-class `proof_strategy` field exists; the closest taxonomy is `DISTRIBUTION_AXES = {activation, behavioral_efficacy, boundary_preservation, context_efficiency}` (`scripts/arsenal_protocol.py`), which is distribution-only. The QMR contract's `evidence_kind` vocab is also distribution-centric. |
| Model/Role allocation | SUPPORTED BY CURRENT MODEL for the *evidence* side; routing (ARS-10 Intent Compiler) is explicitly out of scope today | Capability fragment records `invocation: human | agent | composed` and `authority.required`/`forbidden`; the Flight Record schema records model/harness identity as `runtimeIdentity.status ∈ {observed, not-observed, not-applicable}` (`arsenal/observability/flight-record.schema.json`); the Knowledge Plane records model/role provenance on claims. Arsenal records model/role as evidence, never as authority. | ARS-10 is in `LATER`, not delivered. Arsenal deliberately does **not** choose models; it consumes observed provenance and exposes it as a routing input. ARS-10 contracts (per `arsenal/trust/CONTRACT.md` future-slice seams) are data-only — `route_gate.authorized`, `required_decision_id`, target digest. |
| Contextual effectiveness | SUPPORTED BY CURRENT MODEL for the *binding*; (separate) for "contextual effectiveness *as a learned property*" — there is no observed-effectiveness ledger tying context kind → observed outcomes today | QMR `qualified_for.contexts` + `qualified_for.exclusions` (negative knowledge is first-class) in `evaluation/method-records/qualified-method-record.v0.schema.json`. Capability `context.required` + `context.preferred` in `arsenal/capability.schema.json` and each fragment. | The corpus exercises three context_kinds (straightforward, governed, ambiguous). There is no cross-corpus effectiveness aggregate and no first-class observed-effectiveness record family. KFT-0's `FieldObservation` (`arsenal/knowledge/snapshot.schema.json`) classifies outcomes as `got-right | got-wrong | friction | gap | loss | unknown` but is bound to one snapshot, not generalized. |
| Failure modes | SUPPORTED BY CURRENT MODEL at the *surface* level; (separate) for a unified, cross-cutting failure-mode taxonomy | Bench `case_health.required_checks` vocabulary: `starting_state_reproducible`, `failure_reachable`, `success_reachable`, `acceptance_observable`, `expected_outcome_explicit`, `solution_not_leaked`, `verifier_independent`, `no_remote_credentials` (`scripts/arsenal_protocol.py` `CASE_HEALTH_CHECKS`). Bench `limitations` field on every receipt (`evaluation/BENCH_CONTRACT.md` "Loss retention"). QMR `evaluation.observed_failures` (required for `experimental` and `qualified`). Capability Graph `UNKNOWN` step state. Knowledge Plane `Unknown`, `NegativeKnowledge`, `FrictionEvent` entity kinds. Trust Plane `REVIEW_REQUIRED`, `ESCALATION_REQUIRED`, `REJECTED`, `REVOKED` verdicts. Method evaluator's `qualification_gap.label` closed vocabulary: `bounded-evaluator-only`, `no-behavioral-efficacy-evidence`, `no-qualification-receipt-bound-to-capability`, `experimental-to-experimental` (`scripts/arsenal_evaluate.py` `ALLOWED_GAP_LABELS`). | Failure surfaces are layered across ARS-02/ARS-04/ARS-08/ARS-09; there is no single "failure mode" enum. The closed vocabularies are small but disjoint. |
| "Arsenal learns what works. Loadout chooses what to deploy. Kiln proves what actually occurred. Temper exposes the resulting value." | NATURAL EXTENSION | - *Arsenal learns what works:* QMR + ARS-04 evaluator + Bench + Capability Graph gate + Knowledge Plane typed observations. Arsenal **records** observed effectiveness; it does **not** assert behavioral efficacy. - *Kiln proves what actually occurred:* Not owned by Arsenal. KFT-0 demonstrates the boundary — Arsenal's KFT-0 verdict was `NOT_AUTHORIZED / OWNER ADJUDICATION REQUIRED`, with the rule "Arsenal may record and explain this result but may not alter Kiln or issue authorization on the owner's behalf." The Knowledge Plane treats planning/permitted/authorized/implemented/verified/accepted as independent dimensions. - *Temper exposes the resulting value:* Not owned by Arsenal. Not present in the codebase. - *Loadout chooses what to deploy:* Not owned by Arsenal. The contract documents no source import of Loadout, no runtime dependency on Loadout; the `loadout-runtime` adapter only shells out to a procedure at an operator-supplied path. Arsenal records the adapter identity but does not choose deployments. | The architectural boundary that would need to be preserved is the `consumer-deployed` ownership layer (`arsenal/source-model.json`) — adding a learned-effectiveness ledger must not let Arsenal redefine consumer configuration or promote its own capability state. |
| "Current Arsenal architecture can evolve toward that without abusing QMR or absorbing Loadout ownership" | SUPPORTED BY CURRENT MODEL (as a *boundary-preserving property*, not a feature). Evolution toward the four-system view is consistent with the existing ownership layer split. | QMR validator refuses runtime-authority tokens (`scripts/arsenal_method_record.py` `validate_record`). Capability promotion is a separate decision from QMR status (`docs/arsenal-lifecycle.md`, `evaluation/method-records/contract-map.md`). Capability Contract and Asset Contract have a documented non-overlapping responsibility boundary (`arsenal/ASSET_CONTRACT.md`, `arsenal/CAPABILITY_CONTRACT.md`). Source model classifies `.arsenal.lock` as `consumer-deployed`; `arsenal.project.json` is the only consumer-authored artifact. Capability Graph explicitly refuses to widen authority profiles (`arsenal/graph/CONTRACT.md` "Permission profiles"). Trust Plane refuses to widen canonical capability authority (`arsenal/trust/CONTRACT.md` "Authority arithmetic"). | Two current contract gates would block parts of the evolution today: (a) the QMR contract's `procedure_ref` is a single SHA-256 and cannot bind to multiple adapters (gap item 1,3); (b) the QMR `status` enum has no productized-vs-fixture qualifier (gap item 4). These are explicitly flagged as required before QMR promotion, not blockers for evaluation work. |
| Evaluation of Adapters (ARS-W3 shell adapter) | SUPPORTED BY CURRENT MODEL | `scripts/arsenal_evaluate.py` `ALLOWED_ADAPTERS` = `{internal-fixture-procedure, shell-loadout-recon, loadout-runtime}`; `evaluation/adapters/repository_recon_adapter.py` Protocol + `ALLOWED_KINDS`; `evaluation/adapters/internal_fixture_adapter.py`; `evaluation/adapters/shell_loadout_adapter.py`; `evaluation/adapters/loadout_runtime_adapter.py`; `scripts/test-repository-recon-adapter.py` (determinism, positive, negative, no-silent-fallback, regression, provenance, translation tests); `arsenal/source-model.json` facts `protocol.method-evaluation-adapter-contract`, `protocol.method-evaluation-adapter-findings-shape`, `protocol.method-evaluation-adapter-tests` | Adapter evaluation today is *included in the artifact's run digest*, not *separated as its own first-class receipt*. A reviewer asking "how good is adapter X?" reads the artifact's per-case metrics and the `provenance.adapter` block; the system does not currently emit a separate "adapter evaluation" receipt with its own counterfactual arms or Case Health checks. The ARS-W3 Phase2 illustrative run shows the catalog-mismatch signal (Loadout's 11 FAILURE outcomes on Arsenal-canonical paths) is observable end-to-end. |
| Evaluation of Method + Adapter combinations | NATURAL EXTENSION (mostly built; one QMR-contract addition needed) | `scripts/arsenal_evaluate.py` `_assemble_artifact` `provenance.adapter` block + `method.{method_id,method_record_path,method_record_digest,procedure_ref}` block; `evaluation/method-records/qualified-method-record.v0.schema.json` `procedure_ref` regex (single SHA-256); `docs/arsenal-method-evaluation.md` "Graduation gap" items 1, 3, 4; `evaluation/method-cases/corpus.manifest.json`; the ARS-W3 Phase 2 metrics table in `docs/arsenal-method-evaluation.md` (canonical corpus run through `loadout-runtime`) | No adapter-version-aware QMR exists today; the canonical QMR's `procedure_ref` (`sha256:aabfb65d…`) binds to the canonical internal fixture. Adding `(adapter_identity, adapter_version)` to the QMR and re-deriving `procedure_ref` per binding is the documented gap. The corpus is Arsenal-canonical and is not a fair test for the Loadout productized target until a Loadout-canonical corpus exists (gap item 2). |

## Cross-cutting notes

- **Adapter evaluation already produces a joint signal.** A single ARS-04 run with `--adapter loadout-runtime` is, today, the method+adapter combination evaluation. The evaluator refuses silent fallback, the adapter identity is in the artifact's digest, and the tests prove a broken adapter produces strictly more misses.
- **Promotion cannot be implicit.** The QMR validator, the ARS-04 evaluator, the bench runner, the capability graph preflight, and the trust decision layer all reject silent promotion. Capability lifecycle promotion requires a qualification receipt bound to `(capability, target, adapter_version, suite, digests)` (`evaluation/BENCH_CONTRACT.md`, `scripts/arsenal_bench.py:build_qualification_receipt`).
- **No Formation primitive exists.** Adding one would be a new primitive; the Capability Graph's route/step vocabulary is the natural host, but it currently orders capabilities, not teams.
- **No Temper concept exists.** Anything that exposes a "resulting value" would be a new surface; the Knowledge Plane's `field_observations` classification enum (`got-right | got-wrong | friction | gap | loss | unknown`) is the closest typed vocabulary, and it is bound to a single snapshot, not generalized.

---

# G. CROSS-PRODUCT CONFLICT REGISTER

| ID | Concept | Products involved | Observed conflict | Evidence | Severity | What Prompt 2 must decide |
|---|---|---|---|---|---|---|
| C-1 | Operation vs Run | Kiln vs Loadout-Temper | `Kiln.Domain.Operation` is a transient durable record for model/patch/command. The proposed "Operation Plan" / "Operation" hierarchy implies durable multi-step orchestration. AGENTS.md and `docs/architecture/LOD-02.md` line 192 explicitly exclude "a workflow engine that takes a Plan and orchestrates downstream steps" from Loadout. KILN-DOM-006 explicitly says Worker identity is transient. | `kiln/lib/kiln/domain/operation.ex` (transient); `loadout/docs/architecture/LOD-02.md` line 192; `kiln/AGENTS.md` "Do not pull forward: nested or concurrent Child graphs; writing Children; managed worktrees; ..." | HIGH | Whether the proposed Temper/Loadout Operation hierarchy absorbs Kiln's transient Operation or whether Kiln's transient Operation is the correct primitive being renamed. |
| C-2 | Project Reality | All four | Multiple candidates confuse Project Reality with adjacent concepts: Kiln's `ProjectObservation` (Workspace-level state digest), RepositoryObservation (Wave 3 candidate, repository-level), Loadout's `workspace_state_digest`, Arsenal's `repository_state_digest` (Kiln-owned, separate from Loadout's producer_state). The "Project Reality" concept is not yet a single first-class entity; integration across these digests is the gap. | `kiln/lib/kiln/repository_observation.ex`; `loadout/src/core/workspace.ts`; `kiln/docs/INTERNAL-DOMAIN-MODEL.md` (proposed "Project", "Workspace", "Environment") | HIGH | Whether Project Reality is a canonical object, a projection, a query model, an umbrella, or a hybrid, and which digest is the source of truth under which scope. |
| C-3 | Frontier | All four | No current product derives Frontier. The closest is Kiln's `acceptance_readiness` and Loadout's `Plan` "Notes" section. Wave 3 explicitly says "Frontier should not become a manually maintained project-management slogan." | `kiln/lib/kiln/run_result_envelope.ex` (Wave 3 candidate); `loadout/src/core/plan.ts` (Notes); `engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md` §8 | MEDIUM | Whether Frontier is derived (acceptable_state − current_observed_state) or stored or both; whether it is a Temper concept. |
| C-4 | Pulse vs Motion | Temper proposed | No current product distinguishes Pulse (activity) from Motion (durable transitions). Pulse is cheap; Motion is durable. Each product has telemetry or lifecycle terms but no unified taxonomy. | `kiln/docs/CLI-TUI.md` (renderer boundary); `kiln/AGENTS.md` "Telemetry export" (deferred); `engineering-system/decisions/0001-product-system.md` (no Motion concept); `arsenal/observability/flight-record.schema.json` (event log, not Motion) | MEDIUM | Whether Pulse and Motion are distinct concepts or whether Motion can be derived from existing lifecycle transitions. |
| C-5 | Finding / Unknown / Decision / Attempt | Across Kiln, Arsenal, Temper | Each product has overlapping vocabularies. Kiln has `Decision` (local-user), `Evidence.result`, `Operation.state`, `run_result_envelope.unknowns`. Arsenal has `Knowledge Plane` FieldObservation, NegativeKnowledge, FrictionEvent. Wave 3 contracts use `unknowns` and `evidence` semantically. Temper's proposed taxonomy is undeclared. | `kiln/lib/kiln/domain/decision.ex`; `kiln/lib/kiln/evidence.ex`; `arsenal/knowledge/snapshot.schema.json`; `engineering-system/contracts/run-result-envelope.v0.md` (`unknowns[]` list) | HIGH | Whether each product owns its own Finding/Unknown/Decision or whether a cross-product Finding/Unknown/Decision primitive is needed. |
| C-6 | Formation | Loadout, Arsenal, Kiln | No current product owns Formation. The Capability Graph in Arsenal orders steps; it does not declare teams. The proposed "Loadout chooses engineering strategy" — including Formation — implies Loadout would choose roles/teams. The same hypothetical \"Engineer pick\" could collide with Kiln's transient Worker model and with Arsenal's evidence-side model/role recording. | `arsenal/graph/CONTRACT.md`; `kiln/AGENTS.md` "Worker process can change without changing Run identity"; `loadout/AGENTS.md` "Do not implement: a general AI planner" | MEDIUM | Whether Formation is a natural extension of the Capability Graph or a new primitive. |
| C-7 | Proof Strategy | Arsenal, Loadout | Arsenal currently emits a single hardcoded `repo-state-observed` proof obligation. The proposed Proof Strategy vocabulary (reproduce → establish ownership → falsify hypotheses → implement → independently verify) implies a multi-phase strategy. The Work Envelope v0 contract defines `proof_obligations` as a flat list; expressing a multi-phase strategy without changing the v0 contract is impossible. | `loadout/src/core/compile.ts` lines 71-77; `engineering-system/contracts/work-envelope.v0.md` (flat `proof_obligations[]`) | MEDIUM | Whether Proof Strategy lives in Loadout (composition) or Arsenal (evaluation) or both. |
| C-8 | Model / Reasoning allocation | All four | Each product records model/role information differently. Arsenal records model as evidence (Knowledge Plane). Loadout does not allocate or recommend. Kiln may mandate a model via ARS-10 Intent Compiler (out of scope today). The user's documented disposition rule: "Arsenal records; Loadout recommends; Kiln proves; Temper exposes." But no current primitive lets Loadout make a recommendation or let Kiln prove one. | `arsenal/knowledge/snapshot.schema.json`; `loadout/src/core/schemas.ts`; `kiln/AGENTS.md` (ARS-10 deferred) | MEDIUM | Whether model/reasoning allocation is a primary scope or a derived artifact. |
| C-9 | Worker semantics | Kiln, Loadout, Temper | Kiln treats Worker as a transient process (no struct). Loadout doesn't have a Worker concept. Temper's Worker is proposed. The proposed principle "Workers are disposable. Operations survive them. Project intelligence survives Operations." contradicts the prevailing cross-product ownership split (Kiln owns truth, sessions do not own truth). | `kiln/AGENTS.md` "KILN-DOM-006: Worker identity is transient"; `loadout/AGENTS.md` "Do not implement: a general AI planner, a workflow engine" | HIGH | Whether Worker is a Kiln transient, a Loadout concept, a Temper concept, or not a concept at all. |
| C-10 | Fleet, Attention | Temper proposed | No current Fleet or Attention primitive exists. Adjacent: Kiln's `pending_decision` slot covers user-blocking attention; Arseny's `Knowledge Plane` records observations. | `kiln/lib/kiln/projections/session.ex`; `kiln/docs/INTERNAL-DOMAIN-MODEL.md` (proposed "Attention request", not implemented) | MEDIUM | Whether Fleet/Attention is a Temper concept only or whether Kiln needs first-class Attention. |
| C-11 | Workbench focus types | All four | No current product has a focus type model. Each product has its own data model (Plan, Artifact, Evidence, etc.). Mapping all of them into a single Workbench focus type would require a cross-product semantic layer. | `loadout/src/core/plan.ts` (Plan sections); `kiln/AGENTS.md` (renderer boundary) | MEDIUM | Whether Workbench is a Temper concept only or whether it requires cross-product semantic harmonization. |
| C-12 | Conversation vs durable truth | All four | Each product has a different truth model. Engineering-system policy is "Conversation is the interface to engineering reality. Conversation should not itself be canonical engineering reality." But no current product enforces this. | `engineering-system/decisions/0001-product-system.md`; `kiln/AGENTS.md`; `loadout/AGENTS.md`; `arsenal/AGENTS.md` | HIGH | Whether conversation is rendered-only (Temper) or whether some product must record conversation as Evidence. |
| C-13 | Human steering ownership | All four | Pause / stop / resume / Plan revision / authority revocation / Worker cancellation / stale Evidence recognition — none of these primitives exist in their full form. Kiln owns authority decisions but not conversation-side pause. Loadout has no pause primitive. | `kiln/AGENTS.md` "Authority v0 — only `git.read`"; `kiln/docs/CLI-TUI.md` (renderer boundary); `loadout/AGENTS.md` (no pause) | MEDIUM | Which product owns the steering primitives. |
| C-14 | Returning-project truth source | All four | "Welcome back. Since your last session: ..." assumes durable project intelligence exists. Wave 3 establishes Kiln's durability, but no product projects that into a "Welcome back" UX. | `engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md` §6 (Durability); `kiln/AGENTS.md` | MEDIUM | Whether the "Welcome back" view is a Temper concept only or whether it requires production-grade projection in Kiln. |

---

# H. CONCEPT EVIDENCE MATRIX

| Concept | User value hypothesis | Exists? | Possible existing owner | Durable identity evidence | Can derive? | Conflict risk | Wave 3 dependency |
|---|---|---|---|---|---|---|---|
| Project | durably-anchored engineering system | NO EQUIVALENT | Owner/engineering-system (cross-product coordination) | none currently | No — no Project entity exists in any product | C-12, C-2 | Blocked on Prompt 2 decision |
| Project Reality | current observed state + producer claims | PARTIAL (Kiln owns RepositoryObservation, Loadout owns workspace_state_digest) | Kiln-Knowledge-Plane-Loadout split | Two digests compared only on `observation.current_repository_state_digest` | Maybe, if a canonical projection is added | C-2 | May need KIL-W3 merge for stable canonical form |
| Frontier | current limiting condition | PARTIAL (kiln acceptance_readiness, loadout plan notes) | none as a derived primitive | none | Maybe, if acceptance_readiness + observed_unsupported + open_evidence_gaps can be composed | C-3 | May need Wave 3 first-month stability |
| Objective | desired outcome | PARTIAL (Session.objective, Task.statement, WorkEnvelope.goal.title) | Kiln-Session + Loadout-Plan | session_id, task_id, work_id | Maybe — three candidates exist | C-1 | Requires Kiln session + Loadout plan |
| Operation | durable orchestrating unit | PARTIAL (Kiln Run is the closest; Operator's "Operation" ambiguous) | Kiln (Run) | run_id | Maybe — Run is more than Operation | C-1 | None if Operation = Run |
| Loadout | strategy compiler | YES (current Capability + Skill + QMR + Plan path) | Loadout | plan_id (sha256) | Yes (already exists) | None | Wave 3 Phase 1 refines |
| Formation | team composition | NEW RESEARCH PRIMITIVE NEEDED | none | none | No | C-6 | None |
| Proof Strategy | multi-phase strategy | REQUIRES NEW PRIMITIVE | none | none | Maybe — verbs currently exist as separate capabilities | C-7 | None |
| Tool Requirements | tool-level constraints | NATURAL EXTENSION | Loadout (connector + Work Envelope) | authority capability + scope | Yes (extend Work Envelope) | None | None |
| Authority Request | declared needed authority | YES (currently in Work Envelope) | Loadout (producer) / Kiln (grantor) | work_id, decision_id | Yes (already exists, but real binding to Kiln W3 needed) | None | Wave 3 Phase 2 |
| Model / Reasoning allocation | recommendation for execution | REQUIRES NEW PRIMITIVE | none (Arsenal records as evidence) | none | No | C-8 | ARS-10 |
| Worker | live executor | NO EQUIVALENT | none (proposed) | none | No | C-9 | None |
| Worker inspection | operational view | NO EQUIVALENT | none (proposed) | none | No | C-9 | None |
| Plan | Loadout's compiled intent | YES (Wave 2 LOD-02) | Loadout | plan_id (sha256) | Yes (already exists) | None | Wave 3 Phase 1 enriches |
| Finding | inspection outcome | PARTIAL (Evidence.result, Knowledge Plane FieldObservation) | Kiln + Arsenal | evidence_id, observation_id | Maybe — Evidence is criterion-bound; Finding is often free-form | C-5 | None |
| Unknown | what is not known | PARTIAL (Evidence.result=:unknown, run_result_envelope.unknowns[]) | Kiln | evidence_id | Maybe — multiple unbound strings | C-5 | None |
| Decision | durable local-user-decision | YES (Kiln.Domain.Decision) | Kiln | decision_id | Yes (already exists) | None | None |
| Attempt | one Run | YES (Kiln.Domain.Run) | Kiln | run_id | Yes (already exists) | None | None |
| Evidence | criterion-evaluated observation | YES | Kiln | evidence_id | Yes (already exists) | None | None |
| Contradiction | two current + complete + pass/fail candidates | YES (computed via Currentness.evaluate) | Kiln | (computed, not durable) | Already exists | None | None |
| Artifact | content bytes | YES | Kiln | artifact_id + content_digest | Yes (already exists) | None | None |
| Run Result Envelope | production durable fact envelope | YES (Wave 3) | Kiln | run_id | Yes | None | Wave 3 KIL-W3 |
| Acceptance | closure of a Run lifecycle | YES (RunResultEnvelope.acceptance_readiness) | Kiln | run_id | Yes | None | None |
| Motion | durable reality transition | NO EQUIVALENT | none | none | Maybe — derived from Journal | C-4 | None |
| Pulse | activity | NO EQUIVALENT | none | none | Maybe — derived from tool calls | C-4 | None |
| Attention | pending cognition | PARTIAL (Decision pending) | Kiln (pending_decision) | decision_id | Maybe — single Decision slot | C-10 | None |
| Fleet | visible agent team | NO EQUIVALENT | none | none | No | C-10 | None |
| Workbench | focus type | NO EQUIVALENT | none | none | No | C-11 | None |
| Conversation | real-time interaction | NO EQUIVALENT | none | none | No | C-12 | None |
| Welcome back | session resumption | NO EQUIVALENT | none (cross-product durability exists) | none | Maybe — derived from durable state | C-14 | None |
| Reset of a project | cold-start from durable state | NO EQUIVALENT | none | none | Maybe | C-14 | None |

---

# I. PRODUCT / MARKET INTERACTION FINDINGS

## TABLE STAKES

What most coding-agent products will have soon, based on primary documentation and engineering blogs:

1. **Conversation persistence and resume.** Sessions are saved continuously to local JSONL transcripts; resume restores model, agent identity, permission mode (except `plan` and `bypassPermissions`), and active goal. Source: [Sessions — Claude Code](https://code.claude.com/docs/en/sessions); [Cursor Agent overview](https://cursor.com/docs/agent).
2. **Worktree-based isolation for parallel sessions.** `--worktree` creates a separate git checkout under `.claude/worktrees/&lt;name&gt;/`, branches from default branch by default, and is automatically cleaned when empty. Subagents can request `isolation: worktree` from frontmatter. Source: [Worktrees — Claude Code](https://code.claude.com/docs/en/worktrees); [Cloud Agents — Cursor](https://cursor.com/docs/cloud-agent/capabilities).
3. **Subagents within a session.** Subagents run in their own context window, inherit a tool set filtered by mode, may have restricted tools, can preload skills, can choose their model (`sonnet`/`opus`/`haiku`/`fable`/`inherit`), and can run in the background by default as of v2.1.198. Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents).
4. **Agent view / background dispatch dashboard.** `claude agents` lists every background session with state (Working, Needs input, Idle, Completed, Failed, Stopped). Source: [Agent view — Claude Code](https://code.claude.com/docs/en/agent-view); [Cursor's Cloud Agents](https://cursor.com/docs/cloud-agent/setup).
5. **Persistent project memory.** CLAUDE.md + CLAUDE.local.md + `.claude/rules/` + auto-memory with `MEMORY.md` index file loaded at start (first 200 lines or 25KB). Subagent memory can scope to `user`, `project`, or `local`. Source: [Memory — Claude Code](https://code.claude.com/docs/en/memory).
6. **Hooks for deterministic control.** `PreToolUse`, `PostToolUse`, `SubagentStart`/`SubagentStop`, `TaskCreated`/`TaskCompleted`, `TeammateIdle`, `SessionStart`/`SessionEnd`. Exit code 2 blocks tool calls regardless of permission mode. Source: [Hooks — Claude Code](https://code.claude.com/docs/en/hooks).
7. **Checkpointing / rewind.** `/rewind` keeps the last 100 file-snapshot checkpoints per session; can restore code, conversation, or both; 30-day retention tied to `cleanupPeriodDays`. Source: [Checkpointing — Claude Code](https://code.claude.com/docs/en/checkpointing).
8. **Multi-model choice per agent.** Per-invocation model parameter, env var `CLAUDE_CODE_SUBAGENT_MODEL`, allowlist with substitution rules. Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents#choose-a-model).
9. **Permission modes.** `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`. Source: [Permissions — Claude Code](https://code.claude.com/docs/en/permissions).
10. **Cross-session messaging.** `ListAgents` / `SendMessage` between independent Claude Code sessions on the same machine (per-session inbox socket) and across machines via Anthropic servers. Source: [Cross-session messaging — Claude Code](https://code.claude.com/docs/en/cross-session-messaging).
11. **Dynamic workflows / scripted orchestration.** JavaScript scripts with `agent()`, `pipeline()` primitives; up to 16 concurrent agents, 1,000 per run; resumable in same session. Source: [Workflows — Claude Code](https://code.claude.com/docs/en/workflows); [Anthropic harness blog](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code).

## STRONG LESSONS

1. **Subagents are a context firewall, not just delegation.** The most repeated use case is "isolate high-volume operations" — running tests, fetching docs, processing logs — to keep the main conversation free of noise. Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents#isolate-high-volume-operations).
2. **Fan-out-and-synthesize outperforms serial exploration on research.** Anthropic's harness blog explicitly identifies "anchor bias" as the dominant failure of serial investigation; multiple independent investigators who challenge each other converge faster. Source: [Anthropic harness blog](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code); [Workflows — Claude Code](https://code.claude.com/docs/en/workflows).
3. **Plan approval gates prevent expensive re-work.** `plan` mode + `require plan approval` for teammates is a designed exception where the lead session grants teammate plan approvals without re-prompting the user. Source: [Agent teams — Claude Code](https://code.claude.com/docs/en/agent-teams#require-plan-approval-for-teammates); [Permissions — Claude Code](https://code.claude.com/docs/en/permissions).
4. **Hooks for policy enforcement beat CLAUDE.md for must-run behavior.** Claude Code's own docs state: "CLAUDE.md instructions shape Claude's behavior but are not a hard enforcement layer." Exit-code-2 blocking in `PreToolUse` is the only reliable enforcement. Source: [Permissions — Claude Code](https://code.claude.com/docs/en/permissions); [Hooks — Claude Code](https://code.claude.com/docs/en/hooks).
5. **Auto-memory at a per-project MEMORY.md index works because the index is bounded.** First 200 lines or 25KB at startup; topic files load on demand. Source: [Memory — Claude Code](https://code.claude.com/docs/en/memory).
6. **Worktree isolation has four enforcement checks.** File edits, command working directory, git redirects, and command-shape analysis — all blocking. Source: [Worktrees — Claude Code](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation).
7. **Workflow scripts out-scale turn-by-turn orchestration for large tasks.** The plan moves from Claude's context into JavaScript variables. Intermediate results don't pollute context. Source: [Anthropic harness blog](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code); [Workflows — Claude Code](https://code.claude.com/docs/en/workflows).
8. **Permission boundaries stay per-session, even across messaging.** "Claude is instructed never to ask another session for an action that was denied or blocked in its own session, or that its own permission settings would block." Source: [Cross-session messaging — Claude Code](https://code.claude.com/docs/en/cross-session-messaging).

## COMMON FAILURE MODES

1. **Cognitive overload from verbose tool output.** Recommendation: delegate verbose ops to subagents and use hooks to filter before Claude sees data. Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents#run-parallel-research); [Costs — Claude Code](https://code.claude.com/docs/en/costs).
2. **Context-window cost climbs invisibly in long sessions.** Each request sends the full conversation; cache misses after a long pause reprocess full history. Source: [Costs — Claude Code](https://code.claude.com/docs/en/costs#why-usage-climbs-in-a-long-session).
3. **Agentic laziness, self-preferential bias, goal drift in long single-context work.** Anthropic's harness blog names these three failure modes as the explicit motivation for multi-agent orchestration. Source: [Anthropic harness blog](https://claude.com/blog/a-harness-for-every-task-dynamic-workflows-in-claude-code).
4. **File conflicts without partition.** "Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files." Source: [Agent teams — Claude Code](https://code.claude.com/docs/en/agent-teams#avoid-file-conflicts).
5. **Background subagents that need permission prompts.** Before v2.1.186, background subagents auto-denied any tool call that would have prompted. Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background).
6. **Linear token scaling across teammates.** Agent teams use ~7x more tokens than standard sessions when teammates run in plan mode. Source: [Costs — Claude Code](https://code.claude.com/docs/en/costs#agent-team-token-costs).
7. **Compaction erases rules.** Project-root CLAUDE.md survives compaction; nested CLAUDE.md and path-scoped rules do not re-inject automatically. Source: [Memory — Claude Code](https://code.claude.com/docs/en/memory#troubleshoot-memory-issues).
8. **Checkpoints do not cover subagent edits (except foreground forked skills) and do not cover bash command changes.** Source: [Checkpointing — Claude Code](https://code.claude.com/docs/en/checkpointing#limitations).
9. **Task status lags in teams.** "Teammates sometimes fail to mark tasks as completed, which blocks dependent tasks." Source: [Agent teams — Claude Code](https://code.claude.com/docs/en/agent-teams#limitations).
10. **API errors look like completion.** As of v2.1.198, a teammate whose turn ends on an API error notifies the lead of failure instead of appearing to finish normally. Source: [Agent teams — Claude Code](https://code.claude.com/docs/en/agent-teams#context-and-communication).
11. **Resume does not restore worktrees that fail safety checks.** When launching from inside a refused worktree, Claude Code declines to re-enter; the session continues without isolation. Source: [Worktrees — Claude Code](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree).
12. **Session resumption drops in-process teammates.** `/resume` and `/rewind` do not restore in-process teammates. Source: [Agent teams — Claude Code](https://code.claude.com/docs/en/agent-teams#limitations).
13. **Subagents with conflicting model rules.** Resolution order is env var → per-invocation parameter → frontmatter → main conversation model. Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents#choose-a-model).

## POTENTIAL DIFFERENTIATION

Where a product like Temper could plausibly differentiate, given the gap between current offerings and durable engineering intent. (No architecture proposed.)

1. **Durable projections of execution, not transcripts.** Current products store JSONL transcripts and snapshots, but state that the user can query as a structured object (Work, Run, Authority, Effect, Evidence, Currentness, Readiness) is not first-class. Wave 3 of the engineering-system explicitly binds this: "Inspect/query the Run through an application projection, recover run identity, authority decision, Artifact reference, Evidence, currentness/status, and final Run Result facts." Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) §6 Durability.
2. **Authority that is durable, not session-scoped.** Claude Code has session-level permission modes; worktree isolation has command-level blocking; team leads approve plans. None of these produce a durable, queryable "what authority was granted, when, by whom, against what state, with what scope" record. Wave 3 names this invariant: "The decision must be durable and bound to (Work, Run, requested authority, scope, repository state, decision result)." Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) §5 Authority v0.
3. **Effects and evidence that survive the process.** "If deleting Loadout's local run presentation destroys the only copy of the result, Wave 3 has failed." Cursor and Claude Code keep results on the local machine; Claude Code ties retention to a 30-day default sweep. There is no evidence substrate that records what was observed, when, in what state, and binds it to the action that produced it. Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) §6 Durability; [Claude Code directory cleanup](https://code.claude.com/docs/en/claude-directory).
4. **Inspection of durable state, not just live sessions.** `claude agents` shows running and recently completed sessions. Cursor's "related runs" link cloud agents by environment/repo. None expose a query language over runs across machines, projects, and accounts. Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) §6; [Agent view — Claude Code](https://code.claude.com/docs/en/agent-view).
5. **Honest separation of OBSERVED vs INFERRED.** Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) Loadout W3 Phase 1.
6. **Unknowns as a feature.** Surface unknowns as a feature, not a bug. Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) Loadout W3 Phase 1.
7. **Fail-closed transport between components.** "Local process boundary preferred. Loadout KilnDriver spawns exact executable + argv to the Kiln CLI. No shell command strings. Stable machine-readable JSON in both directions." Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) §3 Transport.
8. **Boundary contracts that are version-pinned fixtures.** Source: [Coordination Overview](../engineering-system/program/COORDINATION-OVERVIEW.md) §Contract vocabulary.
9. **Per-agent capability bound to authority, not just to a tool list.** Source: [Subagents — Claude Code](https://code.claude.com/docs/en/sub-agents); [Agent teams — Claude Code](https://code.claude.com/docs/en/agent-teams#permissions).
10. **Reading the existing repo without rewriting it.** Wave 3 explicitly scopes a Repository Recon wedge.
11. **Stable projections, not terminal rendering.** Wave 3 explicitly rules out terminal work for Temper. Source: [Wave 3 — First Real Run](../engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md) Temper.

---

# J. WAVE 3 DEPENDENCY REGISTER

## DECIDABLE NOW

- Operation vs Run (C-1): Kiln's Run is the closest existing primitive. The proposed "Operation" hierarchy could be mapped to Run. The proposed "Workers are disposable. Operations survive them." conflicts with KILN-DOM-006 ("Worker identity is transient"). Prompt 2 can decide without external evidence.
- Project Reality (C-2): The current products have multiple digests (Kiln's `repository_state_digest`, Loadout's `workspace_state_digest`, Arsenal's `repository_state_digest`). Prompt 2 can decide between canonical object, projection, query model, umbrella, or hybrid.
- Frontier (C-3): No current product derives Frontier. Prompt 2 can decide whether Frontier is a Temper concept or a cross-product derived concept.
- Pulse vs Motion (C-4): No current product distinguishes Pulse from Motion. Prompt 2 can decide.
- Finding / Unknown / Decision / Attempt (C-5): Each product has overlapping vocabularies. Prompt 2 can decide whether each product owns its own or whether a cross-product primitive is needed.
- Formation (C-6): No current product owns Formation. Prompt 2 can decide.
- Proof Strategy (C-7): Arsenal currently emits a single hardcoded `repo-state-observed` proof obligation. Prompt 2 can decide where Proof Strategy lives.
- Model / Reasoning allocation (C-8): No current product allocates or recommends models. Prompt 2 can decide.
- Worker semantics (C-9): Kiln considers Worker transient. No other product has a Worker concept. Prompt 2 can decide.
- Fleet, Attention (C-10): No current Fleet or Attention primitive exists. Prompt 2 can decide.
- Workbench focus types (C-11): No current Workbench primitive exists. Prompt 2 can decide.
- Conversation vs durable truth (C-12): Each product has a different truth model. Prompt 2 can decide.
- Human steering ownership (C-13): Pause/stop/resume/Plan revision/authority revocation/Worker cancellation/stale Evidence recognition — none of these primitives exist in their full form. Prompt 2 can decide.
- Returning-project truth source (C-14): Wave 3 establishes Kiln's durability; no product projects that into a "Welcome back" UX. Prompt 2 can decide.

## PROVISIONAL

- The boundary between "Worker is a transient process" and "Worker is a concept whose lifecycle is durable" depends on whether the proposed "Operation" hierarchy is implemented as durable multi-step orchestration (which conflicts with AGENTS.md stop conditions) or as a re-shaping of the current Plan (which is a natural extension). Prompt 2 can pick the boundary; the architecture will follow.

## BLOCKED ON WAVE 3

None of the conceptual questions are blocked on Wave 3 — the conceptual decisions can be made before Wave 3 is merged. However, the IMPLEMENTATION of several concepts is blocked on Wave 3:

- **Authority v0 stability.** Detailed question: "what does the canonical Run Result Envelope look like at Wave 3 v1?" Missing Wave 3 fact: the post-merge canonical form of `run-result-envelope.v0.md`. Which repository will provide it: `kiln` (after PR #64 merges). What observable evidence will unblock it: the canonical JSON shape emitted by `mix kiln supervise --work-envelope <path> --format json` on the v1 path.
- **First-month status projection stability.** Detailed question: "can Kiln expose a stable JSON projection of Run state for a viewer?" Missing Wave 3 fact: the post-merge form of `lib/kiln/run_result_envelope.ex` `to_map/1`. Which repository will provide it: `kiln`. What observable evidence will unblock it: the canonical JSON produced by `inspect_run/2` after restart.
- **Restart durability form.** Detailed question: "what durable facts survive Kiln restart?" Missing Wave 3 fact: the post-merge `supervision_test.exs` results. Which repository will provide it: `kiln`. What observable evidence will unblock it: the integration-proof restart test (kiln restart, same durable IDs).
- **Real Kiln path from Loadout.** Detailed question: "what does the real Kiln driver call look like?" Missing Wave 3 fact: Loadout W3 Phase 2 closeout. Which repository will provide it: `loadout`. What observable evidence will unblock it: the published LOD-03 Phase 2 PR with the 12-step protocol implemented.

---

# K. QUESTIONS FOR ARCHITECTURE ADJUDICATION

The smallest high-value set of decisions Prompt 2 must settle:

1. **Operation vs Run.** Is the proposed "Operation" hierarchy the same as Kiln's Run, or a new parallel construct? If new, who owns it?

2. **Project Reality.** Is Project Reality a canonical object, a projection, a query model, an umbrella, or a hybrid? Which digest is the source of truth under which scope — Kiln's `repository_state_digest`, Loadout's `workspace_state_digest`, or a new composite?

3. **Frontier.** Is Frontier a derived concept (acceptable_state − current_observed_state), a stored concept, or both? Is it a Temper concept only or cross-product?

4. **Pulse vs Motion.** Are Pulse and Motion distinct concepts, or is Motion derivable from existing lifecycle transitions?

5. **Finding / Unknown / Decision / Attempt.** Does each product own its own Finding/Unknown/Decision/Attempt, or is a cross-product primitive needed?

6. **Formation.** Is Formation a new primitive, or is it a natural extension of the Capability Graph?

7. **Proof Strategy.** Does Proof Strategy live in Loadout (composition), Arsenal (evaluation), or both?

8. **Model / Reasoning allocation.** Is model/reasoning allocation a primary scope, a derived artifact, or deferred?

9. **Worker semantics.** Is Worker a Kiln transient, a Loadout concept, a Temper concept, or not a concept at all?

10. **Fleet.** Is Fleet a Temper concept only, or does it require cross-product semantic harmonization?

11. **Attention.** Is Attention a Temper concept only, or does Kiln need first-class Attention?

12. **Workbench.** Is Workbench a Temper concept only, or does it require cross-product semantic harmonization?

13. **conversation vs durable truth.** Is conversation rendered-only (Temper), or must some product record conversation as Evidence?

14. **human steering ownership.** Which product owns the steering primitives (pause/stop/resume/Plan revision/authority revocation/Worker cancellation/stale Evidence recognition)?

15. **returning-project truth source.** Is the "Welcome back" view a Temper concept only, or does it require production-grade projection in Kiln?

---

# L. EVIDENCE QUALITY / UNKNOWN REGISTER

Places where repository reality was ambiguous or missing:

1. **Wave 3 candidate behavior vs accepted main behavior.** The Wave 3 modules in Kiln (`Kiln.WorkEnvelope`, `Kiln.Supervision`, `Kiln.Authority`, `Kiln.RepositoryObservation`, `Kiln.RunResultEnvelope`, `Kiln.WorkEnvelopeLoader`, migration `0005_supervision_runs.sql`) are present on the candidate branch's working tree but not on canonical main. The integration proof must distinguish between "already true on main" and "requires KIL-W3 merge" claims.

2. **Kiln `lib/` source on disk vs canonical git state.** The checkout's working tree contains the full Kiln Elixir source as untracked files. Investigator B reported: "40 tracked files are coordination/program files only." The actual `lib/kiln/` source is described as Wave 3 candidate or accepted P1-S01 depending on the file.

3. **Docs vs code conflicts.** The Kiln AGENTS.md mentions "transient model invocation Worker" / "transient Command Worker" as a process-creation rule, but no struct/module exists. The `INTERNAL-DOMAIN-MODEL.md` proposes `Worker` and `Project` and `Workspace` and `Environment` and `Attention request` as future-slice entities; none are implemented.

4. **Arsenal QMR contract vs adapter evaluation.** The canonical QMR's `procedure_ref` is a single SHA-256 and cannot bind to multiple adapters. Wave 3 evaluations now bind method+adapter in the artifact, but the QMR itself does not yet know about adapter identity. The graduation gap is documented in `docs/arsenal-method-evaluation.md`.

5. **Loadout procedure vs procedure registry.** The procedure-registry exposes a source/runtime split for the built vs dev paths. The Wave 3 Phase 2 driver will use the runtime path. The procedure itself is a deterministic file-system read; no model is invoked.

6. **Temper has no implementation.** Every Temper concept is VISION ONLY except for the data-side mappings of the Kiln-backed authority UX and the Review experience. The proposal "Conversational engineering environment" is a hypothesis, not an implemented surface.

7. **Worker Runtime is not implemented.** Kiln's AGENTS.md mentions "transient model invocation Worker" but no struct exists. The proposed "Workers are disposable. Operations survive them." cannot be evaluated against current code.

8. **Models in Plan are not allocated.** Loadout's QMR records `evaluation.models[]` as provenance; no allocation, scheduling, or reasoning-tier field exists.

9. **No canonical first-class "Formation" primitive.** The Capability Graph in Arsenal orders steps; it does not declare teams. Loadout's `LoadoutPlanV0Schema` has no `formation`/`team`/`roles` field.

10. **Motion has no first-class primitive.** No current product has a concept of "what meaningfully changed in project reality" beyond the existing Run state machine and the Evidence/Currentness substrate.

11. **Pulse has no first-class primitive.** No current product has a separate activity stream.

12. **Frontier is not derived.** No current product computes a "current limiting condition".

13. **Welcome back UX is not implemented.** Wave 3 establishes Kiln's durability; no product projects that into a "Welcome back" UX.

14. **Conversational evidence is not recorded.** Each product has a different truth model; no cross-product semantic layer.

15. **The plan-vs-Work-vs-Operation-vs-Run semantic split is unresolved.** Investigator B reported: "Operation EXACT EQUIVALENT (Kiln.Domain.Operation transient), but Operation vs Run is borderline." The proposed "Operation" hierarchy in Prompt 2 may overlap with Run, Task, Plan, or Operation.

16. **Wave 3 KIL-W3 supervisor branch is not merged.** PR #64 (#64 OPEN) at `db1acdb6` on `work/p3-w01-kil-w3-work-envelope-supervision`. The supervisor's CLI shape (`mix kiln supervise --work-envelope <path> --format json`) is a candidate, not accepted.

17. **Loadout W3 Phase 2 real Kiln driver is in flight.** Phase 2 closeout not yet available.

18. **The integration proof has not been executed.** The integration proof scaffolding (`program/wave-3/integration-proof/`) is published. The proof-repo initial commit (`git init && git add -A && git commit -m "Initial"`) has not yet been performed. The deterministic fixtures are at `engineering-system` main `9bfdd0d`.

19. **Arsenal W3 graduation gap.** 5-item honest gap documented: missing adapter concept in QMR; no runtime adapter for Loadout yet; no actual evaluation against the Loadout Phase 1 checkpoint at `d95927fb`; no behavioral efficacy evidence; no qualification receipt bound to (capability, target, adapter_version, suite, digests).

20. **The user-stated expected SHAs at the start of Wave 3 do not match the actual current main heads.** All four products have advanced legitimately. The current main heads are the Wave 3 starting baselines.

21. **KIL-W3 PR #64 was opened via `gh pr create` from the session's sandbox** (the worker's report said it could not, but the PR was opened). The author is the session's automation. The acceptance of the Wave 3 communications vs. the PR's actual content must be verified by the owner.

22. **The integration proof's "verifier initializes the proof-repo as a real git repo under a temp directory" requires a verifier implementation.** No verifier has been implemented yet.

---

# M. HANDOFF BLOCK FOR PROMPT 2

## End-state claim (no adjudication — this is just a string the next prompt can choose to delete or assert)

The four investigators collectively suggest:

- **Concepts that are essentially VISION ONLY** in the current codebase: most of the proposed operators (Worker, Fleet, Attention, Pulse, Motion, Frontier, Project Reality, Operation hierarchy, Workbench focus types, Conversation, Welcome back, Formation, Model/Reasoning allocation, etc.) have no concrete backing in any current product.
- **Concepts that are NATURAL EXTENSIONS** of the current architecture: Authority Request, Tool Requirements, Tool/Requirements surfaced differently, "Loadout chooses engineering strategy" (limited to Capability/QMR/Method), "Loadout must not become runtime authority owner" (already enforced), Repository Recon-related surfacing, Proof Strategy (each verb already has a host primitive), "Arsenal learns what works. Loadout chooses what to deploy. Kiln proves what actually occurred. Temper exposes the resulting value." (the four-system separation is already consistent with the source model), "Current Arsenal architecture can evolve toward that without abusing QMR or absorbing Loadout ownership" (supported by current boundary-preserving properties), evaluation of adapters (supported), evaluation of Method + Adapter combinations (mostly built, one QMR-contract addition needed).
- **Concepts that REQUIRE NEW PRIMITIVE**: Formation, Proof Strategy, Model/Reasoning allocation, Alternative Loadouts, multi-step Operation Plan, "Loadout may choose Formation", "Loadout may choose Proof Strategy", "Loadout may recommend model/reasoning allocation".
- **Cross-product conflicts** that require architecture adjudication: Operation vs Run, Project Reality, Frontier, Pulse vs Motion, Finding/Unknown/Decision/Attempt, Formation, Proof Strategy, Model/Reasoning allocation, Worker semantics, Fleet/Attention, Workbench focus types, conversation vs durable truth, human steering ownership, returning-project truth source.

## Required Prompt 2 actions

1. Adjudicate the 15 questions in section K.
2. Decide whether to proceed with Wave 4 or hold.
3. For each concept that is `REQUIRES NEW PRIMITIVE`, either:
   - Define the new primitive (with file paths, schemas, ownership)
   - Decline to define it and explain why
4. For each cross-product conflict, either:
   - Resolve the ownership
   - Defer with a stated reason
5. Specify whether the integration proof must be run before Wave 4 planning can begin.
6. Specify whether the integration proof must be run by the owner or by an independent verifier.

============================================================
END WAVE 3.5 DISCOVERY PACKET FOR PROMPT 2
============================================================
