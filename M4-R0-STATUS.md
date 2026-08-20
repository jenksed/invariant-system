# M4-R0 Zig Render Kernel — STATUS (deferred)

Worktree: `/Users/jenksed/Developer/invariant-system-worktrees/m4-r0-zig-render`
Branch: `experiment/m4-r0-zig-render` @ 82b2d54 (forked from `work/temper-workbench-alpha`)
Started: 2026-08-20

## Completed in this session

- **Orient to current Temper renderer** → `M4-R0-ORIENT.md`
- **Research Elixir↔Zig boundary** (initial):
  - OpenTUI confirms Zig-native double-buffered cell grid is the precedent.
    C-compatible ABI; TypeScript primary binding; `@opentui/solid` / `@opentui/react`
    reconcilers sit ABOVE the native core. (Source: github.com/sst/opentui README).
  - Zigler: Zig NIFs for Elixir. The Reddit thread "Can a Zigler NIF still crash the whole
    BEAM node? Yes" is a hard cautionary: native code can panic the VM. Tiny, deterministic
    NIFs are the safe path. (Source: zigler.hexdocs.pm, hexdocs.pm/zigler).
  - Data crossing the boundary is best kept as plain binaries or maps with primitive keys;
    no Workflow/Session/Run/Decision types cross.

## Deferred until M3 is frozen

- Build disposable Zig prototype
- Run required experiments (stale-frame, resize, multiline, Unicode, partial-diff,
  headless, snapshot, NIF safety)
- Final GO/NO-GO/MORE-EVIDENCE-REQUIRED verdict

## Why deferred

M3 close-out is the lane constraint right now. The M4-R0 lane exists to reduce
uncertainty, but the prompt explicitly says "First finish and freeze M3." After
M3_ACCEPTED_CANDIDATE is fixed:

1. rebase this lane onto M3_ACCEPTED_CANDIDATE;
2. re-orient against current Temper;
3. confirm the experiment still applies;
4. present GO/NO-GO evidence.

No Zig code added in this session. No product files modified in this session.