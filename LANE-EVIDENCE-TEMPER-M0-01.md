# LANE-EVIDENCE — TEMPER-M0-01 (M10)

## Lane metadata

- **Lane:** `TEMPER-M0-01`
- **Branch:** `m0/temper-01-dev-loop`
- **Worktree:** `/Users/jenksed/Developer/invariant-m0-temper-01`
- **Base SHA:** `e3ebf03` (Merge KILN-M0-03 / M9)
- **Started at:** 2026-08-17
- **Author:** orchestrator (Pass-05 execution, M10)
- **Refined work package:** `program/recursive-planning/pass-04/planning/30-day/work-packages/TEMPER-M0-01.md`
- **Owner authorization:** This owner prompt explicitly authorizes implementation of the bounded TEMPER-M0-01 work package; operator projection only — no new authority.

## What this lane establishes

The first trustworthy operator projection of the M0 governed loop:

> Temper can load the real M0 development-loop artifacts produced through M9, reject non-authoritative fixture/simulated data, project their state with traceable sources, and delegate permitted operator actions through Kiln's public CLI without importing sibling-product internals.

Temper remains a projection surface. It never infers acceptance, never mutates state, never re-runs a Kiln command on its own.

## Files added

- `products/temper/src/actions.ts` — bounded delegated action surface. Constructs the exact argv for the owning Kiln CLI command (per artifact ref), invokes via `execFileSync` (no shell), and refuses shell metacharacters. Returns a typed result; the caller re-reads the durable artifacts.
- `products/temper/test/development-loop.test.ts` — 10 new tests covering positive full-loop rendering, negative stale/simulated/malformed/missing projection paths, action argv construction, shell-metacharacter refusal, sibling-source coupling self-check.

## Files modified

- `products/temper/src/types.ts` — added M0 types: `ArtifactRef`, `RunResultProjection` (schema literal `engineering-system/run-result-projection/m0-v1`), `M0ArtifactBundle`. Extended `WorkbenchModel` with `m0ProjectionPath` and `m0` fields. Extended `Focus` with `'loop'`.
- `products/temper/src/load.ts` — added `loadM0Bundle` to discover and load the M0 RunResultProjection; rejects `fixture_only: true` at the load layer; emits bounded `RunResultProjection` typed bundle; per-field `SourceFact`s naming the owning Kiln CLI command.
- `products/temper/src/render.ts` — added `'loop'` to `FOCUSES`; added `loopPanel` rendering the M0 development-loop truth statuses with bounded provenance to artifact refs; updated help navigation; extended `fieldLines` to optionally surface a source hint.
- `products/temper/docs/SOURCES.md` — added M0 sources table; documented discovery convention; documented rejection policy; documented authority boundary.

## Loop focus rendering

The `loop` focus renders:

- **Run status** (from `truth.run_status`) — bounded to `completed|blocked|cancelled|failed|unknown`.
- **Verification** (from `truth.verification_status`) — bounded to `PASS|FAIL|TIMEOUT|ERROR`.
- **Review** (from `truth.review_status`) — bounded to `APPROVE|REQUEST_REVISION|REJECT`. Renders `n/a — review (not yet recorded)` when null.
- **Human decision** (from `truth.human_status`) — bounded to `ACCEPT|REJECT|REQUEST_REVISION`. Renders `n/a — human decision (not yet recorded)` when null.
- **Unknown effects** — listed from `truth.unknown_effects[]`.
- **Provenance** — every artifact ref rendered as `{id} ({digest.slice(0,16)}…)`.

The renderer's source command is the exact Kiln CLI invocation that produced each artifact:

| Field | Source command |
|-------|----------------|
| Run status, Human decision | `mix kiln human-decide` |
| Verification | `mix kiln verify-run` |
| Review | `mix kiln review-propose` |
| M0 projection facts | `mix kiln human-decide` (the final M0 dispatch that emits the projection) |

## Authority boundary compliance

| Doctrine | Compliance |
|----------|-----------|
| Temper is a projection, not authority. | YES — Temper never infers; reads only bounded artifacts. |
| Fixture-only rejected. | YES — `fixture_only: true` rejected at the load layer; surfaces in `errors`. |
| No sibling-source coupling. | YES — `actions.ts` invokes owning Kiln via `execFileSync`; no Kiln module imports. Self-check test in `development-loop.test.ts`. |
| No free-form shell. | YES — `execFileSync` with explicit argv; shell-metacharacter guard refuses `;&|` \` $<>` and newlines. |
| No Temper state mutation. | YES — actions return typed results; caller re-reads durable artifacts. |
| v0 `simulated: true` rejection preserved. | YES — existing rule applied. |
| Missing stages render `n/a — <reason>`, not inferred. | YES — Review and Human Decision render `not yet recorded` when refs are null. |

## Commands run

```
$ cd products/temper && npm run ci
…
1..25
# tests 25
# pass 25
# fail 0

$ ./invariant test temper
1..25
# pass 25

$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is selection-only (src/selector.py + tests)
ok:   temper has no sibling-product source coupling  ← new M10 evidence
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
EXIT=0
```

## Acceptance matrix

| Case | Test | Result |
|------|------|--------|
| Full-loop snapshot renders every stage with correct values | `full-loop snapshot renders every stage with correct values` | PASS |
| Stale projection marked stale | `stale projection is not silently promoted` | PASS |
| Missing Review and Human Decision render `n/a` | `missing Review and Human Decision render as n/a with reason` | PASS |
| `fixture_only: true` rejected at load | `fixture_only projection is rejected at load and surfaces in errors` | PASS |
| Malformed projection rejected | `malformed projection is rejected with bounded error` | PASS |
| Missing projection renders `n/a` with bounded reason | `missing projection renders n/a with bounded reason` | PASS |
| `human-decide-accept` argv exact | `buildArgv constructs exact argv for human-decide-accept` | PASS |
| `patch-decide-reject` argv exact | `buildArgv constructs exact argv for patch-decide-reject` | PASS |
| Shell metacharacters refused | `shell metacharacters in argv are refused at construction` | PASS |
| Missing `mix` binary → bounded failure | `missing mix binary surfaces a bounded failure (no shell expansion)` | PASS |
| Default output path under `.loadout/actions/` | `defaultOutputPath is under .loadout/actions/ and is deterministic` | PASS |
| No sibling-source coupling | `Temper src does not import from sibling product trees` | PASS |

Total: 25/25 PASS (15 existing + 10 new M10 + 2 modified v0 = 25).

## Downstream unlocks

- **M11 (SYS-M0-03):** Can now load the M0 RunResultProjection, render the development-loop view, and delegate operator actions through `mix kiln` commands. The first meaningful Invariant-on-Invariant dogfood can now be executed end-to-end through the operator surface.

## Deferred scope

- Background daemon / file-watcher for live updates (Temper is read-only on demand).
- Inline editing of M0 artifacts (Temper is projection only).
- New provider family or capability (M10 has no new capability).

## Acceptance verdict

- Temper projects M0 truth? **YES** (loop focus renders truth from `engineering-system/run-result-projection/m0-v1`).
- Temper loads real M0 artifacts? **YES** (load layer discovers via canonical discovery path).
- Temper rejects fixture/simulated? **YES** (load-layer enforcement).
- Temper delegates via owning Kiln command? **YES** (`execFileSync` with explicit argv; no shell).
- No sibling-source coupling? **YES** (self-check test passes; boundary check passes).
- Public consumer path proven? **YES** (10 new tests + existing 15 = 25 total).
- 25/25 tests pass + `./invariant test temper` + boundaries check exit 0.
