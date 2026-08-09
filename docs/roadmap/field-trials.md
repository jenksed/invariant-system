# Arsenal Field Trials & Continuous Competence Roadmap

Status: active cross-cutting program

Starts: immediately after ARS-08

This document defines when Project Arsenal stops being only a system we build and becomes a system we actively use to build Arsenal and other software.

It does not establish a competing program frontier. The canonical numbered sequence remains `docs/roadmap/capability-system.md`. Field Trials run across that sequence and turn each new slice into evidence about whether Arsenal is actually useful.

The first named external target is **Kiln**. The detailed Kiln-specific operating plan lives in `docs/roadmap/kiln-field-trial.md`. Arsenal is used to help develop Kiln; it is not added to Kiln's product/runtime merely because it participates in the engineering process.

## Line in the sand

> **From ARS-09 onward, Arsenal must participate in building Arsenal and progressively earn the right to steer real external work.**

The project should no longer wait for the complete architecture before dogfooding.

There are two adoption lines:

1. **Dogfood starts now.** ARS-09 itself is the first formal Field Trial. Arsenal runs alongside the normal engineering workflow, initially read-only/shadow-mode, and records what it would have contributed, prevented, requested, or misunderstood.
2. **Default real-work adoption begins after ARS-10 acceptance.** At that point the pilot has durable Knowledge Plane state plus Intent Compiler routing on top of the already-delivered Capability Graph, Reality Budget, Evidence Observatory, Trust & Authority Plane, compiler, lockfile, and Bench. Selected real feature/bug work should enter through Arsenal by default rather than treating Arsenal as an optional sidecar.

Kiln may begin a read-only baseline/shadow observation during ARS-09 because that does not route or authorize implementation. **Assisted Kiln development begins only after ARS-09 acceptance and only for work Kiln itself has explicitly authorized.** This lets ARS-10 be designed against real usage without using Arsenal as a backdoor around Kiln's authority model.

## Field Trial progression

### FT-0 — Shadow Dogfood

**Starts:** while building ARS-09.

**Repository:** Project Arsenal itself, plus read-only Kiln baseline/shadow observations under `docs/roadmap/kiln-field-trial.md`.

The ordinary engineering workflow remains operational authority. Arsenal participates without controlling the work.

For representative ARS-09 work:

- establish Repository Truth;
- record the task/objective and current repository state;
- capture relevant capability, authority, context, evidence, and outcome data through existing Arsenal contracts where available;
- produce a shadow view of missing knowledge, likely route, proof obligations, and friction;
- record human corrections, repeated reads/commands, scope confusion, stale assumptions, missing invariants, and unnecessary rediscovery;
- compare Arsenal's shadow recommendations with what the successful implementation actually required.

For Kiln during FT-0, Arsenal is read-only and must preserve Kiln's own authorization hierarchy. A correct result may be `implementation not authorized`; shadow observation does not grant permission to proceed.

No shadow recommendation may create authority, block ordinary work, or claim efficacy merely because it appears reasonable.

**Exit evidence:** at least one real ARS-09 implementation slice has a reconstructable field-trial record and concrete observations that feed the Knowledge Plane design, plus at least one Kiln read-only shadow episode exercising the external authority/context boundary.

### FT-1 — Assisted Kiln Pilot

**Starts:** after ARS-09 acceptance.

**Repository:** `jenksed/kiln`, the first named external Field Trial target.

Detailed operating contract: `docs/roadmap/kiln-field-trial.md`.

Start with low-risk, high-observability behavior rather than immediately letting Arsenal control implementation:

- Repository Truth;
- Resume/continuation;
- Verify;
- trust/provenance inspection for imported competence;
- Knowledge Plane context compilation;
- existing competence lock/distribution surfaces that are genuinely supported.

Then expand Pressure Test, Recon, Diagnose, TDD, Review, and other capabilities only when Kiln has a real authorized task that requires them.

Kiln's own accepted plans, preflight, invariants, authorization boundaries, ticket gates, and completion Evidence remain authoritative. Arsenal may advise, record, compare, and later route; it does not manufacture Kiln authorization.

The pilot should collect real friction and corrections. It should not manufacture busywork to make Arsenal look useful.

**Exit evidence:** repeated real Kiln tasks show which context/knowledge/capability surfaces help, which create overhead, and what ARS-10 must route or reject.

### FT-2 — Routed Work

**Starts:** after ARS-10 acceptance.

This is the **default-real-work line**.

For selected Kiln task classes and later pilot repositories, a feature/bug objective enters through Arsenal first:

```text
objective / authorized ticket
→ relevant knowledge subgraph
→ intent compilation
→ capability route
→ capability-gap preflight
→ trust/authority gate
→ reality-budget selection
→ execution / normal harness work
→ evidence / verification
```

For Kiln, the Intent Compiler must treat current Kiln implementation authorization as a hard input. `Planned but unauthorized` compiles to an owner/blocking frontier, not a write route.

Arsenal may recommend or compose write-capable work only inside already-authorized capability and repository boundaries. It does not gain production access, secrets, remote-cloud authority, or other consequential authority merely because it routes the task.

Control/treatment or shadow comparisons remain required so we can detect when Arsenal adds ceremony without improving outcomes.

### FT-3 — Evidence-Gated Completion

**Starts:** after ARS-11 acceptance.

For selected representative task classes:

- material acceptance criteria resolve to evidence;
- builder and verifier independence is structural where useful;
- counterexample/adversarial obligations run when the declared risk warrants them;
- a completion claim can fail even when the implementation agent says it is done;
- extra agents must earn their cost through Bench/Field Trial evidence rather than being added for theater.

On Kiln, this strengthens the evidence feeding Kiln's own accepted completion gates rather than creating a second completion authority.

### FT-4 — Controlled Hardening

**Starts:** after ARS-12 acceptance.

Real observed friction may create improvement candidates:

```text
run / review / incident
→ friction event
→ recurring pattern
→ mechanization or capability proposal
→ quarantine
→ baseline + treatment evaluation
→ regression + adversarial evaluation
→ human review
→ promote or reject
```

Arsenal may observe, classify, propose, implement in quarantine, and produce evidence.

It may not silently rewrite doctrine, increase its authority, replace an accepted capability, hide losses, or promote itself.

For Kiln specifically, an Arsenal-generated improvement to Kiln instructions, tests, scripts, architecture, or workflow must still enter Kiln through the normal Kiln change/authorization process.

### FT-5 — Agent Behavioral CI / AX

**Program owner:** ARS-13.

Once Field Trials have produced real representative tasks, repositories can begin regression-testing themselves as environments for machine contributors.

Kiln is the first intended deep AX tracer because it already has explicit authority order, preflight, invariants, bounded plans, deterministic gates, continuation expectations, and agent-facing instructions.

The question becomes not only:

> Does the code still work?

but also:

> Can an unfamiliar appropriately equipped agent still discover, change, test, verify, and continue work in this repository without unacceptable confusion or waste?

This must use representative behavioral cases rather than a vanity 0–100 score.

## Testing method

Field Trials reuse Arsenal Bench and the Agent Flight Recorder rather than inventing a separate evaluation system.

Same-task replay is not always methodologically valid because the first run changes repository state and leaks knowledge. Prefer, depending on the case:

- read-only shadow runs alongside normal work;
- matched task pairs;
- held-out variants from the same task family;
- randomized treatment assignment when practical;
- before/after comparisons only when repository drift is controlled and disclosed;
- explicit ablation of individual capability/context sources.

Every comparison should preserve what actually ran. An unexecuted control remains unexecuted.

Useful measures include:

- externally verified task success;
- false-completion rate;
- human interventions and corrections;
- scope drift;
- repair cycles;
- repeated file reads and repeated commands;
- context bytes/tokens and irrelevant-context share when observable;
- wall time and model/tool cost;
- authority escalation attempts;
- verification coverage against acceptance criteria;
- continuation/resume rediscovery;
- environment/setup failures;
- capability gaps and routing failures;
- friction events that recur across runs.

Kiln additionally emphasizes authorization-boundary correctness, native-preflight compliance, stale-plan selection, accepted-ticket scope, and Kiln-native completion Evidence.

Losses and overhead are first-class results.

## Where the new concepts belong

The following ideas are intentionally assigned to existing or future owners instead of becoming a parallel pile of skills.

### ARS-09 — Knowledge Plane

ARS-09 should make these first-class durable knowledge where evidence supports them:

- **Negative Knowledge** — rejected architectures, known traps, unsafe shortcuts, and approaches intentionally not chosen;
- **Decision Provenance** — what was decided, supporting/challenging evidence, and why reconsideration may become necessary;
- **Unknowns** — unresolved questions that must not silently harden into assumptions;
- **Exceptions** — intentional rule violations with rationale and reconsideration conditions;
- **Invariant** and **Requirement** relationships;
- **Incident** and **Observation** links;
- **Reconsideration Trigger** — including the ARS-08 trust triggers already emitted;
- **Friction Event** — observable wasted effort/correction suitable for later mining;
- **Competence Expectation** — a task an appropriately equipped agent is expected to perform in the repository.

ARS-09 should compile task context from the relevant subgraph, not dump all durable knowledge into every run.

Kiln is the first external Knowledge Plane tracer: its accepted-vs-planned authority, negative knowledge, explicit invariants, required start sequence, and reconsideration boundaries should validate that the knowledge model preserves authority rather than merely extracting facts.

### ARS-10 — Intent Compiler

ARS-10 should consume typed knowledge and produce bounded work rather than a prose plan.

Concepts that fit here:

- objective → validated capability route;
- task-specific context compilation;
- **Scope Guard** as a route/intent invariant: compare requested outcome with proposed/actual work and surface unexplained expansion;
- explicit frontiers for unresolved decisions/unknowns;
- Capability Gap Preflight;
- ARS-08 `route_gate.authorized` consumption;
- evidence-based model/harness routing only where comparable evidence exists.

Named agents should remain compositions of capabilities + authority + evidence/stopping rules, not persona prompts. ARS-10 can eventually emit such a composition; the Capability Graph and Trust Plane remain the authority.

Kiln is the first external Intent Compiler tracer. A planned-but-unauthorized Kiln objective must compile to a blocked owner frontier; an authorized bounded Kiln ticket may compile to a route only when its prerequisites, capability availability, authority, and proof path all hold.

### ARS-11 — Adversarial Verification

ARS-11 should own the strongest claim-challenge ideas:

- **Proof Graph** — requirement → decision → implementation → test → evidence → claim;
- **Acceptance Trace** — every material acceptance criterion resolves to evidence or remains explicitly unproven;
- **Counterexample Hunt**;
- hostile completion review;
- architecture challenge;
- capability ablation;
- **Capability Fuzzer** for perturbing task wording/context/repository state to expose brittleness;
- independent verifier composition;
- failure laboratories.

Builder must not automatically verify Builder. Independence should be structural when the risk/evidence contract requires it.

Kiln's existing acceptance criteria, deterministic gates, future independent Verifier Child direction, and Evidence/Receipt distinctions make it a demanding external tracer for these contracts.

### ARS-12 — Controlled Capability Evolution

ARS-12 is where the self-hardening loop from real work becomes concrete.

Signature capabilities/concepts:

- **Friction Miner** — aggregate Flight Records, corrections, retries, CI failures, and Friction Events into recurring patterns;
- **Mechanize** — ask whether a recurring correction should become a test, lint, type, schema, script, policy, CI gate, deterministic tool, or capability change;
- **Review-to-Rule** — turn recurring review corrections into candidate prevention mechanisms;
- **Incident-to-Invariant** — turn escaped failures into regression tests, invariants, observability, or capability changes;
- **Invariant Miner** — propose implicit rules discovered across accepted code/tests/history;
- **Toolsmith** — recognize when a tiny deterministic tool beats another prompt;
- **Capability Doctor** — distinguish method failure, missing context, tool failure, authority restriction, environment failure, model weakness, and bad evaluation;
- **Capability Regression** — rerun representative behavioral cases on capability/instruction/tool changes;
- **Behavior Bisect** — use lockfiles, Flight Records, and evaluation history to isolate the change associated with a behavioral regression.

These systems may produce candidate changes and evidence. Promotion stays human-controlled.

Kiln Field Trial evidence becomes one real source for those candidates; it does not grant Arsenal permission to modify Kiln automatically.

### ARS-13 — Agent Behavioral CI & Agent Experience

ARS-13 should become a first-class post-core slice rather than hiding this concept inside ARS-12.

**Goal:** regression-test a repository as an environment for agents.

Candidate surfaces:

- **Fresh Eyes** — clean/minimal-context agents attempt representative repository tasks;
- **Agent Experience (AX) Audit** — profile discoverability, determinism, feedback quality, environment reproducibility, boundary clarity, verifiability, context efficiency, and continuity;
- **Instruction Audit** — detect stale/conflicting/ineffective AGENTS.md, harness instructions, skills, and steering material;
- **Context Ablation** — test with/without context sources to determine what actually changes outcomes;
- **Contradiction Hunter** — detect incompatible rules across instructions, doctrine, code reality, CI, capabilities, and docs;
- **Repository Competence Contract** — explicit behavioral expectations for what an appropriately equipped unfamiliar agent should be able to do;
- behavioral CI cases that run when repository layout, tooling, agent instructions, architecture, Development Packs, or capability packages change.

Do not collapse AX into one vanity score. Emit a profile with receipts and representative failing/passing cases.

Kiln should be the first deep Repository Competence Contract because its current agent rules already state concrete expectations that can later become behavioral cases.

## Capability expansion lane

Several ideas are valuable but do not justify new core architecture yet. Add them as normal capabilities/packs when Field Trial evidence shows recurring demand:

- Failure Reducer;
- Environment Parity;
- Rollback Proof;
- Architecture Fitness;
- Contract Guardian;
- Dependency Skeptic;
- Operational Readiness;
- specialized Scope Guard implementations;
- change-specific threat modeling;
- preview/browser evidence capture;
- migration safety and recovery checks.

The rule is demand-driven growth: do not add a capability because it sounds good. Add it because observed Arsenal/Kiln work or evaluation shows a recurring competence gap.

## The continuous competence loop

The long-term loop is:

```text
Agent works
   ↓
Flight Record + field evidence
   ↓
Friction Events / human corrections / incidents
   ↓
Friction Miner
   ↓
classify the gap
   ├── context / knowledge
   ├── method / capability
   ├── deterministic mechanism
   ├── tool / environment
   └── evaluation defect
   ↓
Mechanize / capability candidate / tool candidate
   ↓
quarantine + Trust & Authority
   ↓
Arsenal Bench + adversarial/regression evidence
   ↓
evidence says better?
   ├── NO → retain the loss / reject
   └── YES → human approval
                 ↓
          compile + lock + distribute
```

The north star is not autonomous self-modification.

It is:

> **Turn recurring agent friction, mistakes, discoveries, and human corrections into permanent, evidence-backed engineering infrastructure.**

## Non-negotiable adoption rules

1. Arsenal never marks itself useful because it was used; improvement requires comparison or defensible evidence.
2. Dogfooding does not weaken ordinary repository verification.
3. A field trial may not silently gain authority to make the test easier.
4. Raw private chain-of-thought is not required for friction analysis.
5. Human correction is evidence, not an automatic rule; recurring corrections become candidates for Mechanize/Bench.
6. No feature becomes a core capability merely because it has a memorable name.
7. If Arsenal creates material ceremony, latency, token cost, or false confidence without better outcomes, record that as a loss.
8. External adoption expands only after the previous phase has produced usable evidence.
9. Kiln remains a separate product boundary: Arsenal can help develop it without becoming Kiln runtime architecture.
10. Kiln's accepted authority always outranks an Arsenal recommendation about Kiln work.
