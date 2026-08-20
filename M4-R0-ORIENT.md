# M4-R0 — Orient to Current Temper

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

## Architecture

```
products/temper/src/
├── tui/
│   ├── tui.ts        — TuiRuntime (event loop, screen stack, alt-screen)
│   ├── frame.ts      — Frame/Cell/Style + putChar/putString (manual layout)
│   ├── render.ts     — renderFrame → ANSI; STYLE_TO_ANSI palette
│   ├── input.ts      — stdin reader
│   ├── keypress.ts   — raw-byte → typed Key
│   └── screen.ts     — Screen contract (id/title/view/update/overlay)
├── screens/
│   ├── home.ts       — main entry screen (354 lines)
│   ├── work.ts
│   └── diff.ts
└── workbench/        — Kiln projection consumption
```

## Authority rule

A screen never owns a workflow boolean (`approved=true`, `verified=true`,
`complete=true`). It only renders state fetched via WorkbenchConnection
from Kiln. Workflow authority stays in Kiln.

## Rendering strategy

- Full clear-and-rewrite on every render. No partial diff, no cell diffing.
- One ANSI write per frame (single stringified buffer).
- Style classes map to a small palette (normal/bold/dim/header/footer/success/warn/error/muted/accent/border/input_focused/input_unfocused/wordmark/wordmark_dim).
- No Unicode width table — single-cell width only (commented: "callers that need them should iterate").

## CURRENT_RENDERING_FAILURE_PRESSURES

Observed in shipped code:

1. **Stale bottom content after shorter frames.** renderFrame moves the
   cursor home (`\x1b[H`) and writes rows × cols. If a previous render
   left N rows of content and the next frame is M < N rows tall, the
   rows [M..N-1] keep their old characters because nothing emits
   `\x1b[J` (erase below) or repaints the trailing area.

2. **Manual layout calculations.** putChar/putString take row/col;
   screens compute layout by hand. No box/rect/grid primitive. Border
   drawing and panel composition are inlined per screen.

3. **Narrow-terminal edge cases.** putString early-returns when
   `c >= frame.cols`; truncation is silent. No wrapping, no ellipsis,
   no minimum-width handling. Multi-byte chars split into first byte
   only ("Only single-cell width supported here; multi-char sequences
   are split").

4. **Resize reliability.** Resize handler rebuilds the Frame at new
   dimensions; but the runtime does not clear the old frame's residual
   rows on the way out, so the same staleness defect as #1 applies
   during resize transitions.

5. **Multiline rendering.** home.ts has a recent fix ("multi-line
   intent input now renders the visible tail correctly") — multiline
   input is fragile enough that it required an M3-boundary patch.

6. **No Unicode/grapheme width.** The renderer assumes one char = one
   cell. CJK, combining marks, and emoji advance the cursor by raw
   UTF-8 code units, not display columns. Frames drift horizontally
   when non-ASCII content is rendered.

7. **No headless/snapshot isolation in renderer.** frameToText and
   cellAt exist for tests, but the runtime does not provide a
   deterministic "render to in-memory frame without stdout write" path
   that would let graph components test in CI without a TTY.

8. **No partial diff.** Every render repaints everything. Graph-heavy
   M4 screens (work graphs, dependency edges, attention state) would
   flicker and burn CPU on full rewrites.

## What is good and should NOT be replaced

- The Screen contract (`view` is pure, `update` is pure-given-state)
  is a clean boundary. Zig should sit BELOW the Frame, not between
  Screen and runtime.
- The Key abstraction (typed Key, not raw bytes) is the right model.
- The Style palette is small and stable.
- The authority rule (screens don't own workflow booleans) must be
  preserved.