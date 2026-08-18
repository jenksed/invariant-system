# Invariant 30-Day T3-Competitive Pathfinder

**Branch:** `roadmap/t3-competitive-pathfinder`
**Base:** `aec49aed9320ee6fc1a634b5124e361e551a9564` (M12-A composed golden path)
**Target:** September 18, 2026 — strongest defensible T3 Code-competitive operator environment
**Strategy:** Pathfinder-front-loaded (Days 1–4 = uncertainty compression, not implementation)

## A. Repository baseline (FROZEN)

```
PATHFINDER_BASE_SHA = aec49aed9320ee6fc1a634b5124e361e551a9564
branch           = roadmap/t3-competitive-pathfinder
worktree         = /Users/jenksed/Developer/invariant-system-worktrees/t3-pathfinder
dirty state      = clean (fresh worktree from clean base)
remote           = git@github.com:jenksed/invariant-system.git

M11 / M12 lane SHAs (already on remote, NOT on GitHub main yet):
  m11-closeout-final      392f790
  m12-a-ci                aec49ae  (PATHFINDER_BASE)
  m12-b-recovery          66a3bc0
  m12-c-artifact          c07f6e6
  m12-d-temper            b3c796e
  m12-e-provider-qual     7d3f67e

Ancestry: 4587baa (recorded auth base) → 8fa7b4d (E4_REPAIR) →
            09cd4f9d (E4_TIMEOUT_REPAIR) → 3315f66 (test) →
            ec76f31 (E4_REPRESENTATION_REPAIR) → 392f790 (M11_CLOSEOUT) →
            aec49ae (M12-A) / 66a3bc0..7d3f67e (M12 B-E lanes)

GitHub main HEAD = 27e0e5e (KILN-M0-03 follow-up; BEFORE M7-M11/M12 work).
Recent local M7-M11/M12 work is NOT yet merged to main.
```

## B. Current-state reconciliation (what actually exists)

```
PROVEN_CURRENT (M0-M11/M12 deterministic + live evidence):
  Kiln bounded execution:
    - provider network dispatch (MiniMax-M3 via Finch.stream_while/5)
    - bounded completion (worker_output, after_image_lines + final_newline
      provider-private representation; canonical after_image_bytes translation)
    - patch-apply-governed (EXACT_TARGET_STATE_OBSERVED; fail-closed preimage
      mismatch; bounded receive_timeout + bounded response size)
    - bounded verification (registered verifier; PASS/FAIL/TIMEOUT/ERROR)
    - bounded review (independent reviewer_assignment_ref, digest-distinct from
      implementer; implementer_transcript_received=false)
    - bounded HumanDecision (ACCEPT/REJECT/REQUEST_REVISION)
    - bounded RunResultProjection (truth: completed/PASS/APPROVE/ACCEPT)
  Manifold bounded intelligence selection (selection != authority):
    - canonical FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST
    - implementer + reviewer + child-task assignment
  Loadout bounded capability surface:
    - implement-change Plan v2 + M0 Execution Binding
    - verify-change + repository-recon
    - bounded agent asset workflows
  Temper operator surface:
    - Node.js CLI (`temper [repository] [--snapshot]`)
    - bounded render of RunResultProjection into operator view
  Arsenal observation + methods (agent workflows + qualification)
  Bench M0 role qualification (campaign + evidence)
  Deterministic bounded surface: 97/97 PASS at M12-A golden path
  Composed golden path: 1/1 PASS at M12-A (full chain with deterministic
    bounded input → Worker → PatchProposal → APPROVE_EXACT_BYTES →
    EXACT_TARGET_STATE_OBSERVED → VR PASS → Manifold Review →
    HumanDecision ACCEPT → RunResultProjection)

PROVEN_AT_OLDER_SHA:
  M0 milestones (M6 BENCH, M7 MANIFOLD, M8 KILN-02, M9 KILN-03, M10 TEMPER,
  M11 SYS-03): merged to GitHub main; M0 contracts are stable.

IMPLEMENTED_UNPROVEN / PARTIAL:
  Temper persistent operator state (currently CLI-snapshot only; no
    long-lived client/server RPC)
  Remote client/server boundary (no authenticated RPC layer; Kiln CLI is
    the only public surface)
  Daemon/service lifecycle (no `invariant serve`; CLI is dev-only)
  Workspace/recovery runtime state (deterministic per-test; no Session
    machinery persisted across process restarts)
  Parent/child agent lifecycle (bounded dispatch exists; persistent
    parent/child coordination not implemented)
  Provider-runtime adapter (only MiniMax-M3 is exercised end-to-end; other
    providers are contract-only)
```

## C. Claims overturned (old docs no longer current)

```
OVERTAKEN by M11/M12 local work:
  "M7-M11 work in progress / roadmap" — actually M7-M11+dogfood are
    PROVEN via LANE-EVIDENCE-* and the M12-A composed golden path.
  "provider adapter is bounded-dispatch only" — also bounded-representation
    + bounded content-validity gate (M12 lane at ec76f31).
  "bounded execution needs live provider for default CI" — disproven: the
    M12-A composed golden path runs with deterministic bounded input, no
    live provider.

NOT OVERTAKEN:
  All roadmap documents dated pre-M11-M12 (e.g. Arsenal product_strategy/)
  remain valid for the M0 contract surface they describe.
  contracts/*.v0.md remain canonical.
```

## D. Proven capability inventory

| Capability | Owner | SHA | Test | Runtime proof |
|---|---|---|---|---|
| Provider dispatch (MiniMax-M3) | Kiln.MinimaxM3Adapter | ec76f31 | m11_e4_finch_timeout_test.exs (5) + m11_e4_provider_representation_test.exs (20) | M11-E4 live call (canonical-Finch dispatched, bounded completion 4734 bytes) |
| Bounded completion | Kiln.MinimaxM3Adapter (representation-repair) | ec76f31 | m11_e4_provider_representation_test.exs (20) | M11-E4 bounded completion translated + content-validated |
| PatchProposal | Kiln.PatchProposal.build/5 | ec76f31 (deterministic test); live M11-E4 | m12_e1_composed_golden_path_test.exs (1) | M11-E4 bounded PatchProposal + apply |
| Bounded apply (EXACT_TARGET_STATE_OBSERVED) | Kiln.PatchService.apply/3 | ec76f31 | m11_e4_provider_canonical_chain_test.exs (5); m12_e1 | M11-E4 live apply succeeded; 97/97 deterministic |
| Preimage-mismatch fail-closed | Kiln.PatchService | ec76f31 | m11_e2_approval_transfer_test.exs; m12_b_recovery_test.exs | proven across multiple M0-M11 milestones |
| Verification (bounded canonical) | Kiln.VerificationResult.build/6 | ec76f31 | m9_verification_review_acceptance_test.exs; m12_e1 | composed golden path PASS |
| Review (bounded canonical, reviewer-independent) | Kiln.Review.build/9 | ec76f31 | m9_verification_review_acceptance_test.exs; m12_e1 | composed golden path APPROVE |
| HumanDecision (bounded canonical) | Kiln.HumanDecision.build/5 | ec76f31 | m9_verification_review_acceptance_test.exs; m12_e1 | composed golden path ACCEPT |
| RunResultProjection (bounded canonical) | Kiln.RunResultProjection.build/10 | ec76f31 | m9_verification_review_acceptance_test.exs; m12_e1; m12_c | composed golden path truth = completed/PASS/APPROVE/ACCEPT |
| Manifold intelligence selection (bounded) | products/manifold/src/selector.py | (run-time digest from materialization) | m11_e4 fixtures; M11-E4 live | review/proposer distinct selection |
| Temper operator projection | products/temper/src/render.ts | (HEAD = main) | snapshot-only CLI | M12-E1 composed golden path → tempered snapshot produced |

## E. Evidence-debt ledger

```
TESTED_BUT_NOT_RUNTIME_PROVEN:
  - m12_e1_composed_golden_path_test.exs (deterministic fixture; not exercised
    through Temper→Kiln client/server RPC — because no such RPC exists)
  - m12_b_recovery_test.exs (2/4 sub-properties PROVEN; 2/4 have test
    setup path issues — not bounded machinery bugs)
  - m11_e4_finch_loopback_test.exs (loopback fixture; live MiniMax
    dispatch proven separately)

IMPLEMENTED_BUT_NOT_TESTED:
  - PatchService.apply_with_completion_ref/4 (separate path from
    apply/3; not exercised in M12-A)
  - WorkerOutputStore (artifact storage path; no Session machinery
    exercised end-to-end)
  - M0ContractPacket frozen schemas (26 positive + 13 of 14 negative;
    `stale-qualification.json` reserved for SYS-M0-03)

PROVEN_AGAINST_FIXTURE_ONLY (not real provider):
  - Manifold implementer/reviewer selection (fixture-based qualification
    evidence; live provider qualification is Lane E's deferred Bench run)

WEAK_PROVEN:
  - bounded timeout semantics under adversarial network conditions
    (loopback tests cover timeout + oversize + no-retry; live MiniMax
    had 1 transient timeout incident (Call 3) which the bounded
    contract repaired via E4_TIMEOUT_REPAIR)
```

## F. T3 competitive matrix (P0 only)

| T3 capability | Invariant today | Sept requirement | Gap | Priority | T3 reference |
|---|---|---|---|---|---|
| project registry | partial (loadout plans reference projects) | durable registry | bounded storage + identity | P0 | apps/server/src/orchestration/ |
| local repo open | partial (loadout.repository-recon) | bounded open + read | bounded apply path | P0 | apps/server/src/vcs/ |
| connect remote env | NOT IMPLEMENTED | authenticated RPC | full service boundary | P0 | apps/server/, apps/desktop/, packages/ssh/, packages/tailscale/ |
| headless daemon | NOT IMPLEMENTED | `invariant serve` lifecycle | full daemon | P0 | (T3 background service via Tauri + server) |
| start governed task | PROVEN (Kiln CLI: kiln worker-propose) | bound to RPC surface | RPC wrapper | P0 | apps/server/src/orchestration/ |
| resume task after reconnect | NOT IMPLEMENTED | persistent session state | bounded Session machinery | P0 | packages/client-runtime/ |
| ≥2 useful providers | partial (MiniMax-M3 proven; MiniMax + future) | at least one direct + one agent-runtime | provider-runtime contract | P0 | apps/server/src/provider/ |
| stream agent activity | NOT IMPLEMENTED | bounded streaming RPC | streaming channel choice | P0 | apps/server/src/orchestration/ |
| interrupt/cancel safely | bounded (cancellation exists in bounded machinery) | client-visible interrupt | RPC plumbing | P0 | apps/server/src/orchestration/ |
| parent/child task visibility | partial (bounded dispatch) | persistent coordination | parent/child machinery | P0 | apps/server/src/orchestration/ |
| Loadout plan integration | PROVEN (Loadout implement-change Plan v2) | bound to RPC surface | RPC wrapper | P0 | (server uses plan contracts) |
| Manifold selection | PROVEN (canonical implementer/reviewer) | bound to RPC surface | RPC wrapper | P0 | apps/server/src/orchestration/ |
| Kiln authority gate | PROVEN | persistent authority record | RPC wrapper | P0 | (server uses authority contracts) |
| exact proposal/mutation | PROVEN | persistent in RPC stream | streaming channel | P0 | apps/server/src/orchestration/ |
| Git/repo awareness | PROVEN (bounded apply) | bound to RPC surface | RPC wrapper | P0 | apps/server/src/vcs/ |
| diff display | bounded (Temper snapshot shows diffs) | bound to RPC surface | RPC + UX | P0 | apps/web/ (or packages/client/) |
| registered verification | PROVEN | bound to RPC surface | RPC wrapper | P0 | apps/server/src/orchestration/ |
| independent review | PROVEN | bound to RPC surface | RPC wrapper | P0 | apps/server/src/orchestration/ |
| explicit HumanDecision | PROVEN | bound to RPC surface | RPC wrapper | P0 | (server uses human-decision contracts) |
| evidence/provenance | PROVEN | bound to RPC surface | RPC wrapper | P0 | apps/server/src/orchestration/ |
| terminal access | partial (Temper CLI render, but no live terminal streaming) | bounded persistent terminal | streaming channel | P0 | apps/server/src/terminal/ |
| recovery/revert | PROVEN (bounded apply fail-closed) | persistent recovery | Session machinery | P0 | apps/server/src/vcs/ + CheckpointReactor |
| open repo in Zed | NOT IMPLEMENTED | `zed <path>` invocation | bounded call surface | P0 | (Zed CLI integration) |
| remote second-Mac | NOT IMPLEMENTED | SSH/Tailscale + bounded session | full remote path | P0 | packages/ssh/, packages/tailscale/ |
| dogfood Invariant | partial (M11-E4) | whole-system | whole-system path | P0 | (T3 dogfoods itself) |

## G. Target architecture

```
CLIENTS (Temper desktop / web / mobile)
       ↓ authenticated RPC over HTTP + WebSocket / Phoenix Channels
       (decision: HTTP+WS; Phoenix Channels; deferred to PF-02)
SERVER RUNTIME (Invariant daemon = Kiln + Loadout + Manifold + Arsenal + Bench)
       ↓ bounded provider/runtime adapters
       (decisions: provider contracts; deferred to PF-03)
PROVIDERS (MiniMax-M3 direct; Claude Code / Codex / OpenCode agent runtimes;
            future direct APIs)
```

Component ownership:
- Kiln owns authoritative execution/run/evidence/recovery
- Loadout owns request/context/plan compilation
- Manifold owns qualified intelligence selection (selection != authority)
- Arsenal owns capability/method/qualification/learning
- Bench owns qualification/evaluation evidence
- Temper owns operator/client surface and projection (UI != authority)

## H. September release definition (P0 acceptance)

| P0 | Property | Evidence required |
|---|---|---|
| 1 | Persistent project registry | bounded session: open→list→select; restart preserves registry |
| 2 | Open local repository | bounded session opens local repo; bounded apply path proven |
| 3 | Connect remote Invariant environment | authenticated RPC; bounded session; persistent identity |
| 4 | Headless server/daemon | `invariant serve` lifecycle; health; logs; crash recovery |
| 5 | Start governed task/session | bounded Worker dispatch via RPC |
| 6 | Resume task/session after reconnect | persistent Session state; bounded replay not blind |
| 7 | ≥2 useful providers | MiniMax-M3 (PROVEN) + ≥1 agent-runtime (PROTOTYPE) |
| 8 | Stream agent activity | bounded streaming RPC; canonical event semantics |
| 9 | Interrupt/cancel safely | bounded cancellation; client-visible interrupt |
| 10 | Parent/child task visibility | bounded coordination; persistent evidence |
| 11 | Loadout plan integration | Loadout plans in RPC surface |
| 12 | Manifold selection | bounded selection in RPC surface |
| 13 | Kiln authority gate | bounded authority in RPC surface |
| 14 | Exact proposal/mutation | persistent; bounded exact-byte approval |
| 15 | Git/repo awareness | bounded repo awareness in RPC |
| 16 | Diff display | bounded diff in Temper |
| 17 | Registered verification | bounded verification in RPC |
| 18 | Independent review | bounded review in RPC |
| 19 | Explicit HumanDecision | bounded HumanDecision in RPC |
| 20 | Evidence/provenance display | bounded evidence projection |
| 21 | Terminal access | bounded persistent terminal |
| 22 | Recovery/revert | bounded recovery from authoritative observable state |
| 23 | Open repo in Zed | bounded Zed CLI invocation |
| 24 | Remote second-Mac | SSH/Tailscale + bounded session |
| 25 | Dogfood Invariant | whole-system path used to develop Invariant |

## I. Critical path (after Pathfinder restructuring)

```
PATHFINDER DAYS 1-4 (uncertainty compression):
  PF-01 T3 architecture archaeology  ─┐
  PF-02 Invariant service boundary     │  parallel
  PF-03 Provider-runtime contract      │  (independent
  PF-06 OTP fast-track experiments     ─┘   files)
                                          │
                                          ▼
WEEK 1 (Days 3-9) local product spine:
  Kiln service boundary (Phoenix + OTP)
  Project + session persistence
  Provider-runtime adapter
  → one durable local project/session operable
                                          │
                                          ▼
WEEK 2 (Days 7-15) governed engineering workbench:
  Temper client → service RPC
  Activity streaming
  Bounded proposals / mutation / verification / review / HumanDecision
  Zed integration
  → real repository engineering task observable from Temper
                                          │
                                          ▼
WEEK 3 (Days 12-21) persistence / recovery / remote:
  Persistent Session state across restarts
  Reconnect
  SSH/Tailscale remote
  E_MUTATION_UNKNOWN_EFFECT handling
  → work survives client + survives across machines
                                          │
                                          ▼
WEEK 4 (Days 18-30) parent/child + whole-system dogfood:
  Parent/child bounded coordination
  Whole-system dogfood (develop Invariant through Invariant)
  Negative cases, restart, stale, recovery, remote
  Packaging (`invariant serve`)
  → September release candidate
```

Parallel candidates (do not consume Pathfinder decisions):
- Temper UI shell (until service boundary decided)
- T3 archaeology (PF-01 itself; one decision ahead)
- Provider-driver adapters (until provider-runtime decided)
- Remote transport prototype (until service boundary decided)
- Docs / evidence debt closure (always parallel-safe)
- Git/diff projection (already proven via Kiln apply)
- Zed integration (until daemon decided)
- Packaging experiments (until daemon decided)

## J. Parallel-safe production (Days 1-30)

```
PARALLEL-SAFE (do not consume Pathfinder decisions):
  - M12-D Temper operator surface contract (CLOSED; already committed)
  - M12-C artifact model (CLOSED; already committed)
  - M12-E provider qualification contract (CLOSED; already committed)
  - M12-B recovery test path fix (PARTIAL → PARTIAL+; bounded machinery correct)
  - Deterministic test additions that don't change bounded contracts

DEPENDENCY-SENSITIVE (block on Pathfinder outputs):
  - Kiln service boundary implementation (waits on PF-02)
  - Provider-runtime adapter (waits on PF-03)
  - Temper RPC client (waits on PF-02 + PF-03)
  - Persistent Session machinery (waits on PF-04)

BLOCKED (external):
  - None identified (no live external calls required for September core)

OPTIONAL (deferred unless cheap):
  - GitHub PR creation
  - Provider configuration UI
  - Tailscale-assisted setup UI
  - Background-service installation
  - Richer child-agent orchestration
  - Searchable historical runs
  - Cost/token/usage telemetry
  - Multiple worktrees
  - Repository cloning
```

## K. Critical-path first 2 weeks (work packages)

(WP-IDs are stable; full implementation-ready detail in work-packages/)

### WP-01 — T3 Architecture Archaeology (Pathfinder)
- **Owner:** Pathfinder (no production code)
- **Objective:** Pin T3 source SHA + map every useful mechanism to Invariant
- **Authoritative inputs:** GitHub pingdotgg/t3code at HEAD = (TO PIN); Invariant
  product structure at PATHFINDER_BASE_SHA = aec49ae
- **Pathfinder findings consumed:** none (this IS Pathfinder)
- **Dependencies:** none
- **Parallel-safety:** yes (read-only inspection)
- **Scope:** T3 server/desktop/web/mobile packages/contracts; identify exact
  source paths, behavior, mechanism cards
- **Non-goals:** copying source code wholesale; reproducing T3 visually;
  integrating T3 directly
- **Acceptance property:** every useful T3 mechanism has a REUSE_CANDIDATE
  record (MAJOR_ACCELERATOR | MODERATE | SMALL | NO_SAVINGS | DISTRACTION)
- **Output:** docs/roadmap/t3-competitive-30-day/t3-reference-map.md + reuse ledger

### WP-02 — Invariant Service Boundary (Pathfinder decision)
- **Owner:** Pathfinder → Kiln
- **Objective:** Decide smallest legitimate service boundary for Temper →
  local/remote Kiln runtime
- **Inputs:** T3 server architecture (WP-01); current Kiln CLI surfaces
- **Pathfinder findings consumed:** WP-01
- **Dependencies:** WP-01 (T3 source map)
- **Parallel-safety:** mostly yes (prototype Phoenix Channel locally first)
- **Scope:** HTTP vs WebSocket/Channels; identity (pairing vs provisioned);
  authorization scopes; reconnect semantics; idempotency
- **Acceptance property:** a Temper client can connect to a local Kiln
  daemon, open a project, start a bounded task, observe activity, and
  disconnect/reconnect without losing bounded state
- **Output:** docs/roadmap/t3-competitive-30-day/client-server-boundary.md

### WP-03 — Provider-Runtime Contract (Pathfinder decision)
- **Owner:** Pathfinder → Kiln
- **Objective:** Define minimum common provider contract + capability
  negotiation for MiniMax-M3 (direct) and Claude Code / Codex / OpenCode
  (agent-runtime)
- **Inputs:** current Kiln.MinimaxM3Adapter (PROVEN); T3 provider driver
  patterns (WP-01)
- **Pathfinder findings consumed:** WP-01
- **Dependencies:** WP-01
- **Parallel-safety:** yes (can prototype provider adapter against
  MiniMax without changing Kiln core)
- **Scope:** capability negotiation; session ownership; streaming; resume;
  cancel; approvals; input requests; failure handling
- **Acceptance property:** bounded provider-runtime contract with both
  MiniMax-M3 (direct) and ≥1 agent-runtime proven end-to-end via composed
  golden path
- **Output:** docs/roadmap/t3-competitive-30-day/provider-runtime-strategy.md

### WP-04 — Workspace / Git / Recovery (Pathfinder decision)
- **Owner:** Pathfinder → Kiln
- **Objective:** Decide smallest bounded model for workspace/Git/recovery
  that does NOT introduce a second source of repository truth
- **Inputs:** Kiln existing Run model (PROVEN); T3 checkpoint model (WP-01)
- **Pathfinder findings consumed:** WP-01
- **Dependencies:** WP-01 (T3 source map)
- **Parallel-safety:** mostly yes (decide before implementing)
- **Scope:** baseline / dirty state / diff / checkpoint / revert /
  stale-state detection / unknown-effect handling / restart reconciliation /
  branch/worktree awareness
- **Acceptance property:** recovery never blind-replays; E_MUTATION_UNKNOWN_EFFECT
  is the bounded error class for uncertain effect; bounded Session machinery
  persists across restarts
- **Output:** docs/roadmap/t3-competitive-30-day/workspace-recovery.md

### WP-05 — Remote Environment Fast Path (Pathfinder decision)
- **Owner:** Pathfinder → runtime
- **Objective:** Choose cheapest secure route for MacBook Air / Temper →
  MacBook Pro / Invariant daemon
- **Inputs:** T3 SSH + Tailscale patterns (WP-01); current M0 contracts
- **Pathfinder findings consumed:** WP-01, WP-02
- **Dependencies:** WP-02 (service boundary)
- **Parallel-safety:** yes (can prototype SSH/Tailscale locally)
- **Scope:** SSH launch; port forwarding; Tailscale/private endpoint;
  pairing / client identity; reconnect
- **Acceptance property:** Temper on one MacBook connects to Invariant
  daemon on another MacBook, observes bounded task, and recovers from
  disconnect/reconnect without losing bounded state
- **Output:** docs/roadmap/t3-competitive-30-day/remote-environments.md

### WP-06 — OTP Fast-Track Experiments (Pathfinder prototype)
- **Owner:** Pathfinder → Kiln (bounded prototypes, not production)
- **Objective:** Validate high-leverage OTP mechanisms for the service
- **Inputs:** current Kiln bounded machinery
- **Pathfinder findings consumed:** none (independent experiment)
- **Dependencies:** none
- **Parallel-safety:** yes (disposable prototypes)
- **Scope:** DynamicSupervisor for provider/agent runtimes; Registry for
  session/process ownership; Phoenix PubSub/Channels; bounded cancellation;
  reconnect behavior
- **Acceptance property:** each prototype answers ONE specific question
  (e.g., "does Registry survive restart?") with measurable evidence
- **Output:** docs/roadmap/t3-competitive-30-day/prototype-results.md

### WP-07 — Kiln Daemon / Service Boundary Implementation (Week 1, after Pathfinder)
- **Owner:** Kiln
- **Objective:** Implement the service boundary decided by WP-02
- **Inputs:** WP-02 contract
- **Dependencies:** WP-02
- **Parallel-safety:** no (sequential after WP-02)
- **Scope:** bounded Phoenix Channel / HTTP daemon; `invariant serve`
  lifecycle; identity + authorization; reconnect; bounded error envelope
- **Acceptance property:** the M12-A composed golden path runs end-to-end
  through the daemon (not just CLI); bounded Session persists across
  daemon restart
- **Output:** products/kiln/lib/kiln/service.ex; products/kiln/lib/kiln/daemon.ex;
  integration/scenarios/daemon/run.sh

### WP-08 — Persistent Session State (Week 2)
- **Owner:** Kiln
- **Objective:** Implement bounded Session machinery for project + session
  persistence
- **Inputs:** WP-04 model; M0 bounded contracts
- **Dependencies:** WP-04
- **Parallel-safety:** no (depends on WP-07 service boundary)
- **Scope:** Session id; project ref; persistence path; bounded replay;
  E_MUTATION_UNKNOWN_EFFECT handling; bounded cancellation
- **Acceptance property:** Session state survives daemon restart; bounded
  replay is impossible; reconnect restores canonical state from authoritative
  observable state
- **Output:** products/kiln/lib/kiln/session.ex; bounded tests

### WP-09 — Temper Client/Server RPC + Activity Stream (Week 2)
- **Owner:** Temper + Kiln
- **Objective:** Connect Temper to Kiln daemon over bounded RPC
- **Inputs:** WP-02 boundary; current Temper CLI render
- **Dependencies:** WP-07
- **Parallel-safety:** no (depends on WP-07)
- **Scope:** bounded RPC client; activity stream subscription; bounded
  proposal / mutation / verification / review / HumanDecision surfaces
- **Acceptance property:** a real repository engineering task is observable
  from Temper end-to-end (open repo → bounded plan → bounded dispatch →
  bounded apply → bounded verify → bounded review → bounded HumanDecision)
- **Output:** products/temper/src/client.ts; bounded RPC tests

### WP-10 — Provider-Runtime Adapter (Week 2, parallel to WP-09)
- **Owner:** Kiln
- **Objective:** Implement ≥1 agent-runtime provider adapter (Claude Code or
  Codex or OpenCode) per WP-03 contract
- **Inputs:** WP-03 contract; Kiln.MinimaxM3Adapter (template)
- **Dependencies:** WP-03
- **Parallel-safety:** yes (against MiniMax adapter doesn't need WP-07)
- **Scope:** provider-runtime adapter; capability negotiation; bounded
  completion extraction
- **Acceptance property:** bounded golden path runs with the agent-runtime
  provider end-to-end
- **Output:** products/kiln/lib/kiln/<agent_runtime>_adapter.ex; bounded tests

### WP-11 — Remote Environment Transport (Week 3)
- **Owner:** runtime
- **Objective:** Implement SSH/Tailscale remote transport per WP-05
- **Inputs:** WP-05 model
- **Dependencies:** WP-05, WP-07
- **Scope:** SSH launch; port forwarding; Tailscale endpoint; pairing;
  reconnect; scoped credentials
- **Acceptance property:** MacBook Air / Temper → MacBook Pro / Invariant
  daemon works end-to-end (full bounded task observable)
- **Output:** runtime transport modules; bounded integration test

### WP-12 — Parent/Child Coordination (Week 4)
- **Owner:** Kiln + Manifold
- **Objective:** Bounded parent/child coordination that preserves authority
  semantics
- **Inputs:** M0 bounded contracts; Manifold selection
- **Dependencies:** WP-07, WP-08
- **Scope:** child session ownership; bounded delegation; parent-visible
  child activity; bounded HumanDecision inheritance
- **Acceptance property:** parent can spawn child bounded work, observe
  child activity, and inherit bounded results without authority leakage
- **Output:** products/kiln/lib/kiln/parent_child.ex; bounded tests

### WP-13 — Whole-System Dogfood (Week 4)
- **Owner:** all products
- **Objective:** Use Invariant to materially develop Invariant
- **Inputs:** all prior WPs
- **Scope:** realistic engineering tasks; restart defects; stale-state;
  recovery; remote defects; provider defects; projection/authority
  confusion; operator UX friction
- **Acceptance property:** 5 distinct bounded tasks completed end-to-end
  via Temper; restart defects found and fixed; remote dogfood works
- **Output:** integration/scenarios/whole-system-dogfood/; September release
  candidate

## L. Acceleration hypotheses (reuse opportunities)

```
MAJOR_ACCELERATORS:
  - Use Phoenix Channels + existing Kiln bounded dispatch for service
    boundary (instead of inventing new transport)
  - Use OTP DynamicSupervisor + Registry for provider/agent/session
    lifecycles (instead of inventing custom machinery)
  - Use `zed <path>` CLI for editor integration (instead of building
    editor UX — saves months)
  - Use SSH/Tailscale for remote MacBook connection (instead of building
    hosted relay — saves weeks)

MODERATE_ACCELERATORS:
  - Use existing Kiln bounded contract envelopes for client/server RPC
    payloads (no new contract schemas needed)
  - Use current Arsenal methods for pathfinder research (not reinvent
    recon)
  - Use existing M0 bounded dispatch for agent-runtime adapter (template
    is already proven)

SMALL_ACCELERATORS:
  - Use existing CLI scripts (`./invariant test kiln`, `./invariant check`)
    for CI
  - Use existing integration/scenarios/ as base for end-to-end tests

NO_MEANINGFUL_SAVINGS (deferred):
  - Building a custom editor (Zed covers it)
  - Building a hosted relay (SSH/Tailscale covers it)
  - Building a custom provider protocol (HTTP+WS+JSON is the minimum)

DISTRACTION (do not pursue):
  - Multi-tenant cloud architecture
  - VS Code extension ecosystem
  - Marketplace
```

## M. T3 source reference atlas (for Pathfinder missions)

```
T3 repo (TO PIN exact SHA via git clone): pingdotgg/t3code
Key paths:
  apps/server/src/orchestration/    command/event lifecycle
  apps/server/src/provider/         adapter registry
  apps/server/src/vcs/              git + checkpoint
  apps/server/src/terminal/         terminal/process supervision
  apps/server/src/auth/             environment auth
  apps/server/src/fs/               filesystem
  packages/contracts/               typed client/server contract
  packages/client-runtime/          reconnect/cache/session
  packages/ssh/                     environment launch/tunnel
  packages/tailscale/               private endpoint setup
  apps/desktop/                     backend supervision (Tauri)
  apps/server/                      headless server
  apps/web/, apps/mobile/           web + mobile clients

MIT license. Substantial source reuse requires attribution. Prefer
architectural/behavioral reference + independent Elixir implementation
over copy-paste. If specific small source mechanisms are reused,
record in REUSE_CANDIDATE documents.
```

## N. Risks and cuts (what gets dropped first)

```
CUT FIRST if schedule slips:
  - Mobile native client (web-only Temper is sufficient for September)
  - Hosted relay architecture (SSH/Tailscale is the remote path)
  - VS Code extension ecosystem (Zed CLI integration is the only editor
    path)
  - Public marketplace
  - Multi-tenant OAuth (provisioned credentials suffice)
  - Every T3 provider (MiniMax + 1 agent-runtime is enough)
  - Rich telemetry (basic bounded evidence is enough)
  - Background-service installer (dev launch is enough for dogfood)

CUT SECOND (if deeper cuts needed):
  - Multiple worktree UI
  - Repository cloning UX
  - Provider configuration UI (provider config in code is fine)
  - GitHub PR creation (operator uses Git CLI)
  - Searchable historical runs (current evidence trail is enough)

NON-NEGOTIABLE:
  - Authority gate (Kiln.M0)
  - Exact-byte approval
  - Independent reviewer (digest-distinct)
  - Explicit HumanDecision
  - Bounded Session persistence
  - Recovery from authoritative observable state (no blind replay)
```

## O. Evidence required for release

```
NOT MERELY TESTS PASS — exact evidence:
  1. M12-A composed golden path: bounded golden path runs end-to-end
     through daemon (not CLI) for both providers, both via Temper UI
  2. Session persistence: 5 distinct bounded tasks survive daemon restart
  3. Remote dogfood: 1 bounded task completed from MacBook Air to
     MacBook Pro Invariant daemon
  4. Recovery: 3 restart scenarios (before mutation, mid-mutation,
     post-mutation before evidence) all classified correctly
  5. Stale-state: 2 scenarios where pre-state diverges; bounded apply
     fails closed; operator can recover
  6. Provider denial: 3 scenarios where provider returns error;
     bounded dispatch fails closed; no blind replay
  7. Authority confusion: 2 scenarios where reviewer digest collides
     with implementer; bounded Review fails closed
  8. Projection integrity: RunResultProjection identity correctly bound
     to inputs; same inputs produce same identity
  9. Operator UX friction: 5 realistic operator tasks completed via
     Temper (not CLI) including resume, interrupt, parent/child
 10. T3-competitive gap closure: explicit comparison vs T3 P0 list; gaps
     are explicit (cuts documented)
```

## P. Immediate next actions (3-7 concrete work packages that can begin as soon as this planning run completes)

```
1. WP-01 T3 architecture archaeology (pathfinder; can begin NOW; no
   production code, read-only; produces t3-reference-map.md + reuse
   ledger within 1-2 days)

2. WP-06 OTP fast-track experiments (pathfinder prototype; can begin
   NOW in disposable worktree; one prototype per high-value question;
   bounded, no production code)

3. WP-02 Invariant service boundary decision (pathfinder; can begin
   AFTER WP-01 produces T3 server architecture map; produces
   client-server-boundary.md; needs no production code)

4. WP-03 Provider-runtime contract decision (pathfinder; can begin in
   parallel with WP-02; produces provider-runtime-strategy.md)

5. WP-04 Workspace/Git/recovery decision (pathfinder; can begin in
   parallel; produces workspace-recovery.md)

6. M12-B recovery test setup path fix (parallel-safe production; 2/4
   sub-properties still need test setup path correction; bounded
   machinery is correct)

7. Continue parallel-safe production: docs, M12 lane closures, evidence
   debt reduction (all independent of Pathfinder decisions)
```

---

## Q. Schedule verdict

```
VERDICT = YES, WITH EXPLICIT CUTS

Conditions:
  - Pathfinder Days 1-4 must produce bounded decisions on WP-01..WP-04
    (otherwise Week 2 cost estimate explodes)
  - WP-07 (Kiln daemon) must complete in Week 1 (blocks everything else)
  - M12-A composed golden path must run end-to-end through daemon
    (not CLI) by end of Week 2
  - All 5 evidence categories (1-5) above must be produced before
    declaring release candidate

If Pathfinder Days 1-4 produce no decisions: AT RISK (Week 2 cost
estimate becomes unbounded).

If Pathfinder Days 1-4 produce decisions but WP-07 slips past Week 1:
AT RISK (entire schedule cascades).

If Pathfinder Days 1-4 produce decisions AND WP-07 lands in Week 1:
ON TRACK (assuming the explicit cuts above are honored).
```
