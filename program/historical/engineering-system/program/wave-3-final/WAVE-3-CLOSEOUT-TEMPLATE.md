# Wave 3 Final Closeout Template

This is a **template** for the combined Wave 3 acceptance + opportunity discovery closeout.

The primary acceptance section is evidentiary. The opportunity discovery section is product research. Do not mix them.

---

# PART I — WAVE 3 ACCEPTANCE

Preserve the actual primary acceptance agent's output exactly. Do not reinterpret failures into success.

## Canonical merged SHAs

```
ARSENAL_MAIN=
LOADOUT_MAIN=
KILN_MAIN=
TEMPER_MAIN=
ENGINEERING_SYSTEM_MAIN=
```

## Plan

```
plan_id=
work_envelope_digest=
method=
method_version=
execution_boundary=
```

## Authority

```
requested=
granted=
denied=
```

## Procedure ordering

```
PLAN_INTEGRITY_VERIFIED                  = yes/no
PLAN_FRESHNESS_VERIFIED                  = yes/no
PROCEDURE_BINDING_VERIFIED               = yes/no
EXACT_WORK_ENVELOPE_SUBMITTED             = yes/no
KILN_DURABLE_WORK_CREATED_OR_REPLAYED     = yes/no
KILN_OBSERVES_REPOSITORY                  = yes/no
KILN_AUTHORITY_DECISION                   = yes/no
GIT_READ_GRANTED                          = yes/no
PROCEDURE_INVOCATION_BEFORE_AUTHORITY    = 0 (must be 0)
PROCEDURE_INVOCATION_AFTER_GRANT         = 1 (must be 1)
NO_FAKE_KILN_INVOCATION_ON_REAL_PATH      = yes/no
```

## Artifact

```
artifact_id=
content_digest=
integrity=
```

## Evidence

```
evidence_id=
criterion=
result=
freshness=
completeness=
contradiction=
```

## Currentness / Run Result

```
RUN_LIFECYCLE_STATUS=
PROOF_OBLIGATIONS_SATISFIED=
PROOF_OBLIGATIONS_UNSATISFIED=
ACCEPTANCE_READINESS=
ACCEPTANCE_READINESS_REASONS=
UNKNOWNS=
```

## Restart durability

```
restart_performed=
truth_recovered_from_kiln=
```

## Negative matrix

| ID | Scenario | Result | Procedure count |
|---|---|---|---|
| A | Stale Plan | | |
| B | Tampered Plan | | |
| C | Kiln unavailable | | |
| D | Authority denied | | |
| E | Procedure failure | | |
| F | Mid-run state change | | |
| G | Idempotent retry | | |
| H | Conflicting retry | | |
| I | Simulation isolation | | |

## Arsenal productized target proof

```
LOADOUT_TARGET_SHA=
ARSENAL_ADAPTER_ID=
EVALUATION_RUN_DIGEST=
SUPPORTED_ASSERTIONS=
MISSES=
UNSUPPORTED_CLAIMS=
UNKNOWNS=
FAILURES=
EPISTEMIC_CONCLUSION=
QMR_STATUS=
QUALIFICATION_GAP=
```

## Dogfood

```
DOGFOOD_REPOSITORY=
DOGFOOD_RUN_ID=
DOGFOOD_ARTIFACT_ID=
DOGFOOD_EVIDENCE_ID=
ANCHORS_FOUND=
CONSTRAINTS_FOUND=
UNKNOWNS_FOUND=
IMPORTANT_MISSES=
FALSE_CLAIMS=
DOGFOOD_USEFUL=yes | partially | no
```

## Wave 3 final verdict

```
A. WAVE 3 LANDED
B. WAVE 3 CORE LANDED — ARSENAL GRADUATION GAP REMAINS
C. HOLD — TARGETED REPAIR
D. HOLD — CONTRACT / OWNER DECISION
```

(Choose exactly one.)

---

# PART II — OPPORTUNITY DISCOVERY

This is product research, not evidentiary. Do not mix with Part I.

## User value observations

- Did Repository Recon materially reduce the work required to understand the repo?
- Did it surface the facts an engineer would actually need?
- Did the result feel shallow despite being correct?
- Did it find obvious architecture anchors?
- Did it explain meaningful constraints?
- Were the unknowns useful?
- Was important information present but buried?
- Did the operator immediately need to manually inspect the repo anyway?

(Capture specific examples.)

## Natural next question

What does a competent operator naturally want to ask after reading the result?

(No preset list. Observe the actual result and determine what question it naturally creates.)

## Arsenal method opportunities

Per limitation:
- OBSERVED LIMITATION
- EXPECTED BETTER BEHAVIOR
- MEASURABLE EVALUATION
- LIKELY METHOD CHANGE
- DOES THIS REQUIRE AN LLM?
- UNKNOWN

## Loadout product opportunities

Per opportunity:
- Is this PRESENTATION / CAPABILITY DESIGN / METHOD SELECTION / PACK-SKILL PACKAGING / INSTALLATION / PLAN EXPERIENCE / RESULT EXPERIENCE / NEW CAPABILITY?

## Kiln truth / acceptance opportunities

Per unresolved proof question:
- desired acceptance claim
- currently available Evidence
- missing Evidence
- is the missing piece: observation / evaluator / proof obligation / currentness rule / contradiction handling / projection / acceptance gate / unsupported capability?

## Temper visibility opportunities

Per repeated lookup:
- QUESTION
- CURRENT COMMANDS / SOURCES REQUIRED
- CAN KILN ALREADY ANSWER IT?
- IS A NEW KILN PROJECTION NEEDED?
- OR CAN TEMPER SIMPLY COMPOSE EXISTING READ MODELS?

## Integration / transport opportunities

Per item:
- ACCEPTABLE V0 FRICTION
- LOCAL TRANSPORT IMPROVEMENT
- APPLICATION API IMPROVEMENT
- CONTRACT PROBLEM

## Contract opportunities

Per gap:
1. What real semantic cannot be represented?
2. Which product owns the source truth?
3. Which product needs to consume it?
4. Is this actually cross-product?
5. Can the current contract express it without semantic abuse?
6. Does the limitation block useful work today?
7. Would changing it break v0 consumers?

## Friction log (chronological)

For every meaningful point of friction:
- STEP
- OBSERVATION
- SEVERITY (S0 cosmetic / S1 annoying / S2 reduces utility / S3 blocks normal use / S4 truth-safety defect)
- MANUAL WORK REQUIRED
- OWNER
- POSSIBLE OPPORTUNITY

## Delight log

For every strong moment:
- STEP
- WHAT FELT GOOD
- WHY
- WHICH ARCHITECTURAL DECISION ENABLED IT

## Dogfood reaction log

- EXPECTED AND FOUND
- EXPECTED BUT MISSED
- SURPRISINGLY USEFUL
- UNSUPPORTED / WRONG (must be traced to evidence)

## Opportunity classification

Every candidate receives exactly one primary disposition:

- IGNORE
- POLISH
- ARSENAL — METHOD OPPORTUNITY
- LOADOUT — PRODUCT OPPORTUNITY
- KILN — TRUTH OR EXECUTION OPPORTUNITY
- TEMPER — VISIBILITY OPPORTUNITY
- ENGINEERING-SYSTEM — CONTRACT OPPORTUNITY

## Opportunity scoring

For each retained opportunity:

- USER VALUE (1–5)
- ARCHITECTURAL LEVERAGE (1–5)
- EVIDENCE STRENGTH (1–5)
- EFFORT (1=low, 5=high)
- RISK (1=low, 5=high)

Conceptual priority = high user value + high leverage + strong evidence - effort - risk

## Flywheel candidates

For each dogfood observation that could enter this loop:

```
DOGFOOD OBSERVATION
    ↓
ARSENAL EVALUATION CASE
    ↓
POTENTIAL METHOD CHANGE
    ↓
EXPECTED LOADOUT IMPACT
    ↓
KILN PROOF IMPACT
```

---

# TOP OPPORTUNITIES (max 7)

For each:

```
Opportunity:
Observed evidence:
Owner:
User value:
Architectural leverage:
Effort:
Risk:
Why now:
What NOT to build:
```

---

# RECOMMENDED NEXT MOVE

```
NEXT DOPAMINE MOVE
    ...

NEXT ARCHITECTURAL MOVE
    ...

NEXT DAILY-USE MOVE
    ...
```

(These may be the same item. If different, explain why.)

---

# WAVE 4 DECISION

Choose one:

- A. TEMPER REAL RUN WORKBENCH v0 NEXT
- B. REPOSITORY RECON METHOD IMPROVEMENT BEFORE TEMPER
- C. KILN ACCEPTANCE / PROJECTION IMPROVEMENT BEFORE TEMPER
- D. NEW LOADOUT CAPABILITY SHOULD PRECEDE TEMPER
- E. CONTRACT ADJUDICATION REQUIRED FIRST
- F. TARGETED WAVE 3 REPAIR REQUIRED

(Use the acceptance run as product research, not the pre-existing roadmap.)

---

# FINAL PRINCIPLE

The acceptance run is not only asking:

> Did Wave 3 work?

It is also our first serious chance to ask:

> Now that it works, what is the system trying to become?

Use every observed success, limitation, unknown, awkward interaction, and natural operator reaction as evidence. Do not manufacture roadmap work. Let usage reveal it.
