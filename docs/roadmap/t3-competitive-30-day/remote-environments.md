# Pathfinder WP-05 — Remote Environment Fast Path Decision

**Question:** What is the cheapest secure route for MacBook Air / Temper → MacBook Pro / Invariant daemon?

## Decision (Pathfinder conclusion)

**Priority order for September scope:**
1. **localhost first** — Temper and Invariant daemon on the same machine (development)
2. **SSH port-forwarding** — `ssh -L` for cross-machine (MacBook Air → MacBook Pro)
3. **Tailscale/private endpoint** — for multi-machine scenarios beyond SSH

**Do NOT invent hosted relay architecture** for September scope.

## Mechanism card

### QUESTION
Cheapest secure route for MacBook Air / Temper → MacBook Pro / Invariant daemon.

### CURRENT INVARIANT FACTS
- No daemon exists yet (WP-07 implements this)
- No remote transport exists yet
- Kiln bounded contracts exist; bounded apply proven
- Temper CLI is local-only

### REFERENCE IMPLEMENTATIONS
- T3 packages/ssh: SSH config parsing, tunnel/environment manager
- T3 packages/tailscale: Tailscale CLI wrapper, ensureTailscaleServe lifecycle
- T3 docs/internals/remote.md: direct/bearer/relay/Tailscale/SSH access methods

### MECHANISM
- **Localhost:** daemon at `http://localhost:<port>`; Temper connects directly
- **SSH port-forwarding:** `ssh -L localhost:<remote_port>:localhost:<remote_port> user@host`; Temper connects to local forward
- **Tailscale:** Tailscale Serve exposes daemon over Tailscale network; pairing via Tailscale identity

### STATE OWNER
- Local daemon: Kiln daemon owns authoritative execution truth
- Remote daemon: same Kiln daemon, accessed over bounded network path
- Token auth: bounded by pairing grant; revocable

### CONTRACT
- Localhost: bounded by Kiln bearer token (per-environment)
- SSH: SSH connection identity + Kiln token (bounded by SSH)
- Tailscale: Tailscale node identity + Kiln token

### FAILURE MODES
- SSH connection drop → bounded reconnect
- Tailscale node offline → bounded failure with bounded retry
- Token compromise → bounded revocation
- Network failure → bounded recovery (E_MUTATION_UNKNOWN_EFFECT for uncertain effects)

### REUSE OPPORTUNITY
- T3 `packages/ssh/` (MIT) → bounded deps adoption with attribution
- T3 `packages/tailscale/` (MIT) → bounded deps adoption with attribution
- Existing `packages/arsenal/scripts/local_cloud_router.md` workflow

### OTP / ELIXIR LEVERAGE
- `System.cmd("ssh", ...)` for SSH launch
- `System.cmd("tailscale", ...)` for Tailscale operations
- No custom transport needed

### WHAT WE DO NOT NEED TO BUILD
- Hosted relay
- Custom SSH client (use `ssh` CLI)
- Custom Tailscale client (use `tailscale` CLI)
- Custom NAT traversal
- Custom firewall rules

### RECOMMENDED INVARIANT DESIGN
- **Localhost:** `mix invariant serve` → daemon at `http://localhost:4000`; Temper connects via `http://localhost:4000`
- **SSH:** `mix invariant serve --bind 0.0.0.0:4000` on MacBook Pro; `ssh -L 4000:localhost:4000 user@macbook-pro` from MacBook Air; Temper connects to `http://localhost:4000`
- **Tailscale:** `tailscale serve` on MacBook Pro exposes daemon over Tailscale network; Temper connects via Tailscale hostname
- **Bounded auth:** one-time pairing for remote; bearer for localhost; scoped tokens
- **Bounded reconnect:** client reconnects with token; server restores bounded state

### CONFIDENCE
VERY HIGH — SSH + Tailscale are established, well-documented mechanisms. Direct CLI invocation eliminates custom transport machinery.

### UNRESOLVED QUESTIONS
1. Tailscale account requirement for MacBook Pro — defer; user has existing or can create
2. SSH key management — use existing OS keychain
3. Multi-user Tailscale — defer; single-user sufficient for September

### DOWNSTREAM WORK UNLOCKED
- WP-11 (Remote environment transport) becomes immediately implementable; bounded = SSH CLI + Tailscale CLI

### ACCEPTANCE PROPERTY
MacBook Air / Temper connects to MacBook Pro / Invariant daemon over bounded SSH port-forwarding or Tailscale, observes bounded task end-to-end, and recovers from disconnect/reconnect without losing bounded state.

### PROVING SCENARIO
1. Start Kiln daemon on MacBook Pro bound to 0.0.0.0:4000
2. SSH port-forward from MacBook Air: `ssh -L 4000:localhost:4000 user@macbook-pro`
3. Temper connects to `http://localhost:4000`
4. Run bounded task end-to-end
5. Disconnect SSH; reconnect
6. Verify bounded state preserved
