# Pathfinder WP-02 — Invariant Service Boundary Decision

**Question:** What is the smallest legitimate boundary supporting Temper → local Kiln daemon and Temper → remote Kiln daemon?

**Current state:** Kiln is CLI-only (`mix kiln ...`). No daemon. No client/server RPC.

## Decision (Pathfinder conclusion)

**Service boundary:** Kiln daemon at `http://localhost:<port>` (local) or `https://<host>:<port>` (remote) with WebSocket upgrade at `/ws` for streaming. Phoenix Channels for per-channel topics (e.g., `project:<id>`, `thread:<id>`). HTTP for bounded unary operations.

**Reused from T3 (M-01):** Effect RPC over WebSocket pattern. Adapted to Phoenix Channels.

**Elixir/OTP leverage:** Phoenix + Plug + WebSocket handler. Existing Kiln bounded contracts become the RPC payload schemas.

## Mechanism card (per Section 10 template)

### QUESTION
Smallest legitimate boundary supporting Temper → local Kiln daemon + Temper → remote Kiln daemon.

### CURRENT INVARIANT FACTS
- Kiln CLI exposes `mix kiln worker-propose`, `patch-apply-governed`, `verify-run`, `review-propose`, `human-decide` (per `lib/kiln/cli.ex`).
- All bounded contracts exist (M0 schemas under `contracts/m0/schemas/`).
- No persistent Session machinery; no client/server RPC; no daemon lifecycle.
- Temper CLI is read-only render of bounded state.

### REFERENCE IMPLEMENTATIONS
- T3 server (M-01): Effect RPC over WebSocket at `/ws`, per-method scope, streaming members.
- Phoenix Channels: topic-per-entity streams; per-channel authorization; binary + JSON payloads.
- Plug + WebSocket + token auth: canonical Elixir pattern.

### MECHANISM
- HTTP at `localhost:<port>` for bounded unary operations (open project, approve bytes, etc.)
- WebSocket at `/ws` for bounded streams (activity, terminal, thread events)
- Per-method scope (mapped from T3's scope table)
- Token auth (one-time pairing for remote; bearer for local)
- Phoenix Channels for per-entity topics

### STATE OWNER
- Server: Kiln daemon owns authoritative execution truth (bounded apply, bounded evidence, bounded recovery)
- Client: Temper consumes bounded state; UI never owns authority

### CONTRACT
- Existing M0 contracts (work-envelope.v0, run-result-envelope.v0, qualified-method-record.v0, learning-observation.v0)
- New: `rpc-method.v0` (Effect RPC-like schema in Elixir, defining unary vs stream members + per-method scope)
- Auth scope: `orchestration:read | orchestration:operate | terminal:operate | review:write | access:read | access:write` (adapted from T3's scope table)

### FAILURE MODES
- Client disconnect → bounded session state preserved; reconnect restores canonical state
- Daemon restart → bounded Session machinery persists; bounded replay is impossible
- Token compromise → revocation; scopes can be downgraded
- Network failure (remote) → bounded retry; never blind replay; bounded UI

### REUSE OPPORTUNITY
- T3's `WS_METHODS` + `RpcServer.toHttpEffectWebsocket` pattern (adapt to Phoenix Channels)
- T3's scope table (direct adoption)
- T3's `ConnectionDriver` / `EnvironmentSupervisor` pattern (adapt to OTP DynamicSupervisor)
- T3's per-channel authorization (adapt to Phoenix.Channel interceptors)

### OTP / ELIXIR LEVERAGE
- Phoenix.Channel as the canonical Elixir streaming primitive
- OTP DynamicSupervisor + Registry for connection lifecycle
- Plug + WebSocket + token auth (no custom transport)
- Jason for bounded JSON payloads (already a dep in M0)

### WHAT WE DO NOT NEED TO BUILD
- Custom transport protocol (HTTP+WS+JSON is the minimum)
- Custom connection supervisor (OTP DynamicSupervisor is canonical)
- Custom streaming primitive (Phoenix Channels is canonical)
- General OAuth provider (scoped bearer tokens are sufficient)
- Custom retry loop (OTP supervisor restart strategies cover this)

### RECOMMENDED INVARIANT DESIGN
- **Daemon:** Elixir release `invariant serve` (Mix release) running `Kiln.Service` (Plug + WebSocket + Channel router)
- **CLI replacement:** `mix kiln` becomes a thin HTTP/WS client (calls the daemon); keep CLI for scripting + CI
- **RPC contract:** bounded by M0 schemas; per-method scope; `RPC_REQUIRED_SCOPE` mapping
- **Auth:** one-time pairing for remote (T3-style `PairingGrantStore`), bearer for local; scoped permissions; DPoP deferred
- **State ownership:** server owns authoritative bounded state; client is read-only projection + bounded action surface
- **Reconnect:** bounded session token; client reconnects with token; server restores canonical state from authoritative observable state

### CONFIDENCE
HIGH — Phoenix Channels + OTP supervisor + Plug WebSocket + existing M0 contracts = canonical Elixir pattern. Direct reuse of T3's scope table. No novel architecture.

### UNRESOLVED QUESTIONS
1. DPoP for remote auth — defer (bearer + TLS is sufficient for September)
2. Multi-region / multi-server — defer (single-server is sufficient for September; multi-region is secondary)
3. Streaming protocol version negotiation — defer to Elixir version negotiation patterns

### DOWNSTREAM WORK UNLOCKED
- WP-07 (Kiln daemon implementation) becomes immediately implementable
- WP-09 (Temper RPC client) becomes immediately implementable
- WP-10 (Provider-runtime adapter) becomes immediately implementable
- WP-11 (Remote environment transport) becomes immediately implementable

### ACCEPTANCE PROPERTY
A Temper client can connect to a Kiln daemon over HTTP+WS, open a project, start a bounded task, observe activity stream, and disconnect/reconnect without losing bounded state.

### PROVING SCENARIO
1. Start local Kiln daemon (`mix invariant serve`)
2. Open Temper client against local daemon
3. Open a project; start a bounded task; observe activity
4. Disconnect Temper; kill daemon
5. Restart daemon; reconnect Temper; observe state restored
6. Repeat with remote daemon (MacBook Pro); Temper on MacBook Air
