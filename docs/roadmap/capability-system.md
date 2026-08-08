# Project Arsenal Capability-System Roadmap

Status: active program

Current frontier: **ARS-08 — Trust & Authority Plane**

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

## Signature primitives

The roadmap deliberately owns a small set of concepts that should make Arsenal feel obvious in hindsight rather than merely comprehensive. They are not all shipped yet; each has an explicit program owner.

| Primitive | Product idea | Program owner |
|---|---|---|
| **Proof-Carrying Capability** | A capability travels with identity, authority, evaluation state, known limitations, and inspectable evidence instead of being trusted because its instructions look good. | ARS-02 seeds the Capability Evidence Passport; ARS-07/08 harden provenance and trust. |
| **Case Health Receipt** | A benchmark case must prove it is fit to judge the agent before its result can count. | ARS-02 — AVAILABLE v0. |
| **Counterfactual / Ablation Receipt** | Record what changed, what stayed fixed, which arms actually ran, and what Arsenal prevented rather than reporting a score without causal context. | ARS-02 — AVAILABLE v0; ARS-11 expands adversarial experiments. |
| **Competence Lockfile — `.arsenal.lock`** | Version the engineering judgment a repository expects its agents to use, including capability versions, digests, provenance, evaluation qualification, and compiled exports. | ARS-03. |
| **Capability Gap Preflight** | Compute required competence versus available/qualified competence before execution, so missing capabilities surface before the agent improvises around them. | ARS-04. |
| **Reality Budget / Proof Ladder** | Spend only as much reality and authority as the evidence requires. | ARS-05. |
| **Agent Flight Recorder** | Preserve capability/model/context/tool/evidence traces so a run can be replayed and successful/failed behavior can be diffed — eventually, git-bisect-like debugging for agent behavior. | ARS-07. |
| **Third-Party Competence Audit** | Treat imported skills as untrusted packages: inspect provenance/authority/conflicts, quarantine, sandbox, evaluate, then approve. | ARS-08. |
| **Evidence-Based Model Routing** | Route a capability to models/harnesses because Bench evidence shows competence for that capability, not because of brand reputation. | ARS-10 after ARS-02/04/07 evidence exists. |

These primitives are architectural commitments only at the slices named above. Public surfaces must continue to distinguish `AVAILABLE`, `BUILDING`, and `FRONTIER` rather than presenting roadmap concepts as shipped features.

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

**Status:** delivered by PR #13.

Delivered:

- a separate Capability Contract v2 while preserving the Asset Contract as repository-artifact metadata;
- deterministic `arsenal/capabilities/*.json` fragments instead of a monolithic capability manifest;
- nine initial `draft` / `unassessed` capabilities spanning Repository Truth, Pressure Test, Recon, Diagnose, TDD, Review, Verify, Resume, and execution-backed Local Cloud Feature Delivery;
- stable capability IDs separated from display names and compatibility aliases;
- Pressure Test aliases `Grill` / `Grilling` without renaming `agent.grill`;
- Recon aliases `Wayfind` / `Wayfinding` without renaming `agent.wayfind`;
- declarative required/optional/forbidden authority, mutation class, execution surfaces, verification requirements, evidence outputs, evaluation state, provenance, and compatibility;
- executable cross-contract validation against the merged Asset Registry;
- seven negative contract cases covering alias collisions, unresolved implementation assets, authority conflicts, read-only mutation authority, execution-substrate errors, harness leakage, and unsupported stable lifecycle claims;
- Local Cloud proof that a behavioral capability can require `cloud.local` while forbidding `cloud.remote` and `production.mutate` by default;
- three registered capability-system reference assets and a generated catalog update.

Boundary preserved:

- ARS-01 records authority but ARS-08 will enforce it;
- ARS-01 records execution intent but ARS-05 will select/enforce substrates and fidelity;
- capability lifecycle remains `draft` until ARS-02 produces evaluation evidence;
- ARS-00B distribution remains a derived compiler regression target rather than canonical capability behavior.

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

**Status:** delivered by PR #14; model-efficacy campaigns remain ongoing evaluation work.

**Goal:** measure whether Arsenal actually improves engineering work and make lifecycle promotion executable.

Delivered in v0:

- `evaluation/BENCH_CONTRACT.md` plus case, Case Health Receipt, and evaluation receipt schemas;
- a 19-case corpus: 8 Core engineering-judgment cases and 11 Local Cloud / former-FLC-06 cases;
- explicit control/treatment, ablation, and contract-counterfactual definitions;
- **Case Health Receipts** so broken or under-specified cases cannot contribute lifecycle evidence;
- **Counterfactual / Ablation Receipts** that preserve unexecuted arms instead of inferring causal wins;
- a **Capability Evidence Passport** inside executable receipts as the first proof-carrying-capability surface;
- deterministic runner + negative contract suite;
- five active Local Cloud routing/boundary cases executed in CI while fourteen deeper/model cases remain explicitly `designed-not-run`;
- retained claim scope and limitations stating that deterministic contract evidence is not model/harness efficacy evidence;
- the first evidence-backed capability lifecycle promotion: `capability.local-cloud-feature-delivery` to `testing` / `candidate`, guarded by the registered Local Cloud suite and exact generated receipt;
- read-only final CI and generated catalog integration.

First candidate campaign evidence: 5/5 active Local Cloud cases executed, healthy, and passing; 6 deeper Local Cloud cases remain designed-not-run, as do all 8 Core model-behavior cases. No capability is promoted to `stable` by this campaign.

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

**Status:** delivered by PR #15.

**Goal:** compile canonical capabilities into downstream harness/distribution formats instead of manually maintaining divergent copies.

Delivered in v0:

- deterministic `scripts/arsenal_compile.py` with validate/build/verify/explain surfaces;
- a target-specific export plan that contains packaging metadata without duplicating canonical behavior;
- Repository Truth → Agent Skills as the first compiler-backed export;
- generated `SKILL.md` carrying capability identity, lifecycle/evaluation state, authority, execution boundaries, outputs, and canonical source pointer;
- byte-identical canonical workflow snapshot generated from the registered primary implementation asset;
- generated `arsenal-manifest.json` as a proof-carrying package manifest with source and file digests;
- deterministic `.arsenal.lock` pinning capability version/digest, primary-asset digest, evaluation qualification, adapter version, export path, package digest, and export-plan digest;
- negative tests for duplicate exports, unknown capabilities, unsupported targets, path traversal, invalid package names, missing discovery context, and package drift;
- deterministic double-build proof;
- ARS-00B distribution/install regression preserved;
- final compiler CI read-only.

ARS-03 deliberately ships one proven exporter rather than speculative adapters. Agent Skills is the v0 target because ARS-00B already established its real package/install contract. Additional Claude, Codex-specific, MiniMax/generic, Kiln-native, or other adapters must earn their own format contract instead of copying behavior into another source of truth.

Candidate export targets:

- Agent Skills;
- Claude-compatible package;
- Codex-compatible package;
- MiniMax/generic agent package;
- Kiln-native capability package.

ARS-03 also owns the **Competence Lockfile** concept: `.arsenal.lock` should pin the capability IDs/versions, content digests, provenance, evaluation qualification, and compiled export expectations a repository depends on. The goal is to make agent competence reproducible infrastructure in the same spirit that dependency lockfiles make software dependencies reproducible.

The lockfile must not freeze model choice or pretend evaluation evidence never expires. It records the accepted competence contract and provenance; later evidence can invalidate or upgrade qualification deliberately.

Potential CLI surface may include concepts such as lint/build/explain/install, but command names are not public contract until implementation reconnaissance proves the right interface.

Proof:

- ARS-00B's manually proven flagship distribution path is reproducibly generated;
- generated packages preserve capability identity, authority boundaries, references, and evaluation provenance;
- canonical behavior remains harness-neutral;
- generated artifacts are verified rather than hand-edited.

---

# Era II — Turn the library into a capability system

## ARS-04 — Capability Graph

**Status:** delivered by PR #16.

**Goal:** make dependencies, preconditions, outputs, authority, implementation availability, and composition machine-readable.

Delivered in v0:

- explicit graph contract and deterministic `arsenal/graph/graph.json`;
- four tracer routes: repository audit, feature delivery, bug repair, and Local Cloud feature delivery;
- Capability Gap Preflight with `READY`, `CAPABILITY_GAP`, `AUTHORITY_GAP`, `QUALIFICATION_GAP`, and `UNKNOWN` verdicts;
- canonical-source and `.arsenal.lock` competence inventories;
- lock version/digest/qualification checks so stale pinned competence fails closed;
- primary implementation resolution through the Asset Registry;
- route minimum semantic-version and lifecycle/evaluation gates;
- read-only, workspace-safe, and local-cloud-safe authority profiles with dangerous remote grants rejected in v0;
- Local Cloud route consuming its ARS-02-earned `testing / candidate` qualification;
- machine-readable JSON preflight output and explicit non-ready exit codes;
- negative graph tests for unknown capabilities, invalid dependencies, bad versions, invalid qualification states, and unsafe profiles.

ARS-04 does not infer routes from vague intent or execute them. It proves the route contract and competence boundary first; ARS-10 later owns intent compilation.

The graph should answer questions such as:

```text
TDD requires an implementation-ready behavior slice
  ↓ missing
Tracer decomposition produces one
  ↓
route: decomposition → TDD
```

FLC-05 is the tracer precedent: it proved that **provider resolved** and **requested capability available for that provider** are separate facts. ARS-04 generalizes that lesson beyond cloud work.

ARS-04 should expose this as **Capability Gap Preflight**: before execution, derive the competence required by the intended route and compare it with capabilities that are actually present, compatible, authorized, and sufficiently qualified. The result should be explainable as covered / missing / unknown rather than allowing an agent to improvise around a consequential gap.

Start deterministic. Models may interpret fuzzy intent; graph machinery validates legal composition.

Proof:

- routes cannot consume outputs/preconditions that do not exist;
- unsupported capability combinations hard-stop rather than borrowing an unrelated implementation;
- authority requirements propagate through compositions;
- the graph can explain why a route was chosen or rejected.

---

## ARS-05 — Execution Substrate Contract

**Status:** delivered by PR #17.

**Goal:** generalize the Local Cloud execution/fidelity lesson into a portable execution-selection model.

Delivered in v0:

- substrate-neutral `arsenal/substrates/CONTRACT.md`;
- ordered 12-rung Reality Budget catalog from deterministic function through production, with Repository Read as an explicit observation rung;
- runtime-agnostic proof requirements bound to canonical capability verification requirement IDs;
- deterministic selector with `SELECTED`, `AUTHORITY_GAP`, `SUBSTRATE_GAP`, `ESCALATION_REQUIRED`, `EVIDENCE_GAP`, and `UNKNOWN` outcomes;
- declared availability profiles instead of pretending every known substrate exists in the current environment;
- reuse of ARS-04 authority profiles without widening them;
- capability execution-surface compatibility checks;
- per-substrate isolation, reproducibility, proof traits, limitations, reset, teardown, and escalation metadata;
- remote sandbox, shared non-production, staging, and production marked explicit-only;
- TDD proof selecting in-process execution before a higher-cost world;
- Local Cloud proof stopping at the emulator when that evidence is sufficient;
- stronger real-provider semantics producing an explicit remote escalation candidate rather than automatic cloud fallback;
- proof vocabulary corrected to separate provider-behavior observation from emulator-vs-real fidelity;
- final Reality Budget CI read-only.

ARS-05 selects but does not execute. ARS-06 owns the first strong execution adapter implementation.

Public concept: **Reality Budget / Proof Ladder**.

> **Spend only as much reality and authority as the evidence requires.**

The selector should be able to explain why a lower-blast-radius substrate is sufficient, what claim it cannot establish, and what additional evidence would justify escalation.

Execution ladder:

```text
pure deterministic function
→ repository read
→ in-process test
→ local process
→ local container
→ real local dependency
→ local emulator
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

**Status:** delivered by PR #18.

**Goal:** give the generalized execution model a strong portable containerized implementation without making Dagger part of Arsenal's architecture.

Delivered in v0:

- a Dagger Development Pack whose responsibility begins only after Reality Budget selects a container world;
- **proof-gated execution**: the runner refuses to execute unless ARS-05 independently selects the world's exact substrate and reality rank;
- `world.tdd-python-container`, a real `capability.tdd` verification world exercising canonical `red_observed` and `green_observed` requirements;
- an explicit caller proof trait, `container-runtime`, that raises this tracer to `substrate.local-container` rank 4 while ordinary TDD still selects rank 2;
- Dagger CLI `0.21.7` pinned and verified at runtime;
- explicit host-input scope: only the Dagger Development Pack is imported into `/pack`;
- no secrets and no runtime network requirement after required images are available;
- deterministic world-definition and fixture digests;
- a raw world receipt plus a composed Arsenal receipt carrying the exact Reality Budget selection evidence;
- byte-identical replay proof across two executions;
- the same checked-in runner command used locally and in CI;
- final Dagger CI read-only.

ARS-06 sharpened an important boundary: current Core capabilities such as TDD contain model/human judgment that a container does not itself execute. The Dagger world executes the **verification environment that earns evidence for the capability contract**. Capability judgment, execution substrate, and verification evidence remain distinct.

Proof achieved:

- a real canonical capability verification contract is exercised inside a reproducible disposable world;
- Reality Budget, not runtime availability, authorizes that world;
- ordinary TDD remains on the cheaper in-process substrate when container proof is unnecessary;
- local and CI use the same declared runner/world contract;
- two executions produce byte-identical Arsenal receipts;
- Dagger emits normal Arsenal evidence without acquiring authority, lifecycle, or completion semantics.

---

## ARS-07 — Evidence Observatory / Agent Flight Recorder

**Status:** delivered by PR #19.

**Goal:** unify receipts, run provenance, evaluation evidence, model/harness usage, and execution traces into a common run model.

Delivered in v0:

- one strict Flight Record envelope shared by normal capability verification and Arsenal Bench evaluation;
- source-addressed evidence references with SHA-256 verification, claim scope, and preserved limitations;
- separate operational `instance_id` and deterministic stable `fingerprint` identities;
- Dagger and Bench normalization into the same top-level provenance/context/tool/evidence/outcome structure;
- explicit evaluator-layer authority semantics rather than invented capability-runtime grants;
- repository-provenance consistency checks when source receipts observed a repository SHA;
- evidence-bound PASS outcomes that cannot exist without accepted evidence IDs;
- metadata-first, content-off privacy policy rejecting prompt, completion, secret, environment-dump, and chain-of-thought fields;
- OpenTelemetry interoperability mapping using Arsenal's own attribute namespace and current log-based Event direction without making a collector/backend part of correctness;
- live CI evidence bundle containing both normalized Flight Records and their original Dagger/Bench source receipts;
- deterministic fingerprint equivalence across reruns whose instance IDs differ.

The v0 evidence authority is the Flight Record plus independently verifiable source receipts. Dashboards, telemetry backends, retention systems, and raw GenAI content capture remain explicitly outside this slice.

The recognizable product surface is the **Agent Flight Recorder**: preserve enough of intent, capability versions, context, tools, authority escalation, verification, cost, and accepted evidence to explain *why* one run succeeded and another failed. Long term, this should enable time-travel inspection and git-bisect-like debugging for agent behavior without requiring private chain-of-thought capture.

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

External capability ingestion should evolve toward an **`arsenal audit` for third-party competence**:

```text
discover
→ quarantine
→ inspect provenance + requested authority + conflicts
→ sandbox
→ evaluate
→ adapt
→ approve/register
```

Unverified imported instructions should default to quarantine rather than becoming trusted behavior because they use a familiar package format.

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
- evaluation history may inform choices only after ARS-02/07 provide sufficient evidence;
- **evidence-based model routing** may select different models/harnesses for different capabilities only when comparable Bench/Flight-Recorder evidence supports that decision — never from brand reputation alone.

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
DELIVERED SPINE
ARS-00  Public Surface & Distribution
ARS-01  Capability Contract v2
ARS-02  Arsenal Bench v0 + first evidence-backed testing capability
ARS-03  Compiler & Distribution + `.arsenal.lock`
ARS-04  Capability Graph + Capability Gap Preflight
ARS-05  Execution Substrate Contract + Reality Budget
ARS-06  Dagger / Executable World Pack + proof-gated execution
ARS-07  Evidence Observatory / Agent Flight Recorder

NOW / NEXT AFTER ARS-07 ACCEPTANCE
ARS-08  Trust & Authority + third-party competence audit

LATER
ARS-09  Knowledge Plane
ARS-10  Intent Compiler + evidence-based model routing
ARS-11  Adversarial Verification / deeper counterfactual laboratories
ARS-12  Controlled Capability Evolution
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