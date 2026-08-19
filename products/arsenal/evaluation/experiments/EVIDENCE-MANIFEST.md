# Arsenal Experiment Evidence Manifest Template

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft

Use this template as `evaluation/experiments/<ars-NNN-short-name>/EVIDENCE-MANIFEST.md` after running an experiment. Evidence is referenced, not copied.

## Experiment identity

- experiment_id: `<placeholder: ars-NNN>`
- protocol_version: `<placeholder: e.g. 0.1.0>`
- protocol_frozen_at: `<placeholder: ISO-8601 timestamp>`
- manifest_digest: `<placeholder: sha256:<64-hex> or 64-zero placeholder until computed>`

## Raw evidence

| path | kind | digest | produced_by |
|------|------|--------|-------------|
| `<placeholder: path/to/raw/run-001.jsonl>` | `<placeholder: run-log / transcript / verifier-output / fixture-state / model-output>` | `sha256:<64-hex>` | `<placeholder: model/harness/script identity>` |
| `<placeholder: path/to/raw/run-002.jsonl>` | `<placeholder>` | `sha256:<64-hex>` | `<placeholder>` |

## Derived evidence

| path | kind | derived_from | digest | reproduction_command |
|------|------|--------------|--------|----------------------|
| `<placeholder: path/to/summary.json>` | summary | `<placeholder: raw evidence paths>` | `sha256:<64-hex>` | `<placeholder: command that regenerates this artifact from raw evidence>` |
| `<placeholder: path/to/analysis.md>` | analysis | `<placeholder>` | `sha256:<64-hex>` | `<placeholder>` |

## Determinism statement

`<placeholder>`

State whether repeated runs with the same fixture, task, model, harness, runtime, repository, and seed produce identical digests. If not, disclose the source of non-determinism and how it is bounded.

## Not-observed metrics

`<placeholder>`

List metrics declared by the protocol that were not observed in this run. Missing metrics remain `not-observed`; they are not converted into zeroes.

## Limitations

`<placeholder>`

Reiterate limitations that bound interpretation of this evidence.

## Retention policy

`<placeholder>`

Failed runs, baseline wins, ablation wins, neutral outcomes, unhealthy cases, and invalidated cases must be retained per `../BENCH_CONTRACT.md`. State the retention location and expiry, if any.
