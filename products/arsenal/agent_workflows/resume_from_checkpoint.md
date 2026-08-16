# Resume from Checkpoint and Execute the Next Slice

The most recent work summary immediately preceding this prompt is the **checkpoint report** for the current repository.

Use that report to resume the work intelligently.

Do not create another prompt.

Do not merely summarize the checkpoint, recommend next steps, produce an implementation plan, or wait for approval. Verify the checkpoint against the actual workspace, determine the correct continuation point, and begin executing the next coherent slice.

## Mission

Continue the project from its latest verified checkpoint and complete the explicitly named next slice, milestone, specification set, or acceptance gate.

The finished result should include:

* the required implementation;
* appropriate tests;
* migrations or schema changes when required;
* API, CLI, UI, documentation, or contract updates required by the slice;
* targeted validation during implementation;
* the named acceptance gate;
* a coherent repository state;
* an exact handoff when anything remains.

The checkpoint report is a high-value operational handoff, but it is not unquestionable truth. Confirm its important claims against the repository before building on them.

## Default execution boundary

The default target is the work identified by the checkpoint’s latest explicit continuation statement, usually introduced by language such as:

* `Next:`
* `Immediate continuation:`
* `Resume at:`
* `Next slice:`
* `Next milestone:`
* `Remaining:`

Complete that named unit of work and its acceptance gate.

Do not drift into later milestones merely because they are nearby.

Continue beyond the named unit only when:

* the checkpoint explicitly instructs continuation through multiple units;
* the next work is an inseparable prerequisite of the named slice;
* a small adjacent correction is required to leave the named slice coherent;
* the current invocation explicitly asks for broader continuation.

Completing a release slice does not automatically authorize beginning the following slice.

## Authority order

When sources disagree, use this order:

1. Explicit instructions in the current invocation.
2. Repository-level instruction files such as `AGENTS.md`.
3. Executable behavior, schemas, migrations, tests, and the current working tree.
4. Canonical specifications, roadmaps, ADRs, release plans, and acceptance-gate scripts.
5. Current project-status and handoff documents.
6. The preceding checkpoint report.
7. Reasonable inference.

Do not override a specific repository requirement with a generic best practice.

Do not blindly follow an outdated plan when the implementation, tests, or later accepted decisions clearly supersede it.

Surface consequential conflicts before building on them, but resolve routine conflicts and continue when the repository provides enough evidence.

## Evidence states

Use these distinctions internally and in progress or final reporting when they matter:

* **Confirmed:** verified directly from the repository, tool output, executable behavior, authoritative project documentation, or a completed check.
* **Checkpoint claim:** stated in the preceding report but not yet independently verified.
* **Reasonable inference:** supported by project structure or surrounding evidence but not directly established.
* **Unknown:** unavailable, conflicting, inaccessible, or not yet investigated enough to support a decision.

Do not turn a checkpoint claim into a confirmed fact merely because it is detailed or confidently written.

Do not invent command output, test results, files, commits, branch state, background-job state, or completed work.

## Execution posture

Operate autonomously inside the named scope.

Do not stop after:

* repeating the checkpoint;
* explaining what the next slice appears to be;
* creating a task list;
* proposing an implementation plan;
* identifying files that need changes;
* describing commands that should be run;
* finding a failing test;
* implementing only the easiest portion;
* asking for approval to begin routine work.

Make grounded, reversible decisions and continue.

Ask a question only when all of the following are true:

* a material requirement cannot be recovered from the repository;
* different answers would lead to substantially different implementations;
* choosing incorrectly would create serious rework, destructive changes, or an invalid deliverable;
* no safe, clearly labeled assumption permits progress.

Routine architectural and implementation decisions belong to you within the established project conventions.

## Phase 1: Reconcile the checkpoint

Begin by verifying the operational state.

### 1. Inspect the workspace

At minimum, determine:

* current repository and working directory;
* current branch;
* working-tree state;
* recent relevant commits;
* whether the checkpoint commit exists;
* whether the branch is ahead of or behind its upstream;
* whether unrelated user changes are present;
* whether active background jobs or reusable worker sessions exist, when the harness exposes them.

Do not reset, discard, overwrite, stash, or rewrite unrelated user work.

When the tree is dirty, distinguish:

* pre-existing user changes;
* incomplete work from the prior slice;
* generated files;
* changes caused during this session.

Work around unrelated changes rather than erasing them.

### 2. Read the governing project instructions

Inspect the relevant repository guidance before editing.

This commonly includes:

* `AGENTS.md`;
* `README.md`;
* `PROJECT_STATUS.md`;
* `PLANS.md`;
* `HANDOFF.md`;
* release or milestone roadmaps;
* the path or specification cited by the checkpoint;
* ADRs referenced by the next slice;
* verification scripts;
* package- or directory-specific instruction files.

Do not read every document in the repository indiscriminately. Follow references from the checkpoint and governing files until the next slice and its contracts are understood.

### 3. Verify the checkpoint’s important claims

Confirm enough of the prior state to build safely on it.

Check, as applicable:

* the reported commit and commit contents;
* the existence of the named implementation;
* migrations and schema state;
* tests added by the prior slice;
* version or release metadata;
* gate scripts;
* status and handoff records;
* generated API or schema artifacts;
* expected branch cleanliness.

Do not automatically rerun every expensive prior gate merely because it appears in the checkpoint.

Use this rule:

* When the reported commit exists, the tree is coherent, the relevant receipts are preserved, and nothing has changed underneath the checkpoint, accept the completed prior gate as the established baseline.
* Rerun a prior full gate only when repository state has changed, evidence is missing, a prerequisite is doubtful, the next gate requires it, or a mismatch makes the checkpoint unsafe to trust.
* Prefer cheap confirmation before expensive repetition.

The goal is confidence, not ceremonial duplication.

### 4. Reconcile discrepancies

When the report and repository disagree:

1. determine whether the difference comes from a later commit, stale report, different branch, uncommitted changes, generated output, or an actual incomplete slice;
2. establish the authoritative current state;
3. correct stale status or handoff information when it is inside scope;
4. resume from the real continuation point.

Do not begin the next slice on top of an unresolved structural mismatch.

Do not abandon the task merely because a minor report detail is stale.

## Phase 2: Build an execution model for the next slice

Before broad editing, translate the named next slice into an actionable implementation model.

Identify:

* the observable outcome;
* specifications and ADRs controlling it;
* dependencies already satisfied;
* prerequisites still missing;
* required data-model changes;
* public contracts that may change;
* security and authorization boundaries;
* tenancy or workspace-isolation requirements;
* concurrency, idempotency, retry, and transaction requirements;
* API, CLI, UI, worker, or documentation surfaces;
* compatibility and migration concerns;
* the exact acceptance gate;
* likely regression surfaces;
* what is explicitly outside this slice.

Keep this model concise and operational.

Do not produce a large speculative design document unless the repository requires one.

### Choose work in dependency order

Derive the implementation order from architectural dependencies rather than from whichever file is easiest to edit.

A typical order may be:

1. domain rules and invariants;
2. data model and migrations;
3. context or service behavior;
4. authorization and scope enforcement;
5. background processing or concurrency behavior;
6. API contracts;
7. CLI or UI surfaces;
8. documentation and generated artifacts;
9. acceptance tests and release gate.

Adapt the order to the repository.

When the slice contains multiple specifications, find their shared foundation and avoid implementing them as disconnected feature fragments.

### Identify proof obligations

For each consequential requirement, determine what will prove it works.

Examples include:

* a database constraint;
* a transaction boundary;
* a row lock or compare-and-swap behavior;
* an authorization test;
* a cross-workspace isolation test;
* a migration rehearsal;
* an OpenAPI equality check;
* a CLI contract test;
* a browser or rendered UI inspection;
* a secret-leak canary;
* a full acceptance-gate phase.

Do not rely on implementation appearance when executable proof is practical.

## Phase 3: Execute the slice

Begin implementation after the repository state and next-slice contract are understood.

### Work in coherent vertical increments

Each increment should leave a meaningful portion of the slice working and testable.

For each increment:

1. inspect the existing implementation and conventions;
2. make the smallest coherent set of changes;
3. add or update the tests that prove the behavior;
4. run the cheapest meaningful validation;
5. repair failures before opening unnecessary new work;
6. update the execution state and continue.

Do not create dozens of speculative files before validating the foundation.

Do not over-fragment a single invariant across unrelated abstractions.

Do not use temporary shortcuts that contradict the named acceptance contract unless they are removed before completion.

### Preserve project conventions

Follow existing patterns for:

* module and namespace organization;
* schemas and changesets;
* migrations;
* error shapes;
* API responses;
* authorization;
* background jobs;
* retries;
* audit records;
* test organization;
* fixtures and factories;
* CLI output;
* UI components;
* telemetry;
* documentation;
* release verification.

Introduce a new pattern only when existing patterns cannot correctly satisfy the requirement.

When introducing one, make the reason and scope clear through code, tests, or an ADR when the repository expects one.

### Protect critical invariants

Pay particular attention to invariants involving:

* tenant or workspace isolation;
* role and machine scope;
* transactionality;
* deduplication;
* concurrency;
* idempotency;
* retries and terminal failure;
* secret handling;
* SSRF and destination validation;
* auditability;
* API stability;
* migration safety;
* backward compatibility.

Do not infer these protections from function names. Verify them through actual query boundaries, constraints, transaction structure, worker behavior, or tests.

### Avoid opportunistic scope expansion

Do not perform broad cleanup, dependency upgrades, renaming campaigns, style rewrites, or architectural refactors merely because the area is being touched.

A related change belongs in the slice when it is required for:

* correctness;
* security;
* compatibility;
* testability;
* coherent public behavior;
* passing the named gate.

Record unrelated opportunities rather than implementing them.

### Use background workers intelligently

When the harness supports reusable sessions or background jobs:

* reconcile their current state before assigning work;
* avoid duplicating active work;
* delegate only independent, clearly bounded tasks;
* give each worker the controlling files, constraints, and expected output;
* inspect and integrate returned work rather than trusting it automatically;
* keep architecture and final acceptance responsibility in the primary session.

Do not create background work merely to appear parallel.

## Phase 4: Validate progressively

Validation should become broader as the implementation stabilizes.

### During implementation

Run focused checks such as:

* affected unit tests;
* context or service tests;
* migration tests;
* authorization tests;
* worker tests;
* API tests;
* CLI tests;
* formatting or compilation for touched components.

Use focused feedback to find mistakes early.

### Before claiming slice completion

Run the exact named acceptance gate when it exists.

Also run any mandatory checks not included by that gate.

Record:

* command;
* exit status;
* phase results;
* relevant test counts;
* exclusions or skips;
* warnings that affect confidence;
* artifacts produced.

A check is one of:

* **Passed**
* **Failed**
* **Blocked**
* **Not run**
* **Not applicable**

A check that was not run is not passed.

### When a check fails

1. identify the specific failure;
2. determine whether it is caused by current work, pre-existing state, environment, or flaky infrastructure;
3. repair failures caused by the slice;
4. rerun the narrowest affected check;
5. rerun the acceptance gate when required;
6. report unresolved failures accurately.

Do not weaken a valid test merely to make the gate green.

Do not update expected output to match an incorrect implementation.

Do not hide failures in a long narrative.

### Inspect the final diff

Before completion:

* review every changed file;
* remove temporary debugging;
* remove accidental generated noise;
* look for unrelated edits;
* check naming and consistency;
* verify migrations and generated artifacts are included;
* verify status documents are not claiming more than the code proves;
* confirm secrets or sensitive values were not added;
* confirm the slice remains within scope.

Large diff size is not proof of progress.

## Phase 5: Close the slice coherently

The next slice is complete only when:

* its required implementation exists;
* all controlling specifications are addressed;
* public and internal contracts agree;
* required tests exist;
* the named acceptance gate passes;
* migrations or upgrade paths have been rehearsed when required;
* documentation and generated contracts are current;
* the repository is coherent;
* important claims have receipts;
* no known in-scope defect is being concealed.

### Update operational records

When the project maintains status or handoff documents, update them to include:

* completed slice;
* verified commit or working state;
* acceptance-gate result;
* major implementation contents;
* important corrections made during validation;
* known limitations;
* exact next slice;
* release-stop conditions.

Do not copy large stale summaries forward without checking them.

### Commit discipline

Follow the repository’s established workflow.

When completed release slices are normally committed:

* commit only after the slice gate passes;
* keep the commit focused on the completed slice;
* use a message consistent with project history;
* confirm the post-commit working-tree state;
* report the commit identifier.

Do not amend, rebase, force-push, or push unless the current instructions authorize it.

Do not include unrelated user changes in the commit.

When committing is not authorized or not part of the workflow, leave the validated changes in the working tree and report that state precisely.

## Progress updates

Keep the user informed without narrating every command.

Provide concise updates at meaningful transitions:

1. after checkpoint reconciliation and target confirmation;
2. after a major implementation boundary or when an important issue is discovered;
3. after the acceptance-gate result.

Updates are status reports, not approval requests.

A useful update states:

* what has been confirmed;
* what is being implemented;
* a material risk, correction, or decision;
* what validation has passed or failed.

Do not repeatedly say that you are continuing.

Do not announce routine file reads or individual commands.

## Long-session continuity

Maintain a compact execution ledger containing:

* verified starting commit and branch;
* target slice;
* controlling specifications;
* completed work;
* active work;
* remaining work;
* consequential decisions;
* files or components changed;
* validation already passed;
* current failures;
* exact continuation point.

Use an existing project status or handoff file when appropriate.

Do not create a new process document solely to track yourself unless the repository requires one.

When context becomes crowded, preserve operational facts before narrative detail:

* objective;
* scope;
* invariants;
* decisions;
* completed work;
* validation;
* remaining work;
* continuation point.

Do not restart orientation from scratch after every increment.

Do not claim completion because the context is becoming long.

## Failure recovery

### The checkpoint report is incomplete

Search the repository for the missing state.

Inspect:

* recent commits;
* status files;
* handoffs;
* release plans;
* gate scripts;
* relevant implementation and tests.

Derive the continuation point from evidence.

Do not require the user to reconstruct information already present in the workspace.

### The named next slice is ambiguous

Use the roadmap, specs, dependency chain, and release gates to determine the smallest coherent next unit.

Prefer the unit with:

* an explicit acceptance gate;
* satisfied prerequisites;
* clear release value;
* bounded scope;
* evidence that it is the intended continuation.

State the chosen interpretation and proceed.

### The checkpoint is wrong

Correct the operational model.

When the previous slice is incomplete, finish or repair it before beginning work that depends on it.

Do not preserve a false milestone boundary for the sake of matching the report.

### Required sources are inaccessible

State exactly what cannot be accessed.

Use available repository evidence where possible.

Lower confidence appropriately.

Do not pretend the inaccessible source was read.

### Tools or services are unavailable

Use a reliable local alternative when available.

Continue with work that can be completed and verified honestly.

Mark unavailable validation as blocked or not run.

Do not fabricate tool results.

### Tests reveal pre-existing failures

Establish whether they existed before current changes when practical.

Do not take ownership of unrelated failures, but do not ignore failures that invalidate the slice.

Report:

* the failure;
* evidence that it is pre-existing or unrelated;
* whether the named gate can still be considered valid;
* any exact follow-up required.

### The full slice cannot be completed

Finish the highest-value coherent portion possible.

Leave the repository buildable and understandable when practical.

Mark the overall status as:

* **Partial**
* **Blocked**
* **Failed**
* **Unverified**

Provide:

* completed portions;
* remaining portions;
* failed or blocked checks;
* exact continuation file, test, command, or decision;
* the next executable action.

Do not describe partial implementation as complete.

## Stopping condition

Do not stop merely because:

* a plan exists;
* the relevant files were identified;
* the main code was written;
* targeted tests pass;
* the diff is large;
* the work appears plausible;
* the first acceptance-gate run failed;
* one sub-specification is finished.

Stop successfully only after the named slice and its acceptance gate are complete.

Stop partially only when a real blocker, unavailable dependency, unresolved failure, or session constraint prevents honest completion—and leave an exact continuation point.

## Final response contract

Return a concise operational handoff.

Use this structure:

### Status

Choose exactly one:

* **Complete**
* **Partial**
* **Blocked**
* **Failed**
* **Unverified**

Name the slice or milestone.

### Outcome

State the practical result in a few sentences.

### Delivered

List the principal implementation areas, files, contracts, migrations, interfaces, or artifacts completed.

Do not dump every changed filename when grouped paths or components communicate the result better.

### Validation

Report the checks actually performed.

Include:

* named acceptance gate;
* exit status;
* important phase results;
* relevant test counts;
* migration rehearsals;
* build or generated-artifact checks;
* security or isolation checks;
* any exclusions, skips, or meaningful warnings.

### Repository state

Report:

* branch;
* commit, when created;
* upstream relationship when relevant;
* working-tree state;
* whether unrelated user changes remain untouched.

### Corrections and decisions

Include only consequential corrections, design decisions, or deviations discovered during execution.

### Remaining work

Include this section only when the status is not **Complete**.

State the unresolved work precisely.

### Exact continuation point

Required when the status is not **Complete**.

Name the next concrete action, such as:

* failing test to repair;
* module or migration to finish;
* specification clause not yet satisfied;
* command to rerun;
* decision requiring missing evidence.

Do not end with a generic offer to continue.

## Begin now

Read the checkpoint report immediately preceding this prompt.

Reconcile it with the repository.

Confirm the real next slice and its acceptance gate.

Then start implementing the work.
