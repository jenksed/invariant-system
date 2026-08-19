# ARS-003 Graph Operator Comprehension

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Schema-Version: 0.1.0

**State: DESIGNED**

**Classification: FORMATIVE RESEARCH — single-operator comprehension study.**
This protocol tests one graph-engineer participant against static prototypes.
Results do not generalize to all graph engineers; they bound the representation
design space and inform a later controlled study. The classification is stated
here and repeated in the limitations section.

This protocol follows the ARS-000 field set. Shared templates
(`PROTOCOL-TEMPLATE.md`, `EVIDENCE-MANIFEST.md`) are maintained by the research
program at `products/arsenal/evaluation/experiments/`; this experiment
references them and does not duplicate them.

| Field | Value |
|-------|-------|
| experiment_id | ARS-003 |
| title | Graph Operator Comprehension |
| research_program | arsenal-foundation-wave-1 |
| State | DESIGNED |

## source_observation

Operators of multi-agent graph work lose orientation in conversation-tab-only
interfaces. After absence, failure injection, or parallel branch activity the
operator must reconstruct "who did what, what is blocked, and why" from a
chronological message stream. This is an observation and hypothesis source,
not evidence.

## research_question

"What representation allows a graph engineer to understand and operate durable
agentic work with the least cognitive reconstruction?"

## hypothesis

The hybrid representation **C** (graph/orientation → selected node →
conversation → timeline/evidence) enables faster correct comprehension and
fewer incorrect interpretations than representation **A**
(conversation/session tabs), and is no worse than representation **B**
(graph-first), on the ARS-003 task battery.

## falsifier (observable)

The hypothesis is falsified if, across the task battery:

1. Representation C fails to beat representation A on both
   `time_to_correct_answer` and `incorrect_interpretations`; or
2. Representation C is worse than representation B on those same metrics.

## system_under_test

The **representation** (A, B, or C), not the operator.

## baseline_conditions

**Representation A — conversation/session tabs.** Each node has a tab that
shows its own chronological events; a "Global" tab shows cross-cutting events.
The operator navigates by switching tabs and scrolling.

## candidate_conditions

- **Representation B — graph-first.** Nodes, edges, and current states are the
  primary view. Event details and evidence appear below the graph in tables.
- **Representation C — hybrid.** Graph overview is primary for orientation; a
  per-node conversation panel shows selected-node context; a timeline/evidence
  strip at the bottom binds events to verification evidence.

All three are realized by `prototype/build_prototype.py` as static,
self-contained HTML files.

## controlled_variables

| Variable | Control |
|----------|---------|
| synthetic fixture | `prototype/graph-fixture.json` (sha256 recorded below) |
| graph topology | 10 nodes, 14 edges, fixed states and descriptions |
| event log | fixed sequence of 18 events |
| evidence index | 4 evidence refs with fixed summaries |
| absence interval | 2026-08-19T09:35:00Z to 2026-08-19T09:42:00Z |
| rendering substrate | static HTML, inline CSS, no JavaScript, no network |
| task battery | 9 questions with correct answers derived from the fixture |
| execution/authority | none; prototypes are read-only representations |

## perturbations

Intentional stressors baked into the fixture:

- **Absence interval:** operator away from 09:35 to 09:42.
- **Failure injection:** `contract-worker` fails at 09:15; `report-worker` fails
  at 09:41.
- **Reconnect:** operator returns at 09:42.
- **External change during absence:** `external-agent-7` patches contract v3 to
  v4 at 09:36.

## primary_metrics

Counting rules operate over the operator's answer transcript and a stopwatch.

- **time_to_correct_answer:** Seconds from task presentation to the first fully
  correct answer. `null` if the final answer is incorrect or abandoned.
- **incorrect_interpretations:** Count of discrete factually wrong claims about
  node state, edge relation, event timestamp/order, or evidence reference in the
  operator's final answer. Each wrong claim counts once; omissions of optional
  detail do not count.
- **navigation_cost:** Count of representation-switching actions (tab changes,
  jumps between graph and table, look-backs to a previously seen panel)
  required to formulate the answer, recorded by observer or interaction log.
- **lost_orientation_events:** Count of explicit operator statements such as
  "where am I?", "what changed?", "go back to...", or observable backtracking
  to re-find a previously seen fact.
- **dependence_on_orchestrator_query:** Count of times the operator asks the
  root/orchestrator for a summary because the representation alone does not
  expose the needed context.
- **context_recovery_after_absence:** For tasks probing the absence interval,
  the proportion of events that occurred during the absence interval that are
  correctly recalled in the answer (0.0 to 1.0).

## secondary_metrics

- representation_preference_ranking: post-battery rank of A/B/C.
- confidence_rating: 1-5 Likert per task, optional.

## repetition_policy

Single-operator formative study. The prototype is verified by run-twice digest
equality of `graph-fixture.json`. A future multi-operator study will declare
participant count, counterbalancing, and statistical aggregation in a new
protocol version.

## seed_policy_if_relevant

Fixture uses fixed constants. No PRNG is used; if randomness is introduced
later, the seed will be fixed and recorded.

## stop_conditions

- All nine tasks answered for each representation condition, or
- operator explicitly abandons a task, or
- observer records a prototype fault (e.g., missing rendering).

## fixture_identity

`prototype/graph-fixture.json`  
sha256:`dd6af90337dfce836157303413c1581313ed563f339d81f6231d652ddde12835`

## task_identity

`prototype/tasks.md` — operator task battery worksheet with correct answers
derived from `prototype/graph-fixture.json`.

## model_identity

not-applicable (static prototype)

## harness_identity

`prototype/build_prototype.py` v0.1.0 — deterministic fixture and rendering
generator.

## runtime_identity

Python 3 standard library only.

## repository_identity

Record the worktree SHA at run time in derived evidence; if the directory is
not a git worktree, record `unknown`.

## possible_promotion_targets

- Temper operator experience (possible downstream target; not authorization to
  implement).

## non-authority constraints

All renderings are static HTML generated by `build_prototype.py`. They are
representations, not execution truth. No file under this experiment mutates
state, issues commands, or speaks for Kiln/Loadout/Temper authority. Any
production UX change must return through `../../promotion/PACKET-TEMPLATE.md`
and the normal product authorization path.

## readiness_gate

| Gate item | Status | Evidence |
|-----------|--------|----------|
| protocol complete | DESIGNED | this file |
| falsifiable research question | yes | research_question + falsifier |
| fixture identity recorded | yes | fixture_identity |
| prototype deterministic | verified | run-twice sha256 equality |
| task battery with correct answers | yes | task_identity |
| non-authority constraints declared | yes | non-authority constraints |

## Operator task battery

Correct answers are derived from `prototype/graph-fixture.json`. A worksheet
with scoring rubrics is in `prototype/tasks.md`.

| Task | Question | Correct answer |
|------|----------|----------------|
| T1 — current blocker | At reconnect (2026-08-19T09:42:00Z), what is the most upstream blocker preventing progress toward final assembly? | `contract-worker` is failed (syntax error in contract v3 at 09:15). Its failure blocks `schema-worker`, `reviewer-contract`, `integration-worker`, and `final-assembly`. `report-worker` is also failed but is a downstream failure on the already-completed test branch, not the upstream blocker. |
| T2 — who/what produced a change | During the absence interval, who or what produced the contract v3 → v4 change? | `external-agent-7` at 2026-08-19T09:36:00Z, event `change_produced`. |
| T3 — why a node is waiting | Why is `schema-worker` in the waiting state? | `schema-worker` is waiting because its dependency `contract-worker` has failed. Event at 09:16: "Set to waiting because dependency contract-worker is failed." It cannot proceed until `contract-worker` produces a valid contract output. |
| T4 — what failed during absence | What node failure occurred inside the absence interval (09:35–09:42)? | `report-worker` failed at 09:41 with "output format mismatch" (evidence `kiln/report-check/v1`). The `contract-worker` failure at 09:15 happened before the absence interval. |
| T5 — locate verification evidence | What evidence reference confirms the `contract-worker` failure, and what does it say? | `kiln/contract-test/v3`, status `failed`, summary "Contract v3 syntax error observed in test run." Linked to the `contract-worker` `failed` event at 09:15. |
| T6 — child → reviewer → parent | Starting from `doc-worker`, identify the reviewer assigned to its parent's output and the parent node itself. | `doc-worker` is a child of `contract-worker`; `reviewer-contract` is assigned to review `contract-worker` output. Path: child `doc-worker` → reviewer `reviewer-contract` → parent `contract-worker`. |
| T7 — what changed after reconnect | After the operator reconnect event at 09:42, what changed in the event log? | Nothing changed after reconnect; the log ends at the reconnect event. The operator must recover context for changes that happened *during* the absence interval (09:35–09:42), not after it. |
| T8 — completion supported | Can `final-assembly` complete given the current graph state? | No. `final-assembly` is waiting. It depends on the failed/waiting contract branch, blocked `integration-worker`, still-running `deploy-worker`, and failed `report-worker`. Multiple dependencies are incomplete or failed, so completion is not supported. |
| T9 — independent branches | Which top-level branches under `root-orchestrator` are independent of the `contract-worker` branch? | `test-runner` branch (`test-runner` → `report-worker`) and `deploy-worker` branch are independent top-level branches orchestrated directly by `root-orchestrator`. The `contract-worker` branch (`contract-worker`, `schema-worker`, `reviewer-contract`, `doc-worker`, `integration-worker`) is internally coupled and currently blocked. |

## limitations

- Single-operator formative research; results do not generalize to all graph
  engineers.
- Static prototype with no live execution, authority, or mutation surface.
- Task battery is bound to the synthetic ARS-003 fixture.
- No model cognition is tested; the system under test is the representation.
- Navigation-cost and lost-orientation counts rely on observer judgment or
  manual interaction logs.

## counterevidence

(to be recorded when run)

## negative_findings

(to be recorded when run)

## result

(blank while running)

## protocol_version

0.1.0

## protocol_frozen_at

(empty until frozen)

## raw_evidence_locations

(to be recorded when run: operator answer transcripts, screen recordings or
interaction logs, per-condition timing logs)

## derived_evidence_locations

(to be recorded when run: scored worksheet, summary table)
