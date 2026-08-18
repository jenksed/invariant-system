# Pathfinder WP-03 — Provider-Runtime Contract Decision

**Question:** What is the minimum common contract + capability negotiation for direct model providers (MiniMax-M3) AND agent runtimes (Claude Code / Codex / OpenCode)?

## Decision (Pathfinder conclusion)

**Two distinct provider classes, each with its own bounded contract.** Do NOT force all providers into a lowest-common-denominator abstraction.

- **Direct intelligence provider** (MiniMax-M3 PROVEN): bounded HTTP request/response via `Kiln.MinimaxM3Adapter`. Capabilities: structured tool calls, bounded receive_timeout, bounded response size.
- **Agent-runtime provider** (Claude Code / Codex / OpenCode — PROTOTYPE needed): bounded adapter invokes the external agent CLI; bounded result is a canonical envelope the same as direct providers.

Common contract: both produce a canonical `engineering-system/implementer-patch-proposal-input/v1` envelope via `kiln_emit_candidate_envelope` function call. The adapter translates each provider's native representation to the canonical envelope.

## Mechanism card

### QUESTION
Minimum common contract + capability negotiation for direct model providers + agent runtimes.

### CURRENT INVARIANT FACTS
- Kiln.MinimaxM3Adapter PROVEN for MiniMax-M3 (M11-E4)
- Kiln.Manifold bounded intelligence selection PROVEN
- No agent-runtime adapter exists
- `kiln_emit_candidate_envelope` function call schema PROVEN (M12-A)

### REFERENCE IMPLEMENTATIONS
- T3 driver registry (`apps/server/src/provider/builtInDrivers.ts`): 5 built-in drivers with capability schemas
- T3 `ProviderAdapter` interface + per-driver adapters in `Layers/`
- T3 `ProviderInstanceRegistry` (config registry) + `ProviderAdapterRegistry` (live adapter registry)

### MECHANISM
- **Direct provider adapter** (Kiln.MinimaxM3Adapter — template): bounded HTTP + native structured output + adapter-private representation translation (M12-C provider-private rep)
- **Agent-runtime provider adapter** (Kiln.ClaudeCodeAdapter — NEW): bounded invocation of external agent CLI (claude/codex/opencode CLI); agent returns bounded output; adapter translates to canonical envelope
- **Common contract:** bounded capability schema (`provider_capability.v0`); per-provider negotiation of session ownership, streaming, resume, cancel, approvals
- **Provider driver registry:** Elixir behaviour + Registry; bounded by M0 contract shapes

### STATE OWNER
- Per-provider bounded adapter owns its own translation + content-validity gate
- Provider driver registry owns the dispatch lookup
- Capability negotiation is owned by the adapter; bounded by M0 schemas

### CONTRACT
- `engineering-system/provider-capability/v0` (NEW bounded schema):
  - `kind` ∈ `{direct_model, agent_runtime}`
  - `supports_streaming`: boolean
  - `supports_resume`: boolean
  - `requires_approval`: boolean
  - `canonical_envelope_schema`: `engineering-system/implementer-patch-proposal-input/v1`
- Existing M0 contracts unchanged
- New per-provider schema: `engineering-system/provider-instance-config/v0`

### FAILURE MODES
- Provider denial: bounded dispatch fails closed (E_PROVIDER_DENIED)
- Malformed output: bounded `decode_provider_response_wrapper` rejects; bounded `E_MALFORMED_OUTPUT`
- Process death: bounded DynamicSupervisor restart; bounded retry (per provider contract)
- Network failure: bounded reconnect; bounded retry budget
- Capability mismatch: bounded `E_CAPABILITY_NOT_NEGOTIATED`

### REUSE OPPORTUNITY
- T3 driver registry pattern (config registry + adapter registry) — direct reuse
- T3 capability schema pattern — direct reuse (map to bounded M0 contract)
- Kiln.MinimaxM3Adapter as template for new adapters — copy pattern, do not copy code

### OTP / ELIXIR LEVERAGE
- Elixir behaviour for provider contracts
- Registry for dispatch lookup
- DynamicSupervisor for provider lifecycle
- System.cmd for external agent CLI invocation (no custom machinery)

### WHAT WE DO NOT NEED TO BUILD
- Custom protocol abstraction (HTTP+JSON for direct; subprocess+JSON for agent-runtime)
- Custom capability negotiation (Elixir behaviour is sufficient)
- Custom provider lifecycle (DynamicSupervisor is canonical)

### RECOMMENDED INVARIANT DESIGN
- **Direct provider:** MiniMax-M3 adapter (PROVEN); bounded HTTP via Finch
- **Agent-runtime provider:** Claude Code adapter (PROTOTYPE in Week 2; bounded subprocess via System.cmd; bounded output extraction)
- **Provider driver registry:** Elixir behaviour + Registry; bounded by M0 contracts
- **Capability negotiation:** bounded by `provider-capability.v0` schema; bounded per-provider config
- **Minimum two providers:** MiniMax-M3 (direct, PROVEN) + Claude Code (agent-runtime, PROTOTYPE) — sufficient for September P0

### CONFIDENCE
HIGH — two distinct provider classes with bounded common contract is a clean architecture; T3's driver registry pattern is direct reuse.

### UNRESOLVED QUESTIONS
1. Approval/input handling for agent-runtime providers (defer to bounded prototype)
2. Session ownership across providers (defer; bounded per provider)
3. Provider configuration UI (defer; bounded config in code is sufficient for September)

### DOWNSTREAM WORK UNLOCKED
- WP-10 (Provider-runtime adapter) becomes immediately implementable; bounded template = MiniMaxM3Adapter
- WP-09 (Temper RPC client) becomes immediately implementable; bounded provider list available
- WP-12 (Parent/child coordination) — child tasks can use either provider class

### ACCEPTANCE PROPERTY
The bounded M12-A composed golden path runs end-to-end with both the direct provider (MiniMax-M3) AND the agent-runtime provider (Claude Code), proving both provider classes are first-class bounded citizens.

### PROVING SCENARIO
1. Bounded golden path runs with MiniMax-M3 (PROVEN; re-run with current SHA)
2. Bounded golden path runs with Claude Code adapter (NEW; bounded subprocess + output extraction)
3. Provider driver registry dispatches both adapters correctly
4. Provider failure modes (denial, malformed, death) handled by bounded adapter
