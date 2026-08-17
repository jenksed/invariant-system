# LANE-EVIDENCE — SYS-M0-00 (M1)

## Lane metadata

- Lane: `SYS-M0-00`
- Branch: `m0/sys-00-worktree-safe-harness`
- Worktree: `/Users/jenksed/Developer/invariant-system`
- Started at: 2026-08-16T20:22Z
- Author: orchestrator (Pass-05 execution, M1)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/SYS-M0-00.md`

## Merge-gate precondition

- Merge gate: **M1** (the first gate; no predecessors).
- Precondition: clean monorepo checkout + `PREFLIGHT.md` green.
- Verified: `git log --oneline -1` returns `cae5375 docs: record post-publication CI verification results` on `main` before the lane opened.

## Path corrections applied

- `none` (the work package has no path corrections; the lane's primary
  path is `invariant` line 108 only).

## Files touched

```text
$ git diff --name-only origin/main..HEAD
invariant
```

Primary paths only? **YES** (the lane's PRIMARY PATHS list contains
exactly one entry: `invariant`).

## Self-test transcript

### 1. Linked-worktree positive test (the actual proof)

```text
$ git worktree add /tmp/invariant-wt-selftest -b m0/selftest-wt m0/sys-00-worktree-safe-harness
Preparing worktree (new branch 'm0/selftest-wt')
HEAD is now at 4a26c6b SYS-M0-00: accept .git as a gitfile in check_structure

$ ls -la /tmp/invariant-wt-selftest/.git
-rw-r--r--  1 jenksed  wheel  87 Aug 16 20:22 .git

$ cd /tmp/invariant-wt-selftest && ./invariant check ; echo "exit $?"
[no output]
exit 0

$ ./invariant check boundaries ; echo "exit $?"
ok:   single Git root
ok:   no submodules
ok:   manifold is documentation-only
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
exit 0
```

`.git` is confirmed a gitfile (87-byte regular file, not a directory),
yet `./invariant check` and `./invariant check boundaries` both pass.
**Worktree isolation is now legal.**

### 2. Negative probe (nested `.git/` still detected)

```text
$ cd /tmp/invariant-wt-selftest
$ mkdir -p products/fake/.git
$ ./invariant check ; echo "exit $?"
FAIL: nested Git roots found: ./products/fake/.git
exit 1

$ rm -rf products/fake
```

Nested-`.git` probe unchanged and still trips. The `[[ -e .git ]]`
fix is narrow: it accepts the gitfile case without weakening the
nested detection.

### 3. Main checkout after the fix

```text
$ cd /Users/jenksed/Developer/invariant-system
$ ./invariant check ; echo "exit $?"
[no output]
exit 0

$ ./invariant check boundaries ; echo "exit $?"
ok:   single Git root
ok:   no submodules
ok:   manifold is documentation-only
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
exit 0
```

`./invariant test` (full) was not run: it requires every product's
toolchain at full capacity and would dominate this lane's evidence
with noise not owned by M1. The full `./invariant test` is the
closeout obligation (Pass-05 → C-1 in `STOP-CONDITIONS.md`), not
an M1 obligation. `./invariant test contracts`, `test manifold`,
`test kiln`, `test loadout`, `test temper`, `test arsenal`, and
`test integration` are each lane-owned and run by their owning
lane, not by SYS-M0-00.

## RISK-protocol status

- **RISK B:** not applicable (KILN-M0-01 owns this).
- **RISK D:** not applicable (LOADOUT-M0-01 owns this).
- **RISK F:** not applicable (BENCH-M0-01 owns this).

## Boundary check

`./invariant check boundaries` from the main checkout on the lane
branch: PASS (8 of 8 ok lines, exit 0; transcript shown in section
3 above).

## Evidence artifacts

- Commit `4a26c6b` on `m0/sys-00-worktree-safe-harness` — the
  one-line fix.
- This file: `LANE-EVIDENCE.md`.
- Selftest worktree (`m0/selftest-wt`): created, used for positive
  test, deleted. Branch deleted.

## STATUS

`ready-to-merge`

## Notes for the integration authority

Per the refined SYS-M0-00 package's `MERGE GATE` field, this lane
merges at **M1** — the first merge of the train. The lane branch
must be deleted post-merge per `BRANCH-STRATEGY.md`. The merge
target is `main`. The merge title must be `SYS-M0-00: <one-line
summary>`; the recommended summary is "worktree-safe harness
(accept .git as a gitfile in check_structure)".

After this lane merges, **M2 (SYS-M0-01)** becomes eligible to
open. M2 owns `contracts/`, `integration/fixtures/`, and
`program/*.md` exclusively and is the gate-keeper for all product
lanes.