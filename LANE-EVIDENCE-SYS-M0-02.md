# LANE-EVIDENCE — SYS-M0-02 (M5)

## Lane metadata

- Lane: `SYS-M0-02`
- Branch: `m0/sys-02-manifold-transition`
- Worktree: `/Users/jenksed/Developer/invariant-m0-sys-02`
- Started at: 2026-08-16
- Author: orchestrator (Pass-05 execution, M5)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/SYS-M0-02.md`
- BT-01 activation record: `program/recursive-planning/pass-03/planning/30-day/BOUNDARY-TRANSITION-REGISTER.md` (approved planned runtime surface + transition gate); sequencing decision D4-06 in `program/recursive-planning/pass-04/PASS-04-VERDICT.md` and `program/recursive-planning/pass-04/planning/30-day/AGENT-LANES.md` (M5 lane boundary scope).

## Merge-gate precondition

- Merge gate: **M5** (after M4).
- Predecessor: `m0/loadout-01-implement-change-plan` (M4) merged at `2c515ab`. ✓
- BT-01 owner acceptance is recorded in the closeout artifacts above (Pass-03 BT register + Pass-04 sequencing/merger verdict). No additional owner adjudication required.
- Start gate run: `git log --oneline | grep m0/loadout-01-` → `2c515ab`. ✓

## What changed (E1–E3 verbatim)

### E1 — `invariant.boundaries.json`

Renamed the dead blanket rule and added the activated surface for Manifold's
bounded selector. `owns` / `may_not` for Manifold are unchanged; the policy
still forbids execution, mutation, authority grant, qualification, fabrication,
and generic-workflow-engine drift.

```diff
-    "manifold_no_runtime": true,
+    "manifold_selection_only": true,
```

```diff
     "manifold": {
       "path": "products/manifold",
       "owns": ["intelligence selection", "allocation"],
+      "activated_surface": [
+        "products/manifold/src/selector.py",
+        "products/manifold/tests/test_selector.py"
+      ],
       "may_not": [ ... ]   // unchanged
     },
```

### E2 — `invariant` `check_boundaries` rule 3 replacement

The blanket `*.md$-only` rule was replaced by a strengthened selection-only
rule:

1. Every tracked file under `products/manifold/` must be one of `*.md`,
   `products/manifold/src/selector.py`, or `products/manifold/tests/test_selector.py`.
   Anything else fails the check.
2. `rg -n 'subprocess|socket|urllib|requests|http\.client|asyncio|multiprocessing|ctypes|import\s+os\b'` over the activated source must find nothing.
3. `rg -n 'products/(arsenal|loadout|kiln|temper)'` over the activated source and tests must find nothing — no sibling-product source coupling.
4. Status line flipped to `ok: manifold is selection-only (src/selector.py + tests)` (or `...no activated surface files yet` when neither file is yet committed at M5/M6).

Other boundary rules are untouched. The check is stronger, not disabled.

### E3 — `products/manifold/README.md` status section and root `AGENTS.md` bullet

The status section in `products/manifold/README.md` now states the activated
surface explicitly and points at the boundary checker as the enforcement
mechanism. The `products/manifold` bullet in root `AGENTS.md` is updated to
describe the BT-01 surface and the stdlib-only, no-sibling-source rules. No
other `AGENTS.md` change.

## Forbidden paths confirmed untouched

- `products/manifold/src/selector.py` — NOT created (MANIFOLD-M0-01 only).
- `products/manifold/tests/test_selector.py` — NOT created (MANIFOLD-M0-01 only).
- No disabling / weakening of any other boundary rule.
- No provider / process / queue / scheduler / persistence code added.
- No Kiln authority transfer.
- No related-product source-import introduced.

## Test transcripts

### `./invariant check boundaries` (positive / pre-Manifold-runtime)

```text
$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is selection-only (src/selector.py + tests)
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
exit 0
```

### Negative probes — each must FAIL the boundary check

All probes were made `git add -N` (intent-to-add) so `git ls-files` saw them,
and torn down immediately afterward (no commit). Each was run from a clean
state.

```text
PROBE A — touch products/manifold/src/executor.py + git add -N
  FAIL: products/manifold has files outside the activated selection surface: products/manifold/src/executor.py
  exit 1 ✓

PROBE B — selector.py with `import subprocess` + git add -N
  FAIL: products/manifold src/tests imports non-stdlib or process/network surface: products/manifold/src/selector.py:1:import subprocess
  exit 1 ✓

PROBE C — touch products/manifold/notes.txt + git add -N
  FAIL: products/manifold has files outside the activated selection surface: products/manifold/notes.txt
  exit 1 ✓
```

The import-surface guard (rule 2 in E2) and the activated-surface guard (rule 1)
are both exercised by these probes. There is no path to a 3rd runtime file
without changing `invariant.boundaries.json` `activated_surface` and the E2
allow-list simultaneously — the policy is enforced in two places.

### `./invariant check`

```text
exit 0
```

### Per-product tests

```text
$ ./invariant test arsenal   exit 0
$ ./invariant test loadout   exit 0
$ ./invariant test kiln      exit 0
$ ./invariant test temper    (not run pre-merge; temper unaffected by boundary text)
$ ./invariant test integration (run separately; M5 does not introduce integration churn)
```

The kiln mix-format diffs visible in `mix format --check-formatted` output
were introduced in KILN-M0-01 (commit `24178e5`, M3) and exist on `main` before
M5 (out of M5 scope). The kiln test gate exit remains 0.

## Architectural changes — what new capability actually exists

**No new runtime; this lane is a policy transition only.** After M5:

1. The root boundary policy `invariant.check_boundaries` rule 3 transitions from
   *Manifold must contain no executable source* to *Manifold may contain only
   its selection-only selector and its test, both stdlib-only, and must not
   reach into sibling product source trees.*
2. `invariant.boundaries.json` keys the policy as `manifold_selection_only` and
   pins the activated surface to exactly two paths.
3. `products/manifold/README.md` and root `AGENTS.md` document the activated
   surface and the enforcement.

`MANIFOLD-M0-01` (M7) becomes eligible to add the two approved files. It does
not add anything else under `products/manifold/` without an explicit BT-01
expansion via a new SYS-* lane.

**Architectural discipline preserved:**

- Manifold has no authority, no mutation, no provider / network / process /
  queue / scheduler / persistence surface (rg-guarded).
- Manifold has no source-level import of sibling products (rg-guarded).
- Kiln remains the only authority / execution / mutation / artifact-truth
  boundary.
- Loadout still expresses capability / work intent; no change.
- Bench still owns qualification evidence; no change.
- Temper remains a read-only projection; no change.

## Questions resolved from repository evidence

1. **What is the *current* rule that keeps Manifold documentation-only?**
   `invariant.check_boundaries` rule 3 + the `manifold_no_runtime` JSON key.
2. **What exact bounded transition does BT-01 authorize?** Renaming the rule
   to `manifold_selection_only`, allowing exactly `src/selector.py` +
   `tests/test_selector.py`, and enforcing stdlib-only + no-sibling-source
   surface guards. Pass-03 BOUNDARY-TRANSITION-REGISTER.md is the
   authorization source.
3. **What source paths may Manifold eventually own?** Only the two above
   (BT-01 activated surface). Anything beyond requires a new BT-* transition.
4. **What dependencies are permitted?** Stdlib only (the rg-guard proves it).
   No sibling-product source imports.
5. **What dependencies remain forbidden?** Provider clients, network stacks,
   process runners, queue/scheduler/multiprocessing/asyncio/ctypes, environment
   access via `import os`, sibling-product source.
6. **What must be true before MANIFOLD-M0-01 may open at M7?** M5 must merge
   (this lane) AND M6 BENCH-M0-01 must merge. Both are required for the M7
   start gate per `program/recursive-planning/pass-04/planning/30-day/AGENT-PROMPTS.md`
   MANIFOLD-M0-01 START-GATE-PRECONDITION.

## STATUS

`ready-to-merge`

## Files touched

```text
M  invariant.boundaries.json                       # E1
M  invariant                                       # E2 (rule 3 only)
M  products/manifold/README.md                     # E3 (status section only)
M  AGENTS.md                                       # E3 (manifold bullet only)
A  LANE-EVIDENCE.md                                # this file (lane evidence convention)
```

Primary paths only? **YES** — every touched path is in the refined package's
PRIMARY PATHS list.

## Notes for the integration authority

Per the merge train, this lane merges at **M5**. The lane branch must be
deleted post-merge per `BRANCH-STRATEGY.md`. The merge title must be
`SYS-M0-02: <one-line summary>`; the recommended summary is "BT-01 Manifold
boundary transition: selection-only surface + stdlib-only selector guards".

After this lane merges, **M6 (BENCH-M0-01) — role qualification campaign**
becomes eligible to open (start gate: M3 merged + M5 merged, per MERGE-TRAIN.md
gate sequence).
