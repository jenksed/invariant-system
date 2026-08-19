# WP-09 Section 6 — Bounded Reconciliation Report

Date: 2026-08-19. Companion to `WP08-WP09-STATE.md` and `LANE-EVIDENCE-M12-SESSION.md`.

Source inspection performed against `wp-09-temper-rpc/` branched from
`WP08_FINAL_SHA = 96f76adf0a63a5928bc2648acf695d1b25aeb868`.

## 1. Daemon surface — RPC method classification

### 1a. Currently real (proxied to bounded Kiln machinery)

| Method | Scope | Handler | Backing machinery | Status |
|---|---|---|---|---|
| `session.start` | orchestration:operate | `Kiln.RPC.Handlers.Session.handle/3` | `Kiln.Workflow.start_session/1` | WP-08 PROVEN |
| `session.cancel` | orchestration:operate | same | `Workflow.cancel_session/2` | WP-08 PROVEN |
| `session.resume` | orchestration:operate | same | `Workflow.resume_session/2` | WP-08 PROVEN (deferred re-observation = P6 carry-forward) |
| `session.query` | orchestration:read | same | `Workflow.query_session/1` | WP-08 PROVEN |
| `session.next_actions` | orchestration:read | same | `Workflow.valid_next_actions/1` | WP-08 PROVEN |
| `patch.apply` | orchestration:operate | `Kiln.RPC.Handlers.Patch.handle/3` | `Kiln.PatchService.apply/3` + Workflow intent/observation journaling | WP-08 PROVEN |
| `project.list` | orchestration:read | inline (`{:ok, %{projects: []}}`) | stub | WP09_NOT_REQUIRED for acceptance path |
| `project.open` | orchestration:operate | inline echo (`{:ok, %{status: "opened", path: …}}`) | stub | WP09_REQUIRED only as minimum-viable "open a repo" affordance |

### 1b. Currently `E_NOT_IMPLEMENTED`

| Method | Scope | Required for WP-09 acceptance? | Classification | Backing machinery that already exists |
|---|---|---|---|---|
| `worker.propose` | orchestration:operate | Yes — bounded dispatch | **WP09_REQUIRED** | `Kiln.Worker.propose/5` (worker.ex:127) — bounded envelope validation, repository observation, CandidateInvocation digest binding |
| `verify.run` | orchestration:operate | Yes — bounded verify | **WP09_REQUIRED** | `Kiln.VerificationResult.build/6` (cli.ex:496) — canonical `verification-result/m0-v1` emission |
| `review.propose` | review:write | Yes — bounded review | **WP09_REQUIRED** | `Kiln.M9Review` (m9_review.ex) + `Kiln.Authority.decide/1` (authority.ex:124) — bounded review envelope |
| `human.decide` | orchestration:operate | Yes — bounded HumanDecision | **WP09_REQUIRED** | `mix kiln human-decide` (cli.ex) — bounded human-decision artifact emission; `Kiln.M0HumanDecision` struct exists |
| `activity.subscribe` | orchestration:read | Yes — live activity stream | **WP09_REQUIRED** | New `Kiln.Activity.Hub` required (no existing module); bounded by Session/Run/Operation ids + canonical revision |
| `terminal.attach` | terminal:operate | **NO** — not in acceptance path | **WP09_NOT_REQUIRED** | Truthful `E_NOT_IMPLEMENTED` preserved per WP-08 closeout |

**BLOCKED_BY_CONTRACT_DECISION: none.** All required methods have a real backing
module or a documented, bounded new module (Activity.Hub).

### 1c. WebSocket transport

| Surface | Current state | WP-09 requirement |
|---|---|---|
| `/ws` upgrade | `service.ex:53-64` — bare 101 with auth gate; no Cowboy WS handler, no frames | Replace stub with real Cowboy WS handler that authenticates, accepts `activity.subscribe` envelope, streams `Kiln.Activity.Hub` notifications |
| `Plug.Cowboy` | installed (lib/kiln/daemon.ex:27) | Keep — no replacement framework |
| Auth during upgrade | service.ex:54 — uses `authenticate/1` (Authorization header bearer) | Browser WS clients cannot set custom headers — defer browser-grade exchange to later WP; current acceptance client (Temper via Node `ws`) can send header |

## 2. Temper seams

### 2a. Surface inventory

| File | Lines | Role | WP-09 reuse strategy |
|---|---|---|---|
| `src/types.ts` | 143 | Canonical TS types (LoadoutPlan, RunResultEnvelope, RunResultProjection, WorkbenchModel, ArtifactRef) | Add `ActivityNotification`, `LiveSessionProjection`, `RpcEnvelope`, `RpcErrorEnvelope` — do NOT rename existing types |
| `src/actions.ts` | 259 | CLI exec argv builder for `kiln patch-decide|human-decide` | Add a `DaemonDispatcher` that maps the same `DelegatedActionKind` set to `worker.propose` / `patch.apply` / `verify.run` / `review.propose` / `human.decide` over HTTP. Keep the CLI dispatcher (`LocalDispatcher`) untouched |
| `src/cli.ts` | 129 | Argv parsing + interactive draw loop | Add `--live` mode flag that switches `loadWorkbench` → `liveLoadWorkbench` (canonical resync) and the redraw loop → `redrawOnActivity(stream)` |
| `src/load.ts` | 410 | Filesystem-only workbench loader (`loadWorkbench`) | Add `WorkbenchSource` interface so `FileSystemSource` and `DaemonSource` coexist; `loadWorkbench` signature unchanged |
| `src/render.ts` | 405 | Pure presentational rendering | Untouched — render stays pure. New live fields feed `WorkbenchModel` |

### 2b. ActionDispatcher seam

Current `runAction` returns `DelegatedActionResult | DelegatedActionError` after
invoking `mix kiln …` synchronously. For live mode the same surface must be
available; the new path forwards the bounded `DelegatedActionRequest` to the
daemon over HTTP RPC and reads back the canonical result envelope. No free-form
shell, no shell metacharacters (existing argv-validator at actions.ts:193-210
must remain).

### 2c. WorkbenchSource seam

`loadWorkbench(repository, options)` reads `.loadout/*` JSON + `git rev-parse
HEAD`. Live mode requires an additional `project.open` call to obtain canonical
state from Kiln. Introduce a `WorkbenchSource` interface so the snapshot path
keeps working unmodified:

```ts
export interface WorkbenchSource {
  loadProject(repository: string, opts: LoadOptions): Promise<WorkbenchModel>;
}
```

Two implementations: `FileSystemSource` (current behavior), `DaemonSource`
(HTTP `project.open` + canonical query). `--live` chooses the latter.

## 3. Identity model

| Concept | Current WP-08 contract | WP-09 contract decision |
|---|---|---|
| repository/project identity | filesystem path | Carry forward — `repository: string` |
| session_id | `ses_<32hex>` (Kiln.Domain.Id) | Carry forward — RPC + projection reuse |
| run identity | `run_<32hex>` | Carry forward |
| operation identity | `opn_<32hex>` | Carry forward — required for `patch.apply` envelope (already enforced in `handlers/patch.ex:62-76`) |
| idempotency_key | `idem_<32hex>` | Carry forward — P1 contract unchanged |
| request_digest | `sha256:<64hex>` | Carry forward — P1 contract unchanged |
| activity revision | new | `revision: integer` (monotonic, derived from journal session_revision after replay) — do NOT use daemon PID, WS connection, hostname, Temper PID |
| client identity | new | `client_id: string` (Temper mints per-process UUIDv4) — used only for activity correlation, NOT for Session identity |
| daemon instance identity | implicit (PID/hostname) | DO NOT expose — Session identity is independent of daemon lifecycle |

### Accidental conflation to avoid

- WS connection ↔ Session — `session_id` is the only authoritative handle.
- Temper PID ↔ daemon PID ↔ provider conversation ↔ Session — none of these
  may enter any envelope, journal entry, or projection.
- `client_id` is for activity correlation only and is never persisted into the
  journal or used to authorize any operation.
- `activity.revision` is derived from authoritative session_revision after
  journal replay, not from event count or timestamp.

## 4. Acceptance-path coverage matrix (initial)

| Acceptance criterion | Required RPC + Activity | Current state |
|---|---|---|
| AC-01 real Temper HTTP client | new `src/client.ts` over Node `fetch` | NOT_PRESENT |
| AC-02 real WebSocket activity stream | new Cowboy WS handler + `Kiln.Activity.Hub` | NOT_PRESENT |
| AC-03 canonical state query/resync | `session.query` (PROVEN) + new `project.open` handler that returns canonical WorkbenchModel | PARTIAL (session.query PROVEN) |
| AC-04 bounded lifecycle RPC path | `worker.propose` / `verify.run` / `review.propose` / `human.decide` / `patch.apply` (PROVEN) | PARTIAL |
| AC-05 explicit authorization preserved | bearer token + exact-scope match (PROVEN) | PROVEN |
| AC-06 five real bounded E2 tasks | full E2 evidence | NOT_PRESENT |
| AC-07..AC-09 reconnect before/during/after | new reconnect tests using existing `Restart.reconstruct/1` (PROVEN) | NOT_PRESENT (tests) |
| AC-10 Temper disconnect preserves Kiln state | journal is sole authority (PROVEN) | PROVEN by construction |
| AC-11 unauthorized RPC bounded rejection | `:E_SCOPE_INSUFFICIENT` envelope (PROVEN) | PROVEN |
| AC-12 UI cannot bypass approval | P2/P3/P4 PatchService semantics (PROVEN) | PROVEN |
| AC-13..AC-15 duplicate/stale/missed activity | new activity dedupe logic | NOT_PRESENT |
| AC-16 unknown-effect replay protection | P2/P5 + `Restart.reconstruct/1` (PROVEN) | PROVEN |
| AC-17 daemon restart + Temper recovery | WP-08 Lane 4 PROVEN | PROVEN |
| AC-18 verification distinct from completion | bounded `verification-result/m0-v1` is evidence, not authority | PROVEN |
| AC-19 review independent | bounded review envelope, separate operation class | PROVEN |
| AC-20 HumanDecision explicit | bounded human-decision artifact emission | PROVEN |
| AC-21 final Temper projection derives from canonical Kiln truth | new `Kiln.RPC.Handlers.Project.query_projection/1` returning canonical WorkbenchModel-shape JSON | NOT_PRESENT |

## 5. Required new modules (preliminary contract-freeze candidates)

- `Kiln.RPC.Handlers.Worker` — wraps `Kiln.Worker.propose/5`
- `Kiln.RPC.Handlers.Verify` — wraps `Kiln.VerificationResult.build/6`
- `Kiln.RPC.Handlers.Review` — wraps `Kiln.M9Review` review envelope + Authority decide
- `Kiln.RPC.Handlers.HumanDecision` — wraps the bounded human-decision CLI path
- `Kiln.RPC.Handlers.Project` — `project.open` / `project.list` / canonical query
- `Kiln.Activity.Hub` — bounded publisher + subscriber registry with revision monotonicity
- `Kiln.Activity.WebSocket` — Cowboy WS handler at `/ws`
- `products/temper/src/client.ts` — HTTP RPC client (Node `fetch`)
- `products/temper/src/stream.ts` — WS client + canonical resync orchestrator
- `products/temper/src/source.ts` — `WorkbenchSource` interface + FileSystemSource + DaemonSource

## 6. WP-08 contract constraints preserved

The contract freeze must NOT violate:

- Exact-scope match (no scope widening to `orchestration:operate`)
- P1 idempotency-key envelope field (preserved in router.ex:88-92)
- P5 bounded error code preservation (router.ex:65-72)
- P2 production intent/observation journaling via `handlers/patch.ex:131-230` — same pattern for new consequential RPCs
- Journal via the correct Kiln domain boundary (`Kiln.Store.Journal.commit/4`), not via `PatchService`
- No contract identity string rename (`session.*`, `patch.apply`, `M0PatchProposal`, `M0PatchDecision`, `verification-result/m0-v1`, `engineering-system/run-result-projection/m0-v1`, etc.)
- `pending` / `active` / `interrupted` / `replacement` distinctions remain distinguishable in projection
- Unknown-effect reconciliation semantics (WP-08 FI-1..FI-5 PROVEN) preserved
- Single-writer journal and mutation-ownership assumptions preserved

## 7. Next action

Produce the WP-09 contract-freeze record (Section 7) before any implementation
begins. Do not start parallel lanes until the contracts are frozen.
