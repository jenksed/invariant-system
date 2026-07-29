# P0-W19: Reconcile implementation-like assets

**Document type:** Planning work package  
**Status:** In progress  
**Branch:** `work/p0-w19-implementation-scaffold-reconciliation`  
**Depends on:** P0-W18 integrated through pull request 23  
**Scope:** Implementation inventory, status, blast radius, disposition, and Prompt 4 inputs only

## Objective

Inspect every material implementation-like Repository asset and record what exists, what it proves, what should survive, what must change later, and which unresolved planning decision blocks any disposition.

This pass does not implement, repair, remove, or reconfigure product source, tests, JSON Schemas, CI, scripts, Skills, prompts, specialist agents, dependencies, runtime configuration, or executable gates.

## Observed current state and evidence

- Pull request 23 is integrated into `main` at merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e`.
- That merge commit is the current `main` head at the start of P0-W19.
- ADR 0020 and the Prompt 2 delivery sequence are integrated.
- Production source contains one dependency-free Mix project, one public version function, and one empty application supervisor.
- Production tests contain one version assertion plus `ExUnit.start/0`.
- CI validates prose, obsolete preflight behavior, agent-asset shape, dependency installation, formatting, compilation, compile-connected cycles, and ExUnit.
- Eleven JSON Schema files exist as planning-conformance assets.
- No product Run, journal, provider, Context, Patch, Command, Evidence, Receipt, CLI, Child, or recovery capability is implemented.

## Assumptions and unknowns

### Assumptions

- Prompt 2 remains the accepted evaluation target.
- Documentation-only status and disposition records are sufficient for this pass.
- Existing executable and machine-readable assets must remain unchanged.

### Unknowns

- Exact Run transition and recovery rules.
- SQLite library, migrations, journal transactions, and replay design.
- Patch format, base binding, rollback, and dirty-state policy.
- Command registration, process-tree control, cancellation, and unknown-effect behavior.
- Provider disclosure, Context sealing, and secret screening.
- Evidence, Artifact, and Receipt retention.
- Later Child permission derivation and Attention behavior.

## Requirements

- Inventory every material production, test, Schema, CI, script, agent-facing, structural, and contract-like asset.
- Group assets into implementation units rather than treating every file as a separate capability.
- Assign one current status, blast-radius class, and explicit disposition to every material unit.
- Separate repository mechanics from product behavior and conformance from implementation.
- Record active safety issues, near-term hazards, conformance drift, misleading status, and deferred concerns without exaggeration.
- Provide implementation-grounded Prompt 4 inputs.
- Do not issue build authorization.

## Proposed changes

- Add a detailed implementation inventory and disposition authority.
- Add a blast-radius and planning-dependency register.
- Update only planning indexes or status references required to make the new record discoverable.
- Close this work record with exact final-head Evidence.

## Files or components expected to change

- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md` — new Prompt 3 authority.
- `docs/work/P0-W19-implementation-scaffold-reconciliation.md` — work record and verification Evidence.
- A planning index or README link only when required for discoverability.

No production source, test, JSON Schema, CI workflow, script, Skill, prompt, specialist-agent definition, dependency, runtime configuration, or executable gate shall change.

## Acceptance criteria

- Every material implementation-like asset is inventoried.
- Every first-month and cross-cutting unit has an explicit disposition.
- Every twelve-week unit has a disposition or named planning dependency.
- Every deferred unit has a review trigger.
- The Mix shell, empty supervisor, version surface, Schema package, preflight concept and implementation, preflight tests, CI enforcement, planned gates, agent assets, source layout, acceptance gates, and Receipts have explicit dispositions.
- Current green CI is described precisely without implying product completion.
- Prompt 4 receives implementation-grounded planning inputs.
- The final diff is documentation-only.
- Repository validation passes on the exact final branch head.

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Targeted inspection must also prove existing modules, tests, Schemas, scripts, workflow steps, agent assets, and absent `scripts/gates/*` commands.

## Required completion evidence

- Integrated Prompt 2 merge and current-main Evidence.
- Exact production module and test inventory.
- Exact script, CI, Schema, and agent-asset inventory.
- Implementation unit, status, blast-radius, and disposition tables.
- Safety and integrity findings.
- Prompt 4 planning inputs.
- Final compare against `main`.
- Exact final-head CI run.

## Explicit exclusions

P0-W19 does not:

- implement or refactor runtime behavior;
- change production source or tests;
- edit JSON Schemas;
- alter CI, scripts, preflight, or validation logic;
- change Skills, prompts, or specialist agents;
- add dependencies, migrations, provider code, Context, Tools, Patch logic, Commands, Evidence, Receipts, CLI behavior, or gate scripts;
- remove implementation-like assets;
- sequence the final Planning Round Register;
- begin Prompt 4;
- issue build authorization.
