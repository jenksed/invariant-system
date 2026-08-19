# T3 Code Reference Atlas (Pathfinder WP-01)

**T3 source pin:** `26af903b9bec7f8da56bb5f545d9980d08d418e1` (pingdotgg/t3code @ main, depth 50)
**T3 repo:** https://github.com/pingdotgg/t3code
**T3 license:** MIT (substantial source reuse requires attribution)
**Source location (local clone):** `/tmp/t3-archaeology/t3code/`

## Mapped mechanisms (Pathfinder WP-01 output)

For each mechanism:
- T3 source paths
- Problem being solved
- Invariant analogue (existing or missing)
- Reuse/adaptation opportunity
- Elixir/OTP leverage
- Reuse classification

### M-01: Effect RPC over WebSocket (client/server boundary)

- **T3 paths:** `packages/contracts/src/*`, `apps/server/src/ws.ts`, `apps/server/src/rpc.ts`, `packages/client-runtime/src/connection/`
- **Problem:** typed client/server contract with streaming support; per-method authorization scopes; one authenticated WS endpoint
- **Invariant analogue:** Kiln CLI (no client/server RPC); no streaming channel; per-method authorization not implemented
- **Reuse opportunity:** Use **Effect RPC over Phoenix Channels** for the same pattern. Phoenix Channels already provides the typed streaming + per-method authorization pattern; Elixir/OTP-native.
- **Elixir/OTP leverage:** Phoenix.PubSub + Phoenix.Channel + token-scoped auth (`RPC_REQUIRED_SCOPE` equivalent)
- **REUSE_CANDIDATE:** MODERATE_ACCELERATOR — Phoenix Channels gives us 80% of T3's RPC machinery; we just need to design the per-method scope model (T3 has a clean one to copy)

### M-02: Connection Runtime (reconnect/cache/session)

- **T3 paths:** `packages/client-runtime/src/connection/{layer,driver,resolver,registry,session}.ts`, `apps/web/src/connection/runtime.ts`, `apps/mobile/src/connection/runtime.ts`
- **Problem:** shared non-visual client concern (lifecycle, auth, retry, transport, cached environment data, domain state as Atom)
- **Invariant analogue:** none (Temper is CLI-snapshot only; no persistent client runtime)
- **Reuse opportunity:** The runtime is platform-shared between web and mobile. Invariant only needs desktop initially; web/mobile are secondary.
- **Elixir/OTP leverage:** OTP DynamicSupervisor + Registry is the canonical match for `EnvironmentSupervisor`. Avoid inventing custom retry loops.
- **REUSE_CANDIDATE:** MAJOR_ACCELERATOR — Temper's client runtime should reuse Phoenix Channels + OTP supervision directly; no custom machinery.

### M-03: OrchestrationEngine (event-sourced command/event/project)

- **T3 paths:** `apps/server/src/orchestration/{OrchestrationEngine,decider,projector}.ts`
- **Problem:** single-worker totally-ordered command processing; transactional event log + read model; durable command receipts (idempotent retries)
- **Invariant analogue:** Invariant Section 18 explicitly cautions "Do not conclude that Invariant therefore needs a new generic event-sourcing layer." Kiln's Run model + ledger + evidence + artifacts + state transitions already exist.
- **Reuse opportunity:** **DO NOT REIMPLEMENT**. Extend Kiln's existing Run/ledger/evidence model. The event-sourcing pattern is already implicitly present in M0 artifacts.
- **Elixir/OTP leverage:** Ecto + GenServer + bounded transactions already in Kiln's existing patterns.
- **REUSE_CANDIDATE:** DISTRACTION — Kiln's existing Run/ledger/evidence is the bounded equivalent. DO NOT introduce a new event-sourcing layer.

### M-04: Provider Driver Registry + Adapters

- **T3 paths:** `apps/server/src/provider/{builtInDrivers,builtInProviderCatalog,Drivers/*,Layers/*}.ts`, `apps/server/src/provider/ProviderAdapterRegistry.ts`, `apps/server/src/provider/ProviderInstanceRegistry.ts`, `apps/server/src/provider/ProviderService.ts`
- **Problem:** pluggable provider drivers (Codex, ClaudeAgent, Cursor, Grok, OpenCode) with capability negotiation; two registries separate config from live processes
- **Invariant analogue:** Kiln.MinimaxM3Adapter (PROVEN); Manifold bounded intelligence selection
- **Reuse opportunity:** Direct reuse of the **registry pattern** (config registry + adapter registry). For each provider, write only the bounded adapter (not full driver).
- **Elixir/OTP leverage:** Elixir behaviour + Registry is the canonical match. Use `provider_registry` GenServer with capability schema validation.
- **REUSE_CANDIDATE:** MAJOR_ACCELERATOR — direct pattern reuse; Kiln has one PROVEN adapter (MiniMax-M3). Add ≥1 more (Claude Code or Codex).

### M-05: Workspace Filesystem Abstraction

- **T3 paths:** `apps/server/src/workspace/{WorkspaceEntries,WorkspaceFileSystem,WorkspacePaths,WorkspaceSearchIndex}.ts`
- **Problem:** filesystem abstraction over the actual VCS; per-project state
- **Invariant analogue:** Kiln's existing repo awareness is more bounded — Kiln applies bounded diffs, not full FS abstraction
- **Reuse opportunity:** **DO NOT REIMPLEMENT full FS abstraction.** Kiln's bounded apply IS the abstraction. Add filesystem ops only as needed for the bounded apply (read target, write target, compute sha256).
- **Elixir/OTP leverage:** Elixir `File` module is sufficient for Kiln's bounded surface.
- **REUSE_CANDIDATE:** NO_MEANINGFUL_SAVINGS — bounded apply is already the minimum FS surface needed.

### M-06: Git VCS Driver (registry pattern)

- **T3 paths:** `apps/server/src/vcs/{GitVcsDriver,GitVcsDriverCore,VcsDriver,VcsDriverRegistry,VcsProcess}.ts`
- **Problem:** pluggable VCS abstraction (Git today; extensible); registry pattern for drivers
- **Invariant analogue:** Kiln's bounded apply uses raw `File` ops (no Git operations); branch/worktree awareness mentioned but not implemented
- **Reuse opportunity:** **DO NOT REIMPLEMENT VCS driver registry.** Use `git` CLI directly via Porcelain or System.cmd. Reuse only the bounded apply's preimage-check pattern.
- **Elixir/OTP leverage:** Elixir's `System.cmd("git", ...)` for direct shell invocation. No custom VCS abstraction.
- **REUSE_CANDIDATE:** SMALL_ACCELERATOR — invoke `git` directly; no registry abstraction needed for September scope.

### M-07: Environment Authentication (capability-based, scoped)

- **T3 paths:** `apps/server/src/auth/{EnvironmentAuth,EnvironmentAuthAdmin,EnvironmentAuthPolicy,PairingGrantStore,dpop,http}.ts`, `docs/internals/environment-auth.md`
- **Problem:** environment-scoped capability-based authorization (orchestration:read, orchestration:operate, terminal:operate, review:write, access:read, access:write, relay:read, relay:write); one-time pairing; bearer tokens; browser session cookies; DPoP
- **Invariant analogue:** Kiln has KILN-M0-01-E4 authorization record (bounded, scoped); no general capability model
- **Reuse opportunity:** **Adopt the scoped capability model**. T3's scope table is clean and battle-tested. Map directly to bounded Kiln operations.
- **Elixir/OTP leverage:** Plug auth pipelines or `:pow` (if needed); for September scope, hand-rolled scopes tied to bounded Kiln operations is sufficient.
- **REUSE_CANDIDATE:** MAJOR_ACCELERATOR — direct scope-table adoption; avoid building a general OAuth provider (the user explicitly cautioned against this).

### M-08: Terminal Abstraction (PTY adapter)

- **T3 paths:** `apps/server/src/terminal/{PtyAdapter,BunPtyAdapter,NodePtyAdapter,Manager,Services,Layers}.ts`
- **Problem:** pluggable PTY backend (Bun or Node); terminal lifecycle supervision
- **Invariant analogue:** none (Temper is CLI-snapshot only)
- **Reuse opportunity:** **Use Elixir/OTP directly** — `:os.cmd` or `Mint`/`Ports`. No custom PTY abstraction needed for September scope.
- **Elixir/OTP leverage:** Elixir Ports or `:erlang.open_port/2` for PTY; OTP supervision for lifecycle.
- **REUSE_CANDIDATE:** NO_MEANINGFUL_SAVINGS — Elixir/OTP-native PTY is canonical.

### M-09: Persistence (sqlite + migrations + auth sessions)

- **T3 paths:** `apps/server/src/persistence/{NodeSqliteClient,Migrations,AuthPairingLinks,AuthSessions}.ts`
- **Problem:** durable local persistence with migrations; auth session/linking storage
- **Invariant analogue:** Kiln has bounded state via Run/ledger/evidence but no Session machinery persisted across restarts
- **Reuse opportunity:** **Use Ecto + SQLite for Kiln Session machinery.** Direct pattern reuse; bounded migrations per Session schema.
- **Elixir/OTP leverage:** Ecto + SQLite (already a dep in M0 kiln.exs), `mix ecto.migrate`, M0 bounded contracts as schema sources.
- **REUSE_CANDIDATE:** MODERATE_ACCELERATOR — Ecto is canonical; bounded migrations per Session schema; reuse M0 contract shapes.

### M-10: SSH/Tailscale Transport

- **T3 paths:** `packages/ssh/`, `packages/tailscale/`
- **Problem:** SSH config parsing + tunnel/environment manager + Tailscale CLI wrapper for `ensureTailscaleServe`/`disableTailscaleServe` lifecycle
- **Invariant analogue:** none (no remote transport in Invariant)
- **Reuse opportunity:** **Direct reuse as packages.** Both are T3's MIT packages. Invariant can adopt them as-is OR invoke `ssh`/`tailscale` CLIs directly.
- **Elixir/OTP leverage:** `System.cmd("ssh", ...)` + `System.cmd("tailscale", ...)`; no Elixir-native replacement needed.
- **REUSE_CANDIDATE:** MAJOR_ACCELERATOR — adopt `packages/ssh/` and `packages/tailscale/` as bounded dependencies (with attribution); no need to reinvent.

### M-11: Streaming (Effect RPC `stream: true`)

- **T3 paths:** `apps/server/src/orchestration/{OrchestrationEngine}.ts`, `apps/server/src/stream/`
- **Problem:** server pushes only on subscription (e.g., `orchestration.subscribeShell`, `orchestration.subscribeThread`); bounded streams replace broadcast push bus
- **Invariant analogue:** bounded Run/ledger events exist but no streaming channel to clients
- **Reuse opportunity:** **Phoenix Channels** (already OTP-native) for bounded streams. Use channel topic per (project_id, thread_id).
- **Elixir/OTP leverage:** Phoenix.Channel + PubSub for bounded event streams; bounded event types in M0 contracts.
- **REUSE_CANDIDATE:** MAJOR_ACCELERATOR — Phoenix Channels gives us the streaming pattern; bounded event types already exist.

### M-12: Desktop Backend Supervision

- **T3 paths:** `apps/desktop/`, `apps/desktop/src/`
- **Problem:** Electron shell supervises a desktop-scoped `t3` backend; loads web bundle over `t3code://` protocol
- **Invariant analogue:** none (no Invariant desktop yet)
- **Reuse opportunity:** **September scope = desktop only.** Electron + Tauri are both viable. T3 uses Electron; Tauri (Rust) is lighter. **Adopt Electron for September** to match T3's pattern; defer Tauri.
- **Elixir/OTP leverage:** Electron + node-bridge to Elixir daemon; or **build native Elixir daemon** with web UI loaded by Electron.
- **REUSE_CANDIDATE:** SMALL_ACCELERATOR — Electron for UI shell; Elixir daemon is the substantive piece.

### M-13: Workspace Model (execution environment, project, thread)

- **T3 paths:** `apps/server/src/project/`, `apps/server/src/orchestration/`, `packages/contracts/src/{project,environmentHttp,t3ProjectFile}.ts`
- **Problem:** model the execution environment, project, and thread as canonical entities
- **Invariant analogue:** Kiln has Run + bounded completion + bounded proposals; no Environment/Project entity separate from Run
- **Reuse opportunity:** **Adopt the entity model.** Environment is bounded by `environmentId`; Project by `projectId`; Thread by `threadId`. Each is a bounded identity with bounded semantics.
- **Elixir/OTP leverage:** Use M0 contract shapes (engineering-system/...) as schemas; bounded registry per entity.
- **REUSE_CANDIDATE:** MODERATE_ACCELERATOR — entity model is straightforward; reuse M0 contract shapes.

### M-14: Streaming Activity Timeline

- **T3 paths:** `apps/web/src/thread/`, `apps/desktop/src/`
- **Problem:** visual activity timeline for the operator
- **Invariant analogue:** Temper snapshot (CLI render); no persistent timeline
- **Reuse opportunity:** **Phoenix LiveView** for server-driven UI updates, OR **HTMX + Phoenix Channels** for incremental server-driven UI without JS frameworks. Both are Elixir-native.
- **Elixir/OTP leverage:** LiveView gives us bounded reactive UI without a separate JS build pipeline.
- **REUSE_CANDIDATE:** MAJOR_ACCELERATOR — LiveView saves building a JS UI; bounded event types feed LiveView components.

### M-15: Workspace Diff Display

- **T3 paths:** `apps/web/src/diff/`, `apps/desktop/src/diff/`
- **Problem:** visual diff presentation
- **Invariant analogue:** bounded apply produces canonical post-state; diff is `expected_before_digest → actual_post_state_digest`
- **Reuse opportunity:** **Compute diff from canonical sha256s**; render with Phoenix LiveView or simple HTML. No custom diff library.
- **Elixir/OTP leverage:** Compute sha256 of before/after; if equal, no diff. Else show side-by-side or inline.
- **REUSE_CANDIDATE:** SMALL_ACCELERATOR — bounded diff is trivial; no library needed.

## Reuse ledger summary

| Mechanism | Classification | Notes |
|---|---|---|
| M-01 Effect RPC over WebSocket | MODERATE_ACCELERATOR | Phoenix Channels |
| M-02 Connection Runtime | MAJOR_ACCELERATOR | OTP supervisor + Registry |
| M-03 OrchestrationEngine | DISTRACTION | DO NOT reimplement; extend Kiln Run/ledger |
| M-04 Provider Driver Registry | MAJOR_ACCELERATOR | Direct pattern reuse |
| M-05 Workspace Filesystem | NO_MEANINGFUL_SAVINGS | Bounded apply is the minimum |
| M-06 Git VCS Driver | SMALL_ACCELERATOR | Invoke `git` directly |
| M-07 Environment Auth | MAJOR_ACCELERATOR | Adopt scoped capability model |
| M-08 Terminal | NO_MEANINGFUL_SAVINGS | Elixir/OTP-native |
| M-09 Persistence | MODERATE_ACCELERATOR | Ecto + bounded migrations |
| M-10 SSH/Tailscale | MAJOR_ACCELERATOR | Adopt T3 packages as bounded deps |
| M-11 Streaming | MAJOR_ACCELERATOR | Phoenix Channels |
| M-12 Desktop Backend | SMALL_ACCELERATOR | Electron shell; Elixir daemon |
| M-13 Workspace Model | MODERATE_ACCELERATOR | M0 contract shapes |
| M-14 Activity Timeline | MAJOR_ACCELERATOR | Phoenix LiveView |
| M-15 Workspace Diff | SMALL_ACCELERATOR | Sha256-based diff |

**Downstream work unlocked:** Every September P0 capability can be implemented by reusing 1+ of these mechanisms. **Major accelerators** eliminate weeks of architecture work; the absence of M-03 means we do NOT need a new event-sourcing layer (Kiln's existing bounded Run/ledger suffices).

**Acceleration total estimate:**
- Major accelerators save ~3-5 weeks of architecture work (reusing established patterns instead of inventing)
- Moderate accelerators save ~1-2 weeks (direct Elixir/OTP-native equivalents)
- Small accelerators save ~3-5 days (no custom machinery)
- M-03 discipline (NOT reimplementing) saves ~1-2 weeks (would have been a major rabbit hole)

**Net Pathfinder Week-2 cost reduction:** substantial. Without this archaeology, Week 2 implementation would have re-discovered the same architecture (and likely invented a worse event-sourcing layer).
