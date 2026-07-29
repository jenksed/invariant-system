# Kiln Domain Contracts

**Document type:** Contract authority index  
**Status:** First-month conformance active; historical broad contracts deferred  
**Implementation status:** Conformance support only  
**Build authorization:** P1-S01 only after Prompt 8-A merges

## Current required contract

`kiln-first-month.schema.json` is the only recurring machine-readable contract in the active first-month subset.

It covers:

- Root Run projection state;
- sealed MiniMax M3 Context manifest and four-Tool maximum;
- complete-text Patch manifest;
- local-user Patch Approval;
- registered non-shell Command and terminal result;
- criterion Evidence and evaluation;
- non-authoritative product Receipt;
- CLI result status and exit code.

The Schema is a bounded contract subset. It is not a database layout, full product serialization model, permission grant, runtime implementation, or proof that any external effect exists.

## Dual validation

Install the project-scoped validator:

```bash
python3 -m pip install -r requirements/conformance.txt
```

Run both validators:

```bash
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
```

The validators have different responsibilities.

### Semantic validator

`scripts/validate_first_month_contracts.py` protects relationships and rules that the current Schema does not express completely, including:

- known Command completion requires proved process-group cleanup;
- passing Evidence must be current, complete, and non-contradicted;
- CLI status and exit code must agree;
- Patch operation relationships and exact protected limits.

### Draft 2020-12 validator

`scripts/validate_json_schema_contracts.py` uses pinned `jsonschema==4.26.0` to:

- validate the Schema against Draft 2020-12;
- reject non-local `$ref` values;
- validate every positive fixture;
- confirm every protected negative fixture matches its declared Schema disposition;
- verify the pinned validator version.

The script performs no network access. CI installs the pinned package before validation.

Each negative fixture states whether Schema validation must accept or reject it. Every current negative fixture must still be rejected by the semantic validator.

Schema validation and semantic validation are complementary. Neither can claim the other's result.

## Executable Elixir conformance

The `Kiln.Conformance` modules expose only:

- accepted constants and transition shapes;
- a temporary provider behaviour boundary;
- a temporary macOS Command-host behaviour boundary.

They perform no external effect.

Prompt 8-A dispositions:

| Scaffold | Disposition | Reason |
| --- | --- | --- |
| `Kiln.Conformance.FirstMonth` | Revise and retain | accepted constants remain useful; the product-like `scaffold_status/0` export was removed |
| `Kiln.Conformance.Provider` | Retain temporarily | callback seam is useful; broad `map()` types must be replaced by authorized typed requests before provider implementation |
| `Kiln.Conformance.CommandHost` | Retain temporarily | callback seam protects the host boundary; typed protocol records belong to the later authorized Command ticket |
| conformance constant tests | Retain | protect accepted decisions and deferred scope |
| absent-runtime-module test | Remove | named future modules created unnecessary namespace lock-in |
| first-month Schema | Revise and retain | now receives actual Draft 2020-12 validation |
| semantic validator | Retain | protects cross-field invariants |
| preflight and CI wiring | Revise and retain | now runs dual validation |

The conformance namespace is not product domain state. Authorized runtime code must use the focused authorities and its own accepted types.

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

They are not one active contract set, implementation backlog, or authorization source.

They cannot force:

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

A later authorized ticket can reuse a compatible historical field only after mapping it to a focused authority and adding current positive and protected negative fixtures.

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
10. A product Receipt has no authority and is sealed only after committed completion.
11. CLI status and exit code must agree.
12. No first-month contract includes Child or Wave B concepts.

## Extension rule

Prompt 8-A authorizes only the exact P1-S01 ticket sequence recorded in the final adjudication.

A new or changed contract requires:

- an owning accepted authority;
- a bounded implementation purpose;
- positive fixtures;
- protected negative fixtures;
- recurring Schema and semantic validation when applicable;
- an explicit disposition of superseded fields;
- no fake success.
