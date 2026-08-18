# M12-D — Temper Operator Surface Contract

**Lane:** M12-D
**Branch:** `m12-d-temper` (from HEAD=ec76f31)
**Owner:** Temper (operator surface) consumes Kiln bounded machinery

## Goal

Move Temper from "can render a final snapshot" toward "where the human actually operates governed work". The current E4 result exposed Session-derived N/A fields. Build the bounded surface contract that a future desktop client can consume.

## Architectural rule (load-bearing)

**Temper does NOT own execution truth.** Temper consumes and invokes bounded Kiln/Loadout/Manifold surfaces. UI action != authority unless the proper authority artifact is produced.

Concretely:
- A click in Temper that initiates a mutation MUST go through `Kiln.Worker.build_provider_completion/1` → bounded dispatch → bounded apply
- A click in Temper that approves a mutation MUST produce a `Kiln.M0PatchDecision{decision: "APPROVE_EXACT_BYTES", ...}` — never an internal flag
- A click in Temper that records HumanDecision MUST produce a `Kiln.M0HumanDecision` — never an internal boolean
- A click in Temper that selects a reviewer MUST go through `Manifold` — never an internal list

## Bounded operator workflow

```
1. open run
   → inspect requirement (canonical requirement digest)
2. inspect assigned implementer
   → Manifold-emitted assignment (canonical implementer_assignment_ref)
3. observe provider/Worker state
   → bounded dispatch status (real, not synthesized)
4. inspect proposed exact diff
   → bounded completion bytes (canonical bytes, provider-private rep translated)
5. approve exact bytes
   → produces M0PatchDecision{decision: "APPROVE_EXACT_BYTES"}
6. observe mutation
   → M0PatchEvidence{effect: "EXACT_TARGET_STATE_OBSERVED"}
7. verification
   → M0VerificationResult{status: "PASS"} (canonical verifier ran)
8. reviewer assignment
   → Manifold-emitted reviewer_assignment_ref (digest-distinct from implementer)
9. review/findings
   → M0Review{verdict: "APPROVE"|"REJECT"|"REQUEST_REVISION", implementer_transcript_received: false}
10. HumanDecision
    → M0HumanDecision{decision: "ACCEPT"|"REJECT"|"REQUEST_REVISION"} (owner-explicit)
11. completed projection
    → M0RunResultProjection (terminal artifact)
12. Temper snapshot
    → consumes RunResultProjection; does NOT own execution truth
```

## Reload/reconnect invariants

- Pending approval survives UI restart: the bounded decision is persisted as `M0PatchDecision` in the bounded store; UI reloads it from canonical store
- Pending HumanDecision survives UI restart: `M0HumanDecision` is persisted; UI reloads it
- Unknown-effect state visible honestly: when effect is uncertain, UI shows "E_MUTATION_UNKNOWN_EFFECT" with bounded error class — never a synthetic "in progress"
- Evidence links: every UI element links to the canonical artifact (id + digest) that produced its state
- No invented success state: bounded machinery only reports "EXACT_TARGET_STATE_OBSERVED"; no other state is shown as success
- No CLI/JSON dump as the intended normal UX: Temper's primary surface is the bounded operator surface; CLI/JSON are debug surfaces, not the primary UX

## What Temper consumes

- `M0RunResultProjection` (terminal bounded artifact)
- Canonical `RunResultProjection.truth` fields:
  - `run_status` ∈ `{completed, blocked, cancelled, failed, unknown}`
  - `verification_status` ∈ `{PASS, FAIL, TIMEOUT, ERROR}`
  - `review_status` ∈ `{APPROVE, REQUEST_REVISION, REJECT}`
  - `human_status` ∈ `{ACCEPT, REJECT, REQUEST_REVISION}`
  - `unknown_effects` = bounded list of artifact IDs

## What Temper does NOT own

- Execution truth: bounded machinery owns it
- Authority: bounded machinery owns it
- Artifact IDs/semantic_digests: bounded machinery owns them
- Provider selection: bounded machinery owns it
- Reviewer selection: Manifold owns it
- Approval semantics: bounded machinery + owner authority own it
- Mutation: bounded machinery owns it

## Open implementation questions

- Operator UX surface (web vs desktop vs terminal): out of scope for M12-D
- Persistent UI state across restarts: bounded store owns it (deferred to Lane C follow-up)
- Reconnect protocol: bounded machinery + Session machinery (deferred to follow-up)

## M12_D_TEMPER_OPERATOR_CORE = CONTRACT_PROVEN (no runtime yet)

The bounded contract is documented. The actual operator surface (web/desktop/terminal) and the Session machinery for persistent state across restarts are follow-up work beyond M12-D.
