# Arsenal Research Provenance and Reproducibility

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft
Owner: ARS-00
Scope: Provenance and reproducibility rules for Arsenal research artifacts.

## Purpose

Research artifacts must be inspectable, traceable, and reproducible. This document expands the source hierarchy from `products/arsenal/docs/arsenal-experiment-contract.md` with concrete handling rules and states the provenance fields required on every evidence artifact.

## Provenance guidance

### Source hierarchy handling rules

The hierarchy from strongest to weakest is restated here with handling rules for each level.

1. **Executable repository / runtime evidence.**
   - Required: repository SHA, runtime identity, fixture digest, harness identity, raw evidence location.
   - May be cited as direct evidence for behavioral claims.
   - If the run is non-deterministic, record `seed_policy`, `model_identity`, `runtime_identity`, and `repetition_policy`.

2. **Reproducible experiment evidence.**
   - Required: experiment record with all mandatory fields, protocol version, protocol frozen timestamp, and derived evidence locations.
   - May support or falsify a hypothesis.
   - Must remain loadable and interpretable after the original run environment changes.

3. **Existing Invariant contracts and authoritative documentation.**
   - `contracts/`, `products/arsenal/arsenal/*/CONTRACT.md`, `products/arsenal/arsenal/capabilities/*.json`, `engineering/doctrine/`.
   - Cite exact file paths and, where possible, content digests.
   - Conflicts between authoritative sources must be recorded, not resolved by choosing the more convenient one.

4. **Research papers / primary external technical sources.**
   - Cite DOI, URL, version, and section.
   - Use for methodological context or for claims the source itself supports; do not extend the claim beyond the source.

5. **Transcripts / talks / interviews / demonstrations / anecdotal reports.**
   - Record as a `source_observation` or hypothesis source only.
   - Include date, speaker/author, and medium.
   - Never cite a transcript as experimental evidence.

6. **Inference.**
   - State premises explicitly.
   - Label confidence as bounded or limited.
   - Inference that contradicts a stronger source must be rejected or recorded as a known conflict.

### Conflict handling

When two sources of equal or unequal rank disagree:

- Preserve both claims.
- Record the source ranks and why each was considered.
- If the conflict affects the experiment result, classify the result as `inconclusive` until the conflict is resolved by stronger evidence.
- Do not average or vote away contradictions.

### Required provenance block fields

Every evidence artifact produced by Arsenal research must carry a provenance block with at least:

| Field | Value / rule |
|---|---|
| `arsenal_commit` | The Arsenal repository SHA the artifact was produced against. May be `null` only for pre-merge experimental drafts. |
| `harness` | Harness or evaluator identity, including version or digest. |
| `model` | Model identity when a model is in the loop; `not-applicable` otherwise. |
| `adapter` | Adapter identity when an adapter invokes an external procedure; `not-applicable` or omitted when none is used. |
| `remote_credentials_used` | Always `false` for Arsenal research artifacts. |

Additional provenance fields (task identity, fixture identity, runtime identity, repository identity, repetition number, seed) are required by the experiment record and should be included whenever they affect reproducibility.

## Reproducibility guidance

### Repository identity

Pin `repository_identity` by full SHA. Short SHAs or branch names are not sufficient for reproducibility. If multiple repositories are involved (e.g. Arsenal, Loadout, Kiln), record each SHA separately.

### Fixture digests

Compute fixture digests using the canonical rule:

```python
json.dumps(obj, sort_keys=True, separators=(",", ":"))
```

followed by SHA-256, with any self-referential digest field replaced by a 64-zero placeholder (`sha256:0000...0000`). This rule is implemented in `scripts/arsenal_method_record.py`, `scripts/arsenal_evaluate.py`, and `scripts/wave5_recon_bench.py`.

### Deterministic harnesses

Prefer deterministic harnesses. A deterministic harness must pass a run-twice digest comparison: two executions against the same fixture produce identical run digests. If the harness fails this test, it must be classified as non-deterministic and the additional provenance fields below must be recorded.

### Non-deterministic (model-in-loop) runs

When a model is in the loop, record:

- `model_identity`: model family, version, and provider when known.
- `runtime_identity`: the exact runtime, substrate, and tool versions.
- `seed_policy`: how seeds are set, fixed, or varied.
- `repetition_policy`: number of repetitions and whether they share seeds, contexts, or fixtures.

Do not report a single non-deterministic run as a generalized conclusion.

### Missing measurements

Missing measurements are recorded as `not-observed`, matching the Bench metrics vocabulary (`products/arsenal/evaluation/BENCH_CONTRACT.md`). They are never converted into zeroes, estimates, or silent omissions.

### Derived metrics

Every derived metric must name:

- the script that computed it;
- the raw evidence files or identifiers it derives from;
- the exact version of the derivation script;
- any assumptions or filters applied.

Derived metrics must be reproducible from the named raw evidence by running the named script.

### Anti-authority invariants

No Arsenal research artifact may carry tokens such as `filesystem.write`, `network.write`, `git.write`, `production.mutate`, or `cloud.remote`. `remote_credentials_used` is always `false`. No composite quality scores are permitted.
