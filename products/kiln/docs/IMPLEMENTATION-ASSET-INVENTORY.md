# Implementation-Like Asset Inventory

**Document type:** Observed Repository inventory  
**Status:** Proposed by P0-W19  
**Baseline commit:** `33da2a718d8d5305bf89035503ac372f07e80a6e`  
**Scope:** Current implementation-like files and absent expected paths

## 1. Purpose

This inventory records what exists without assigning product capability to names, tests, Schemas, or planned paths.

`docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` assigns status, blast radius, and future disposition.

## 2. Production application

### 2.1 Mix project

**Path:** `mix.exs`

Observed:

- application: `:kiln`;
- version: `0.1.0-dev`;
- Elixir requirement: `~> 1.20`;
- application callback: `Kiln.Application`;
- extra application: `:logger`;
- dependencies: none;
- `check` alias: format, warnings-as-errors compilation, and ExUnit.

Not present:

- `mix.lock`;
- runtime dependency;
- database dependency;
- CLI dependency;
- provider dependency;
- Patch dependency;
- process-control dependency.

### 2.2 Public module

**Path:** `lib/kiln.ex`

Observed public function:

```elixir
Kiln.version/0
```

The function returns the literal `0.1.0-dev`.

No public domain workflow function exists.

### 2.3 Application callback

**Path:** `lib/kiln/application.ex`

Observed:

- implements `Application.start/2`;
- defines `children = []`;
- starts `Kiln.Supervisor` with `:one_for_one`.

No child process exists.

No Session, Run, database, provider, Command, scheduler, publisher, or interface process starts.

### 2.4 Runtime configuration

`config/config.exs` does not exist.

No runtime configuration file defines:

- Repository roots;
- SQLite paths;
- provider credentials;
- network destinations;
- Commands;
- disclosure rules;
- Artifact storage;
- retention;
- CLI behavior.

## 3. Tests

### 3.1 ExUnit bootstrap

**Path:** `test/test_helper.exs`

Observed behavior:

```elixir
ExUnit.start()
```

### 3.2 Product test file

**Path:** `test/kiln_test.exs`

Observed test:

- asserts `Kiln.version() == "0.1.0-dev"`;
- uses `async: true`.

No test proves:

- application child startup;
- domain construction;
- Run transitions;
- persistence;
- replay;
- provider behavior;
- Context limits;
- Repository reads;
- Patch behavior;
- Approval;
- Command execution;
- Evidence;
- Receipt;
- CLI;
- recovery;
- delegated work.

No fixture, integration test, property test, skipped product test, or generated product test was found.

## 4. Development tool configuration

### 4.1 Tool versions

**Path:** `mise.toml`

Pinned:

- Erlang 28.4;
- Elixir 1.20.2 for OTP 28;
- Vale 3.14.2.

### 4.2 Formatter

**Path:** `.formatter.exs`

Inputs include:

- `mix.exs`;
- `.formatter.exs`;
- Elixir and ExUnit files under `config/`, `lib/`, and `test/`.

The formatter pattern includes `config/`, but that directory has no current runtime configuration file.

### 4.3 Vale

**Path:** `.vale.ini`

Observed:

- Markdown uses the `Kiln` style;
- engineering-quality guidance disables two rules for its own explanatory content.

Observed custom styles:

- `styles/Kiln/Terms.yml`;
- `styles/Kiln/Marketing.yml`;
- `styles/Kiln/VagueCompletion.yml`.

These rules validate prose. They do not validate product behavior.

## 5. Executable Repository scripts

Four executable Bash scripts were found.

### 5.1 `scripts/agent-preflight`

Observed behavior:

- resolves and enters Repository root;
- rejects detached HEAD;
- rejects `main`, `master`, and `develop`;
- accepts named branch classes;
- requires `AGENTS.md` and three development references;
- recognizes only `work/pN-wNN-*` work grammar;
- requires one matching P0 work plan;
- checks obsolete plan headings;
- rejects every other `work/*` branch;
- prints Repository, branch, commit, plan, and dirty state.

Accepted P1 ticket grammar is not supported.

### 5.2 `scripts/test-agent-preflight`

Observed cases:

- old P0-W03 branch passes;
- malformed P0 branch fails;
- `main` fails;
- unknown branch class fails.

No P1-SXX-TXX positive or negative case exists.

No current implementation-plan heading fixture exists.

### 5.3 `scripts/validate-agent-assets`

Observed behavior:

- requires at least one Skill, specialist agent, and prompt;
- validates Skill names, directory names, and descriptions;
- validates specialist name, description, and Tool allowlist;
- rejects `edit` and `write` Tools;
- requires start, review, and close prompts;
- requires invariant `KILN-INV-014`.

It does not evaluate semantic compatibility with current planning.

### 5.4 `scripts/check`

Observed sequence:

1. `scripts/test-agent-preflight`;
2. `scripts/validate-agent-assets`;
3. `vale .`;
4. `mix format --check-formatted`;
5. `mix compile --warnings-as-errors`;
6. compile-connected cycle detection;
7. `mix test`.

Not included:

- complete JSON Schema validation;
- documentation-reference validation;
- product slice gate;
- demo;
- Receipt validation;
- end-to-end workflow.

## 6. CI workflow

**Path:** `.github/workflows/ci.yml`

Triggers:

- pull requests;
- pushes to `main`.

Jobs:

### Prose

- checkout;
- Vale action.

### Test

- checkout;
- Erlang and Elixir setup;
- Mix cache restore;
- preflight behavior test;
- agent-asset validation;
- dependency installation;
- format check;
- warnings-as-errors compile;
- compile-connected cycle check;
- ExUnit.

CI contains no product-behavior job.

CI contains no complete Schema job.

CI contains no gate, demo, Receipt, packaging, or release job.

## 7. Development-agent assets

### 7.1 Skills

Five Skill files were found:

- `.agents/skills/kiln-work-package/SKILL.md`;
- `.agents/skills/kiln-evidence-closeout/SKILL.md`;
- `.agents/skills/kiln-integrity-review/SKILL.md`;
- `.agents/skills/kiln-dependency-review/SKILL.md`;
- `.agents/skills/kiln-elixir-otp/SKILL.md`.

### 7.2 Specialist agents

Three specialist definitions were found:

- `.pi/agents/kiln-verifier.md`;
- `.pi/agents/kiln-otp-reviewer.md`;
- `.pi/agents/kiln-integrity-reviewer.md`.

All are configured without `edit` or `write` Tools.

The verifier can use Bash for non-mutating checks.

### 7.3 Prompts

Three required prompts were found:

- `.pi/prompts/start-work.md`;
- `.pi/prompts/review-work.md`;
- `.pi/prompts/close-work.md`.

The work-package Skill, start prompt, verifier, and closeout flow call current scripts. They inherit the current script limitations.

These assets help build Kiln. They do not prove Kiln runtime Agents, Skills, Scout Runs, or Verifier Runs.

## 8. JSON Schema assets

Eleven JSON Schema files were found:

1. `docs/contracts/kiln-core.schema.json`;
2. `docs/contracts/kiln-execution.schema.json`;
3. `docs/contracts/kiln-evidence.schema.json`;
4. `docs/contracts/kiln-capability.schema.json`;
5. `docs/contracts/kiln-context.schema.json`;
6. `docs/contracts/kiln-git-change.schema.json`;
7. `docs/contracts/kiln-delegation.schema.json`;
8. `docs/contracts/kiln-interface.schema.json`;
9. `docs/contracts/kiln-knowledge.schema.json`;
10. `docs/contracts/kiln-knowledge-security.schema.json`;
11. `docs/contracts/kiln-execution-plane.schema.json`.

### 8.1 Contract index

**Path:** `docs/contracts/README.md`

The index states that the package is conformance scaffolding and is not implemented.

It records:

- first-month candidates;
- deferred families;
- known Prompt 2 conflicts;
- retained contract rules;
- absence of a recurring complete validation command.

### 8.2 Cross-family overlap

Observed overlap includes:

- Run states in core and delegation;
- Command records in execution and execution-plane;
- Patch and Change set records in evidence, Git, and execution-plane;
- Receipt records in evidence and execution-plane;
- Context records in core and Context;
- Capability records in execution and capability;
- interface Run state repeated from domain planning.

No runtime consumer selects one owner.

### 8.3 Deferred detail present in Schemas

Observed deferred detail includes:

- Agent catalogs;
- runtime Skills;
- generalized capability selection;
- TUI and broad Client state;
- depth-two delegation;
- worktree leases;
- containers;
- semantic and external retrieval;
- local project intelligence;
- telemetry;
- attestations.

## 9. Repository structure

Actual product source tree:

```text
lib/
├── kiln.ex
└── kiln/
    └── application.ex
```

Actual test tree:

```text
test/
├── kiln_test.exs
└── test_helper.exs
```

No premature product namespace was found.

Not present:

- `domain/`;
- `store/`;
- `repository/`;
- `model/`;
- `context/`;
- `policy/`;
- `execution/`;
- `artifacts/`;
- `evidence/`;
- `receipt/`;
- `cli/`;
- `delegation/`;
- `attention/`;
- `tui/`;
- `knowledge/`;
- `protocols/`.

Their absence is not an implementation defect before an accepted ticket creates a real responsibility.

## 10. Documentation with contractual effect

Current documents likely to guide implementation directly include:

- `AGENTS.md`;
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`;
- `docs/ARCHITECTURE.md`;
- `docs/ROADMAP.md`;
- `docs/IMPLEMENTATION-SLICES.md`;
- `docs/SLICE-ACCEPTANCE-GATES.md`;
- `docs/RUN-MODEL.md`;
- `docs/SESSION-MODEL.md`;
- `docs/DELEGATED-WORK.md`;
- `docs/CLI-TUI.md`;
- `docs/AGENT-FRIENDLY-CODEBASE.md`;
- `docs/BRANCHING-AND-WORK-PLANNING.md`;
- `docs/templates/IMPLEMENTATION-PLAN.md`;
- accepted ADRs;
- `docs/PROJECT-INVARIANTS.md`;
- `docs/contracts/README.md` and Schema files.

Observed implementation pressure:

- module names and paths;
- ticket names;
- state lists;
- command names;
- gate paths;
- Receipt names;
- data fields;
- process examples;
- future adapter types.

These records remain planning or conformance assets until source and tests implement an accepted ticket.

## 11. Planned but absent product commands

Documented paths include:

- `scripts/gates/slice-01`;
- `scripts/gates/slice-02`;
- `scripts/gates/slice-03`;
- `scripts/gates/slice-04`;
- `scripts/gates/slice-05`;
- `scripts/gates/version-0-1`.

No `scripts/gates/` command exists.

No empty path should be created to reserve a planned name.

## 12. Current absence summary

No current product source or test implements:

- Workspace or Project registration;
- Session or Task state;
- Root Run identity or lifecycle;
- event envelope or journal;
- SQLite persistence, migrations, replay, or projections;
- transcript storage;
- provider invocation or fake provider;
- Context package or Tool projection;
- Repository read or search policy;
- secret screening or disclosure decision;
- Patch proposal, Approval, application, rollback, or mutation observation;
- Command registration, Worker, timeout, cancellation, output, or cleanup;
- Artifact storage;
- Evidence freshness or criterion evaluation;
- Receipt generation;
- CLI request or result;
- restart or orphan recovery;
- Scout, Verifier, Attention, delivery, or Child navigation;
- TUI, code intelligence, protocol, knowledge, telemetry, remote execution, or attestation behavior.

This absence is the observed implementation maturity. It is not a failed product test because build authorization has not been issued.
