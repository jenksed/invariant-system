# Arsenal Negative Knowledge Catalog

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft

This catalog records durable negative results, rejected methods, excluded contexts, observed failures, contract gaps, and deferred ideas for the Arsenal research program. It instantiates the rejected-decision-memory pattern defined in `../../foundations/rejected_decision_memory.md`.

## Rules

- Negative results are first-class. Publish losses per `../BENCH_CONTRACT.md`.
- Entries are never deleted. They may be superseded by a new entry with a backward link.
- Every entry has reconsideration triggers consistent with `../../foundations/rejected_decision_memory.md`.
- Every entry cites inspectable evidence paths; content is not copied here.

## Entries

### NK-001 — Wave 5 rejected-then-repaired selection candidates

- kind: `observed-failure`
- claim / what was tried: During Wave 5 Repository Recon selection, several candidates produced misses that were rejected and repaired before the winner was locked. The misses included an invalid filesystem-presence claim for an unmaterialized Kiln gitlink and retained Elixir punctuation in raw manifest lines.
- evidence references:
  - `../wave5/SELECTION-AND-ABLATION.md`
  - `../wave5/winner-lock.v1.json`
- status: `active`
- reconsideration triggers:
  - A new selection campaign that changes the adapter, target product, or corpus.
  - A revision to the Repository Recon method that removes the staged-composition boundary.

### NK-002 — Wave 5 miss taxonomy classes A–F

- kind: `excluded-context` / `observed-failure` classification scheme
- claim / what was tried: Wave 5 established a canonical failure classification for Repository Recon misses: A DETECTION_MISS, B RELATIONSHIP_MISS, C PRIORITIZATION_MISS, D INFERENCE_MISS, E INTENTIONALLY_UNKNOWN, F INVALID_EXPECTATION.
- evidence references:
  - `../wave5/miss-taxonomy.v1.json`
  - `../wave5/SELECTION-AND-ABLATION.md`
- status: `active`
- reconsideration triggers:
  - New miss classes observed outside A–F in a subsequent campaign.
  - Contract evolution that changes the evaluator's classification responsibility.

### NK-003 — Canonical recon QMR: no behavioral efficacy evidence in v0

- kind: `observed-failure`
- claim / what was tried: The canonical Repository Recon QMR for `architecture-anchor-incremental` lists observed failures including the inability to execute behavioral efficacy cases for v0 and the absence of a qualification receipt for `capability.recon`. The record therefore remains `experimental` and cannot be promoted to `qualified`.
- evidence references:
  - `../method-records/repository-recon.architecture-anchor.v0.yaml`
- status: `active`
- reconsideration triggers:
  - A qualification receipt for `capability.recon` is emitted by the bench.
  - The record's `observed_failures` are addressed by new execution evidence.

### NK-004 — QMR v0 adapter / target binding gap

- kind: `contract-gap`
- claim / what was tried: QMR v0 can carry only one `procedure_ref`. It cannot canonically state which product target and adapter an evaluation exercised, so Wave 5 cannot mark the winner `qualified` under QMR v0.
- evidence references:
  - `../wave5/CONTRACT-ADJUDICATION-REQUIRED.md`
  - `../../docs/arsenal-method-evaluation.md`
- status: `active`
- reconsideration triggers:
  - Contract evolution decision on `engineering-system/qualified-method-record/v0` or a successor.
  - Introduction of a canonical evaluation-target binding containing target_product, target_commit, target_procedure_digest, adapter_id, adapter_version_or_digest, evaluation_suite_digest, and result_digest.

### NK-005 — Composite quality scores refused by evaluation validators

- kind: `rejected-method`
- claim / what was tried: Arsenal evaluation rejects composite quality scores. Metrics must remain decomposed (outcome, process, efficiency, durability) and missing metrics must stay `not-observed` rather than being converted to zeroes.
- evidence references:
  - `../../docs/arsenal-method-evaluation.md`
  - `../BENCH_CONTRACT.md`
- status: `active`
- reconsideration triggers:
  - A new product requirement that can demonstrate why a composite score improves decision quality without hiding losses.
  - External contract change explicitly allowing composite scores.
