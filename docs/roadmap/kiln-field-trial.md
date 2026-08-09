# Kiln Development Field Trial

Status: planned external dogfood program

Program: Arsenal Field Trials

Target repository: `jenksed/kiln`

Purpose: use Project Arsenal to improve and evaluate the **development of Kiln** without adding Project Arsenal to the Kiln product itself.

## 1. Boundary

This is an engineering-process pilot, not a Kiln integration project.

Project Arsenal may:

- inspect Kiln repository truth;
- compile task-relevant context outside the Kiln runtime;
- model durable project knowledge about Kiln;
- propose capability routes;
- preflight competence and authority;
- select an appropriate Reality Budget;
- help structure planning, diagnosis, TDD, review, verification, and handoff;
- record Flight Records and field-trial evidence outside the Kiln product boundary;
- compare assisted work with baseline/shadow/control evidence;
- identify recurring friction and later propose mechanization candidates.

Project Arsenal may **not**, merely because this field trial exists:

- become a Kiln runtime dependency;
- add an Arsenal subsystem to Kiln;
- change Kiln product architecture to accommodate Arsenal;
- commit `.arsenal.lock`, Arsenal packages, Arsenal telemetry, or Arsenal runtime state into Kiln solely for the pilot;
- change Kiln CI solely to make Arsenal easier to test;
- change `AGENTS.md`, `CLAUDE.md`, roadmap authority, accepted plans, ADRs, or project invariants merely to make Arsenal's route succeed;
- bypass Kiln's existing preflight, branch grammar, ticket gates, owner approvals, acceptance Evidence, or authorization hierarchy;
- treat a planned Kiln ticket or proposed roadmap item as authorization to implement it;
- grant a development agent authority that Kiln itself forbids;
- automatically commit, push, merge, publish, deploy, or mutate production state.

If a future Arsenal capability belongs in the Kiln product, that is a separate Kiln product decision and must enter Kiln through Kiln's own roadmap and authorization process.

## 2. Current Kiln authority snapshot

At field-trial design time:

- Kiln `main` is `ad319d7c748a6b723b9cff4187fa06c60bc3cf06`;
- P1-S01 is integrated and owner-accepted;
- P1-S02 is planned but not authorized;
- Prompt 8-A remains the current build-authorization authority;
- Kiln explicitly states that a named ticket, planning document, passing planning CI, JSON Schema, specification, or proposed ticket sequence does not independently authorize implementation;
- planned work begins with Kiln's own `scripts/agent-preflight` and `scripts/test-agent-preflight` plus the accepted-plan / doctrine / ADR / invariant / source / test / Git / Evidence inspection sequence;
- project-local development Skills are subordinate to current repository authority.

The field trial therefore has a useful first trust invariant:

> **Arsenal must be able to understand planned Kiln work without turning planned work into authorized work.**

A correct Arsenal result may be: `STOP — implementation not authorized yet`.

That is success, not a routing failure.

## 3. Operating topology

Arsenal remains an external engineering sidecar:

```text
Project Arsenal repository
  ├── capability contracts
  ├── Knowledge Plane / field-trial records
  ├── Bench / comparison evidence
  ├── Flight Records
  └── pilot configuration / receipts

                read / advise / measure
                         ↓

Kiln repository + normal development harness
  ├── Kiln authority documents
  ├── current accepted work package
  ├── source / tests / Git state
  ├── existing Kiln preflight and gates
  └── normal branch / PR / acceptance process
```

The development harness may be Claude Code, Codex, MiniMax, or another normal operator tool. Arsenal is not a replacement model or harness.

Where a supported Arsenal distribution already exists, prefer a non-invasive installation path. For example, Repository Truth may be consumed through a supported user-global Agent Skills installation when the active harness supports that format.

Do not commit a project-local Arsenal package to Kiln merely to run the pilot.

For capabilities that do not yet have a compiler-backed package for the active harness, use their canonical Arsenal contract/method through the operator workflow. Do not invent an unverified harness adapter to make the field trial look more complete.

## 4. Evidence placement

Field-trial evidence belongs in Arsenal or in external ephemeral working storage, not in Kiln product state.

Preferred durable shape once ARS-09 defines the required schemas:

```text
field_trials/
  kiln/
    manifest.json
    baselines/
    runs/
    comparisons/
    friction/
```

Until those contracts exist, this document is the plan; do not create speculative data files just to fill the directory.

Durable records should prefer:

- Kiln repository URL;
- exact commit SHA;
- branch / PR / ticket identifiers;
- path + digest references to governing Kiln documents;
- capability IDs/versions;
- model/harness identity;
- authority profile and Trust Decision references where applicable;
- Reality Budget selection;
- evidence/receipt references;
- measured process/outcome metrics;
- human correction records;
- explicit limitations.

Do not copy private prompts, secrets, environment dumps, or raw chain-of-thought into field-trial evidence.

Do not duplicate large Kiln source artifacts into Arsenal when a path + commit + digest reference is sufficient.

## 5. Rollout phases

### KFT-0 — Baseline and read-only observation

**Timing:** begin during ARS-09.

**Control:** normal Kiln development process remains the sole operational process.

**Arsenal authority:** read-only observation and analysis.

**Kiln mutation:** none because of the field trial.

This phase may begin before ARS-09 is accepted because it does not route or authorize Kiln implementation.

#### Step 0.1 — Freeze the initial observation point

For each observation session:

1. record exact Kiln `main` SHA;
2. record active branch/PR if one exists;
3. record dirty/clean state when operating from a local checkout;
4. record which Kiln planning/authorization document currently governs the requested work;
5. record the Arsenal version/commit used for the observation;
6. do not assume a previous field-trial record is current.

The first planned baseline is `ad319d7c748a6b723b9cff4187fa06c60bc3cf06` unless Kiln moves before execution.

#### Step 0.2 — Run Repository Truth against Kiln's authority hierarchy

The shadow audit should establish at minimum:

- current integrated slice;
- current authorized vs planned frontier;
- current accepted work plan, if any;
- current Git state;
- applicable invariants/ADRs;
- current tests/gates relevant to the requested work;
- explicit exclusions;
- statements in historical docs that no longer control current work.

Repository Truth must preserve Kiln's authority order rather than flattening all documents into equally trusted context.

#### Step 0.3 — Seed ARS-09 knowledge from authoritative Kiln facts

Create candidate typed knowledge from the smallest useful source set.

Priority initial entities:

- `Decision`: P1-S01 integrated and accepted;
- `Decision` / authorization boundary: P1-S02 planned but unauthorized;
- `Requirement`: Kiln required start sequence;
- `Invariant`: model may propose a Patch but cannot approve/apply its own Patch;
- `Invariant`: completion requires current Evidence, not model confidence;
- `Invariant`: capability availability, policy allowance, explicit grant, and user Approval are distinct;
- `NegativeKnowledge`: do not pull TUI, managed worktrees, generic capability broker, protocols, telemetry export, containers/remote execution, auto commit/push/merge, and other explicitly deferred surfaces into the current Kiln boundary;
- `Unknown`: unresolved P1-S02 implementation details that remain planning inputs rather than decisions;
- `ReconsiderationTrigger`: accepted authorization change, governing-plan change, canonical invariant/ADR change, or new owner Evidence;
- `CompetenceExpectation`: an appropriately equipped development agent should discover the current authorization boundary before implementation;
- `CompetenceExpectation`: an agent should run Kiln preflight before planned work;
- `CompetenceExpectation`: an agent should distinguish current from proposed behavior and state expected mutation/verification surfaces.

These are candidate knowledge entries until ARS-09's schema/evidence rules validate them.

#### Step 0.4 — Establish a retrospective baseline from P1-S01

Use existing P1-S01 history only as a **non-causal historical baseline**.

Potential evidence sources:

- accepted P1-S01 plans;
- PRs #40–#46 and their review/CI history where relevant;
- final acceptance Evidence;
- branch/ticket closeout records;
- repeated planning corrections and reconciliations;
- known places where work had to be restarted or re-explained.

Extract only defensible observable measures, such as:

- number of correction cycles;
- PR repair iterations;
- CI failures attributable to process/setup vs implementation;
- rediscovery events visible in handoffs or repeated repo inspection;
- authority/scope corrections;
- stale-plan/document conflicts;
- verification omissions caught before merge;
- time-to-reconstruct continuation state where observable.

Do **not** label P1-S01 vs Arsenal as a control/treatment experiment. The repository, tasks, tooling, model behavior, and operator knowledge differ.

The baseline is useful for generating hypotheses and metric definitions, not causal marketing claims.

#### Step 0.5 — Shadow the next Kiln planning/reconciliation task

Because P1-S02 is currently unauthorized, the first prospective Kiln shadow trial should be a planning/authorization/reconciliation task, not runtime implementation.

Arsenal should independently produce:

- repository truth summary;
- relevant Knowledge Plane subgraph;
- proposed capability route;
- capability gaps;
- authority result;
- proposed Reality Budget;
- proof obligations;
- explicit blocker if implementation authority is absent;
- likely friction/unknowns.

The normal Kiln workflow proceeds separately.

Compare afterward:

- what Arsenal surfaced that mattered;
- what Arsenal missed;
- what Arsenal incorrectly elevated;
- unnecessary context it requested;
- false blockers;
- whether it correctly refused unauthorized implementation;
- human corrections required.

#### KFT-0 exit gate

KFT-0 passes when:

1. at least one real Kiln shadow task has a reconstructable field-trial record;
2. Arsenal correctly preserves the Kiln authorization boundary;
3. no Kiln product/repository change was required just to run the trial;
4. at least one concrete Knowledge Plane design input came from real Kiln use;
5. observed overhead/losses are recorded, not hidden.

Failure to recognize that P1-S02 is unauthorized is an immediate KFT-0 failure.

---

### KFT-1 — Assisted development pilot

**Timing:** after ARS-09 acceptance and after Kiln itself explicitly authorizes the relevant work.

**Control:** Kiln's accepted plan and normal development harness remain operational authority.

**Arsenal role:** assisted context, competence, proof, and evidence sidecar.

**Kiln mutation:** performed by the normal authorized development workflow, not by an Arsenal autonomous mutation layer.

If Kiln still has no authorized implementation ticket at this point, continue with planning/reconciliation work; do not manufacture an implementation pilot.

#### Step 1.1 — Select the first authorized Kiln task

Choose the smallest bounded real task that:

- is explicitly authorized by Kiln's own accepted plan;
- has clear acceptance criteria;
- has deterministic or independently inspectable verification;
- has limited blast radius;
- does not require production, secret, remote-cloud, or other exceptional authority;
- is representative enough to reveal context/routing friction.

Do not choose a toy task created only for Arsenal.

Do not jump from “P1-S02 is authorized” to “Arsenal may implement all of P1-S02.” Follow the exact authorized ticket sequence.

#### Step 1.2 — Run the Kiln native start sequence first

Before Arsenal assists implementation:

1. run `scripts/agent-preflight`;
2. run `scripts/test-agent-preflight`;
3. read the accepted plan;
4. read engineering doctrine for unresolved material choices;
5. list applicable ADRs and `KILN-INV-*` invariants;
6. inspect current source/tests/Git/dependency direction;
7. distinguish current vs proposed behavior;
8. state expected mutation surface;
9. state narrow verification and complete required gate.

Arsenal consumes these outputs. It does not replace them.

If Kiln preflight fails, Arsenal records the failure and stops the assisted route. It does not route around it.

#### Step 1.3 — Compile the task-specific Arsenal knowledge view

ARS-09 should return the minimum relevant subgraph:

- accepted objective/criteria;
- governing plan/ticket;
- requirements;
- invariants;
- decisions and rejected alternatives;
- known exceptions;
- unresolved unknowns;
- relevant negative knowledge;
- prior evidence/observations;
- reconsideration triggers.

Measure how much context is excluded as well as included.

The objective is not to create a better history dump. It is to reduce rediscovery and stale context.

#### Step 1.4 — Run Capability Gap Preflight in advisory mode

For the first assisted tasks, Arsenal should identify the likely route using existing capabilities such as:

- Repository Truth;
- Pressure Test when consequential ambiguity exists;
- Recon for unresolved multi-session frontier work;
- Diagnose for failing behavior;
- TDD for implementation behavior where appropriate;
- Review;
- Verify;
- Resume for continuation/handoff.

During KFT-1 this route is advisory. If Arsenal proposes a route Kiln's accepted work package contradicts, Kiln authority wins and the mismatch becomes field-trial evidence.

Record:

- capabilities selected;
- capabilities missing;
- capabilities present but insufficiently qualified;
- why a capability was not used;
- where the normal agent had to improvise because Arsenal lacked competence.

#### Step 1.5 — Preflight authority separately

Translate the assisted route into required authority and compare it with Kiln's allowed workflow.

Important Kiln-specific rules include:

- model has no direct mutation Tool;
- exact Patch proposal precedes user Approval;
- model cannot approve/apply its own Patch;
- no automatic commit/push/merge;
- command execution follows registered-command policy when within Kiln runtime work;
- project-local skills are subordinate to repository authority.

The field trial must not confuse “development agent can edit the checkout under the normal engineering workflow” with “Kiln runtime model is authorized to mutate source.” Those are different layers.

Any ambiguity about which layer is acting becomes a Friction Event / Knowledge Plane issue.

#### Step 1.6 — Select proof with Reality Budget

For every material claim, ask what the least expensive sufficient world is.

Examples:

- schema/pure-function behavior → deterministic/in-process tests;
- Elixir behavior → normal local Mix tests where sufficient;
- integration behavior → local process/dependency world only if needed;
- container execution → only when the proof requirement justifies it;
- no remote/staging/production escalation merely because tooling exists.

Arsenal's selected substrate is advisory in KFT-1, but divergence from the actual successful verification should be captured.

#### Step 1.7 — Execute through the normal Kiln development harness

The chosen coding agent/harness performs the authorized work using the accepted Kiln plan.

Arsenal does not require a model switch merely for the experiment.

Record exact:

- model;
- harness;
- starting commit;
- capability assistance actually used;
- context supplied;
- human interventions;
- tool/command failures;
- patch/review iterations;
- final verification.

If multiple models/harnesses are used, record each contribution rather than treating the whole task as one anonymous agent.

#### Step 1.8 — Run Review and Verify as separate evidence stages

Where practical:

- implementation agent performs the build;
- review is a distinct step against actual diff/acceptance criteria;
- verification resolves the material criteria to current evidence;
- completion remains governed by Kiln's existing accepted gates.

ARS-11 later strengthens independence/adversarial requirements. KFT-1 should not fake that maturity early.

#### Step 1.9 — Emit a Field Trial / Flight Record

Record:

- objective/ticket;
- Kiln authority sources and digests;
- starting/final repository SHA;
- model/harness;
- Arsenal capability versions;
- Knowledge Plane entities consumed;
- authority assumptions/results;
- Reality Budget proposal;
- evidence references;
- outcome;
- human corrections;
- friction events;
- limitations;
- whether Arsenal materially changed the route or merely documented it.

#### Step 1.10 — Compare against a defensible baseline

Do not rerun the exact implementation task after learning its solution and call that a control.

Prefer one of:

- matched authorized Kiln tickets with similar risk/size;
- held-out variants from the same task family;
- shadow Arsenal on one task and assisted Arsenal on a later comparable task;
- capability/context ablation on read-only planning/review tasks;
- alternating treatment assignment for a series of sufficiently similar small tickets.

Disclose task differences.

#### KFT-1 adoption gate

Do not promote Arsenal from “assisted experiment” to default Kiln entry merely because several tasks completed.

Require a minimum prospective evidence package such as:

- at least 3 real assisted Kiln episodes across at least 2 task types;
- at least 1 episode involving continuation/resume or handoff;
- at least 1 episode where Arsenal surfaces a real blocker, scope issue, knowledge gap, or verification obligation — or explicit evidence that it did not;
- zero cases where Arsenal caused unauthorized implementation to proceed;
- every episode has exact start/end repository identity and outcome evidence;
- overhead is measured, including cases where Arsenal added no value;
- at least one comparison/ablation design is strong enough to influence ARS-10 design decisions.

This is a minimum evidence package, not a success quota. Negative episodes can justify shrinking or redesigning Arsenal rather than promoting it.

KFT-1 should answer:

- Did Arsenal reduce rediscovery?
- Did it catch authority/scope mistakes before implementation?
- Did it improve acceptance/verification coverage?
- Did it reduce or increase correction cycles?
- Did it add context/token/tool overhead?
- Which capabilities were actually used?
- Which planned capabilities were irrelevant?
- What missing capability/knowledge repeatedly hurt?

There is no requirement that Arsenal “wins.” A measurable loss is acceptable evidence; hiding it is not.

---

### KFT-2 — Arsenal-routed Kiln work

**Timing:** after ARS-10 acceptance and after KFT-1 produces usable evidence.

This is the Kiln-specific **default-use line**.

For selected authorized Kiln task classes, the operator begins with Arsenal:

```text
Kiln objective / authorized ticket
        ↓
Repository Truth
        ↓
relevant Kiln Knowledge Plane subgraph
        ↓
Intent Compiler
        ↓
validated capability route
        ↓
Capability Gap Preflight
        ↓
Trust / authority gate
        ↓
Reality Budget
        ↓
normal coding harness executes
        ↓
review / verification / evidence
        ↓
Flight Record + Kiln-native acceptance process
```

#### Step 2.1 — Intent Compiler must consume Kiln authorization as a hard input

A route is invalid when the requested implementation is not authorized by Kiln.

Examples of correct outputs:

```text
OBJECTIVE UNDERSTOOD
ROUTE POSSIBLE
IMPLEMENTATION AUTHORITY ABSENT
RESULT: BLOCKED / OWNER FRONTIER
```

or:

```text
AUTHORIZED TICKET FOUND
REQUIRED CAPABILITIES PRESENT
AUTHORITY COMPATIBLE
PROOF PATH AVAILABLE
RESULT: READY
```

The model may interpret the objective. It may not synthesize authorization from prose.

#### Step 2.2 — Default Arsenal routing applies only to selected task classes

Initial default-routed Kiln classes should be low/medium-risk engineering work with clear acceptance gates, for example:

- bounded bug repair;
- narrow feature ticket;
- test-backed refactor inside accepted architecture;
- verification/closeout work;
- planning reconciliation;
- resume/continuation.

Keep migrations, high-consequence architecture changes, secret-bearing work, remote execution, release/publishing, and other exceptional surfaces outside the default route until evidence justifies expansion.

#### Step 2.3 — Measure operator bypasses

Every time the operator bypasses Arsenal because it is:

- too slow;
- wrong;
- missing competence;
- asking for irrelevant context;
- blocked on an inaccurate authority interpretation;
- unable to represent the task;

record the bypass.

Bypass rate is a product metric, not operator disobedience.

#### KFT-2 promotion/retention gate

Arsenal earns continued default use only if the routed workflow is operationally competitive with normal work and provides material safety, context, verification, or continuity benefit.

Evaluate after a bounded cohort, initially 5–10 selected routed Kiln tasks or a smaller cohort if the signal is decisive.

Possible outcomes:

- **retain default route** for the task class;
- **retain with narrower capability/context set**;
- **return to assisted mode**;
- **disable Arsenal for that task class**;
- **open a capability/knowledge/evaluation defect**.

Do not make “default” permanent. Later regressions may demote a route.

---

### KFT-3 — Evidence-gated Kiln completion

**Timing:** after ARS-11 acceptance.

Apply to selected Kiln task classes where the evidence contract warrants it.

Add:

- Proof Graph from Kiln criterion/requirement to implementation/test/evidence/claim;
- Acceptance Trace for every material ticket criterion;
- independent verifier where risk justifies it;
- Counterexample Hunt;
- architecture challenge when a boundary is touched;
- explicit unresolved evidence instead of optimistic completion.

Kiln's own acceptance/gate system remains authoritative. Arsenal's role is to strengthen the evidence feeding that system, not create a second completion truth.

Measure whether independent challenge catches real defects often enough to justify its model/tool cost.

---

### KFT-4 — Controlled Kiln hardening

**Timing:** after ARS-12 acceptance.

Use accumulated Kiln Field Trial evidence to identify recurring friction such as:

- repeated confusion about authorization documents;
- repeated failure to run the right gate;
- repeated source/plan rediscovery;
- recurring review correction;
- repeated accidental scope expansion;
- recurring command/environment failures;
- recurring invariant violations;
- repeated context that never changes outcomes.

Then run:

```text
friction event(s)
→ recurring pattern
→ classify
   ├── knowledge/context problem
   ├── capability/method problem
   ├── deterministic-rule opportunity
   ├── tooling/environment problem
   └── evaluation problem
→ Mechanize / capability candidate / tool candidate
→ quarantine
→ Bench / regression / adversarial evidence
→ human decision
```

A candidate improvement to Project Arsenal does not automatically alter Kiln.

A candidate improvement to Kiln's own repo instructions, scripts, tests, or architecture must enter Kiln through its ordinary authority/change process.

This boundary is essential: **Arsenal may learn from Kiln without becoming an unreviewed co-maintainer of Kiln.**

---

### KFT-5 — Kiln Agent Experience / Behavioral CI

**Timing:** ARS-13.

Kiln is an especially strong AX target because it already has explicit authority order, preflight, invariants, bounded plans, deterministic gates, and detailed agent instructions.

Create a Repository Competence Contract containing representative expectations such as:

An appropriately equipped unfamiliar agent should be able to:

- identify the current authoritative planning documents;
- state whether implementation is currently authorized;
- run the correct preflight;
- distinguish accepted behavior from proposed behavior;
- identify relevant invariants/ADRs;
- locate the active ticket and acceptance criteria;
- make one narrow authorized change without crossing excluded scope;
- run the required narrow and aggregate gates;
- produce an evidence-backed completion/handoff;
- resume from a prior handoff without large rediscovery.

Then test repository/instruction/tooling changes against those expectations.

AX dimensions for Kiln should include:

- discoverability;
- authority clarity;
- context efficiency;
- deterministic feedback;
- environment reproducibility;
- boundary clarity;
- verification discoverability;
- error-message usefulness;
- continuation quality.

Do not compress this into a single score.

A strong result is a profile such as:

```text
Authority discovery        PASS
Preflight discoverability  PASS
Ticket discovery           PASS
Verification discovery     WARN — 3 redundant reads
Context efficiency         FAIL — stale historical plan selected first
Continuation               PASS
```

with receipts and representative task evidence.

## 6. Capability rollout matrix for Kiln development

| Arsenal surface | KFT-0 | KFT-1 | KFT-2 | KFT-3+ |
|---|---|---|---|---|
| Repository Truth | shadow | assisted/default read | default | default |
| Knowledge Plane | design tracer | task context | default context compiler input | default |
| Pressure Test | shadow observations | assisted when ambiguity matters | route-selected | route-selected |
| Recon | shadow for planning frontiers | assisted | route-selected | route-selected |
| Diagnose | observe only | assisted on real failures | route-selected | route-selected |
| TDD | observe proof expectations | assisted on authorized code work | route-selected | route-selected |
| Review | shadow | assisted | route-selected | adversarially strengthened |
| Verify | shadow comparison | assisted | default evidence stage | evidence-gated |
| Resume | observe handoff quality | assisted | default continuation | behavioral CI target |
| Capability Gap Preflight | shadow | advisory | gating route input | gating |
| Reality Budget | shadow | advisory | gating route input | gating |
| Dagger world | only if proof requires | proof-gated | proof-gated | proof-gated |
| Flight Recorder | shadow record | required field-trial record | default routed record | default |
| Trust & Authority | inspect imported competence | advisory/gating where applicable | route gate | route gate |
| Intent Compiler | not yet | design from evidence | default selected tasks | default |
| Adversarial Verification | not yet | no fake substitute | not yet | selected tasks |
| Controlled Evolution | record friction only | record friction | record friction | candidate proposals |

## 7. Kiln-specific evaluation design

### 7.1 Primary outcomes

For real Kiln work measure:

- externally verified ticket success;
- compliance with accepted scope;
- authorization-boundary correctness;
- acceptance-criterion evidence coverage;
- false completion;
- review defects found pre-merge;
- CI/gate repair cycles;
- human corrections;
- operator interventions;
- continuation rediscovery;
- task abandonment/bypass.

### 7.2 Efficiency outcomes

When observable:

- wall time;
- model calls;
- token/context volume;
- number of files read;
- repeated reads;
- repeated commands;
- failed commands;
- context discarded as irrelevant;
- number of compactions/session restarts;
- number of model/harness switches.

### 7.3 Safety/process outcomes

- unauthorized implementation attempts;
- forbidden authority requests;
- unexpected mutation surface;
- scope expansion;
- bypassed preflight;
- stale plan selected as authority;
- verification against stale repository state;
- incomplete cleanup/uncertain side effects;
- automatic commit/push/merge attempts.

### 7.4 Continuity outcomes

- time/reads required to resume;
- facts rediscovered vs retrieved from knowledge;
- stale assumptions carried across sessions;
- handoff completeness;
- whether the next agent can identify exact current frontier without re-reading broad history.

### 7.5 Knowledge quality outcomes

- useful knowledge entities retrieved;
- irrelevant entities supplied;
- unknowns incorrectly hardened into facts;
- rejected alternatives rediscovered;
- reconsideration triggers correctly activated;
- authoritative source mismatch;
- human corrections to compiled knowledge.

## 8. Experimental structure

The Kiln pilot should use multiple evidence classes rather than pretend one design proves causality.

### A. Retrospective historical baseline

Use P1-S01 history for hypothesis generation and rough process baselines only.

Label it `RETROSPECTIVE / NON-CAUSAL`.

### B. Prospective shadow evidence

Arsenal observes the same live task without controlling it.

Useful for:

- missed context;
- missed authority boundaries;
- predicted vs actual capability needs;
- predicted vs actual proof needs;
- friction detection.

It does not prove outcome improvement because the shadow recommendations did not necessarily affect execution.

### C. Matched future ticket comparisons

When P1-S02 or later work provides sufficiently similar bounded tickets, compare normal vs Arsenal-assisted episodes with disclosed differences.

### D. Read-only ablations

For planning/review tasks, safely compare:

- full task-relevant Knowledge Plane context;
- broad history dump;
- no Arsenal context;
- individual context-source removal.

This is a strong early way to test context compilation without contaminating source state.

### E. Behavioral regression cases

Once representative Kiln task families exist, freeze held-out variants for later ARS-11/12/13 evaluation.

Never put the exact benchmark answer in the capability package being evaluated.

## 9. Daily operating protocol once KFT-2 starts

For a selected real Kiln task:

1. identify exact Kiln objective/ticket;
2. establish current Git/repository truth;
3. run Kiln-native preflight;
4. verify implementation authorization;
5. retrieve task-relevant durable knowledge;
6. compile intent into a candidate route;
7. run Capability Gap Preflight;
8. verify Trust/authority gate;
9. select Reality Budget;
10. hand the bounded route/context to the normal coding harness;
11. implement only the authorized slice;
12. run narrow verification as work progresses;
13. run Review against actual diff and acceptance criteria;
14. run complete required Kiln gate;
15. resolve material criteria to evidence;
16. create Flight Record / Field Trial record;
17. record human corrections and friction;
18. compare against applicable baseline/treatment evidence;
19. produce normal Kiln closeout/handoff;
20. do not let Arsenal's record substitute for Kiln's required acceptance process.

## 10. Stop / rollback conditions

Reduce or pause Arsenal use on Kiln if any of the following recur:

- it misreads Kiln authorization and pushes unauthorized implementation;
- it causes accepted Kiln authority to be ignored;
- it adds substantial context/tool/model overhead without measurable benefit;
- it creates false confidence about completion;
- it repeatedly selects unnecessary execution substrates;
- it increases scope drift;
- it turns read-only assistance into unreviewed mutation;
- it causes significant agent confusion by duplicating Kiln terminology/contracts;
- field-trial instrumentation starts driving product architecture rather than observing it;
- evidence cannot distinguish Arsenal contribution from ordinary workflow contribution.

Rollback is simple because Arsenal is external: return to the normal Kiln development workflow and retain the failed Field Trial evidence.

## 11. Success criteria

The Kiln pilot is successful when we can defend, with evidence, claims such as:

- an unfamiliar agent reaches the correct Kiln authority frontier with less rediscovery;
- context compilation reduces irrelevant reading without hiding required authority;
- capability/authority preflight catches real mistakes before implementation;
- verification coverage improves or false completion falls;
- continuation quality improves across model/session boundaries;
- recurring friction produces useful mechanization/capability candidates;
- Arsenal's overhead is known and acceptable for the task classes where it is enabled.

It is also a successful experiment if the evidence tells us some Arsenal surface should **not** be in the default Kiln workflow.

## 12. Immediate execution order

Do this in sequence:

### During ARS-09

1. keep PR #21's ARS-09 implementation as the internal FT-0 dogfood;
2. build Knowledge Plane contracts with Kiln's authority/negative-knowledge/unknown/reconsideration cases as one real design input;
3. perform one read-only Repository Truth + knowledge extraction against current Kiln main;
4. record the current `P1-S02 planned but unauthorized` state as a required authorization test case;
5. create the first Kiln shadow field-trial record for a real planning/reconciliation task;
6. use observed Kiln friction to refine ARS-09 rather than inventing generic memory features;
7. do not alter Kiln for the trial.

### Immediately after ARS-09 acceptance

8. select Kiln as the named FT-1 external pilot repository;
9. wait for / verify exact Kiln work authorization before implementation assistance;
10. use Repository Truth + Knowledge context + Verify/Resume first;
11. expand to Pressure Test/Recon/Diagnose/TDD/Review only on real authorized demand;
12. collect the KFT-1 minimum prospective evidence package;
13. feed route/context/authority friction directly into ARS-10 acceptance design.

### During ARS-10

14. use Kiln assisted episodes as real Intent Compiler fixtures;
15. ensure “planned but unauthorized” compiles to a blocked owner frontier;
16. ensure authorized bounded tickets compile to routes that preserve Kiln prerequisites and exclusions;
17. test Scope Guard against Kiln's explicit mutation/slice boundaries;
18. test Capability Gap Preflight against real missing/available competence;
19. do not add model routing until comparative Bench/Flight Record evidence supports it.

### After ARS-10 acceptance

20. promote selected Kiln task classes to KFT-2 default Arsenal entry;
21. record every operator bypass and why;
22. compare routed vs non-routed work honestly;
23. shrink scope if Arsenal is slower/noisier without safety or quality benefit.

### During/after ARS-11

24. add Proof Graph + Acceptance Trace for selected Kiln tickets;
25. add independent verification only where the evidence contract warrants the extra agent/cost;
26. measure defects actually caught by challenge;
27. retain challenge cases that find nothing as cost evidence.

### During/after ARS-12

28. mine accumulated Kiln Flight Records, review corrections, CI failures, and friction events;
29. propose Mechanize / Review-to-Rule / Incident-to-Invariant candidates;
30. evaluate them outside accepted Kiln behavior first;
31. route any Kiln repository change through Kiln's own normal authority and review process;
32. never let Arsenal self-install its own proposal into Kiln.

### ARS-13

33. turn the accumulated representative Kiln tasks into a Repository Competence Contract;
34. run Fresh Eyes agents against held-out tasks;
35. audit Kiln instructions/context with ablations;
36. establish receipt-backed AX profiles;
37. use Behavioral CI to detect when future Kiln changes make the repository materially harder for agents to understand or modify correctly.

## 13. North-star relationship

Kiln is not merely a convenient test repository.

Its existing engineering discipline — explicit authority, durable state, exact Evidence, bounded context, safe mutation, deterministic gates, resumability, and independent verification direction — makes it a demanding environment for Arsenal's claims.

Arsenal should help us build Kiln more reliably **without weakening those rules and without becoming part of the Kiln product merely because it helped build it**.

If that works, it is much stronger evidence than a synthetic demo.