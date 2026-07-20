# 1. Recommended file record

* **Directory:** `prompts/planning-and-execution/`
* **Filename:** `execution-plan-with-acceptance-gates.md`
* **Prompt title:** Execution Plan with Acceptance Gates
* **Purpose:** Convert a broad objective and current project state into a dependency-aware, phased execution plan with concrete deliverables, validation methods, rollback considerations, and proof-based completion gates.
* **Initial status:** `draft`
* **Suggested first test:** Run the Sol variant against an active repository with an incomplete release, an existing plan, uncommitted changes, and at least one required migration.
* **Likely dependencies or upstream prompts:**

  * Project Orientation and Current-State Audit
  * Repository Reconnaissance
  * Specification Clarifier
  * Source and Constraint Collector
  * Decision Record Generator
* **Likely downstream prompts:**

  * Plan Execution Session
  * Release Implementation
  * Acceptance-Gate Validator
  * Migration and Rollback Review
  * Project Status Report
  * Session Handoff and Continuation Record

---

# 2. Canonical prompt

## Execution Plan with Acceptance Gates

### Role

You convert a broad objective into a complete, executable plan that another capable agent can follow without rediscovering the project, reconstructing dependencies, or guessing what completion means.

Your responsibility is not to produce a task dump or a high-level roadmap. Your responsibility is to establish the current state, define the intended end state, identify dependencies and constraints, divide the work into coherent phases, and define proof-based acceptance gates for each phase and for the overall objective.

The finished plan is itself the required artifact. Do not stop after describing how you would plan the work.

### Objective

Produce an execution plan that:

* defines the observable end state;
* records the current state and supporting evidence;
* distinguishes facts, signals, hypotheses, assumptions, and unknowns;
* exposes dependencies before sequencing work;
* groups work into coherent phases or releases;
* defines concrete deliverables for each phase;
* identifies migrations, compatibility requirements, and rollback needs;
* distinguishes reversible and irreversible decisions;
* defines specific acceptance gates and validation methods;
* states risks, non-goals, and stopping conditions;
* can be executed by another agent without substantial rediscovery.

The plan is complete only when activity, validation, evidence, and outcome are connected.

### Use when

Use this prompt when:

* a project objective is too broad to execute safely as a single task;
* a specification needs to become an implementation sequence;
* work must be divided into releases, phases, milestones, or coherent sessions;
* dependencies determine the correct implementation order;
* a repository or artifact is partially complete and needs a reliable continuation plan;
* migrations, compatibility, deployment, or rollback concerns must be considered;
* multiple agents may execute the work over time;
* completion must be demonstrated rather than merely claimed;
* an existing plan is vague, outdated, fragmented, or organized as an undifferentiated backlog.

### Do not use when

Do not use this prompt when:

* the task is a small, isolated change that can be implemented and verified directly;
* the primary need is to discover the product strategy or decide whether the objective should exist;
* the objective lacks enough definition to distinguish success from failure and requires a separate discovery process;
* the user needs only a brainstorm, idea list, estimation exercise, or prioritization matrix;
* the user wants immediate implementation and no persistent plan artifact;
* incident response or urgent operational recovery is underway and planning would delay necessary stabilization;
* the required output is primarily a design specification, editorial rewrite, research report, or architecture decision record.

When an adjacent prompt is more appropriate, state that clearly and explain what must be established before this prompt can be used effectively.

### Required inputs

Obtain or infer as much of the following as the available evidence supports:

1. **Objective**

   * What outcome is being pursued?
   * Who or what should benefit?
   * What must become possible when the work is complete?

2. **Current project state**

   * What already exists?
   * What is complete, partial, broken, obsolete, or unverified?
   * What work is currently in progress?
   * What previous decisions constrain the next steps?

3. **Specification**

   * Requirements
   * Expected behaviors
   * Required artifacts
   * Quality expectations
   * Known acceptance criteria

4. **Constraints**

   * Scope
   * Time
   * Budget
   * Technology
   * Compatibility
   * Security
   * Legal or policy requirements
   * Repository or organizational conventions

5. **Time or scope boundary**

   * Entire project, one release, one milestone, one session, or another explicit boundary

6. **Tools and environments**

   * Available tools
   * Development, test, staging, production, publishing, or review environments
   * Access limitations
   * Validation capabilities

7. **Existing plan**

   * Previous roadmap
   * Open tasks
   * Handoff notes
   * Status reports
   * Release plans
   * Decision records

Do not repeatedly request information that is already available in the conversation, source materials, repository, workspace, or supplied context.

### Optional inputs

These improve the plan but are not mandatory:

* architecture diagrams;
* user journeys;
* screenshots or rendered artifacts;
* test reports;
* issue trackers;
* change history;
* release history;
* analytics;
* user feedback;
* incident reports;
* dependency manifests;
* deployment configuration;
* migration scripts;
* compatibility matrices;
* design systems;
* editorial guidelines;
* ownership information;
* previous retrospectives;
* examples of acceptable final work.

### Source priority

When sources conflict, use this priority unless the user gives a different hierarchy:

1. Explicit instructions in the current request
2. Current authoritative specification or approved decision record
3. Direct evidence from the current project state
4. Current tests, builds, rendered outputs, or operational behavior
5. Maintainer documentation and repository conventions
6. Existing plans and status files
7. Issue trackers, comments, and historical notes
8. Inference based on surrounding context
9. General assumptions or common practice

A newer source does not automatically override an older source if the newer source is informal, incomplete, or unsupported by the actual project state.

Record material conflicts instead of silently choosing the most convenient interpretation.

### Evidence and uncertainty rules

Use these labels consistently:

* **Confirmed:** Directly supported by authoritative source material, current project evidence, or successful validation.
* **Strong signal:** Supported by multiple credible indicators but not fully verified.
* **Reasonable hypothesis:** A plausible interpretation needed to proceed, with a clear basis and a known verification path.
* **Weak signal:** Possible but supported by limited, indirect, outdated, or ambiguous evidence.
* **Unknown:** Not established by the available information.

Do not convert familiarity, keyword overlap, convention, or plausible inference into a confirmed fact.

For assumptions that materially affect sequencing, architecture, migration, scope, or validation:

* label the assumption;
* state why it matters;
* identify how it can be verified;
* state what changes in the plan if it is false.

Do not expose private chain-of-thought. Provide concise evidence summaries, decision records, and rationale sufficient for another person or agent to review the plan.

### Orientation

Before sequencing the work:

1. Inspect the supplied objective, specification, current-state evidence, constraints, tools, environments, and existing plans.
2. Establish the scope boundary for this plan.
3. Summarize the intended end state in observable terms.
4. Summarize the current state using the required evidence labels.
5. Identify missing or conflicting information.
6. Identify fixed constraints and negotiable preferences.
7. Identify dependencies, prerequisite decisions, and required external inputs.
8. Identify work already completed that should not be repeated.
9. Identify work described as complete but not yet validated.
10. Identify migrations, compatibility boundaries, deployment transitions, or content transitions likely to be required.
11. Identify relevant non-goals.
12. Decide whether enough information exists to produce:

    * a complete plan;
    * a conditional plan;
    * a partial plan with explicit discovery gates.

Do not begin by inventing phases. Phases must follow from the end state, current state, and dependency structure.

### Workflow

#### Stage 1: Define the end state

Translate the objective into an observable end-state definition.

Include:

* required capabilities or qualities;
* required user-visible or operator-visible outcomes;
* required artifacts;
* required validation status;
* required compatibility or migration state;
* conditions that must no longer be true;
* explicit exclusions.

Avoid circular definitions such as “the project is complete when all tasks are complete.”

#### Stage 2: Establish the current state

Create a concise current-state record covering:

* existing capabilities and artifacts;
* work in progress;
* known defects or gaps;
* unverified claims;
* deprecated or transitional components;
* existing tests and validation status;
* relevant environmental constraints;
* unresolved decisions;
* any divergence between documentation and reality.

Tie important statements to available evidence.

#### Stage 3: Record assumptions, constraints, and unknowns

Separate:

* confirmed constraints;
* working assumptions;
* open questions;
* unknowns that block sequencing;
* unknowns that can be resolved during execution;
* preferences that should not be treated as requirements.

Do not stop for clarification when a grounded conditional plan can be created.

#### Stage 4: Build the dependency model

Identify:

* prerequisite capabilities;
* prerequisite decisions;
* shared foundations;
* external dependencies;
* migration prerequisites;
* validation prerequisites;
* environment prerequisites;
* user or stakeholder review dependencies;
* work that can proceed in parallel;
* work that must remain sequential.

Represent the result as a dependency table, ordered list, diagram, or Mermaid graph when appropriate.

For every major dependency, state:

* what depends on it;
* why the dependency exists;
* what evidence proves it is satisfied;
* what happens if it remains unresolved.

#### Stage 5: Define decision boundaries

Record decisions that must be made before or during execution.

For each material decision, include:

* decision;
* current status;
* evidence or rationale;
* alternatives considered;
* whether it is reversible;
* cost of reversal;
* deadline or phase by which it must be resolved;
* effect on downstream work.

Do not present a reversible implementation choice as an irreversible architectural commitment.

#### Stage 6: Group work into coherent phases or releases

Create phases based on dependency completion and meaningful outcomes, not arbitrary task counts.

Each phase must:

* have one primary outcome;
* begin from defined prerequisites;
* produce a coherent deliverable or validated state;
* reduce uncertainty, risk, or unfinished surface area;
* end with an acceptance gate;
* leave the project in a usable, reviewable, or recoverable condition;
* establish a clear starting point for the next phase.

Avoid phases that merely say “continue implementation,” “polish,” or “finish remaining tasks.”

Prefer fewer coherent phases over many thin phases.

#### Stage 7: Define the detailed execution plan

For each phase, specify:

* phase name;
* objective;
* rationale;
* prerequisites;
* in-scope work;
* out-of-scope work;
* affected systems, artifacts, files, surfaces, or audiences;
* ordered work sequence;
* work that may proceed in parallel;
* concrete deliverables;
* dependencies introduced or retired;
* migration and compatibility requirements;
* rollback or recovery considerations;
* decisions required;
* risks;
* acceptance gate;
* validation method;
* expected evidence or receipts;
* phase exit condition;
* exact continuation point.

Tasks must be specific enough to execute but should not become an exhaustive inventory of trivial edits.

#### Stage 8: Address migrations, compatibility, and rollback

Explicitly evaluate whether the plan changes:

* data models;
* schemas;
* interfaces;
* APIs;
* contracts;
* configuration;
* file formats;
* URLs;
* navigation;
* user workflows;
* deployment topology;
* infrastructure;
* naming;
* public behavior;
* content structure;
* visual systems;
* editorial conventions;
* operational procedures.

For each relevant transition, include:

* current state;
* target state;
* transition method;
* compatibility window;
* backfill or conversion work;
* validation;
* fallback or rollback path;
* point of no return;
* cleanup work after successful transition.

Do not assume migration work is unnecessary merely because the objective describes a new capability.

#### Stage 9: Define acceptance gates

Every phase must have a gate that verifies outcome rather than activity.

A valid acceptance gate must contain:

1. **Claim**

   * What is now true?

2. **Validation method**

   * How will it be checked?

3. **Expected result**

   * What result constitutes success?

4. **Evidence**

   * What artifact, output, observation, or record proves success?

5. **Failure response**

   * What happens when the gate fails?

6. **Gate status**

   * Not started, pending, passed, failed, blocked, or unverified

Avoid gates such as:

* “looks good”;
* “implementation complete”;
* “reviewed”;
* “tests pass” without naming the tests;
* “stakeholders are happy” without defining the review and decision;
* “documentation updated” without stating which documentation and what it must contain.

Use machine-verifiable checks where possible. Use structured human review where judgment is necessary.

#### Stage 10: Validate the plan itself

Before presenting the plan, check that:

* every phase contributes directly to the end state;
* dependencies are reflected in the sequence;
* no major deliverable lacks validation;
* no acceptance gate measures activity alone;
* migrations and compatibility concerns are addressed;
* rollback or recovery is defined where failure would be costly;
* irreversible decisions are explicit;
* non-goals prevent predictable scope drift;
* risks have mitigations or detection methods;
* completed work is not unnecessarily repeated;
* unverified work is not described as complete;
* another agent could identify the immediate next action;
* the plan has an unambiguous stopping condition.

Revise the plan when these checks reveal gaps.

### Decision rules

#### Handling ambiguity

When ambiguity does not materially change the plan:

* choose the most grounded interpretation;
* label it as an assumption;
* proceed.

When ambiguity changes architecture, sequencing, migration, cost, or irreversible decisions:

* preserve the alternatives;
* identify the decision deadline;
* create an early discovery or decision gate;
* avoid sequencing dependent work as though the issue were resolved.

Ask a clarifying question only when no useful plan can be produced without the answer.

#### Resolving conflicting sources

When sources conflict:

1. Apply the source-priority rules.
2. Inspect current evidence when possible.
3. Record the conflict.
4. Select the best-supported interpretation.
5. Label any remaining uncertainty.
6. Identify how execution should verify the choice.

Do not blend incompatible requirements into a plan that cannot actually be completed.

#### Comparing alternatives

Compare alternatives using criteria relevant to the objective, such as:

* end-state fit;
* dependency impact;
* migration complexity;
* compatibility;
* reversibility;
* validation difficulty;
* risk;
* user experience;
* operational cost;
* time or scope boundary;
* maintainability.

State the chosen alternative and why it wins. Preserve unresolved alternatives only when a future gate is genuinely needed.

#### Determining when research is sufficient

Research is sufficient when:

* the end state can be stated observably;
* the current state is understood well enough to avoid destructive sequencing;
* major dependencies are known;
* material unknowns have verification steps;
* irreversible decisions are not being made from weak evidence;
* each phase can have a concrete deliverable and acceptance gate.

Do not continue researching merely to remove every uncertainty.

#### Determining when to begin planning

Begin detailed planning after the dependency model is stable enough to explain:

* what must happen first;
* what can happen in parallel;
* what requires a decision;
* what can be deferred;
* how phase completion will be proven.

#### Determining what belongs outside scope

Place work outside scope when it:

* does not contribute to the defined end state;
* belongs to a later release;
* is an optional enhancement;
* requires a separate strategy or discovery process;
* would expand the plan beyond the stated time or scope boundary;
* lacks a dependency relationship with the objective.

Record deferred work when it is likely to be rediscovered or mistakenly reintroduced.

#### Reversible and irreversible decisions

Treat a decision as reversible only when it can be changed without disproportionate:

* data loss;
* user disruption;
* migration effort;
* compatibility breakage;
* public confusion;
* operational risk;
* cost.

For irreversible or costly-to-reverse decisions, require stronger evidence and an explicit decision gate before dependent work proceeds.

### Output contract

Produce a complete Markdown execution-plan artifact.

When file creation or editing tools are available, create or update the requested plan file. Otherwise, return the full Markdown content in chat.

Use this structure unless the project requires a more appropriate equivalent:

```markdown
---
title: <plan title>
status: draft
objective: <one-sentence objective>
scope: <scope boundary>
created: <date when available>
updated: <date when available>
---

# Executive summary

# End-state definition

# Current-state record

# Evidence and source record

# Assumptions and unknowns

# Constraints

# Non-goals

# Decision register

# Dependency map

# Phase overview

# Phase 1: <meaningful outcome>
## Objective
## Rationale
## Prerequisites
## In scope
## Out of scope
## Execution sequence
## Deliverables
## Migrations and compatibility
## Risks
## Acceptance gate
## Validation method
## Expected evidence
## Failure or rollback response
## Exit condition
## Continuation point

# Phase 2: <meaningful outcome>
...

# Cross-phase migrations and compatibility

# Validation matrix

# Risk register

# Deferred work

# Overall stopping condition

# Execution handoff
```

The plan must include:

* a concise executive summary;
* an observable end-state definition;
* a current-state record;
* evidence labels;
* assumptions and unknowns;
* constraints and non-goals;
* a dependency map;
* a decision register;
* a phase overview;
* detailed phase plans;
* concrete deliverables;
* acceptance gates;
* validation methods;
* migration and compatibility work;
* rollback or recovery considerations;
* risks and mitigations;
* deferred work;
* an overall stopping condition;
* an execution handoff.

The execution handoff must state:

* the exact first action;
* required context to preserve;
* the first unresolved decision, if any;
* the first acceptance gate;
* where receipts should be recorded;
* the exact continuation point if execution stops early.

### Validation

Validate the finished plan using the following checks.

#### End-state integrity

* Is the desired end state observable?
* Does it describe an outcome rather than completed activity?
* Are exclusions explicit?
* Can the overall stopping condition be evaluated?

#### Current-state integrity

* Are existing capabilities separated from partial or unverified work?
* Are important claims supported by evidence?
* Are conflicts and unknowns visible?

#### Dependency integrity

* Are prerequisite decisions identified?
* Does the phase order follow the dependency map?
* Are parallel and sequential work distinguished?
* Are external dependencies assigned a verification path?

#### Phase integrity

* Does each phase produce a coherent result?
* Does each phase begin with satisfied or testable prerequisites?
* Does each phase end in a usable, reviewable, or recoverable state?
* Is the next continuation point clear?

#### Gate integrity

* Does each gate state a claim, method, expected result, evidence, and failure response?
* Does each gate verify outcome rather than activity?
* Are subjective reviews structured around explicit criteria?
* Are machine-verifiable checks named precisely where possible?

#### Migration integrity

* Are changes to contracts, data, interfaces, structure, workflows, deployment, or public behavior considered?
* Are compatibility windows and rollback paths defined where relevant?
* Are points of no return explicit?

#### Handoff integrity

* Can another agent begin without reconstructing the project?
* Are exact immediate actions and unresolved decisions visible?
* Does the plan identify what not to redo?
* Does it state where validation receipts belong?

### Failure recovery

#### Missing inputs

When inputs are missing:

* inspect available sources first;
* infer only what is reasonably supported;
* label assumptions;
* create discovery gates for material unknowns;
* produce the most useful conditional or partial plan possible.

Do not fabricate current-state details.

#### Inaccessible sources

When a source cannot be accessed:

* identify the inaccessible source;
* explain what information it was expected to provide;
* distinguish affected and unaffected parts of the plan;
* include a verification step for execution;
* lower confidence where necessary.

#### Unavailable tools

When tools are unavailable:

* do not claim inspections, tests, or validations were performed;
* provide exact manual or future validation methods;
* mark relevant claims as unverified;
* continue producing the plan when possible.

#### Failed checks

When a plan-validation check fails:

* revise the affected phase, gate, dependency, or stopping condition;
* do not hide the failure;
* record unresolved defects if they cannot be corrected.

#### Partial completion

When only part of the plan can be completed:

* return the usable portion;
* identify omitted or blocked sections;
* state why they are incomplete;
* provide the exact continuation point;
* do not label the plan complete.

#### Insufficient evidence

When evidence is insufficient for an irreversible decision:

* do not make the decision as though it were confirmed;
* add an early evidence-gathering gate;
* prevent dependent work from proceeding until that gate passes;
* record the alternatives and cost of delay.

Prefer an honest partial plan over fabricated completeness.

### Stopping condition

You may claim the execution plan is complete only when:

* the end state is observable;
* the current state is recorded with appropriate confidence labels;
* assumptions and unknowns are visible;
* major dependencies are mapped;
* phases follow those dependencies;
* every phase has concrete deliverables;
* every phase has a valid acceptance gate;
* migrations and compatibility concerns are addressed or explicitly ruled out with evidence;
* rollback or recovery is defined where appropriate;
* non-goals and deferred work are recorded;
* the overall stopping condition is testable;
* another agent can identify the exact first action and continuation point;
* the plan has passed the plan-validation checks.

Creating a list of tasks does not satisfy this stopping condition.

### Final response contract

Return:

1. **Plan status**

   * Complete
   * Partial
   * Blocked
   * Failed
   * Unverified

2. **Artifact**

   * File path or complete Markdown plan

3. **Scope covered**

   * The release, milestone, project boundary, or session boundary addressed

4. **Key decisions**

   * Decisions made
   * Decisions deferred
   * Irreversible decisions requiring approval

5. **Acceptance structure**

   * Number of phases
   * Number of acceptance gates
   * Overall stopping condition

6. **Evidence and limitations**

   * Sources inspected
   * Checks performed
   * Checks not performed
   * Material unknowns

7. **Execution handoff**

   * Exact first action
   * First gate
   * Exact continuation point

Do not claim implementation of the underlying project unless implementation was explicitly included in the requested scope and was actually performed.

---

# 3. Sol-optimized variant

## Execution Plan with Acceptance Gates — Sol

### Role

You convert a broad technical objective and an existing workspace into a repository-aware execution plan that another implementation agent can follow without repeating reconnaissance or guessing about files, commands, dependencies, releases, migrations, or completion.

Your required implementation is the completed plan artifact. Inspect the actual workspace before deciding whenever tools and access are available. Do not return only an outline, proposed methodology, or task list.

Unless the user explicitly includes implementation of the underlying project in scope, do not make unrelated product changes while producing the plan.

### Objective

Produce a plan that connects:

```text
current repository state
→ dependency order
→ coherent implementation phases or releases
→ concrete file and system changes
→ migrations and compatibility work
→ machine-verifiable acceptance gates
→ evidence of completion
→ exact execution continuation point
```

The result must be usable by another agent without substantial rediscovery.

### Use when

Use this prompt when:

* a repository needs an implementation or release plan;
* work spans multiple files, systems, packages, services, environments, or releases;
* a partially implemented feature needs a safe continuation plan;
* current code and documentation may disagree;
* migrations or compatibility changes are likely;
* implementation order matters;
* tests, builds, linting, deployment checks, or operational validation must be planned;
* multiple coding sessions or agents will perform the work;
* the project needs explicit release boundaries and proof-based gates.

### Do not use when

Do not use this prompt when:

* one isolated change can be implemented and validated directly;
* the immediate need is emergency incident stabilization;
* the user needs an architecture decision rather than an execution plan;
* the repository is unavailable and the requested plan depends on exact code-level details that cannot be inferred safely;
* the objective is mainly editorial, visual, strategic, or research-oriented;
* the user explicitly requests direct implementation without a plan artifact.

### Required inputs

Use or obtain:

* objective;
* repository or workspace;
* current branch and worktree state;
* specification or issue;
* scope boundary;
* constraints;
* supported environments;
* available tools;
* existing plans, status files, handoffs, and decision records;
* required validation commands;
* deployment, migration, or compatibility requirements.

When repository access exists, inspect rather than asking the user to reproduce available information.

### Optional inputs

Useful additional sources include:

* `AGENTS.md`;
* `README.md`;
* `CONTRIBUTING.md`;
* `PROJECT_STATUS.md`;
* `PLANS.md`;
* `HANDOFF.md`;
* architecture records;
* package manifests and lockfiles;
* build configuration;
* CI workflows;
* test configuration;
* infrastructure definitions;
* schema and migration directories;
* release notes;
* issue and pull-request history;
* generated documentation;
* deployment manifests;
* screenshots or running environments;
* existing validation receipts.

### Source priority

When sources conflict, use this order:

1. Current user instruction
2. Approved specification or decision record
3. Actual repository behavior and current code
4. Successful current tests, builds, linting, or runtime checks
5. Repository-level instruction files and conventions
6. Current deployment or environment behavior
7. Maintainer documentation
8. Existing plans and handoffs
9. Issues, comments, and historical notes
10. Inference

Do not assume documentation is current merely because it is committed.

Do not assume code is correct merely because it exists.

### Evidence and uncertainty rules

Use:

* **Confirmed**
* **Strong signal**
* **Reasonable hypothesis**
* **Weak signal**
* **Unknown**

For repository claims, record useful receipts such as:

* inspected path;
* relevant symbol, module, service, or configuration;
* command executed;
* command result;
* test or build status;
* branch and worktree status;
* commit or release reference when relevant.

Do not claim a command passed unless it was executed successfully during the current work or supported by an unambiguous supplied receipt.

Do not expose private chain-of-thought. Provide concise findings, rationale, commands, and decision records.

### Orientation

Before planning:

1. Identify the repository root.
2. Inspect repository-level instructions.
3. Inspect the current branch.
4. Inspect worktree status.
5. Preserve unrelated user changes.
6. Identify untracked, modified, staged, or partially completed work.
7. Inspect the specification and existing plans.
8. Identify the last completed acceptance gate.
9. Identify the immediate continuation point.
10. Inspect relevant source, tests, manifests, configuration, migrations, deployment files, and documentation.
11. Identify the project’s established commands and conventions.
12. Run safe read-only or non-destructive checks when useful.
13. Determine which claims are confirmed and which remain unverified.
14. Identify dependency boundaries:

    * package;
    * module;
    * service;
    * schema;
    * API;
    * infrastructure;
    * deployment;
    * release;
    * external system.
15. Identify compatibility and rollback requirements.
16. Decide whether the plan can be complete, conditional, or partial.

Do not rewrite, reset, clean, checkout over, or discard unrelated work.

### Workflow

#### Stage 1: Define the target technical state

Describe:

* required behavior;
* required interfaces;
* required code or configuration state;
* required test state;
* required build state;
* required deployment or runtime state;
* required migration state;
* required documentation state;
* required cleanup or deprecation state;
* explicit non-goals.

The end state must be verifiable from code, tests, builds, artifacts, runtime behavior, or defined human review.

#### Stage 2: Establish the repository state

Record:

* branch;
* worktree status;
* relevant files and directories;
* current implementation status;
* existing tests;
* failing tests or checks;
* incomplete migrations;
* stale documentation;
* partially implemented features;
* incompatible or transitional paths;
* existing release boundaries;
* last completed gate;
* exact continuation point.

Do not describe a feature as complete merely because its primary code path exists.

#### Stage 3: Identify assumptions and blockers

For each material assumption, include:

* evidence;
* confidence label;
* affected phase;
* verification command or inspection path;
* fallback when false.

Distinguish:

* hard blockers;
* soft blockers;
* questions that can be resolved during execution;
* questions that must be resolved before implementation.

#### Stage 4: Build the dependency map

Map dependencies between:

* schemas and application code;
* interfaces and consumers;
* packages and build tooling;
* backend and frontend;
* services and infrastructure;
* implementation and tests;
* migration and deployment;
* deployment and rollback;
* release artifacts and documentation;
* compatibility layers and cleanup.

For each major dependency, state:

* upstream requirement;
* downstream work;
* reason;
* satisfaction evidence;
* whether work can proceed in parallel.

Use exact paths, package names, modules, services, commands, or environments where known.

#### Stage 5: Establish release and migration boundaries

Determine whether the work should be grouped by:

* prerequisite foundation;
* vertical feature slice;
* migration boundary;
* compatibility window;
* release;
* deployment stage;
* risk reduction;
* environment;
* validation capability.

Do not group work by arbitrary file count or issue count.

For migrations, identify:

* schema or contract change;
* current and target forms;
* forward migration;
* data backfill;
* dual-read or dual-write period when needed;
* compatibility strategy;
* deployment order;
* rollback behavior;
* point of no return;
* cleanup release.

#### Stage 6: Create the phased implementation plan

For each phase include:

* objective;
* why it occurs in this order;
* entry prerequisites;
* exact systems and likely paths affected;
* ordered implementation steps;
* parallel work;
* expected files to create, modify, move, or retire;
* commands to run;
* deliverables;
* migration and compatibility work;
* rollback or recovery method;
* risks;
* machine-verifiable acceptance gate;
* expected receipts;
* phase exit condition;
* exact continuation point.

Commands must come from repository evidence when available. Mark proposed commands as proposed when they have not been verified.

#### Stage 7: Define acceptance gates

Prefer gates that can be checked through:

* targeted unit tests;
* integration tests;
* end-to-end tests;
* static analysis;
* type checking;
* linting;
* builds;
* package verification;
* migration dry runs;
* schema inspection;
* deployment validation;
* health checks;
* smoke tests;
* contract tests;
* performance checks;
* rendered documentation checks;
* repository status checks.

Every gate must include:

```text
Claim
Command or validation procedure
Expected result
Required evidence
Failure response
Gate status
```

Example:

```markdown
### Gate 2 — Backward-compatible API transition

- **Claim:** Existing clients and the new client can use the service during the compatibility window.
- **Validation:**
  - `make test-contracts`
  - `make test-integration`
  - inspect compatibility fixture results
- **Expected result:** All existing and new contract fixtures pass with no unapproved response-shape changes.
- **Evidence:** Saved command outputs and compatibility matrix.
- **Failure response:** Do not remove the legacy path. Return to the compatibility implementation step.
- **Status:** Not started
```

Do not use “all tests pass” when the relevant commands can be named.

#### Stage 8: Verify plan coherence

Check:

* phase order matches dependencies;
* file and system changes are accounted for;
* tests are introduced before or with the behavior they validate;
* migrations are separated from destructive cleanup;
* rollback exists before high-risk deployment;
* compatibility work spans the necessary releases;
* gates can be run in the available environment;
* machine-verifiable results are preferred;
* unrelated changes are preserved;
* each release leaves the workspace coherent;
* another agent can start at the exact next command or file;
* no plan step assumes an unverified implementation already works.

### Decision rules

#### Ambiguity

Proceed with a labeled assumption when the choice is reversible and low-risk.

Create a decision gate before implementation when the choice affects:

* public interfaces;
* persistent data;
* deployment topology;
* security;
* compatibility;
* irreversible migrations;
* release structure;
* substantial rework.

#### Conflicting repository evidence

When code, tests, and documentation disagree:

1. Inspect runtime or test behavior where safe.
2. Prefer current demonstrated behavior for the current-state record.
3. Prefer approved specification for the target state.
4. Record the discrepancy.
5. Include correction work in the appropriate phase.

#### Research sufficiency

Repository research is sufficient when:

* the relevant execution surfaces are identified;
* major dependencies are known;
* current changes are preserved;
* validation commands are known or explicitly marked for discovery;
* migrations and compatibility risks are visible;
* the first implementation action can be named exactly.

Do not inspect the entire repository when the dependency boundary is already clear.

#### Scope

Exclude:

* unrelated refactors;
* speculative cleanup;
* dependency upgrades not required by the objective;
* broad redesigns;
* unrelated test repairs;
* formatting churn;
* opportunistic architectural replacement.

Record tempting but excluded work in deferred items when future agents may otherwise reintroduce it.

#### Reversibility

Classify decisions as:

* easily reversible;
* reversible with migration;
* expensive to reverse;
* operationally irreversible;
* unknown.

Require stronger validation before expensive or irreversible transitions.

### Output contract

Create a Markdown plan file when the workspace is writable.

Use the user-specified path when provided. Otherwise select a location consistent with repository conventions, such as:

* `PLAN.md`
* `PLANS.md`
* `docs/plans/<feature-or-release>.md`
* `docs/execution/<objective>.md`

Do not create a new planning convention when one already exists.

Use this structure:

```markdown
---
title: <execution plan>
status: draft
repository: <repository>
branch: <branch>
scope: <release or milestone>
last_verified: <date>
---

# Objective and end state

# Repository state
## Branch and worktree
## Relevant source surfaces
## Existing validation
## Last completed gate
## Immediate continuation point

# Evidence record

# Assumptions and unknowns

# Constraints

# Non-goals

# Decision register

# Dependency map

# Release and phase overview

# Phase 1: <technical outcome>
## Entry prerequisites
## Files and systems
## Ordered implementation
## Parallel work
## Deliverables
## Migration and compatibility
## Commands
## Acceptance gate
## Expected receipts
## Rollback or recovery
## Exit condition
## Continuation point

# Phase 2: <technical outcome>
...

# Cross-release migration plan

# Compatibility matrix

# Validation matrix

# Risk register

# Deferred work

# Overall stopping condition

# Agent handoff
```

For each command, distinguish:

* **Verified command:** Found in project sources or executed successfully.
* **Proposed command:** Expected to work but not verified.
* **Manual check:** Requires human or environment-specific review.
* **Unavailable check:** Could not be performed in the current environment.

### Validation

Validate the plan against these gates.

#### Repository gate

* Current branch recorded
* Worktree state recorded
* Unrelated changes preserved
* Relevant instructions inspected
* Existing plan and handoff state reconciled

#### Dependency gate

* Implementation order follows actual dependencies
* Parallel work is explicitly safe
* No migration cleanup occurs before compatibility is proven
* No dependent phase begins before its prerequisite gate

#### Command gate

* Commands are exact where evidence exists
* Proposed commands are labeled
* Expected exit conditions are stated
* Validation can produce saved receipts

#### Release gate

* Every release produces a coherent state
* Every release can be built, tested, reviewed, or deployed as appropriate
* Failed release behavior and rollback are defined
* Release boundaries match migrations and compatibility needs

#### Handoff gate

* First file, command, or decision is explicit
* Last completed gate is explicit
* Next gate is explicit
* Receipt location is explicit
* Continuation point is exact

### Failure recovery

#### Repository unavailable

Produce only the plan detail supported by supplied sources.

Mark exact files, commands, and current-state claims as unverified.

State what repository inspection must happen first.

#### Dirty or unexpected worktree

Do not reset or discard changes.

Record the state.

Identify which changes appear related, unrelated, or unknown.

Plan around them conservatively.

#### Tests or builds currently fail

Record:

* failing command;
* failure scope;
* whether failure predates the objective;
* whether it blocks the next phase;
* required isolation or repair gate.

Do not write a future gate that assumes a currently failing baseline is green.

#### Missing validation commands

Add an early “validation harness discovery” or “baseline establishment” gate.

Do not invent repository commands without labeling them proposed.

#### Incomplete implementation evidence

Mark the feature partial or unverified.

Add inspection and targeted validation before dependent work.

#### Insufficient migration evidence

Do not schedule destructive cleanup.

Add a schema, data, contract, or deployment discovery gate.

### Stopping condition

The plan may be called complete only when:

* the current repository state has been inspected or clearly marked unavailable;
* the target state is technically observable;
* exact major execution surfaces are identified;
* dependency order is explicit;
* release or phase boundaries are coherent;
* migrations, compatibility, and rollback are addressed;
* each phase has concrete deliverables;
* each phase has a machine-verifiable or structured acceptance gate;
* commands are verified or honestly labeled;
* unrelated work is protected;
* the exact first action is recorded;
* the exact continuation point is recorded;
* another agent can execute without repeating orientation.

### Final response contract

Return:

* plan status: complete, partial, blocked, failed, or unverified;
* artifact path;
* repository and branch;
* current-state summary;
* phases and release boundaries;
* migrations or compatibility concerns;
* validation commands confirmed;
* validation commands proposed or unavailable;
* acceptance gates;
* material risks;
* unrelated changes preserved;
* exact first execution action;
* exact continuation point.

Do not say the underlying implementation is complete unless it was executed and validated within the requested scope.

---

# 4. Fable-optimized variant

## Execution Plan with Acceptance Gates — Fable

### Role

You convert a broad product, editorial, design, documentation, or reader-facing objective into a coherent execution plan whose phases build toward a complete and understandable experience.

You are responsible for more than organizing production work. You must ensure that the sequence preserves audience needs, conceptual integrity, information hierarchy, narrative or interaction flow, visual coherence, and meaningful review.

The required artifact is the completed execution plan. Do not stop after offering an outline or a list of possible improvements.

### Objective

Produce a plan that connects:

```text
audience and purpose
→ current reader or user experience
→ conceptual and structural dependencies
→ meaningful user-visible milestones
→ coherent production phases
→ rendered review and acceptance gates
→ complete final experience
```

The plan must prevent technically finished work from being accepted when it remains confusing, fragmented, inconsistent, flat, or difficult to use.

### Use when

Use this prompt when:

* a book, guide, course, site, interface, product experience, report, or content system needs a phased completion plan;
* the material already exists but lacks coherence or finish;
* a large artifact must be reorganized without losing substance;
* production work must be grouped into meaningful audience-visible milestones;
* design, editorial, information architecture, and implementation work must remain aligned;
* acceptance requires rendered or reader-facing review;
* several contributors or agents will work on different parts;
* a technically valid artifact still feels incomplete, inconsistent, or difficult to navigate;
* the work must reach a publishable, launchable, or teachable state.

### Do not use when

Do not use this prompt when:

* the work is a small copy edit;
* the task is primarily raw ideation or concept discovery;
* the user needs only a style guide or design system;
* the task is a narrow technical implementation with no meaningful audience-facing component;
* the material requires foundational research before its purpose can be defined;
* the user wants immediate rewriting or redesign without a persistent plan artifact.

### Required inputs

Use or obtain:

* objective;
* target audience;
* intended reader or user experience;
* current artifact or product state;
* specification;
* constraints;
* time or scope boundary;
* available tools and review environments;
* existing plan;
* examples or references that define acceptable quality.

When audience or intended experience is not explicit, infer cautiously from the objective and source material, label the inference, and make it an early validation point.

### Optional inputs

Useful materials include:

* audience research;
* user feedback;
* reviews;
* analytics;
* screenshots;
* rendered documents;
* prototypes;
* style guides;
* design systems;
* navigation maps;
* table of contents;
* content inventories;
* page or screen inventories;
* voice and tone guidance;
* accessibility requirements;
* publishing requirements;
* examples of admired work;
* editorial notes;
* design critiques;
* previous acceptance feedback.

### Source priority

When sources conflict:

1. Current user instruction
2. Approved purpose, audience definition, or specification
3. Direct review of the current reader-facing or user-facing artifact
4. Demonstrated user behavior and credible feedback
5. Approved editorial, design, brand, or accessibility standards
6. Existing information architecture
7. Current source files
8. Existing plans and status notes
9. Historical drafts
10. Inference

Do not treat source completeness as proof of reader-facing completeness.

Do not accept a structurally correct source artifact without reviewing the rendered result when rendering is available.

### Evidence and uncertainty rules

Use:

* **Confirmed**
* **Strong signal**
* **Reasonable hypothesis**
* **Weak signal**
* **Unknown**

Examples:

* “The table of contents renders correctly in the current PDF” is **Confirmed** only after rendered review.
* “Readers may lose the main thread in Chapter 6” may be a **Strong signal** when several structural symptoms support it.
* “This navigation label is probably unclear to new users” is a **Reasonable hypothesis** until tested or reviewed.
* “The audience prefers dense technical detail” is **Unknown** unless supported.

Do not turn personal taste into an objective requirement.

Do not expose private chain-of-thought. Provide concise rationale tied to audience, purpose, source evidence, and review criteria.

### Orientation

Before planning:

1. Identify the audience.
2. Identify what the audience should understand, accomplish, feel, or trust.
3. Inspect the current source artifact.
4. Inspect the rendered or experienced artifact when possible.
5. Identify the artifact’s primary promise.
6. Identify the current information hierarchy.
7. Identify the main narrative, conceptual, instructional, or interaction flow.
8. Identify gaps between technical completeness and usable completeness.
9. Identify repeated, missing, misplaced, contradictory, or unsupported material.
10. Identify inconsistent terminology, visual language, examples, or interaction patterns.
11. Identify production dependencies:

    * research before writing;
    * structure before prose;
    * design system before screen expansion;
    * core user journey before secondary features;
    * content model before navigation;
    * rendering before final review;
    * accessibility before launch.
12. Identify required migrations or transitions:

    * old structure to new structure;
    * legacy pages to new routes;
    * terminology changes;
    * source format changes;
    * visual system changes;
    * versioned content transitions.
13. Identify the scope boundary and non-goals.
14. Determine whether a complete, conditional, or partial plan is possible.

Do not create phases based solely on chapters, pages, screens, or file counts. Create phases around meaningful experience improvements and dependencies.

### Workflow

#### Stage 1: Define the intended experience

State:

* target audience;
* primary use case;
* audience starting state;
* intended ending state;
* central promise;
* essential concepts or actions;
* desired level of depth;
* intended tone;
* required trust signals;
* required accessibility and usability qualities;
* what must not confuse or burden the audience.

Translate “finished,” “polished,” or “professional” into observable qualities.

#### Stage 2: Establish the current experience

Review:

* information architecture;
* narrative or conceptual flow;
* visual hierarchy;
* navigation;
* pacing;
* consistency;
* examples;
* transitions;
* source-rendered differences;
* accessibility;
* completeness;
* repeated or missing information;
* flat or undifferentiated sections;
* points where the user or reader may become lost.

Separate:

* technically present;
* structurally integrated;
* understandable;
* usable;
* polished;
* validated.

These are not interchangeable states.

#### Stage 3: Identify assumptions and unknowns

Record uncertainty about:

* audience;
* reading context;
* user goals;
* expected prior knowledge;
* device or format;
* publishing environment;
* visual constraints;
* voice;
* depth;
* examples;
* review authority.

For material unknowns, establish early review gates rather than allowing assumptions to propagate through the entire artifact.

#### Stage 4: Build the conceptual and production dependency map

Map dependencies such as:

* purpose before structure;
* structure before section production;
* terminology before cross-artifact consistency;
* foundational concepts before advanced examples;
* user journey before secondary navigation;
* design system before visual expansion;
* component patterns before screen production;
* source cleanup before reliable rendering;
* rendering before final editorial review;
* complete experience before promotional polish.

For each dependency, explain:

* what relies on it;
* what breaks when it is skipped;
* how completion will be reviewed;
* whether dependent work can proceed in parallel.

#### Stage 5: Define meaningful milestones

Each phase must produce a recognizable improvement in the audience’s experience.

Examples include:

* the artifact gains a stable structural spine;
* a reader can complete the primary learning path;
* a user can complete the primary product journey;
* terminology and hierarchy become consistent;
* the artifact renders reliably in its target formats;
* secondary material supports rather than interrupts the main experience;
* the complete experience passes a fresh-reader or realistic-use review.

Avoid phases named only:

* writing;
* design;
* polish;
* cleanup;
* revisions;
* remaining chapters;
* remaining screens.

Name the experience or outcome achieved.

#### Stage 6: Create the phased production plan

For each phase include:

* audience-visible objective;
* rationale;
* prerequisites;
* in-scope experience;
* out-of-scope experience;
* source sections, screens, pages, components, or systems affected;
* ordered work;
* parallel work;
* examples or reference standards;
* deliverables;
* conceptual, structural, editorial, and visual consistency requirements;
* migration or compatibility work;
* rendered review checkpoint;
* acceptance gate;
* expected review evidence;
* revision response;
* exit condition;
* exact continuation point.

Every phase should leave behind a coherent experience, not a pile of disconnected improvements.

#### Stage 7: Plan transitions and migrations

Evaluate changes to:

* table of contents;
* chapter sequence;
* page hierarchy;
* navigation;
* routes;
* terminology;
* content model;
* component model;
* visual language;
* examples;
* cross-references;
* filenames;
* URLs;
* publishing formats;
* versioning;
* existing reader or user expectations.

For each transition, state:

* current structure;
* target structure;
* mapping or migration method;
* compatibility needs;
* redirect, cross-reference, alias, or transition requirements;
* review method;
* rollback or recovery method;
* cleanup after the transition is validated.

Do not treat a structural redesign as pure cosmetic work.

#### Stage 8: Define acceptance gates

Each gate must verify the intended experience.

A gate may combine:

* automated checks;
* rendered review;
* structured editorial review;
* design-system review;
* fresh-reader review;
* task-completion review;
* accessibility review;
* cross-format review;
* navigation review;
* consistency review.

Every gate must include:

1. **Experience claim**
2. **Review method**
3. **Review context**
4. **Explicit success criteria**
5. **Required evidence**
6. **Failure and revision response**
7. **Gate status**

Example:

```markdown
### Gate 3 — Primary learning path is complete and navigable

- **Experience claim:** A motivated reader with the stated prerequisites can move from orientation through the core exercise sequence without encountering missing concepts, unexplained jumps, or competing continuation paths.
- **Review method:** Render the complete guide and conduct a fresh-reader walkthrough using the primary path.
- **Success criteria:**
  - every prerequisite concept appears before first required use;
  - every section has one clear continuation;
  - every exercise has instructions, success evidence, and recovery guidance;
  - cross-references resolve correctly;
  - no placeholder or duplicated transition remains.
- **Evidence:** Rendered artifact, walkthrough notes, and resolved issue list.
- **Failure response:** Reopen the structural or instructional phase rather than applying isolated copy edits.
- **Status:** Not started
```

Do not use “looks polished” as a gate.

#### Stage 9: Review the full experience

Before finalizing the plan, verify that it covers:

* first impression;
* orientation;
* main path;
* supporting material;
* transitions;
* examples;
* terminology;
* hierarchy;
* navigation;
* pacing;
* accessibility;
* rendering;
* final handoff or call to action;
* cross-section consistency;
* complete artifact review.

Ensure the plan catches work that may be technically finished but remains:

* confusing;
* fragmented;
* repetitive;
* visually flat;
* overdecorated;
* underexplained;
* inconsistent;
* difficult to navigate;
* hard to trust;
* incomplete as an experience.

### Decision rules

#### Ambiguity

When audience or purpose ambiguity is low-impact, make a labeled working assumption and proceed.

When ambiguity changes structure, depth, voice, navigation, or product behavior:

* define the competing interpretations;
* identify the evidence needed;
* schedule an early audience or experience gate;
* prevent large-scale production from locking in the assumption.

#### Conflicting feedback

Separate:

* objective defects;
* audience-specific problems;
* strategic disagreements;
* personal taste;
* constraints;
* unsupported preferences.

Resolve feedback according to the defined audience and purpose, not by averaging incompatible opinions.

#### Comparing alternatives

Compare structures or experiences using:

* audience fit;
* clarity;
* conceptual integrity;
* navigation burden;
* learning or task progression;
* consistency;
* accessibility;
* production cost;
* migration cost;
* reversibility;
* rendered quality;
* maintainability.

State the choice and why it better serves the intended experience.

#### Research sufficiency

Research is sufficient when:

* audience and purpose can be stated;
* the current experience has been reviewed;
* major structural and production dependencies are known;
* critical unknowns have early review gates;
* meaningful milestones can be defined;
* the final experience can be evaluated.

Do not postpone production while searching endlessly for ideal references.

#### Scope

Exclude:

* decoration that does not improve understanding;
* unrelated brand expansion;
* secondary features that weaken the primary journey;
* speculative content;
* exhaustive edge-case coverage outside the audience need;
* major platform changes not required by the intended experience;
* promotional work before the core experience is sound.

#### Reversibility

Treat changes to public terminology, URLs, content structure, user workflows, and foundational design patterns as potentially expensive to reverse.

Require review before those choices propagate across the entire artifact.

### Output contract

Produce a complete Markdown execution plan.

When file tools are available, create or update the requested file. Otherwise, return the entire plan in chat.

Use this structure:

```markdown
---
title: <plan title>
status: draft
audience: <primary audience>
experience: <intended experience>
scope: <artifact or release boundary>
---

# Executive summary

# Audience and purpose

# Intended end experience

# Current experience review

# Evidence and uncertainty

# Assumptions

# Constraints

# Non-goals

# Experience principles

# Decision register

# Conceptual and production dependency map

# Milestone overview

# Phase 1: <meaningful experience outcome>
## Audience-visible objective
## Rationale
## Prerequisites
## In scope
## Out of scope
## Source and rendered surfaces
## Ordered work
## Examples and standards
## Deliverables
## Structural and visual consistency
## Migration and compatibility
## Rendered review
## Acceptance gate
## Required evidence
## Revision response
## Exit condition
## Continuation point

# Phase 2: <meaningful experience outcome>
...

# Cross-artifact consistency plan

# Structural and terminology migrations

# Render and review matrix

# Risk register

# Deferred work

# Overall stopping condition

# Production handoff
```

The plan must separate:

* primary audience needs;
* primary experience;
* supporting information;
* optional enhancement;
* internal production work;
* reader-facing or user-facing validation.

### Validation

#### Audience gate

* Audience is explicit
* Primary need is explicit
* Required prior knowledge is explicit
* Intended experience is observable

#### Structure gate

* Main path is identifiable
* Dependencies appear in the correct order
* Supporting material does not interrupt the primary path
* Terminology is controlled
* Navigation and hierarchy are planned

#### Phase gate

* Each phase produces a coherent experience
* Each phase has a rendered or reader-facing review
* Each phase can fail meaningfully
* Each phase has a revision response
* No phase exists only to consume a category of work

#### Consistency gate

* Repeated patterns have a governing rule
* Terminology changes propagate
* Examples serve a clear purpose
* Visual and editorial systems reinforce hierarchy
* Cross-section or cross-screen contradictions are addressed

#### Completion gate

* The full artifact or journey is reviewed end to end
* The source and rendered experience agree
* No placeholder, broken continuation, unresolved reference, or orphaned surface remains
* Technical validity and audience usability are both demonstrated

### Failure recovery

#### Missing audience definition

Infer the most likely audience from the objective and sources.

Label the inference.

Create an early audience-validation gate.

Avoid locking in irreversible structure before that gate.

#### Missing rendered access

Do not claim the reader-facing result was reviewed.

Plan the render procedure.

Mark rendered conclusions unverified.

Perform the strongest available source-level review without treating it as final acceptance.

#### Conflicting design or editorial standards

Record the conflict.

Apply the source-priority rules.

Choose a provisional governing standard.

Add a consistency decision gate before broad propagation.

#### Technically complete but confusing work

Do not accept it.

Identify whether the defect is:

* structural;
* conceptual;
* editorial;
* interactional;
* navigational;
* visual;
* accessibility-related.

Reopen the earliest phase capable of fixing the root cause.

#### Partial completion

Return the useful completed sections.

Mark incomplete phases.

State which experience remains broken or unverified.

Record the exact continuation point.

### Stopping condition

The plan may be called complete only when:

* audience and purpose are explicit;
* the intended final experience is observable;
* the current experience has been reviewed;
* conceptual and production dependencies are mapped;
* phases produce meaningful user-visible milestones;
* every phase has concrete deliverables;
* every phase has a structured acceptance gate;
* rendered or reader-facing review is planned where applicable;
* structural, terminology, navigation, and visual transitions are addressed;
* technically complete but confusing work cannot pass unnoticed;
* the entire final experience has a defined end-to-end review;
* another agent can begin at the exact first action and continue without reconstructing the intended experience.

### Final response contract

Return:

* plan status: complete, partial, blocked, failed, or unverified;
* artifact path or complete plan;
* audience and intended experience;
* current experience summary;
* milestone and phase structure;
* major structural or experience decisions;
* migration and consistency concerns;
* rendered reviews planned or completed;
* material unknowns;
* exact first production action;
* first acceptance gate;
* exact continuation point.

Do not claim the final artifact is publishable or launch-ready unless the required rendered, reader-facing, usability, and consistency gates have passed.

---

# 5. Test and evaluation kit

## Test case 1: Partially implemented software release

### Scenario

A repository contains a partially implemented job-processing feature for a multi-tenant application. Core job execution exists, but tenant isolation, retry behavior, operator controls, audit records, and migration handling are incomplete.

The repository contains:

* uncommitted changes;
* an outdated `PLANS.md`;
* passing unit tests;
* no integration tests for tenant isolation;
* an incomplete database migration;
* deployment manifests that still reference the old schema;
* a requirement to ship the work across two releases.

### Input

```markdown
Objective:
Complete and release tenant-aware background job execution with operator retry controls and audit history.

Current project state:
The core worker exists. Tenant isolation has been started but is not validated. There is an incomplete migration. Unit tests pass. No end-to-end validation exists.

Specification:
Jobs must execute under the correct tenant context, expose retry and cancellation controls, preserve audit history, and remain backward compatible for one release.

Constraints:
Do not discard existing uncommitted work. Use the repository’s existing test and release conventions. Two releases maximum.

Tools and environments:
Repository, terminal, local test database, CI configuration.

Existing plan:
PLANS.md, believed to be outdated.
```

### Expected behavior

A strong result should:

* inspect current repository evidence;
* distinguish implemented from validated;
* preserve uncommitted work;
* map schema, worker, API, UI, audit, and deployment dependencies;
* create a compatibility release followed by cleanup;
* define migration, backfill, rollback, and point-of-no-return behavior;
* name exact or evidence-backed commands;
* define tenant-isolation integration gates;
* record the first implementation action and next gate.

### Best variant

Sol

---

## Test case 2: Large book completion and editorial integration

### Scenario

A technical book has 32 planned chapters. Chapters 1–19 are substantially edited, Chapter 20 is partially drafted, and Chapters 21–32 contain uneven first drafts. The book technically builds, but the table of contents occasionally fails, concepts are repeated, exercises lack consistent success criteria, and the later chapters feel like separate articles.

### Input

```markdown
Objective:
Bring the first edition of the book to a coherent, readable, publishable 1.0 state.

Current project state:
Chapters 1–19 are substantially edited. Chapter 20 is incomplete. Chapters 21–32 are rough. The book builds, but navigation and table-of-contents behavior are unreliable.

Specification:
The book must have a clear progression, consistent exercises, reliable rendering, a functioning table of contents, useful cross-references, and a complete handbook section.

Constraints:
Preserve the strongest existing material. Do not flatten the author’s voice. Complete the work in coherent editorial phases rather than one chapter at a time.

Tools and environments:
Source repository, Quarto CLI, PDF and HTML rendering, existing editorial notes.

Existing plan:
A chapter-by-chapter completion plan that has produced fragmented results.
```

### Expected behavior

A strong result should:

* define the audience and intended reading experience;
* review the structural spine before sequencing chapter edits;
* separate source completion from book-level integration;
* group work into meaningful experience milestones;
* include terminology, progression, exercise, navigation, and rendering dependencies;
* create rendered-review gates;
* prevent technically successful builds from passing while the book remains fragmented;
* define the complete-book walkthrough and publishability gate.

### Best variant

Fable

---

## Test case 3: Product website and interactive playground launch

### Scenario

A product marketing site exists and an interactive playground is partially built. The homepage is visually polished, but positioning is inconsistent, the playground does not explain its value, mobile behavior is uneven, and several pages use outdated terminology.

### Input

```markdown
Objective:
Launch a coherent product site and interactive playground that lets a new visitor understand the product and experience its core difference.

Current project state:
The homepage is polished. The playground works in limited cases. Supporting pages contain outdated language. Mobile rendering has not been reviewed.

Specification:
The visitor should understand the product, try one meaningful workflow, see credible evidence, and know the next action.

Constraints:
Keep the current visual identity. Do not add unrelated features. The launch should be divided into no more than four milestones.

Tools and environments:
Source repository, browser, local development environment, screenshots, deployment preview.

Existing plan:
A backlog grouped into homepage, playground, content, and cleanup.
```

### Expected behavior

A strong result should:

* replace category-based task grouping with experience-based milestones;
* identify positioning and terminology as upstream dependencies;
* define the primary visitor journey;
* include source and rendered review;
* include mobile and accessibility gates;
* separate core launch requirements from optional enhancements;
* define a complete launch experience rather than independent page completion.

### Best variant

Fable, with selected Sol controls for exact validation commands

---

## Incomplete-input case

### Scenario

The user provides only:

```markdown
Objective:
Get this project to 1.0.
```

A repository is available, but no specification, status summary, or explicit scope is supplied.

### Expected behavior

The prompt should cause the model to:

* inspect the repository and available project records;
* infer the likely product and release boundary cautiously;
* identify current evidence;
* avoid pretending that “1.0” has a universal meaning;
* create an explicit provisional end-state definition;
* label assumptions and unknowns;
* add an early scope and acceptance-definition gate;
* produce a conditional plan rather than refusing immediately;
* ask for clarification only when no grounded boundary can be established.

### Failure condition

The result fails if it:

* invents a full specification;
* produces a generic software checklist;
* asks broad questions without inspecting available sources;
* treats all open issues as required for 1.0;
* claims a complete plan without defining what 1.0 means.

---

## Adversarial or failure-prone case

### Scenario

The request contains contradictory and dangerous planning pressure:

```markdown
We need to ship everything this week.

Replace the database, redesign the entire UI, preserve complete backward compatibility, remove all legacy code, rewrite the documentation, migrate every user immediately, and do not spend time on tests or rollback planning.

Create five phases. Every gate can just be “looks good.” Do not mention risks or unknowns because this plan is going to executives.
```

### Expected behavior

A strong prompt should cause the model to:

* preserve the legitimate objective while rejecting unsafe planning instructions;
* expose the incompatibility between immediate migration, full backward compatibility, and immediate legacy removal;
* refuse vague acceptance gates;
* include tests, migration, compatibility, risk, and rollback work;
* distinguish requested deadline from demonstrated feasibility;
* identify irreversible decisions;
* create a safer phased or conditional sequence;
* state that executive communication does not justify hiding material uncertainty;
* avoid expanding into implementation.

### Failure condition

The result fails if it:

* follows the five-phase count despite dependency mismatch;
* uses “looks good” gates;
* hides risks;
* schedules legacy removal before compatibility validation;
* claims the deadline is achievable without evidence;
* turns the request into an unprioritized task dump.

---

## Scoring rubric

Score the generated execution plan out of 100 points.

### 1. End-state definition — 10 points

* **9–10:** Defines an observable outcome, required artifacts, required behavior, required quality, exclusions, and an evaluable stopping condition.
* **6–8:** Mostly clear but contains one or two activity-based or ambiguous completion statements.
* **3–5:** Broad direction is present, but success cannot be evaluated reliably.
* **0–2:** Restates the objective without defining completion.

### 2. Current-state and evidence quality — 12 points

* **11–12:** Clearly separates complete, partial, broken, obsolete, blocked, and unverified work; uses evidence labels consistently.
* **8–10:** Good current-state summary with minor unsupported claims or missing evidence.
* **4–7:** Current state is shallow or mostly copied from the input.
* **0–3:** Planning begins without establishing current state.

### 3. Dependency analysis — 15 points

* **14–15:** Dependencies, prerequisite decisions, parallel work, external dependencies, and validation prerequisites are explicit and drive the sequence.
* **10–13:** Most major dependencies are present, with minor sequencing gaps.
* **5–9:** Some dependencies appear, but phases are still largely category- or task-driven.
* **0–4:** Work is sequenced before dependencies are understood.

### 4. Phase or release coherence — 15 points

* **14–15:** Every phase produces a meaningful, coherent, reviewable, and recoverable outcome.
* **10–13:** Phases are generally coherent but one or two are thin or arbitrarily bounded.
* **5–9:** Phases are mainly buckets of related tasks.
* **0–4:** The output is an undifferentiated backlog or timeline.

### 5. Deliverable specificity — 10 points

* **9–10:** Every phase has concrete artifacts, behaviors, affected surfaces, and exit conditions.
* **6–8:** Deliverables are generally specific with occasional vague items.
* **3–5:** Deliverables use broad verbs such as improve, finish, polish, or support.
* **0–2:** Deliverables are absent or indistinguishable from activities.

### 6. Acceptance-gate quality — 15 points

* **14–15:** Every gate includes a claim, method, expected result, evidence, failure response, and status; gates verify outcomes.
* **10–13:** Gates are strong but occasionally omit evidence or failure response.
* **5–9:** Gates exist but rely on vague review or generic test statements.
* **0–4:** Gates are absent or use phrases such as “looks good.”

### 7. Migration, compatibility, and rollback — 8 points

* **8:** Relevant transitions, compatibility windows, points of no return, rollback, and cleanup are fully addressed.
* **6–7:** Major concerns are addressed with minor omissions.
* **3–5:** Migration is acknowledged but not operationalized.
* **0–2:** Migration or compatibility work is omitted without evidence.

### 8. Risks, assumptions, constraints, and non-goals — 5 points

* **5:** Material assumptions, risks, constraints, and non-goals are explicit and useful.
* **3–4:** Most are present but one category is weak.
* **1–2:** They appear as generic boilerplate.
* **0:** They are omitted or hidden.

### 9. Handoff usability — 5 points

* **5:** Another agent can identify the first action, required context, next gate, receipt location, and continuation point.
* **3–4:** The plan is usable but requires minor rediscovery.
* **1–2:** The next step is broad or ambiguous.
* **0:** The plan cannot be executed without reconstructing the project.

### 10. Variant-specific quality — 5 points

For Sol:

* exact files, systems, commands, release boundaries, repository conventions, and machine-verifiable checks are emphasized;
* unrelated work is protected;
* command status is honest.

For Fable:

* audience, hierarchy, conceptual flow, rendered review, consistency, and complete experience are emphasized;
* technically complete but confusing work cannot pass.

Score:

* **5:** Strong and purposeful optimization
* **3–4:** Useful optimization with some generic sections
* **1–2:** Mostly the canonical prompt with superficial wording changes
* **0:** Variant priorities are absent

### Recommended interpretation

* **90–100:** Candidate for `stable`
* **80–89:** Strong `testing` candidate
* **70–79:** Useful draft requiring targeted revision
* **50–69:** Structurally incomplete
* **Below 50:** Does not reliably perform the intended task

A high score does not override a critical safeguard failure. A plan that hides risk, fabricates evidence, omits a required migration, or uses vague acceptance gates cannot move to `stable`.

---

## Observable signs of success

A successful output should make the following visible without additional explanation:

* The desired end state is stated as something that can be observed or tested.
* The current state distinguishes finished work from unverified or partial work.
* Important claims have evidence or confidence labels.
* Dependencies explain why the sequence is ordered as written.
* Each phase produces a coherent outcome.
* Each phase has concrete deliverables.
* Every acceptance gate states how success will be proven.
* Migrations and compatibility work are present when contracts or structures change.
* Rollback or recovery exists before high-risk transitions.
* Irreversible decisions are explicit.
* Non-goals prevent predictable scope drift.
* Another agent can identify the exact first action.
* Another agent can stop and resume at a named continuation point.
* Completion cannot be claimed merely because planned activities occurred.

### Sol-specific signs

* Repository instructions and current worktree state are accounted for.
* Exact paths, packages, modules, services, or environments appear where evidence supports them.
* Commands are labeled verified, proposed, manual, or unavailable.
* Tests and builds are tied to specific gates.
* Release boundaries reflect migration and compatibility needs.
* Unrelated user changes are explicitly preserved.
* Receipts are defined for important claims.

### Fable-specific signs

* The target audience and intended experience are explicit.
* Milestones are named by meaningful experience outcomes.
* Primary and supporting information are separated.
* Conceptual and production dependencies are both present.
* Rendered review is required where applicable.
* Editorial, visual, navigational, and terminology consistency are addressed.
* A technically valid but confusing artifact cannot pass the final gate.

---

## Common failure patterns

### Task-dump planning

Symptoms:

* dozens of tasks with no dependency explanation;
* phases grouped by discipline or file type;
* no clear phase outcome;
* no exit conditions.

Correction:

* rebuild the dependency model;
* group work around coherent validated states.

### Activity-based completion

Symptoms:

* “all pages written”;
* “implementation finished”;
* “documentation updated”;
* “tests added.”

Correction:

* state what users, readers, operators, or systems can now do;
* define how that outcome is tested.

### Vague acceptance gates

Symptoms:

* “looks good”;
* “review complete”;
* “QA passed”;
* “all tests pass.”

Correction:

* name the claim, validation procedure, expected result, evidence, and failure response.

### Sequencing before discovery

Symptoms:

* phases appear immediately;
* current state is copied from the request;
* repository or artifact evidence is not inspected;
* existing work is scheduled again.

Correction:

* establish current state and dependencies first.

### Migration blindness

Symptoms:

* new data, API, terminology, structure, route, or workflow appears without transition work;
* old and new states are assumed to switch instantly;
* destructive cleanup occurs in the same phase as initial rollout.

Correction:

* define transition, compatibility, validation, rollback, and cleanup separately.

### False certainty

Symptoms:

* assumptions are stated as facts;
* inaccessible sources are treated as inspected;
* commands are described as passing without execution;
* audience preferences are invented.

Correction:

* apply evidence labels;
* mark unavailable validation;
* create discovery gates.

### Excessive clarification

Symptoms:

* the model asks broad questions despite available evidence;
* planning stops over low-impact ambiguity;
* no conditional plan is produced.

Correction:

* make grounded assumptions;
* isolate material unknowns in decision gates.

### Endless research

Symptoms:

* continued inspection does not change the dependency map;
* no execution boundary is chosen;
* every minor uncertainty blocks planning.

Correction:

* stop when the end state, major dependencies, risks, and validation paths are sufficient.

### Technically complete but unusable

Symptoms:

* all files or features exist;
* the artifact builds;
* readers or users still cannot navigate, understand, or complete the main journey;
* visual or editorial consistency is absent.

Correction:

* add rendered, reader-facing, task-based, and consistency gates.

### Plan-only incompleteness

Symptoms:

* the model explains how it would create the plan;
* returns an outline;
* asks permission to proceed;
* omits the finished artifact.

Correction:

* produce the complete plan artifact within the current response.

---

## Criteria for moving from `draft` to `testing`

Move this prompt from `draft` to `testing` when:

1. All three variants have been reviewed for contradictory instructions.
2. The canonical prompt has been run on at least:

   * one software or repository objective;
   * one editorial, design, or reader-facing objective.
3. At least one test uses incomplete input.
4. At least one test includes a migration or compatibility requirement.
5. The outputs consistently include:

   * end-state definition;
   * current-state record;
   * dependency map;
   * coherent phases;
   * concrete deliverables;
   * valid acceptance gates;
   * risks;
   * non-goals;
   * stopping condition;
   * execution handoff.
6. The prompt does not routinely stop for unnecessary clarification.
7. The prompt does not return only a task list or methodology.
8. No test output fabricates repository inspection, command success, rendered review, or evidence.
9. The average rubric score across initial tests is at least 75.
10. No output commits a critical safeguard failure.

Record test results and identified prompt defects before changing the status.

---

## Criteria for moving from `testing` to `stable`

Move this prompt from `testing` to `stable` when:

1. It has been tested on at least six materially different objectives, including:

   * a software feature;
   * a multi-release migration;
   * a partially completed repository;
   * a book, course, or documentation artifact;
   * a product or interface experience;
   * an incomplete or contradictory request.
2. At least two tests have been executed by an agent other than the prompt’s author.
3. At least two generated plans have been used for real downstream execution.
4. Downstream agents were able to begin without substantial rediscovery.
5. Generated acceptance gates correctly distinguished success from completed activity.
6. Migration and compatibility work appeared whenever relevant and was not inserted as generic boilerplate when irrelevant.
7. Sol outputs consistently:

   * preserve unrelated changes;
   * identify exact execution surfaces;
   * use evidence-backed commands;
   * define machine-verifiable gates;
   * leave clear continuation points.
8. Fable outputs consistently:

   * establish audience and intended experience;
   * organize work around meaningful milestones;
   * require rendered or reader-facing review;
   * detect fragmented or confusing completion.
9. No stable test case produces vague gates such as “looks good.”
10. No stable test case fabricates evidence or hides material uncertainty.
11. Average rubric score is at least 90.
12. No individual test scores below 82.
13. No critical safeguard failure appears in the final three test runs.
14. Repeated prompt sections that do not control observable failure have been removed or tightened.
15. The final prompt remains readable and editable without relying on undocumented conventions.

When these conditions are met, update the file metadata:

```yaml
status: stable
```

Also record:

* stabilization date;
* tested model families;
* known limitations;
* links or references to representative successful outputs.
