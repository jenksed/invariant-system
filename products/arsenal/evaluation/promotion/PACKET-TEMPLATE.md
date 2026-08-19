# Arsenal Promotion Packet Template

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft

Use this template to propose that a research result be considered for promotion to a product, contract, or capability decision. A packet PROPOSES; the external product or runtime authority DECIDES. Arsenal never promotes its own work by writing a packet.

## Preamble rules

- `SUPPORTED` ≠ `QUALIFIED` ≠ `PROMOTED`. A supported experiment result is not, by itself, qualified.
- Qualification of a method additionally requires the Qualified Method Record path (`evaluation/method-records/`).
- The packet must list known counterexamples and limitations; hiding them is grounds for rejection.
- `do-not-promote` is a successful research outcome. The packet still records it.
- Promotion decisions bind to a specific repository/runtime identity; record currentness constraints explicitly.

## supported_claim

`<placeholder>`

The exact claim the evidence supports, scoped to the observed context.

## claim_scope

`<placeholder>`

Where the claim applies and where it does not. Include product, repository, adapter, model, and runtime boundaries.

## falsified_alternatives

`<placeholder>`

Alternatives that were considered and falsified, or why the baseline remains competitive.

## experiment_ids

`<placeholder>`

Array of experiment identifiers (e.g. `ars-001`, `ars-003`) whose evidence supports the packet.

## replication_status

`<placeholder>`

Whether the result has been replicated, on what corpus, and any divergence observed.

## raw_evidence

`<placeholder>`

| path | digest |
|------|--------|
| `evaluation/experiments/<ars-NNN>/evidence/raw/...` | `sha256:<64-hex>` |

## derived_evidence

`<placeholder>`

| path | reproduction_command | digest |
|------|----------------------|--------|
| `evaluation/experiments/<ars-NNN>/evidence/derived/...` | `<command>` | `sha256:<64-hex>` |

## known_counterexamples

`<placeholder>`

List any cases, contexts, or inputs where the supported claim fails or weakens.

## limitations

`<placeholder>`

List limitations that bound the claim and any proposed runtime change.

## currentness_constraints

`<placeholder>`

- repository_identity / commit SHA the evidence binds to:
- runtime_identity / version the evidence binds to:
- staleness boundary (how long the evidence remains valid without re-run):

## affected_product

`<placeholder>`

One of: `kiln`, `loadout`, `manifold`, `bench`, `temper`, `arsenal`.

## affected_contracts

`<placeholder>`

Array of contract identity strings (e.g. `engineering-system/qualified-method-record/v0`).

## proposed_runtime_change

`<placeholder>`

Concrete change proposed to the affected product or runtime, if any. If no change is proposed, state "none — informational packet only."

## expected_property_improvement

`<placeholder>`

The property or metric expected to improve if the change is adopted.

## possible_new_failure_modes

`<placeholder>`

New failure modes the change could introduce.

## rollback_strategy

`<placeholder>`

How to revert or disable the change if it fails in production.

## promotion_recommendation

`<placeholder>`

One of:

- `promote`
- `do-not-promote`
- `gather-more-evidence`

## human_decision

`<placeholder>`

| field | value |
|-------|-------|
| decision | `pending` / `accepted` / `rejected` |
| decided_by | `<placeholder: name or role>` |
| decided_at | `<placeholder: ISO-8601 timestamp>` |
| rationale | `<placeholder: why the authority accepted or rejected the proposal>` |
