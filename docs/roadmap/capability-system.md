# Project Arsenal Capability-System Roadmap

Status: active program

Current frontier: **ARS-01 — Capability Contract v2**

Project Arsenal is evolving from a reusable library of prompts, methods, workflows, references, and Development Packs into a capability engineering system for making good engineering judgment reusable, composable, executable, evaluable, and governable.

This roadmap is the canonical program-level sequence for that evolution.

Provider- or pack-specific roadmaps may define their own tracer slices, but they must not establish a competing project frontier. Their remaining work should feed the program slice that owns the relevant cross-cutting capability.

## Product thesis

Project Arsenal should be useful before a reader understands its architecture.

Publicly:

> **Stop re-teaching your coding agent how to work.**
>
> **Reusable engineering judgment for coding agents.**

Technically, Arsenal is building toward:

> **A harness-neutral capability engineering system for specifying, composing, executing, evaluating, governing, and improving intelligent work.**

The primary technical unit becomes a **Capability**: a versioned, evidence-backed contract describing a useful outcome, what it needs, what authority it requires, where it may operate, and what proof is required before success may be claimed.

Prompts, methods, workflows, scripts, Development Packs, receipts, policies, evaluators, harness adapters, and runtime integrations become implementations, supporting assets, or exports of capabilities rather than independent organizing centers.

## Program rules

1. **Public value before architecture.** Show recognizable engineering failures and useful capabilities before asking users to understand the capability system.
2. **Reality labels are mandatory.** Public claims must resolve to working implementation, current contract, clearly labeled building work, or clearly labeled frontier research.
3. **Prototype before compiler.** Manually prove a useful distribution path before automating exports.
4. **Determinism over repeated judgment.** Use schemas, routers, evaluators, policy, tests, and typed relationships where they can decide reliably.
5. **Models interpret; infrastructure enforces.** Models may resolve fuzzy intent. Deterministic machinery validates capability availability, authority, evidence, lifecycle, and composition.
6. **Use only as much reality and authority as the evidence requires.** Execution escalates deliberately from low-blast-radius local surfaces toward higher-consequence environments.
7. **Stable is an evidence claim.** Lifecycle promotion must be earned by representative evaluation evidence.
8. **Publish losses.** Arsenal Bench exists to challenge Arsenal, not to manufacture favorable marketing results.
9. **No self-granted authority.** Future capability evolution may propose changes but cannot silently increase its authority, rewrite doctrine, or promote itself.
10. **Build the spine; grow packs in parallel.** Ecosystem-specific Development Packs should prove the shared contracts rather than fork the architecture.

---

# Era I — Make Arsenal understandable and usable

## ARS-00 — Public Surface & Distribution

**Goal:** make Arsenal understandable in seconds, useful in minutes, and technically credible on deeper inspection.

### ARS-00A — README / Operator Console + unified roadmap

**Status:** delivered by PR #11.

Deliver:

- replace the library-first README with a problem-first operator-console public surface;
- lead with recognizable coding-agent failure modes and the capabilities that address them;
- curate a Core Arsenal rather than using the full generated catalog as the storefront;
- explain Model vs Harness vs Arsenal;
- show an Arsenal run, evidence model, lifecycle, and current execution boundary philosophy;
- add `AVAILABLE`, `BUILDING`, and `FRONTIER` truth labels;
- establish this document as the canonical project roadmap;
- reconcile pack-specific roadmaps with the project frontier;
- use **Pressure Test** and **Recon** as public names while preserving current canonical IDs until alias/migration semantics exist.

Proof:

- the README contains no fake CLI or unimplemented distribution claim;
- every major future-facing claim is explicitly labeled;
- a newcomer can understand the problem, current value, and direction without reading `CATALOG.md` first;
- Arsenal Integrity remains green.

### ARS-00B — Flagship quickstart and distribution pilot

**Status:** delivered by the Repository Truth Agent Skills pilot.

Delivered:

- Repository Truth selected as the flagship tracer;
- portable Agent Skills package under `distribution/agent-skills/repository-truth/`;
- thin `SKILL.md` discovery adapter with canonical Arsenal identity/provenance metadata;
- bundled canonical reference snapshot that must remain byte-for-byte identical to `agent_workflows/repository_truth_audit.md`;
- Codex project-local install path at `<repo>/.agents/skills/repository-truth`;
- optional user-global install path at `~/.agents/skills/repository-truth`;
- safe installer that is idempotent for identical state and refuses divergent overwrite;
- deterministic package/spec/source-drift verifier;
- repository-native quickstart and external-format source audit;
- CI acceptance for package shape, install layout, idempotence, non-clobber behavior, and Arsenal Integrity.

Proof:

- the first independent GitHub Actions run passed package validation and the project-local Codex installation contract;
- the installed reference is compared byte-for-byte with the canonical Arsenal workflow;
- the installer proves identical reinstall succeeds without mutation;
- a deliberately divergent installed `SKILL.md` causes exit `3` and remains untouched;
- distribution limitations are explicit: Agent Skills is an export format, Codex project-local is the first verified harness path, and outcome efficacy remains an ARS-02 question.

Compiler regression contract:

ARS-03 must be able to reproduce the ARS-00B package shape from canonical capability data without hand-maintained behavioral divergence.

---

## ARS-01 — Capability Contract v2

**Status:** next slice.

**Goal:** introduce a machine-readable behavioral capability representation while preserving the existing Asset Contract as artifact metadata.

Distinction:

```text
Asset
  = a registered artifact or package in the Arsenal repository

Capability
  = a versioned behavioral contract for a useful outcome
```

Capability Contract v2 should be able to represent:

- identity and version;
- public/display name and compatibility aliases;
- purpose;
- inputs and outputs;
- preconditions;
- context strategy and preferred evidence sources;
- method/reference implementation;
- required, optional, and forbidden authority;
- mutation/blast-radius classification;
- execution substrate requirements;
- verification requirements;
- evidence outputs/receipts;
- evaluation suite;
- provenance;
- compatibility;
- lifecycle.

First migration set:

- Repository Truth;
- Pressure Test (current canonical ID `agent.grill`);
- Recon (current canonical ID `agent.wayfind`);
- Diagnose;
- TDD;
- Review;
- Verify;
- Resume;
- at least one execution-backed Floci capability.

Proof:

- the flagship set can be represented without harness-specific semantics;
- the schema rejects invalid authority, lifecycle, relationship, and evaluation references;
- alias/name migration does not require breaking stable IDs;
- Asset Contract and Capability Contract have a documented non-overlapping responsibility boundary.

---

## ARS-02 — Arsenal Bench & Evaluation Lab v0

**Goal:** measure whether Arsenal actually improves engineering work and make lifecycle promotion executable.

This slice **absorbs the former FLC-06 evaluation/stabilization program**. Floci becomes the first substantial evaluation corpus for the general Arsenal evaluation system rather than receiving a parallel one-off evaluation framework.

Deliver:

- executable evaluation case schema;
- fixture and starting-state conventions;
- control/treatment experiment contract;
- held-out deterministic verifier interface where possible;
- model/harness/tool/budget provenance;
- result and receipt format;
- process, outcome, efficiency, and durability metrics;
- small Arsenal-native evaluation suite;
- FLC-06 scenarios as a Local Cloud evaluation track;
- lifecycle evidence rules for `testing` and later `stable`.

Initial evaluation corpus should emphasize 10–20 strong cases, including:

### Core engineering judgment

- implementation begins before repository truth;
- consequential ambiguity is ignored;
- scope expands beyond the required slice;
- bug is patched without a red-capable reproduction;
- convenient tests are mistaken for acceptance evidence;
- false completion after partial verification;
- poor continuation context causes rediscovery.

### Local Cloud / former FLC-06

- supported green-path feature delivery;
- unsupported operation discovered before implementation;
- documented provider-semantic/fidelity gap;
- dirty persistent-state false positive caught by clean replay;
- missing endpoint/public-cloud fallback prevented;
- LocalStack migration compatibility difference;
- IaC apply succeeds locally while provider-only residue remains;
- snapshot cache invalidation after material input/runtime change;
- multi-cloud routing;
- resolved provider with unsupported higher-level capability;
- agent attempts to request real credentials when local execution is sufficient.

Benchmark tracks:

1. capability isolation;
2. Arsenal Core vs baseline;
3. external benchmark adapters where methodologically appropriate;
4. Arsenal-native engineering-judgment tasks.

Ablation is required for claims about the value of composed Arsenal Core behavior.

Proof:

- control and treatment runs are reproducibly comparable;
- results disclose model, harness, tools, budget, repository state, Arsenal version, verifier, repetitions, and limitations;
- losses are retained and visible;
- at least one existing capability earns `testing` only through recorded evaluation evidence;
- no capability is promoted to `stable` from a single campaign.

---

## ARS-03 — Compiler & Distribution

**Goal:** compile canonical capabilities into downstream harness/distribution formats instead of manually maintaining divergent copies.

Candidate export targets:

- Agent Skills;
- Claude-compatible package;
- Codex-compatible package;
- MiniMax/generic agent package;
- Kiln-native capability package.

Potential CLI surface may include concepts such as lint/build/explain/install, but command names are not public contract until implementation reconnaissance proves the right interface.

Proof:

- ARS-00B's manually proven flagship distribution path is reproducibly generated;
- generated packages preserve capability identity, authority boundaries, references, and evaluation provenance;
- canonical behavior remains harness-neutral;
- generated artifacts are verified rather than hand-edited.

---

# Era II — Turn the library into a capability system

## ARS-04 — Capability Graph

**Goal:** make dependencies, preconditions, outputs, authority, implementation availability, and composition machine-readable.

The graph should answer questions such as:

```text
TDD requires an implementation-ready behavior slice
  ↓ missing
Tracer decomposition produces one
  ↓
route: decomposition → TDD
```

FLC-05 is the tracer precedent: it proved that **provider resolved** and **requested capability available for that provider** are separate facts. ARS-04 generalizes that lesson beyond cloud work.

Start deterministic. Models may interpret fuzzy intent; graph machinery validates legal composition.

Proof:

- routes cannot consume outputs/preconditions that do not exist;
- unsupported capability combinations hard-stop rather than borrowing an unrelated implementation;
- authority requirements propagate through compositions;
- the graph can explain why a route was chosen or rejected.

---

## ARS-05 — Execution Substrate Contract

**Goal:** generalize the Local Cloud execution/fidelity lesson into a portable execution-selection model.

Execution ladder:

```text
pure deterministic function
→ in-process test
→ local process
→ container
→ real local dependency
→ emulator
→ local cluster
→ disposable remote sandbox
→ shared non-production
→ staging
→ production
```

Each substrate contract should describe:

- availability;
- authority;
- isolation;
- fixture/reset behavior;
- reproducibility;
- fidelity;
- evidence;
- teardown;
- escalation rules.

Proof:

- a capability can state what evidence it needs without hard-coding one runtime;
- execution selection prefers the lowest blast radius that can establish the required claim;
- evidence cannot silently jump fidelity levels.

---

## ARS-06 — Dagger / Executable World Pack

**Goal:** give the generalized execution model a strong portable containerized implementation.

Treat Dagger as an adapter/Development Pack, not as Arsenal's architecture.

Use it to begin constructing purpose-built executable repository worlds that may include application code, dependencies, database, browser, cloud emulator, fixtures, and verifiers.

Proof:

- at least one real Arsenal capability runs inside a reproducible disposable world;
- local and CI execution share the same declared behavior where practical;
- the substrate emits normal Arsenal evidence and respects authority boundaries.

---

## ARS-07 — Evidence Observatory

**Goal:** unify receipts, run provenance, evaluation evidence, model/harness usage, and execution traces into a common run model.

Start with data contracts, not a dashboard.

Candidate fields include:

- run ID;
- capability ID/version;
- phase;
- model/harness;
- context sources and token volume;
- tool invocation;
- verification result;
- human intervention;
- wall time and cost;
- accepted/rejected change;
- evidence references.

Map onto OpenTelemetry where appropriate rather than inventing an isolated telemetry ecosystem.

Proof:

- Bench and normal capability execution emit comparable provenance;
- a run can be reconstructed sufficiently to explain what capability/model/tools/evidence produced its outcome;
- telemetry does not contain secrets by default.

---

## ARS-08 — Trust & Authority Plane

**Goal:** make useful action distinct from authority to perform it and make capability/package provenance inspectable.

Capabilities/packages should eventually declare and enforce permissions such as:

- filesystem read/write;
- shell execution;
- network access;
- secrets;
- git mutation;
- cloud sandbox access;
- production access;
- reversibility/mutation class.

External capability ingestion should evolve toward:

```text
discover
→ inspect
→ classify
→ sandbox
→ extract/adapt
→ evaluate
→ register
```

Proof:

- imported capability material cannot silently acquire authority;
- provenance/version/digest are preserved;
- authority escalation is explicit, reviewable, and revocable.

---

# Era III — Durable knowledge and intelligent composition

## ARS-09 — Knowledge Plane

**Goal:** represent durable engineering knowledge with types and relationships rather than generic conversational memory.

Candidate entities:

- Decision;
- Requirement;
- Invariant;
- Assumption;
- Unknown;
- Rejected Alternative;
- Evidence;
- Experiment;
- Observation;
- Incident;
- Capability;
- Artifact;
- Reconsideration Trigger.

This should unify lessons already present in Repository Truth, Recon, rejected-decision memory, domain language, specifications, and handoffs.

Proof:

- task context can be compiled from the relevant knowledge subgraph instead of a history dump;
- decisions and assumptions retain supporting/challenging evidence;
- stale knowledge has explicit invalidation/reconsideration triggers.

---

## ARS-10 — Intent Compiler

**Goal:** compile a human objective into a validated capability graph rather than merely asking a model to invent a plan.

Models interpret ambiguous intent. The Capability Graph validates required inputs, outputs, availability, authority, execution surfaces, and evidence.

Proof:

- the compiler can explain the capability route from objective to completion proof;
- missing decisions or unavailable capabilities surface as explicit frontiers;
- no route gains authority merely because a model proposed it;
- evaluation history may inform choices only after ARS-02/07 provide sufficient evidence.

---

# Era IV — Challenge and improve the system safely

## ARS-11 — Adversarial Verification

**Goal:** make builder/skeptic/verifier compositions first-class without treating additional agents as automatic quality.

Candidate uses:

- hostile completion review;
- architecture challenge;
- failure laboratories;
- counterfactual implementation experiments;
- capability ablation;
- independent verifier compositions.

Proof:

- adversarial roles operate against the same typed capability, authority, and evidence contracts;
- additional agents must demonstrate measurable benefit in Arsenal Bench;
- disagreement is resolved through evidence rather than agent voting.

---

## ARS-12 — Controlled Capability Evolution

**Goal:** let observed failures generate candidate capability improvements without permitting silent self-modification or self-authorization.

Target loop:

```text
observed failures
→ recurring pattern
→ candidate capability revision
→ baseline evaluation
→ regression evaluation
→ adversarial evaluation
→ ablation/comparison
→ human review
→ promote or reject
```

Hard constraints:

- no self-granted authority;
- no silent doctrine changes;
- no autonomous lifecycle promotion;
- no hidden benchmark losses;
- canonical capability replacement requires review.

Proof:

- a candidate revision can be proposed, evaluated, compared, and rejected without mutating the accepted capability;
- promotion requires explicit human approval and evidence.

---

# Parallel Development Pack lane

Development Packs grow alongside the program spine and should increasingly implement the shared Capability, Evaluation, Execution, Evidence, and Trust contracts.

Current/likely priority:

1. Floci / Local Cloud — existing tracer and first major evaluation corpus;
2. Dagger — execution substrate tracer;
3. Elixir / OTP / Phoenix;
4. Kubernetes;
5. PostgreSQL;
6. Playwright / browser/frontend verification;
7. TypeScript;
8. Python;
9. MCP;
10. failure injection;
11. security review.

This order is directional, not permission to build every pack before evidence shows demand.

MCP and other fast-moving external protocols should remain adapters/packs unless repository evidence proves a core contract depends on them.

---

# Relationship to the Floci program

FLC-00 through FLC-05 remain valuable delivered tracer slices.

They established:

- local-cloud execution boundaries;
- operation-level fidelity;
- deterministic fixtures;
- completion receipts;
- IaC preflight;
- migration and diagnosis;
- multi-cloud provider overlays;
- provider/capability routing;
- composed delivery.

The former **FLC-06 — Evaluation and stabilization** is now a track inside **ARS-02 — Arsenal Bench & Evaluation Lab v0**.

Do not build a separate Floci-only lifecycle/evaluation platform. Reuse the Floci scenarios as demanding tests of the general Arsenal evaluation contract.

Future Floci work should be justified either as:

- a missing Local Cloud capability required by real work;
- an evaluation fixture/scenario;
- a provider/runtime compatibility update;
- a Development Pack improvement under the shared Arsenal contracts.

---

# Public naming transition

The public surface may use clearer capability names before canonical IDs change:

- **Pressure Test** → current `agent.grill` / `foundations.grilling` lineage;
- **Recon** → current `agent.wayfind` / `foundation.wayfinding` lineage.

Do not mechanically rename stable IDs during ARS-00.

ARS-01 Capability Contract v2 must define display names, aliases, compatibility/deprecation metadata, and migration rules first. Provenance/source audits remain intact.

---

# Current frontier

```text
PROVEN FOUNDATION
Asset registry · invocation model · doctrine · methods · workflows
Development Pack contract · evidence/receipts · Floci FLC-00→05

NOW
ARS-00A  Public Surface & Unified Roadmap

NEXT
ARS-00B  Flagship quickstart / distribution pilot
ARS-01   Capability Contract v2
ARS-02   Arsenal Bench & Evaluation Lab v0
ARS-03   Compiler & Distribution

THEN
ARS-04   Capability Graph
ARS-05   Execution Substrate Contract
ARS-06   Dagger / Executable World Pack
ARS-07   Evidence Observatory
ARS-08   Trust & Authority Plane

LATER
ARS-09   Knowledge Plane
ARS-10   Intent Compiler
ARS-11   Adversarial Verification
ARS-12   Controlled Capability Evolution
```

## Program success criterion

Project Arsenal succeeds when useful engineering judgment can be represented as portable capabilities that:

- are easy to discover and use;
- compose through explicit dependencies and preconditions;
- receive only the context and authority they require;
- execute in the lowest-blast-radius environment capable of answering the question;
- produce evidence before claiming completion;
- are evaluated against baselines and adversarial cases;
- retain provenance and lifecycle truth;
- improve only through controlled, evidence-backed evolution.

The ambition should be visible in the engineering, not in unsupported adjectives.