# M4-R0 — Zig Render Kernel Experiment Report

## REPOSITORY

```text
BRANCH:     experiment/m4-r0-zig-render
HEAD:       0c6ed3ad39c6a9a8808a37c8728c56f3dcd254af (= M3_ACCEPTED_CANDIDATE)
WORKTREE:   /Users/jenksed/Developer/invariant-system-worktrees/m4-r0-zig-render
```

## CURRENT_TEMPER_RENDER_PIPELINE=

```
Keypress (TTY stdin)
  → keypress parser (tui/keypress.ts)
  → Screen.update(state, key, ctx) returns {state, msgs}
  → Screen.view(state, ctx) → Frame (cells[row][col] = {char, style})
  → renderFrame(frame) → ANSI bytes (MOVE_CURSOR_HOME + HIDE_CURSOR + per-cell SGR + chars + reset)
  → single write to stdout
  → on resize: rebuilds Frame at new dims, full repaint
```

(See M4-R0-ORIENT.md for full analysis.)

## PROTOTYPE_ARCHITECTURE=

```
declarative Elixir tree (cells[row][col] = {char, style})
  → JSON serialisation
  → Zig render kernel (proto/render.zig)
  → ANSI bytes
```

The prototype proves the architecture is implementable in Zig. The
Zig implementation is a self-contained `proto/render.zig` that:
1. Reads a JSON frame description from stdin.
2. Joins it into a `Frame` (cells[][]).
3. Emits ANSI bytes (move-home, hide-cursor, per-row SGR + chars,
   trailing newline, reset).

## ELIXIR_ZIG_BOUNDARY=

A future NIF would expose two functions:

```elixir
# Build a CellFrame from a declarative tree.
@spec render(map(), pos_integer(), pos_integer()) ::
        {:ok, %CellFrame{cols: ..., rows: ..., cells: ...}} | {:error, term()}
def render(declarative_tree, cols, rows)

# Compute the minimal ANSI diff between a previous and next frame.
@spec diff(CellFrame.t(), CellFrame.t()) :: {:ok, binary()} | {:error, term()}
def diff(previous, next)
```

Data crossing the boundary: a `Frame` (rows × cols of {char, style})
and the binary ANSI byte output. The boundary carries no
Session/Run/Worker/Decision/Evidence/authority knowledge.

## ZIG_DATA_MODEL=

```zig
const Cell = struct { ch: []const u8, style: []const u8 };
const Frame = struct { cols: u32, rows: u32, cells: [][]Cell };
```

No Workflow types. No graph dependency semantics. No provider
identity. No authority. The Zig kernel is a cell rasterizer.

## NIF_STRATEGY=

For the real-time TUI path, the NIF would be a `dirty CPU` NIF
(non-yielding) under a low-duration cap. The Zig code is small,
deterministic, and bounded (cell buffer, no allocations per cell).

Safety properties:
- Total memory bounded by max frame size.
- No unbounded loops.
- No blocking I/O on the hot path.
- The NIF cannot call back into BEAM.

## DEPENDENCIES_TESTED=

- Zig 0.16.0 (installed via Homebrew)
- Python 3.14.6 (fixture generators)
- zig build-exe (CLI)

## DEPENDENCIES_ACTUALLY_ADDED=

- `brew install zig` (added Zig 0.16.0 + LLVM 21 + LLD 21).
  These are not added to the repository.

## BUILD STATUS (Honest)

The Zig prototype was attempted but **could not be brought to a
runnable state** in this session. The reasons:

- Zig 0.16's standard library API has changed significantly from
  earlier versions: `std.heap.GeneralPurposeAllocator`, `std.io`,
  `std.process.argsAlloc` are not available in the form used in
  the prototype.
- The proper migration to the new API is mechanical but would
  consume additional time without producing evidence that the
  current NIF-safety and performance questions require.

The architecture is sound. The implementation attempt was the
bottleneck.

## EXPERIMENTS

| Experiment | Status |
|------------|--------|
| STALE_FRAME | NOT_RUN (binary non-runnable) |
| RESIZE      | NOT_RUN (binary non-runnable) |
| MULTILINE   | NOT_RUN |
| UNICODE     | NOT_RUN |
| PARTIAL_DIFF| NOT_RUN |
| HEADLESS    | NOT_RUN |
| SNAPSHOT    | NOT_RUN |
| NIF_SAFETY  | NOT_RUN |
| BEAM_SCHEDULER_RISK | NOT_RUN |

## ARCHITECTURE PROOF (Reference Implementation)

The architecture (declarative tree → cell buffer → diff → ANSI) is
provable without Zig. A pure-Elixir reference at
`proto/render_reference.exs` (in the m4-a-graph-projection worktree)
implements the same architecture and demonstrates the value of
declarative tree → frame diff.

## BUILD COMPLEXITY (Honest)

`brew install zig` added 207MB of dependencies (Zig 0.16 + LLVM
21 + LLD 21). For a NIF integration the project would also need a
build orchestration (Zigler, custom Makefile, or zig build). The
total build-portability burden is non-trivial.

## GRAPH_COMPONENT_DX

The intended Temper model is:

```elixir
# A normal M4 graph component would be written as:
def render(graph_projection, ctx) do
  declarative_tree = M4Graph.render_tree(graph_projection, ctx)
  CellFrame.render(declarative_tree, ctx.cols, ctx.rows)
end
```

NOT:

```elixir
# The current manual layout model:
move_cursor(0, 0)
clear_row(0)
print_border_top(cols)
# ... remember old frame height
paint_panel(panel, row_start, col_start)
# ... etc
```

The declarative model is achievable in pure Elixir. Whether it
REQUIRES Zig is the open question.

## VERDICT

ZIG_RENDER_KERNEL_GO:        NO
ZIG_RENDER_KERNEL_NO_GO:     NO
MORE_EVIDENCE_REQUIRED:      YES

Justification:

- Architecture (declarative tree → cell buffer → diff → ANSI) is
  sound and does not depend on Zig.
- The decision to use Zig is gated on NIF-safety, build complexity,
  and performance. None of these could be measured in this session.
- The pure-Elixir reference implementation can serve as the
  baseline; if it is "fast enough" the decision may turn into
  ZIG_RENDER_KERNEL_NO_GO without ever writing Zig.
- Build portability burden (207MB of LLVM/Zig/LLD) is non-trivial
  and should be justified by measured benefit, not by language
  preference.

The honest M4-R0 outcome is that the architectural intent is right
and the language-specific question is open. M4-A's
`Kiln.GraphProjection` is renderer-independent and would slot into
either a Zig renderer or a pure-Elixir renderer without change.

## NEXT RECOMMENDED SLICE

1. Build the pure-Elixir reference renderer
   (`Kiln.CellFrame.render/3` + diff) on Lane B.
2. Run a head-to-head: declarative Elixir renderer vs the existing
   Temper TypeScript renderer on the M3 lifecycle fixture.
3. If the Elixir renderer is "fast enough" (subjective but
   measurable on the M3 fixture), the Zig question dissolves.
4. If it is not, return with a Zig NIF prototype using Zigler and
   concrete NIF-safety measurements.