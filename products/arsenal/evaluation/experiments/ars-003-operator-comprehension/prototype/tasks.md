# ARS-003 Operator Task Battery Worksheet

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


**Fixture:** `graph-fixture.json`  
**Fixture digest:** `sha256:dd6af90337dfce836157303413c1581313ed563f339d81f6231d652ddde12835`

This worksheet is used with each representation condition (A, B, C). For each
task, record the operator's answer, score incorrect interpretations and
orchestrator dependence, and note time to correct answer and navigation cost.

## Scoring conventions

- **incorrect_interpretations:** Count one for each discrete factually wrong
  claim about node state, edge relation, event timestamp/order, or evidence
  reference in the final answer. Omissions of optional detail do not count.
- **dependence_on_orchestrator_query:** Count one if the operator asks the
  root/orchestrator for a summary because the representation alone does not
  expose the needed context.
- **time_to_correct_answer:** Seconds from task presentation to first fully
  correct answer; `null` if incorrect or abandoned.
- **navigation_cost:** Count of representation-switching actions (tab changes,
  graph/table jumps, look-backs) observed while answering.

## Task definitions

### T1 — Identify the current blocker

**Question:** At reconnect (2026-08-19T09:42:00Z), what is the most upstream
blocker preventing progress toward final assembly?

**Correct answer:** `contract-worker` is failed (syntax error in contract v3 at
09:15). Its failure blocks `schema-worker`, `reviewer-contract`,
`integration-worker`, and `final-assembly`. `report-worker` is also failed, but
it is a downstream failure on the already-completed test branch, not the
upstream blocker.

**Scoring rubric:**
- +1 `incorrect_interpretations` if a different node is named as the upstream
  blocker, or if the answer states there is no blocker.
- +1 `dependence_on_orchestrator_query` if the operator asks the orchestrator
  for a status summary instead of reading the representation.

---

### T2 — Identify who/what produced a change

**Question:** During the absence interval, who or what produced the contract
v3 → v4 change?

**Correct answer:** `external-agent-7` at 2026-08-19T09:36:00Z, event
`change_produced`.

**Scoring rubric:**
- +1 `incorrect_interpretations` if the answer names the operator,
  `root-orchestrator`, `contract-worker`, or `test-runner` as the producer.
- +1 `dependence_on_orchestrator_query` if the operator asks the orchestrator
  who changed the contract.

---

### T3 — Explain why a node is waiting

**Question:** Why is `schema-worker` in the waiting state?

**Correct answer:** `schema-worker` is waiting because its dependency
`contract-worker` has failed. The event log at 09:16 states: "Set to waiting
because dependency contract-worker is failed." It cannot proceed until
`contract-worker` produces a valid contract output.

**Scoring rubric:**
- +1 `incorrect_interpretations` if the answer says `schema-worker` is blocked
  by `reviewer-contract`, `integration-worker`, or `final-assembly`, or if it
  says no reason is shown.
- +1 `dependence_on_orchestrator_query` if the operator asks why the node is
  waiting.

---

### T4 — Identify what failed during absence

**Question:** What node failure occurred inside the absence interval
(09:35–09:42)?

**Correct answer:** `report-worker` failed at 09:41 with "output format
mismatch" (evidence `kiln/report-check/v1`). The `contract-worker` failure at
09:15 happened before the absence interval.

**Scoring rubric:**
- +1 `incorrect_interpretations` if the answer names `contract-worker` or
  another node, or omits the output-format mismatch.
- +1 `dependence_on_orchestrator_query` if the operator asks what failed while
  away.

---

### T5 — Locate relevant verification evidence

**Question:** What evidence reference confirms the `contract-worker` failure,
and what does it say?

**Correct answer:** `kiln/contract-test/v3`, status `failed`, summary
"Contract v3 syntax error observed in test run." It is linked to the
`contract-worker` `failed` event at 09:15.

**Scoring rubric:**
- +1 `incorrect_interpretations` if the answer gives the wrong evidence ref
  (e.g., `kiln/contract-test/v4` or `kiln/report-check/v1`) or the wrong
  summary.
- +1 `dependence_on_orchestrator_query` if the operator asks the orchestrator
  for the evidence location.

---

### T6 — Navigate child → reviewer → parent

**Question:** Starting from `doc-worker`, identify the reviewer assigned to its
parent's output and the parent node itself.

**Correct answer:** `doc-worker` is a child of `contract-worker`;
`reviewer-contract` is assigned to review `contract-worker` output. Path: child
`doc-worker` → reviewer `reviewer-contract` → parent `contract-worker`.

**Scoring rubric:**
- +1 `incorrect_interpretations` per wrong node or relationship (e.g., naming
  `schema-worker` or `integration-worker` as the reviewer or parent).
- +1 `dependence_on_orchestrator_query` if the operator asks the orchestrator
  for the graph relationships.

---

### T7 — Identify what changed after reconnect

**Question:** After the operator reconnect event at 09:42, what changed in the
event log?

**Correct answer:** Nothing changed after reconnect; the log ends at the
reconnect event. The operator must recover context for changes that happened
*during* the absence interval (09:35–09:42), not after it.

**Scoring rubric:**
- +1 `incorrect_interpretations` if the answer lists post-reconnect changes.
- +1 `dependence_on_orchestrator_query` if the operator asks what happened
  after reconnect.

---

### T8 — Determine whether completion is actually supported

**Question:** Can `final-assembly` complete given the current graph state?

**Correct answer:** No. `final-assembly` is waiting. It depends on the
failed/waiting contract branch, blocked `integration-worker`, still-running
`deploy-worker`, and failed `report-worker`. Multiple dependencies are
incomplete or failed, so completion is not supported.

**Scoring rubric:**
- +1 `incorrect_interpretations` if the answer says yes or omits the
  failed/waiting dependencies.
- +1 `dependence_on_orchestrator_query` if the operator asks the orchestrator
  whether completion is possible.

---

### T9 — Identify which branches are independent

**Question:** Which top-level branches under `root-orchestrator` are
independent of the `contract-worker` branch?

**Correct answer:** `test-runner` branch (`test-runner` → `report-worker`) and
`deploy-worker` branch are independent top-level branches orchestrated directly
by `root-orchestrator`. The `contract-worker` branch (`contract-worker`,
`schema-worker`, `reviewer-contract`, `doc-worker`, `integration-worker`) is
internally coupled and currently blocked.

**Scoring rubric:**
- +1 `incorrect_interpretations` per omitted independent branch or per
  inclusion of the `contract-worker` branch as independent.
- +1 `dependence_on_orchestrator_query` if the operator asks the orchestrator
  for branch independence.

---

## Score summary table

| task | incorrect_interpretations | dependence_on_orchestrator_query | time_to_correct_answer | navigation_cost | notes |
|------|---------------------------|----------------------------------|------------------------|-----------------|-------|
| T1   |                           |                                  |                        |                 |       |
| T2   |                           |                                  |                        |                 |       |
| T3   |                           |                                  |                        |                 |       |
| T4   |                           |                                  |                        |                 |       |
| T5   |                           |                                  |                        |                 |       |
| T6   |                           |                                  |                        |                 |       |
| T7   |                           |                                  |                        |                 |       |
| T8   |                           |                                  |                        |                 |       |
| T9   |                           |                                  |                        |                 |       |
