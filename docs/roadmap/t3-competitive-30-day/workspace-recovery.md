# Pathfinder WP-04 — Workspace / Git / Recovery Decision

**Question:** How does Kiln's existing bounded model interact with workspace, Git, and recovery — and do we need anything new?

## Decision (Pathfinder conclusion)

**Use Kiln's existing bounded model; do NOT introduce a second source of repository truth.**

Kiln already provides:
- Bounded apply with EXACT_TARGET_STATE_OBSERVED
- Preimage-mismatch fail-closed (E_PATCH_PREIMAGE_MISMATCH)
- Bounded completion bytes (canonical)
- Authoritative observable state (post-state sha256)

This satisfies the recovery invariants:
- Never blind-replay (fail-closed on stale base)
- E_MUTATION_UNKNOWN_EFFECT for uncertain effect (NEW bounded error class needed for cross-restart uncertainty)
- Session state persists across restarts (NEW Session machinery, built on bounded artifacts)

## Mechanism card

### QUESTION
Smallest model for workspace/Git/recovery that does NOT introduce a second source of repository truth.

### CURRENT INVARIANT FACTS
- Kiln bounded apply: `Kiln.PatchService.apply/3` enforces preimage check + fail-closed on mismatch
- Kiln produces `M0PatchEvidence` with `effect: "EXACT_TARGET_STATE_OBSERVED"` + `pre_state_digest` + `post_state_digest`
- Kiln's `WorkerOutputStore` (per M12-C artifact model) stores raw completion bytes
- `Kiln.PatchProposal.build/5` produces `M0PatchProposal` with bounded digest
- `M11_CLOSEOUT_FINAL_SHA = 392f790` already accepted a bounded mutation end-to-end
- M12-A composed golden path runs end-to-end with deterministic fixtures

### REFERENCE IMPLEMENTATIONS
- T3: CheckpointReactor + VCS driver registry + GitVcsDriver + VcsProcess
- T3: hidden-ref checkpoint model (separate from main repo state)

### MECHANISM
- **Workspace model:** project + session bounded artifacts (M12-C). Project is identified by stable projectId (UUID); Session is bounded by sessionId + bounded artifact set.
- **Git awareness:** use `git` CLI directly via `System.cmd("git", ...)`. No custom VCS abstraction needed for September scope.
- **Recovery semantics:** authoritative observable state reconciliation. On restart:
  1. Read Session artifacts from store
  2. Compare pre-state digests with actual disk sha256
  3. Classify: same → resume; different → E_MUTATION_UNKNOWN_EFFECT → operator reconcile
  4. NEVER blind-replay

### STATE OWNER
- Server (Kiln daemon): authoritative bounded state (Session artifacts + post-state digests)
- Git: existing repository; Kiln does NOT own git internals — uses `git` CLI for operations
- Filesystem: actual file content is authoritative observable state

### CONTRACT
- Existing M0 contracts (work-envelope.v0, run-result-envelope.v0, etc.)
- New: `session-state.v0` (bounded Session artifact schema with projectId + sessionId + bounded artifact refs)
- New: `recovery-classification.v0` (bounded error envelope: same_pre | stale_pre | effect_unknown | replay_rejected)

### FAILURE MODES
- Stale base: bounded apply fails closed (E_PATCH_PREIMAGE_MISMATCH) ✓
- Process die mid-mutation: bounded Session state has pre + proposed; reconcile on restart
- Verification interrupted: bounded Session state has post + applied; resume verification
- Missing/corrupt artifact: bounded Session state fails closed; bounded recovery flow
- Operator reconnect: bounded state restored from Session artifacts
- Stale base across restart: E_MUTATION_UNKNOWN_EFFECT (NEW bounded error class)
- Duplicate command: bounded command receipt (idempotent retry) per M12-C artifact model

### REUSE OPPORTUNITY
- Kiln's bounded apply + EXACT_TARGET_STATE_OBSERVED is the foundation
- M12-C bounded artifact model is the Session machinery
- M12-B recovery tests (2/4 PROVEN) prove fail-closed preimage

### OTP / ELIXIR LEVERAGE
- `System.cmd("git", ...)` for git operations (no custom VCS abstraction)
- Ecto for Session artifact persistence (M12-C follow-up)
- GenServer + bounded state machines for Session lifecycle

### WHAT WE DO NOT NEED TO BUILD
- Custom VCS driver registry (T3's pattern)
- Hidden-ref checkpoint model (T3's pattern) — Kiln's preimage check is the bounded equivalent
- Custom branch/worktree abstraction (use `git` CLI)
- Custom recovery engine (use existing bounded apply fail-closed)

### RECOMMENDED INVARIANT DESIGN
- **Session persistence:** Ecto + bounded migrations; Session artifacts persisted at canonical paths
- **Recovery classification:** bounded error envelope; operator reconcile flow when E_MUTATION_UNKNOWN_EFFECT fires
- **Git integration:** direct `git` CLI; no custom abstraction; bounded commands only (`status`, `diff`, `apply`, `log`, `worktree`, `checkout`)
- **Branch/worktree awareness:** use existing `git worktree` (no custom model); bounded commands per worktree
- **Workspace model:** project identified by UUID; session bounded by SessionId; bounded artifacts persisted per session

### CONFIDENCE
HIGH — Kiln already has the core invariants (bounded apply + EXACT_TARGET_STATE_OBSERVED + preimage fail-closed). Adding Session persistence + Ecto + bounded recovery classification is the minimum extension.

### UNRESOLVED QUESTIONS
1. Ecto schema for Session persistence (defer to M12-C runtime follow-up)
2. Hidden-ref checkpoint model (T3-style) — defer; not needed for September scope
3. Cross-host worktree coordination — defer; single-host for September

### DOWNSTREAM WORK UNLOCKED
- WP-08 (Persistent Session state) becomes immediately implementable
- WP-11 (Remote environment transport) — recovery applies across remote disconnect
- WP-12 (Parent/child coordination) — bounded Session can be child-scoped

### ACCEPTANCE PROPERTY
A bounded task survives daemon restart, client disconnect, network failure, and operator reconnect. Recovery never blind-replays; E_MUTATION_UNKNOWN_EFFECT is the bounded error class for uncertain effect.

### PROVING SCENARIO
1. Start bounded task; observe state
2. Kill daemon mid-mutation → restart daemon → bounded Session restored; bounded apply resumes from authoritative observable state
3. Operator kills daemon after mutation but before verification → restart → verification resumes
4. Modify target file out-of-band between sessions → next apply fails closed (E_PATCH_PREIMAGE_MISMATCH)
5. Operator reconnects from new client → bounded state restored; no blind replay
