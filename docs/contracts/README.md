# Kiln Domain Contracts

**Document type:** Contract authority index  
**Status:** First-month conformance active; historical broad contracts deferred  
**Implementation status:** Conformance scaffolding only  
**Build authorization:** Not issued

## Current required contract

`kiln-first-month.schema.json` is the only recurring machine-readable contract required before Prompt 8-A.

It covers the narrow records exercised by the accepted Single-Run plan:

- Root Run projection state;
- sealed MiniMax M3 Context manifest and four-Tool maximum;
- complete-text Patch manifest;
- local-user Patch Approval;
- registered non-shell Command and terminal result;
- criterion Evidence and evaluation;
- non-authoritative Receipt;
- CLI result status and exit code.

Validation:

```bash
python3 scripts/validate_first_month_contracts.py
```

The validator checks the Schema's protected enums and limits, accepts the positive fixtures, and proves each protected negative fixture fails for its expected reason.

This contract is not:

- runtime implementation;
- a database layout;
- a complete serialization format for every planned field;
- permission or authority;
- proof that a provider, Store, Patch engine, Command runner, Evidence evaluator, Receipt sealer, or CLI exists;
- build authorization.

## Executable Elixir conformance

The `Kiln.Conformance` modules expose only:

- accepted constants and transition shapes;
- provider behaviour callbacks;
- macOS Command-host behaviour callbacks.

They provide no external-effect implementation.

Tests explicitly require these runtime modules to remain absent during Prompt 6-A:

- Store and Session runtime;
- MiniMax adapter;
- Context builder and Repository reader;
- Patch and mutation Worker;
- Command Worker;
- Evidence and Receipt runtime;
- CLI.

## Historical broad Schemas

These files preserve earlier planning and remain deferred review inputs:

- `kiln-core.schema.json`;
- `kiln-execution.schema.json`;
- `kiln-evidence.schema.json`;
- `kiln-capability.schema.json`;
- `kiln-context.schema.json`;
- `kiln-git-change.schema.json`;
- `kiln-delegation.schema.json`;
- `kiln-interface.schema.json`;
- `kiln-knowledge.schema.json`;
- `kiln-knowledge-security.schema.json`;
- `kiln-execution-plane.schema.json`.

They are not one active contract set and are not implementation backlog.

Prompt 6-A does not rewrite all historical Schemas. It prevents them from forcing:

- deferred Run states;
- Agent catalogs;
- generalized Capability brokerage;
- runtime Skills;
- worktrees;
- TUI or external Client state;
- Child Runs;
- code or project intelligence;
- telemetry or attestations;
- protocols, containers, or remote execution.

A later authorized ticket can reuse a compatible historical field only after mapping it to the focused authority and adding current fixtures.

## Protected first-month rules

1. Root Run states are `ready`, `running`, `waiting_for_user`, `orphaned`, `completed`, `failed`, and `canceled`.
2. Workflow step and external-operation state remain separate from Run state.
3. MiniMax M3 is the only real provider; fallback is false.
4. At most four Tool schemas exist: `repo.search`, `repo.read`, `artifact.read`, and `change.propose`.
5. Patches support only complete-text `add`, `replace`, and `delete` operations.
6. Approval actor is the local user.
7. Registered Commands do not use a shell.
8. Known terminal Command cleanup requires the process group to be proved gone.
9. Passing Evidence is current, complete, and non-contradicted.
10. A Receipt has no authority.
11. CLI status and exit code must agree.
12. No first-month contract includes Child or Wave B concepts.

## Extension rule

Prompt 8-A can authorize implementation against this subset. It cannot silently authorize every historical Schema.

A new or changed contract requires:

- an owning accepted authority;
- a bounded implementation purpose;
- positive fixtures;
- protected negative fixtures;
- recurring validation;
- an explicit disposition of any superseded field;
- no fake success.
