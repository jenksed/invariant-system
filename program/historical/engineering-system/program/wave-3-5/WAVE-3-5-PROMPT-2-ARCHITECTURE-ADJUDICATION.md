# Wave 3.5 — Architecture Adjudication & Wave 4 Definition

**Prompt 2 of 2.** This document adjudicates the proposed long-term product world against the Wave 3.5 Discovery Packet and produces the smallest truthful, exciting Wave 4.

This is an architectural decision document. It does NOT implement code. It does NOT create PRs. It does NOT modify any repository.

---

# A. EXECUTIVE VERDICT

**APPROVE WITH SPECIFIC MODIFICATIONS.**

The long-term product thesis is sound. The four-system separation (Arsenal learns, Loadout chooses, Kiln proves, Temper presents) is consistent with the existing accepted architecture. The proposed concepts are largely well-targeted at real engineering pain points.

**But three structural corrections are required before any Wave 4 implementation begins:**

1. **`Operation` cannot be the name of the higher-level engineering undertaking.** Kiln already uses `Operation` for a transient execution-level concept. Treating the higher-level concept as `Operation` would create a real namespace collision with Kiln's `Kiln.Domain.Operation`. The higher-level concept should use a different term (recommended: `Engagement` or `Project`).

2. **Project Reality must NOT collapse into a single canonical digest.** Different scopes rightly produce different identities (Loadout's workspace_state_digest, Kiln's repository_state_digest, Evidence records, Run state, Decision records). Project Reality is a DERIVED PROJECTION over these scoped truths, not a replacement digest.

3. **Wave 4 must NOT assume a runtime that does not exist.** No Worker process, no Lead, no Fleet, no general conversation engine exists. Wave 4 produces a Workbench that inspects real state from existing Wave 3 products. It does NOT fake conversation, Fleet, Frontier, or Motion. The architecture allows those capabilities to be added later without structural redesign.

**If we preserve accepted product boundaries and build incrementally from real capability, is this the right world for Temper to grow into?**

**YES, with the modifications above and the worker-runtime / conversation-runtime deferrals below.**

---

# B. DISCOVERY-PACKET CORRECTIONS

The Discovery Packet is largely sound. The following corrections apply:

| Original Packet conclusion | Disposition |
|---|---|
| `Operation` is an EXACT EQUIVALENT to `Kiln.Domain.Operation` | **REJECTED.** The two meanings are incompatible: `Kiln.Domain.Operation` is a transient execution-level unit (model invocation, patch application, command execution) with its own lifecycle. The proposed Temper "Operation" is a higher-level engineering undertaking containing Plan, Runs, Workers, Findings, Evidence, Decisions. Conflating these would invite a real collision. |
| `Operation` = `Run` for the proposed hierarchy | **REJECTED.** A Run is a single durable attempt. The higher-level undertaking contains multiple Plans, multiple Runs, and possibly multiple Failure-decisions. Run is genuinely narrower. |
| `Frontier` is "an interesting concept" but not yet derivable | **ACCEPTED.** Frontier remains long-term direction, but Wave 4 cannot derive it. It must remain a deferral candidate. |
| `Motion` is a useful closed vocabulary | **ACCEPTED WITH MODIFICATION.** Motion at the closed-vocabulary level (`Run blocked → completed`, `Evidence unknown → pass`, etc.) is reasonable. A generalized Motion ontology is not. |
| `Project Reality` is a hybrid or umbrella | **ACCEPTED.** Project Reality is a DERIVED PROJECTION over scoped truths. Pick this when forced to label. |
| Investigation A found 26 concepts in Temper | **ACCEPTED.** Mostly VISION ONLY. Two NATURAL EXTENSION on the data side. |
| Investigation B found Operation as EXACT EQUIVALENT in Kiln | **REJECTED.** See correction above. |

---

# C. PRODUCT CONSTITUTION

## TEMPER

**OWNS**
- Workbench UX (focus types, navigation, narrow/medium/wide layout, back/Escape behavior)
- Read-only projection over other products' canonical state
- Attention vocabulary (Temper-presented glyphs derived from real Kiln/Loadout/Arsenal state)
- Future conversational interface (when a real conversation runtime exists)
- Future Fleet visualization (when a real Worker runtime exists)

**MUST NOT OWN**
- Durable execution truth
- Authority decisions
- Engineering intelligence (methods, evaluation, qualification)
- Plan compilation
- Evidence evaluation
- Plan revision authority
- Authority revocation
- Real conversation engine (until it exists)
- Worker runtime (until it exists)
- A second persistence authority for Kiln truth
- Run/Attempt/Decision duplication
- Operator authority over Kiln state

## LOADOUT

**OWNS**
- Goal, Capability, Skill, Pack, QMR consumption
- Plan compilation (including embedded Work Envelope)
- Capability registry
- User-facing Result presentation
- Selection criteria for engineering strategy (when Formation/Proof Strategy are adopted)
- Repackaged Run display (when showing the user what Kiln did)

**MUST NOT OWN**
- Runtime authority
- Effect execution
- Canonical evidence
- Recovery
- Acceptance readiness
- Generic provider infrastructure
- Workflow engine that takes a Plan and orchestrates downstream steps
- Fail-fast authority grants
- Silent fallback to simulated Kiln when real Kiln is unavailable

## KILN

**OWNS**
- Runs (Root Run, canonical attempt)
- Authority (granted/denied, durable, auditable)
- Effects (canonical record of what happened)
- Artifacts (content bytes, immutable)
- Evidence (criterion-evaluated observations)
- Currentness (freshness/contradiction)
- Recovery
- Acceptance readiness (always `false` in v0; supervisor never manufactures user acceptance)
- Work Envelope supervision (CLI → Kiln.Supervision)
- Restart durability
- Operation (transient execution-level unit: model invocation / patch application / command execution)
- Decision (durable local-user decision)

**MUST NOT OWN**
- Producer state (input_state)
- Workspace state
- Generic agent runtime
- Plan compilation
- Cross-product reconciliation of architecturally distinct digests
- Manual Frontier authoring
- Fake Frontend product rendering

## ARSENAL

**OWNS**
- Methods and QMR authoring
- Method evaluation (deterministic procedure invocation + verifier)
- Qualification recipes
- Knowledge Plane (typed observations: Decision, Evidence, Capability, Authorization, FieldObservation, FrictionEvent, NegativeKnowledge, Unknown)
- Bench / Counterfactual / Ablation / Case Health / Capability Evidence Passport receipts
- Capability Graph (route-level verdict: READY / CAPABILITY_GAP / AUTHORITY_GAP / QUALIFICATION_GAP / UNKNOWN)
- Flight Recorder (metadata-first, content-off)
- Adapter surface (procedure-adapter inspection)

**MUST NOT OWN**
- Runtime authority
- Plan compilation
- Worker scheduling
- Conversation
- Cross-product reconciliation that would break Loadout's consumer-deployed boundary
- Promotion that bypasses its own qualification receipt (capability, target, adapter_version, suite, digests)
- A facade over consumer configuration

## ENGINEERING-SYSTEM

**OWNS**
- Cross-product decisions (0001 etc.)
- Boundary contracts (the four v0 envelopes)
- Work packages
- Launch gates
- Integration proof scaffolding
- Wave coordination agreements (e.g., `program/wave-3/WAVE-3-FIRST-REAL-RUN.md`)

**MUST NOT OWN**
- Implementation in any product
- A fourth product
- A runtime dependency
- Mutable narrative status that can be derived from GitHub
- Speculative architecture docs not yet bound to acceptance

---

# D. MAJOR IDEA ADJUDICATION

| Idea | Verdict | Confidence | Reason | Existing truth reused | New primitive? | Wave 4 relevance |
|---|---|---|---|---|---|---|
| Temper as primary engineering environment | ACCEPT | DECIDABLE NOW | Long-term thesis; consistent with the four-system separation | None | None | Yes (Workbench v0) |
| Persistent conversational long-term thesis | ACCEPT WITH MODIFICATION | PROVISIONAL | Long-term correct; deferred implementation | None | None | No |
| Workbench | ACCEPT | DECIDABLE NOW | Focus types over real state; no backend primitive needed | Yes (Plan, Run, Evidence, Artifact) | None | Yes |
| Conversation as future default | DEFER | BLOCKED ON WAVE 3 | No conversation runtime exists | None | Conversation primitive | No |
| Fleet | DEFER | BLOCKED ON WAVE 3 | No truthful Worker runtime to fleet | None | None | No |
| Higher-level Operation concept | ACCEPT | DECIDABLE NOW | Long-term useful; different name (see G) | Yes (Session/Task/Run) | None | No |
| Attention | ACCEPT WITH MODIFICATION | DECIDABLE NOW | Long-term; minimal derived projection | Yes (Kiln pending Decision, Run state) | None | Optional Wave 4 |
| Frontier | ACCEPT WITH MODIFICATION | PROVISIONAL | Long-term; derive only when state supports it | None | None | No |
| Pulse | DEFER | BLOCKED ON WAVE 3 | No truthful activity stream | None | None | No |
| Motion | ACCEPT WITH MODIFICATION | PROVISIONAL | Long-term; minimal closed vocabulary | Yes (Run state, Evidence) | None | Optional Wave 4 |
| Project Reality | REJECT (single canonical) | DECIDABLE NOW | Different scopes rightly produce different identities | Yes (multiple digests) | None | No |
| Higher-level Objective | ACCEPT (existing) | DECIDABLE NOW | Session.objective + Task.statement already cover | Yes (Kiln) | None | No |
| Finding | REJECT (first-class) | DECIDABLE NOW | Evidence + rationale carries the meaning | Yes (Evidence) | None | No |
| Unknown | ACCEPT (existing) | DECIDABLE NOW | Evidence.result=:unknown + run_result_envelope.unknowns[] | Yes (Kiln) | None | No |
| Decision | ACCEPT (existing) | DECIDABLE NOW | Kiln.Domain.Decision is real | Yes (Kiln) | None | No |
| Attempt | ACCEPT (existing) | DECIDABLE NOW | Run = attempt | Yes (Kiln) | None | No |
| Loadout future model | ACCEPT WITH MODIFICATION | PROVISIONAL | Long-term; not all fields in Plan at v0 | Yes (existing primitives) | None | No |
| Formation | DEFER | BLOCKED ON WAVE 3 | No truthful runtime to instantiate | None | Formation primitive | No |
| Proof Strategy | DEFER | PROVISIONAL | Long-term; defer contract change | Yes (Phase verbs exist) | None | No |
| Model/reasoning allocation | DEFER | BLOCKED ON WAVE 3 | No runtime to allocate | None | None | No |
| Alternative Loadouts / engineering postures | DEFER | PROVISIONAL | Long-term; no trustworthy preset | None | None | No |
| Kiln-backed authority interactions | ACCEPT | DECIDABLE NOW | Authority is durable | Yes (Kiln W3) | None | Yes |
| Evidence-backed Review | ACCEPT WITH MODIFICATION | DECIDABLE NOW | Diff + Evidence + Currentness | Yes | None | Yes |
| Workbench pinning | DEFER | PROVISIONAL | Reserved for after Wave 4 | None | None | No |
| Raw output / terminal access | ACCEPT WITH MODIFICATION | DECIDABLE NOW | Run Result JSON; raw drill-in | Yes (Kiln) | None | Yes |
| New-project FORMING behavior | DEFER | BLOCKED ON WAVE 3 | Worker runtime missing | None | FORMING primitive | No |
| Returning-project briefing | ACCEPT WITH MODIFICATION | PROVISIONAL | Use only real durable facts | Yes (Wave 3) | None | Yes (minimal) |
| Arsenal learning from Method / Formation / Proof outcomes | DEFER | BLOCKED ON WAVE 3 | No Formation/Proof primitive yet | None | None | No |

---

# E. PRIMITIVE EXISTENCE / OWNERSHIP MAP

| Concept | Canonical? | Semantic owner | Storage owner | Projection owner | UI owner | Existing representation | Wave 4 needed? |
|---|---|---|---|---|---|---|---|
| Project | NO | engineering-system | engineering-system | none | Temper | No | No |
| Project Reality | NO (single canonical) | scoped owners | scoped | Loadout + Kiln | Temper | Yes (multiple digests) | No |
| Frontier | NO | none | none | none | Temper | No | No |
| Objective | YES (partial) | Kiln (Session.objective + Task.statement) | Kiln | Loadout (Goal) | Loadout | Yes | No |
| Higher-level engineering work concept | NO | n/a | n/a | n/a | none | No (renamed, see G) | No |
| Kiln.Domain.Operation | YES | Kiln | Kiln | Kiln | n/a | Yes | No |
| Loadout | YES | Loadout | Loadout | Loadout | Loadout | Yes | Yes |
| Formation | NO | none | none | none | none | No | No |
| Proof Strategy | NO | n/a | Loadout composition | Loadout | none | No | No |
| Worker | NO (transient) | runtime | n/a | Kiln (transient) | Temper | No (transient) | No |
| Role | NO | n/a | n/a | n/a | Temper | No | No |
| Plan | YES | Loadout | Loadout | Loadout | Loadout | Yes | Yes |
| Finding | NO | n/a | n/a | n/a | n/a | No (Evidence carries rationale) | No |
| Unknown | NO (first-class) | Kiln (Evidence.result) | Kiln | Kiln | Temper | No | No |
| Decision | YES | Kiln | Kiln | Kiln | Temper | Yes | No |
| Evidence | YES | Kiln | Kiln | Kiln | Temper | Yes | Yes |
| Contradiction | YES (computed) | Kiln | Kiln | Kiln | Temper | Yes | No |
| Attempt / Run | YES | Kiln | Kiln | Kiln | Temper | Yes | Yes |
| Acceptance | YES | Kiln | Kiln | Kiln | Temper | Yes | Yes |
| Motion | NO | n/a | n/a | Loadout + Kiln | none | No | No |
| Pulse | NO | n/a | n/a | n/a | n/a | No | No |
| Attention | NO | Kiln (pending Decision) | Kiln | Kiln | Temper | Partial | No |
| Fleet | NO | n/a | n/a | n/a | n/a | No | No |
| Workbench | NO | Temper | n/a | n/a | Temper | No | Yes |
| Conversation | NO | n/a | n/a | n/a | Temper | No | No |

---

# F. OBJECTIVE / SESSION / TASK / RUN MODEL

The recommended durable hierarchy is **composition over existing primitives, not a new parallel hierarchy.**

```text
Project
  └ Session (Kiln)
      ├ Objective  (Session.objective)
      ├ initial Task (Task.statement + Task.criteria)
      └ Root Run
          ├ Plan (Loadout, one canonical per Run typically)
          ├ Work Envelope (produced by Loadout, submitted to Kiln)
          ├ Operation (transient, Kiln.Domain.Operation)
          ├ Evidence (durable, criterion-evaluated)
          ├ Artifact (durable, content bytes)
          ├ Decision (durable, local-user)
          └ Currentness (derived evaluation)
```

**Where the proposed Temper Engineering-Undertaking concept fits:**

The proposed higher-level engineering undertaking (e.g., "investigate architecture conflict") is **not** a new durable object. It is a **PROJECTION over** an existing Session + its Task + its Run(s) + its plans + its evidence. The Termper product presents this as a coherent story; the underlying storage is durable Kiln state.

**Why this is the right choice:**

- Adding a new durable object at the engineering-undertaking level would duplicate Session / Task / Run semantics.
- Wave 3 already establishes Session → Task → Run → Operation durability.
- The proposed "Workers are disposable. Operations survive. Project intelligence survives Operations." is preserved without inventing any new primitive.

**Plan and Work Envelope fit:**

- `Plan` is Loadout's compiled intent at a specific instant. It belongs to Run.
- `Work Envelope` is the canonical Loadout-to-Kiln request. It also belongs to Run.
- Both remain durable.

**What Temper does with this model:**

- Projects are projections over Sessions.
- Sessions are projections over Tasks + Root Runs.
- Tasks are projections over objectives + criteria.
- Root Runs are projections over Plans + Work Envelopes + Evidence + Artifacts.

---

# G. OPERATION NAMING / SEMANTIC DECISION

**Should the long-term product use the word `Operation` for the higher-level concept?**

**NO.**

**Reasoning:**

- Kiln already has `Kiln.Domain.Operation` as a transient execution-level concept (model invocation / patch application / command execution) with its own lifecycle (intent_recorded → started → succeeded / failed / canceled / unknown).
- The proposed Temper higher-level engineering undertaking is a categorically different concept: a long-running orchestration containing Plan, Runs, Workers, Findings, Decisions, Evidence, and Result.
- Treating these as the same would create a real namespace collision, a real semantic confusion, and a real architectural risk. Saying "Operation completed" must mean "this single model invocation completed" — not "this whole engagement completed."

**Recommended naming for the higher-level concept:**

The proposed higher-level engineering undertaking should use a different term. Recommended candidates (in order of preference):

1. **Engagement** — captures the "we're engaged in this work" semantic without colliding with Kiln.Domain.Operation.
2. **Project** — broad; already used in some forms; captures the long-running nature.
3. **Initiative** — possible but implies a strategic-program sense.

**Decision:** Use `Engagement` (or `Project`) for the higher-level engineering concept. Never use `Operation` for this.

**The existing `Kiln.Domain.Operation` keeps its current meaning.** No Kiln renaming is required.

---

# H. PROJECT REALITY DECISION

**Project Reality is a DERIVED PROJECTION over scoped truths, NOT a single canonical digest.**

**Reasoning:**

The Discovery Packet revealed multiple distinct state identities, each with a legitimate scope:

| Source | Scope | Owner |
|---|---|---|
| Loadout `workspace_state_digest` | producer-observed workspace state | Loadout |
| Kiln `repository_state_digest` | Kiln-observed repository state | Kiln |
| `Evidence` | criterion-evaluated observations | Kiln |
| `Decision` | durable local-user decisions | Kiln |
| `Run` state | durable attempt / coordination boundary | Kiln |
| Arsenal epistemic observations | evaluation-state observations | Arsenal |
| accepted product/configuration state | cross-product acceptance | engineering-system |

**These are all real. They are not the same. They are not interchangeable.**

A naive "Project Reality digest" would silently equate a Kiln-observed state with a Loadout-observed state, breaking the Wave 3 substrate's explicit separation. The Wave 3 integration agreement explicitly preserves this distinction:

> "If the algorithms differ: retain the Loadout producer state as input_state, retain Kiln's independent observed state separately, compare only the facts whose equivalence is actually defined, preserve uncertainty."

**Adjudication:**

1. **Semantic owner:** scoped (each scoped truth has its own owner)
2. **Truth contributors:** Loadout + Kiln + Arsenal + engineering-system
3. **Storage owners:** scoped (each owner stores its own)
4. **Projection owner:** Temper (computes a unified view across scoped truths)
5. **Whether a unified digest exists:** NO. Each scope has its own digest.
6. **Whether a unified digest SHOULD exist:** NO. Cross-scope digests would lose information.
7. **How conflicting/scoped observations remain distinguishable:** each scope has its own digest; Temper projects them side-by-side, never collapsing.
8. **Temper's relationship:** Temper is a TEMP-PROJECTION viewer. It does not author or store.

**Wave 4 does NOT need a unified Project Reality view.** Wave 4 displays Run state, Plan state, Evidence state, Unknowns — each from its true source. No "one SHA" abstraction.

---

# I. FINDING / UNKNOWN / DECISION / ATTEMPT DECISION

## Decision

**ACCEPT EXISTING.** `Kiln.Domain.Decision` is a real durable local-user-decision shape. Temper renders it. No new primitive.

## Attempt

**ACCEPT EXISTING.** Kiln Run is the attempt. No new primitive. A Run is more than an Attempt (workflow_step, pending_decision, operation reference), so a Temper-facing "Attempt" is just a UI projection over Run.

## Unknown

**ACCEPT EXISTING (across multiple vocabularies).** Unknown-ness exists at multiple layers:
- `Evidence.result = :unknown`
- `Operation.state = :unknown`
- `RunResultEnvelope.status = :unknown`
- `RunResultEnvelope.unknowns[]` (list of explicit unknown strings)

No clean first-class `Unknown` entity exists, and creating one would not improve honest expression. Temper surfaces the existing unknown vocabularies.

**No new primitive.**

## Finding

**REJECT (as new first-class object).** The proposed "Finding" is a free-form inspection report with `findings`/`omissions`/`scope`/`method`. The existing `Evidence` carries `result ∈ {pass, fail, blocked, unknown}` plus a rationale field (max 8192 bytes). Adding a separate Finding object would duplicate Evidence's role without adding trustworthy semantics.

**Alternative:** Use Evidence with a richer rationale, or use Arsenal's `FieldObservation` (`got-right | got-wrong | friction | gap | loss | unknown`) bound to a specific snapshot.

**No new primitive.**

---

# J. FRONTIER DECISION

**LONG-TERM: ACCEPT.** Frontier ("what currently separates the project from its next meaningful state") is a strategically interesting concept.

**WAVE 4: DEFER.** Frontier cannot be truthfully derived from current products. To implement Frontier, Temper would need:
- A canonical blocker inventory (criteria unsatisfied, decisions pending, evidence stale, unknowns unresolved, requests blocked)
- A deterministic algorithm for "the next meaningful state"
- Clear separation between real state and editorially authored slogans

None of this exists.

**Note:** Frontier must NOT be a manually maintained statement. It must be derived from real state, with uncertainty preserved.

**Implementation prerequisite:** at least two "next meaningful states" must be derivable from current Wave 3 product state. Today, only one obvious candidate exists: "Close the first real Plan → Kiln execution loop." Wave 4 should not attempt more than this.

**DEFER implementation. Adjudicate direction.**

---

# K. PULSE / MOTION DECISION

## Pulse

**LONG-TERM: ACCEPT-concept, DEFER-implementation.**

Pulse = "what is happening right now." Examples: command running, tests executing, Run state change.

**Wave 4 DEFER.** Pulse requires an event stream that:
- Wave 3 does not currently expose (the Kiln Run Result is a final envelope, not a stream).
- A Worker runtime does not currently exist to produce Pulse events.

Wave 4 should not build synthetic Pulse. If Wave 3 produces final envelopes/projections only, a static truthful Workbench is better than synthetic liveliness.

## Motion

**LONG-TERM: ACCEPT-WITH-MODIFICATION, Wave 4 minimal closed vocabulary.**

Motion = "what meaningfully changed in engineering reality." Examples:
- Unknown → resolved
- Decision → accepted
- Criterion → satisfied
- Candidate → rejected
- Objective → unblocked

**Minimal Wave 4 closed vocabulary (derived from existing transitions):**
- `Run.state`: ready → running → completed/failed/canceled
- `Evidence.result`: unknown → pass/fail/blocked
- `Decision.state`: pending → resolved/expired
- `RunResultEnvelope.acceptance_readiness`: ready → false / true

**Do NOT** build a generalized Motion ontology across Findings, Unknowns, Decisions, hypotheses, capabilities, and Objectives. That is a Level 2 implementation that Wave 4 cannot justify.

**Protect:** Activity ≠ Motion. Loading spinner ≠ Frontier moved.

---

# L. ATTENTION DECISION

**LONG-TERM: ACCEPT WITH MODIFICATION.**

Attention = "what needs human cognition right now."

**Wave 4: OPTIONAL minimal derived projection.**

The hypothesis to test:

> Attention is a derived Temper projection over backend states, not a new canonical Attention database.

**Possible sources for a minimal Wave 4 Attention:**

| Glyph | Source | Status |
|---|---|---|
| `! CONTRADICTION` | `currentness.contradiction = :present` | derivable now |
| `? DECISION` | `pending Decision` | derivable now |
| `△ REVIEW READY` | future concept | NOT derivable yet |
| `⚿ AUTHORITY` | `Kiln.Authority` Wave 3 candidate | derivable after PR #64 merges |
| `✓ RESULT` | `RunResultEnvelope.status = completed` | derivable after PR #64 merges |

**Wave 4 may include a minimal Attention surface only if every entry is derived from real backend state.** If not, **DEFER Attention entirely**.

---

# M. LOADOUT FUTURE MODEL

**LONG-TERM: ACCEPT-WITH-MODIFICATION.**

Loadout's long-term proposition ("equip the engineering work with the best strategy currently justified") is sound. The proposed evolution:

```text
Intent
  ↓
Capability
  ↓
Method
Formation
Proof Strategy
Tools
Authority Request
Model / Reasoning Recommendation
  ↓
Plan
```

**Important constraints:**

- Do NOT require all of these concepts to become new fields in Plan at v0.
- Do NOT require accepted v0 contract changes now.
- Many of these are **future composition** at the Loadout layer, not new durable fields.

**Wave 4 considers Loadout frozen at its current spec.** Wave 4 reads whatever Loadout emits and renders it truthfully. Wave 4 does NOT extend Loadout's contract.

**Adjudication:** Long-term direction accepted. Wave 4 implementation does NOT modify Loadout's v0 contract. Future waves may extend Loadout.

---

# N. WORKER / FLEET MODEL

The investigation established:

- **Worker:** Transient process. No generalized struct. Kiln's `KILN-DOM-006` explicitly says Worker identity is transient.
- **Role:** Vocabulary only. No canonical entity.
- **Run:** Kiln-existing. Durable attempt / coordination boundary.
- **Model:** Runtime implementation. No struct.
- **Formation:** New primitive. DEFER.

**The right model:**

```text
Durable Run (Kiln)
  has optional role/provenance metadata
    e.g. run.role = "Builder"
    e.g. run.method_provenance = QMR

Transient Worker
  executes against Run
  identity is ephemeral
  identity changes do not change Run identity

Temper
  presents the role/worker while alive
  falls back to durable Run after death
```

**This protects the existing invariant: Worker identity is transient. Runtime handles must not become durable identity.**

**Wave 4 does NOT render a Fleet.** No truthful Worker runtime exists. Wave 4 may show a single "active Worker" placeholder tied to a Run, but it must NOT invent multiple convincing-but-fake workers.

---

# O. TEMPER UX MODEL

## Workbench

**ACCEPT.** Workbench is the center of Temper. Conversation may eventually be its default focus, but Workbench is the structural commitment.

**Wave 4 default:** Workbench shows real Run state. Conversation is NOT the default.

**Focus types (Wave 4 initial set):**

- Overview
- Plan
- Run
- Authority
- Evidence
- Artifact
- Raw Result

**NOT in Wave 4 initial set:** Conversation, Fleet, Frontier, Pulse, Motion, Attention. (Each has its own verdict above.)

## Interaction model

**Keyboard-driven. One action into detail. One Escape toward default context.**

## Layout

- **Narrow:** single focus only.
- **Medium:** primary focus + status strip.
- **Wide:** primary focus + secondary focus (Result JSON, Plan JSON).

**No Fleet/Attention rails in Wave 4.** Only the real focus targets.

## Raw output

**Always drillable.** The Workbench must allow drilling into the actual Run Result JSON, the actual Plan content, the actual Evidence. Conversation does not abstract this away.

## Review

**Retro on Evidence + Currentness + Constraints + Diff.** Not a separate backend object. Use the artifacts that already exist.

## Pinning

**DEFER.** Single focus in Wave 4. No Lead + Builder side-by-side. The truthful Worker runtime does not exist.

---

# P. ARSENAL LEARNING MODEL

**LONG-TERM: ACCEPT WITH MODIFICATION.**

Arsenal's long-term learning expansion (Method effectiveness, Formation effectiveness, Proof Strategy effectiveness, model/role effectiveness, contextual effectiveness) is sound.

**Protect:**

```text
Arsenal learns.
Loadout chooses.
Kiln proves.
Temper presents.
```

**QMR remains Method-specific.** QMR is a specific artifact for a specific method maturity claim. It does NOT become a generic "anything Arsenal evaluated" record.

**Future Formation/Proof research,** if approved, deserves distinct research artifacts. They are NOT QMRs.

**What is required for future expansion:**

- Observed outcomes (per context) for each Formation/Proof Strategy
- Effectiveness ledgers that bind to (context, Formation/Proof, observed outcome)
- No auto-promotion

**Wave 4 does NOT trigger any new Arsenal learning.** Wave 4 surfaces current ARS-W3 adapter evaluation results.

**Adjudication:** Long-term direction accepted. Wave 4 unchanged. Wave 4 must NOT open the Graduation Gap prematurely.

---

# Q. WAVE 3 DEPENDENCY / IMPLEMENTATION GATE

**WHAT CAN BE DECIDED NOW:** Architecture planning for Wave 4. Constitution, primitive ownership, UX model. None of these depend on Wave 3.

**WHAT CAN BE PLANNED NOW:** The full Wave 4 specification (Section R). The vertical slice can be planned against existing Wave 3 + candidate KIL-W3 truth.

**WHAT MUST WAIT FOR WAVE 3:**

The actual Wave 4 implementation MUST wait for the Wave 3 independent integration proof to demonstrate that:

```text
Loadout Plan
    ↓
real Work Envelope
    ↓
real Kiln Run
    ↓
real authority decision
    ↓
procedure executes after grant
    ↓
Artifact
    ↓
Evidence
    ↓
Run Result
    ↓
restart
    ↓
same durable facts still inspectable
```

Without this proof, Wave 4 would be rendering against a candidate interface that has never actually completed the loop.

**EXACT INTEGRATION PROOF REQUIRED:**

The integration proof at `engineering-system/program/wave-3/integration-proof/` must be executed end-to-end. The 8 negative cases (stale, tampered, Kiln unavailable, authority denied, procedure failure, mid-run state change, retry, conflicting retry) must pass. The restart proof must pass. The dogfood against one real repository must succeed.

**Decision:**

> **Architecture planning can complete now. Wave 4 implementation must wait for the Wave 3 independent integration proof.**

---

# R. WAVE 4 RECOMMENDATION

Slice name: **Temper Real Run Workbench v0**

Alternative name considered: "Temper Workbench v0". The chosen name emphasizes the real-Kiln thesis.

## User outcome

**An operator can open Temper inside a real repository and immediately inspect:**

- what the engineering system planned
- what Kiln authorized
- what actually ran
- what evidence exists
- what remains uncertain
- what acceptance readiness is
- what is current vs. stale

All visible values are derived from real backend state. No fabrications.

## 30-60 second demo

```text
$ temper /path/to/real/repository

Repository
  project-arsenal

Goal
  Understand this repository

Plan
  <real Loadout Plan>

Run
  <real Kiln Run id>

Authority
  git.read             GRANTED

Evidence
  repo-state-observed  PASS
  freshness            CURRENT
  contradiction        NONE

Artifacts
  <real artifact id>

Unknowns
  <real unknown>

Acceptance readiness
  <truthful value>
```

Pressing `[evidence]` opens structured Evidence. Pressing `[raw]` shows the actual Run Result JSON. Escape returns to Overview.

After Kiln restart, the same durable Run truth is still inspectable.

## Default screen

```
┌─ TEMPER ───────────────────────────────────────────────────────┐
│ repository                         run / state                 │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                         WORKBENCH                             │
│                                                               │
│ Goal                                                          │
│   Understand this repository                                  │
│                                                               │
│ Plan                                                          │
│   <real plan id>                                              │
│                                                               │
│ Kiln Run                                                      │
│   <real durable run id>                                       │
│                                                               │
│ Authority                                                     │
│   git.read                                  GRANTED            │
│                                                               │
│ Evidence                                                      │
│   repo-state-observed                       PASS / CURRENT     │
│                                                               │
│ Unknowns                                                      │
│   <real unknowns only>                                        │
│                                                               │
│ [plan] [run] [evidence] [artifacts] [raw] [?] [esc]           │
├───────────────────────────────────────────────────────────────┤
│ real status / activity if available                           │
└───────────────────────────────────────────────────────────────┘
```

## Workbench focus types

**Initial set (Wave 4 v0):**

- Overview
- Plan
- Run
- Authority
- Evidence
- Artifact
- Raw Result

**Reserved for future:** Conversation, Frontier, Pulse, Motion, Attention, Fleet.

## Sources of truth

For EVERY visible value, the implementation must identify:

| Producer | Semantic owner | Projection/interface consumed | Candidate vs accepted |
|---|---|---|---|
| Goal | Loadout | Loadout CLI | Accepted |
| Plan id | Loadout | Loadout CLI | Accepted |
| Capability | Loadout | Loadout CLI | Accepted |
| Pack | Loadout | Loadout CLI | Accepted |
| Skill | Loadout | Loadout CLI | Accepted |
| QMR | Loadout | Loadout CLI | Accepted |
| Work Envelope | Loadout | Loadout CLI | Accepted |
| Run id | Kiln | Kiln CLI / artifact | Accepted (Wave 1) |
| Authority | Kiln | Kiln CLI | Wave 3 candidate (PR #64) |
| Artifact | Kiln | Kiln CLI | Accepted (Wave 1) |
| Evidence | Kiln | Kiln CLI | Accepted (Wave 1) |
| Currentness | Kiln | Kiln CLI | Accepted (Wave 1) |
| Acceptance readiness | Kiln | Kiln CLI | Wave 3 candidate (PR #64) |
| Repository Recon | Loadout | Loadout CLI | Wave 3 candidate (PR #5) |

## Interaction model

- Keyboard-driven
- Tab/arrow keys move focus
- Enter opens detail
- Escape returns to Overview
- `?` opens help
- `q` exits

## Responsive layout

- **Narrow:** single focus only
- **Medium:** primary focus + status strip
- **Wide:** primary focus + secondary focus (Run Result JSON, Plan JSON)

## Failure states

At minimum, the Workbench must handle:

- Kiln unavailable → render `n/a` and a clear error; do NOT fake
- No Run exists → render empty state
- Plan missing → render empty state
- Evidence stale → mark stale; do NOT claim current
- Evidence contradictory → mark contradiction; do NOT hide
- Artifact unavailable → render `n/a`
- Run incomplete → render `Run.state` truthfully
- Candidate interface incompatible → render `n/a` and explain

## Truthfulness rules

**Temper must NEVER:**

- Claim a Run completed when it didn't
- Claim `evidence: PASS` when result is unknown
- Claim `freshness: CURRENT` when evidence is stale
- Claim `acceptance_readiness: true` when not
- Fabricate a Lead, Fleet, Worker, or Frontier
- Show synthetic activity when no real activity exists
- Claim Conversation happened when no conversation runtime exists

## Scope

- Single repository opening
- Read-only navigation across existing products
- Renders real Loadout, Kiln, Arsenal state
- No new contract fields
- No new durable primitives
- ~4-6 focus panels
- Status bar
- Keyboard navigation

## Non-goals

- Conversation (no runtime)
- Fleet (no Worker runtime)
- Frontier (defer)
- Pulse (defer)
- Motion closed vocabulary (optional)
- Attention (optional)
- Model allocation (defer)
- Formation (defer)
- Proof Strategy (defer)
- Multi-repo support
- SAAS / network / cloud
- Marketplace
- Billing
- Custom plugins

## Acceptance criteria

Behavioral:

- AC-T1: `temper /path/to/repo` opens the Workbench inside that repository.
- AC-T2: Goal shows the real Goal from Loadout's `GOAL_CATALOGUE`.
- AC-T3: Plan shows the real Plan from `loadout plan --out <path>`.
- AC-T4: Run shows the real Run id from Kiln's `run_id`.
- AC-T5: Authority reflects the real authority decision from `Kiln.Authority`.
- AC-T6: Evidence shows the real Evidence records from `Kiln.Evidence.Store`.
- AC-T7: Artifact references show real Artifact ids from `Kiln.Artifact.Store`.
- AC-T8: Unknowns list reflects `RunResultEnvelope.unknowns[]`.
- AC-T9: Acceptance readiness reflects `RunResultEnvelope.acceptance_readiness.ready`.
- AC-T10: Pressing `[raw]` shows the actual `RunResultEnvelope.to_map/1` JSON.
- AC-T11: Pressing Escape returns to Overview from any focus.
- AC-T12: After Kiln restart, the same durable facts remain inspectable.
- AC-T13: Every visible value has a verifiable source file path and CLI command documented.
- AC-T14: No fabricated values appear anywhere in the Workbench.
- AC-T15: If any input is missing, the Workbench says `n/a` and explains why.

## Tests

- Unit: focus navigation, key bindings, source-of-truth mapping
- Integration: clean-checkout test against the Wave 3 integration proof fixtures
- Fixture: deterministic proof repo at `engineering-system/program/wave-3/integration-proof/proof-repo/`
- Terminal behavior: smoke test for narrow/medium/wide layout
- Truthfulness: every value in the rendered output must be traceable to a specific source

## Wave 3 prerequisites

Exact Wave 3 state required before Wave 4 implementation begins:

1. **Kiln PR #64 (KIL-W3 supervisor) merged.** The Kiln CLI shape `mix kiln supervise --work-envelope <path> --format json` must be canonical.
2. **Loadout W3 Phase 2 (real Kiln driver) merged.** The `loadout run --plan <path>` real path must be canonical.
3. **Arsenal PR #28 (ARS-W3 adapter) merged.** The `loadout-runtime` adapter must be canonical for the proof.
4. **The Wave 3 independent integration proof executed successfully.** The 8 negative cases + restart + dogfood must pass.

---

# S. DEFERRED PRODUCT TRAJECTORY

After defining Wave 4, here are the approved-but-deferred concepts organized by dependency, not by arbitrary Wave number.

## NEAR-TERM AFTER WAVE 4

- Verify This Change (minimal Review feature)
- Real Conversation interface (when a runtime exists)
- Minimal derived Attention (over real states)
- Minimal Pulse over Wave 3 events (when the events exist)
- Minimal Motion closed vocabulary (Run/Evidence transitions)

## REQUIRES REAL WORKER RUNTIME

- Fleet visualization
- Worker inspection (mission, reason, parent, current activity)
- Worker terminal attachment
- Formation visualization
- Real Lead agent

## REQUIRES STRATEGY INTELLIGENCE

- Formation selection (semantic owner: Loadout)
- Proof Strategy selection (semantic owner: Loadout)
- Alternative Loadouts / engineering postures (semantic owner: Loadout)
- Model / Reasoning Recommendation (semantic owner: Loadout)

## REQUIRES PROJECT-REALITY SEMANTICS

- Generalized Motion (beyond closed vocabulary)
- Frontier (when derivable from canonical state)
- FORMING / ORIENTING / BUILDING transitions
- Returning-project semantic delta

## REQUIRES ARSENAL LEARNING

- Evidence-informed Formation selection
- Proof Strategy effectiveness
- Contextual model allocation
- Capability-level qualification receipts

---

# T. TOP FIVE ARCHITECTURAL RISKS

## 1. Inventing a "Project Reality" digest that collapses Loadout's `workspace_state_digest` and Kiln's `repository_state_digest`

**Why it matters:** The Discovery Packet explicitly shows these digests have different scopes and different algorithms. Collapsing them would silently break the Wave 3 substrate's explicit separation.

**How the approved architecture avoids it:** Project Reality is a DERIVED PROJECTION scoped per source. Wave 4 displays each digest side-by-side, never collapsed.

## 2. Wave 4 implementing fictional Fleet, Workers, or Conversation

**Why it matters:** No truthful Worker runtime exists. Faking it would put the architecture in a position where it has to roll back later.

**How the approved architecture avoids it:** Wave 4 does NOT render Fleet, Workers, or Conversation. Workbench is the only structural commitment. Conversation is explicitly deferred.

## 3. Adding a new shared cross-product contract (Project, Motion, Frontier, Pulse, Worker, Attention)

**Why it matters:** The four v0 contracts are the authoritative cross-product boundary. Adding a fifth without crystal-clear justification would dilute the contract boundary.

**How the approved architecture avoids it:** Zero shared contract changes for Wave 4. Wave 4 consumes existing Loadout / Kiln / Arsenal projections.

## 4. Loadout becoming a workflow engine that orchestrates multiple Plans

**Why it matters:** Loadout's AGENTS.md explicitly excludes "a workflow engine that takes a Plan and orchestrates downstream steps." Multi-step orchestration would creep Loadout into a scheduler role.

**How the approved architecture avoids it:** Loadout's Plan emits exactly one Work Envelope per Run. Composition of multiple Plans is a Temper concern, not a Loadout concern.

## 5. Persisting runtime handles as durable identity

**Why it matters:** Kiln's `KILN-DOM-006` explicitly says Worker identity is transient. Persisting runtimes leaks session state into durable truth.

**How the approved architecture avoids it:** Wave 4 reads durable Run state. Worker / Fleet / runtime handles are not persisted. Temper is a read-only client.

---

# U. FINAL STATEMENT

> **Temper should grow into a Temper Real Run Workbench that surfaces real engineering reality — Run, Plan, Evidence, Authority, Unknowns, Acceptance readiness — using existing durable Kiln primitives, with Motion as a minimal closed vocabulary derived from existing state transitions, and Attention as a projection over real state, not a new database.**

> **The single biggest architecture mistake we must avoid is inventing a new "Project Reality" or "Operation" object that splinters the existing Kiln / Loadout / Arsenal authority model, or implementing a fictional Fleet / Conversation layer before the runtime that backs it exists.**

> **The next thing we should actually build is the Wave 3 independent integration proof — the proof that the real Plan → Kiln → Evidence → restart loop actually works end-to-end — because the truthful inputs for Tempe r's Workbench v0 are still pending until that proof passes.**

---

# END OF PROMPT 2 ADJUDICATION
