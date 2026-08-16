# Arsenal Method Evaluation (ARS-04)

Status: accepted (ARS-04 v0); adapter infrastructure added in ARS-W3 Phase 1
Owner: ARS-04

## Purpose

ARS-04 is the deterministic, local-only evaluation surface for Project
Arsenal's Repository Recon method. It answers the question:

> Given the canonical Repository Recon method
> (`repository-recon/architecture-anchor-incremental`) and a bounded
> local-repository corpus, what can Arsenal honestly say about the
> method's behavior in v0?

ARS-04 is NOT:

* a leaderboard generator;
* a composite quality scorer;
* a behavioral-efficacy benchmark (it does not run models or
  harnesses);
* a runtime authority surface (it grants no filesystem, network,
  Git, or production authority);
* a capability promoter (it never writes to
  `capability.lifecycle` or `capability.evaluation.status`);
* a Loadout source importer (the adapter surface wraps external
  procedures without importing or depending on Loadout).

ARS-04 IS:

* a deterministic, run-twice-and-compare-the-digest evaluator over
  on-disk repository fixtures;
* a QMR-evidence emitter: the run can optionally emit a revised
  QMR that always stays `status: experimental`;
* a closed-shape artifact whose schema, metric set, and conclusion
  vocabulary are versioned and machine-checkable;
* an adapter-configurable evaluator: the procedure-invocation
  adapter can be switched between the internal fixture procedure
  (the canonical default) and an external adapter (currently a
  shell placeholder for the eventual Loadout productized procedure).

## Surface

```text
scripts/arsenal_evaluate.py
├── repository-recon   # the only v0 subcommand
│   --corpus PATH
│   --out PATH
│   --revised-qmr PATH       (optional)
│   --adapter NAME           (default: internal-fixture-procedure)
│   --adapter-input PATH     (required for shell-loadout-recon)
└── validate
    --artifact PATH
```

`repository-recon` evaluates the canonical method against the
default corpus at
`evaluation/method-cases/corpus.manifest.json`, emits an evaluation
artifact at the chosen `--out` path, and (optionally) emits a
revised QMR at the chosen `--revised-qmr` path.

`validate <artifact>` re-validates a previously-emitted artifact.
It checks the schema, the closed epistemic-conclusion vocabulary,
the closed qualification-gap label set, the auto-promotion flags
(which must all be `false`), and the deterministic run digest.

## Adapter surface (ARS-W3)

The evaluator can be configured to invoke an external procedure
through the adapter package at `evaluation/adapters/`. The
default is the internal fixture procedure
(`internal-fixture-procedure`); Phase 1 added the
`shell-loadout-recon` placeholder; Phase 2 added the
`loadout-runtime` adapter that shells out to the Loadout W3
checkpoint's `runRepositoryRecon` procedure.

| Adapter name                  | Module                                                                  | Phase | Description |
|-------------------------------|-------------------------------------------------------------------------|-------|-------------|
| `internal-fixture-procedure`  | `evaluation.adapters.internal_fixture_adapter`                          | v0    | The canonical internal procedure. Default. |
| `shell-loadout-recon`         | `evaluation.adapters.shell_loadout_adapter`                             | W3-P1 | Reads pre-emitted findings from a JSON file. Used for fixture-only test surfaces. |
| `loadout-runtime`             | `evaluation.adapters.loadout_runtime_adapter`                           | W3-P2 | Shells out to the Loadout W3 checkpoint (`runRepositoryRecon`). Read-only; no target mutation; no Arsenal source import of Loadout. |

Adapter contract (Wave 3 frozen invariants):

1. An adapter MUST NOT import Loadout source code (no Python
   `import` of any Loadout module).
2. An adapter MUST NOT depend on Loadout runtime (no bundling of
   Loadout source; Phase 2 may shell out to a Node.js procedure
   the operator points the adapter at).
3. An adapter MUST be deterministic and read-only with respect to
   the target repository (no writes to the repo, no network, no
   remote credentials).
4. An adapter MUST emit findings in the documented shape
   (`kind`, `subject`, `evidence`, `actual`).
5. A broken adapter MUST produce strictly worse evaluation
   evidence. There is no silent fallback to the internal fixture
   procedure; the evaluator refuses to mask a broken candidate.

The artifact records the adapter identity under
`provenance.adapter`:

```json
{
  "provenance": {
    "adapter": {
      "name": "loadout-runtime",
      "input": null,
      "module": "evaluation.adapters.loadout_runtime_adapter:LoadoutRuntimeAdapter",
      "loadout_root": "/path/to/loadout-installation"
    }
  }
}
```

The `provenance.adapter` block is mandatory on every artifact,
so every emitted artifact is self-describing about which procedure
produced the findings.

## Loadout runtime adapter (ARS-W3 Phase 2)

The `loadout-runtime` adapter invokes the Loadout Repository
Recon v1 procedure (`runRepositoryRecon`) at the exact checkpoint
supplied by the Loadout Wave 3 maintainer (currently
`d95927fbb675902d0fba992684b101ff60ff5a52`). The adapter:

1. Resolves the procedure at
   `<loadout-root>/dist/packs/repository-recon/run.js` (built) or
   `<loadout-root>/src/packs/repository-recon/run.ts` (source
   fallback).
2. Writes a small ESM bootstrap to a private temp file and runs
   it through `node`. The bootstrap dynamically imports the
   procedure by absolute path and prints the result as JSON on
   stdout. The bootstrap is removed in a finally block.
3. Captures the `ReconResultV1` JSON, rejects it if the schema is
   not `loadout/repository-recon/v1`, and translates the result
   1:1 into Arsenal findings.
4. Emits a presence finding (`actual=True`) for every detected
   architecture anchor.
5. Emits presence findings (`actual=False`) for every canonical
   path implied by an `architecture_anchor:KIND` unknown (the
   canonical catalogues are mirrored verbatim from the Loadout
   source so the translation is transparent and reviewable).
6. Does NOT supplement Loadout outputs with internal-procedure
   checks. Arsenal-specific paths that Loadout does not catalog
   produce FAILURE outcomes in the evaluation -- which is the
   honest output-driven signal that Loadout's catalogue differs
   from Arsenal's.

CLI:

```bash
python3 scripts/arsenal_evaluate.py repository-recon \
    --adapter loadout-runtime \
    --loadout-root /path/to/loadout \
    --corpus evaluation/method-cases/corpus.manifest.json \
    --out .arsenal-eval/repository-recon-evaluation.loadout.v0.json
```

The `loadout-runtime` adapter is environment-conditional in the
test suite: when the W3 Loadout checkpoint is not on disk the
test skips itself rather than failing the suite. CI runs against
the exact checkpoint the Wave 3 maintainer supplies (the
environment variable `ARSENAL_W3_LOADOUT_ROOT` overrides the
default lookup).

## Corpus (v0)

The v0 corpus is `evaluation/method-cases/corpus.manifest.json` and
contains three cases. Each case is a self-contained
`<case>/{repo,expected.json}` directory.

| Case                                       | Context                                       |
|--------------------------------------------|-----------------------------------------------|
| `recon.straightforward.small-clean`        | `local-git-repository-with-AGENTS.md`         |
| `recon.governed.explicit-architecture`     | `local-git-repository-with-arsenal-canonical-contracts` |
| `recon.ambiguous.incomplete-state`         | `incomplete-or-ambiguous-local-repository`    |

The three cases exercise materially different recon conditions:

* **Straightforward.** A small repo with an `AGENTS.md` and a
  `src/` tree. The recon method is expected to bind cleanly.
* **Governed.** A repo that includes canonical contracts
  (`engineering/doctrine/`), a capability fragment
  (`arsenal/capabilities/recon.json`), a script validator, and an
  existing QMR. The recon method is expected to bind the
  architecture anchor to the canonical ownership layers.
* **Ambiguous.** A repo that lacks `AGENTS.md` and the canonical
  contracts. The recon method is expected to report unknowns and
  refuse to claim context-binding.

## Artifact shape

Every evaluation artifact is a JSON object with the following
top-level keys:

| Key                    | Meaning                                                       |
|------------------------|---------------------------------------------------------------|
| `schema`               | Always `arsenal/method-evaluation/v0`.                        |
| `method`               | The QMR identity block: `method_id`, `method_version`, `method_record_path`, `method_record_digest`, `method_status`, `procedure_ref`. |
| `capability`           | The capability under test (`capability.recon`).               |
| `contexts`             | `declared_by_method` (from the QMR) and `exercised_by_corpus` (from the run). |
| `corpus`               | The corpus identity block.                                    |
| `provenance`           | `arsenal_commit`, `evaluator`, `model` (always `not-applicable`), `harness` (always `deterministic-python-adapter`), `remote_credentials_used` (always `false`), `adapter` (the procedure-invocation adapter identity; see "Adapter surface"). |
| `metrics`              | Counters: `cases_total`, `assertions_evaluated`, `assertions_supported`, `assertions_missed`, `assertions_failed`, `unknowns_documented`, `unsupported_claims_documented`, `evidence_references`, `repetitions`. No composite score. |
| `case_results`         | Per-case observation list, with `successes`, `misses`, `failures`, `unknowns`, `unsupported_claims`, and a per-assertion evidence list. |
| `qualification_gap`    | A primary `label` (closed vocabulary) and a list of `gaps` with rationale. |
| `epistemic_conclusion` | Always `experimental` in v0 (the closed vocabulary is enforced). |
| `qmr_revisions`        | Auto-promotion flags (all `false`) and the revised QMR's status (`experimental`). |
| `limitations`          | Documented honest limitations.                                |
| `run_digest`           | Deterministic SHA-256 of the canonicalized artifact (with the digest field replaced by its placeholder). |

## Epistemic conclusion and qualification gap

The closed `epistemic_conclusion` vocabulary is currently
`{"experimental"}`. The closed `qualification_gap.label`
vocabulary is currently:

* `bounded-evaluator-only`
* `no-behavioral-efficacy-evidence`
* `no-qualification-receipt-bound-to-capability`
* `experimental-to-experimental`

The v0 evaluator's primary gap is always
`experimental-to-experimental` because the system is explicitly
allowed to conclude `experimental -> experimental`. The other
labels appear in the `gaps[]` list with explicit rationale.

## Capability binding

The QMR remains evidence, not authority. The evaluator:

* reads `capability.lifecycle` and `capability.evaluation.status`
  from the canonical capability fragment *only as evidence*;
* never writes to `arsenal/capabilities/recon.json`;
* never promotes the method's QMR `status` to `qualified`;
* never emits a qualification receipt.

A revised QMR may be emitted as evidence, but the canonical
capability fragment remains the single owner of
`capability.current-lifecycle` and
`capability.current-evaluation`. See
`arsenal/source-model.json` facts.

## Anti-patterns the evaluator refuses

* composite quality scores (the validator refuses any field named
  `quality_score`, `composite_score`, `score`, or `grade` in
  `metrics`);
* runtime authority tokens in the artifact body (the artifact
  validator scans for `filesystem.write`, `network.write`,
  `git.write`, `production.mutate`, `cloud.remote`);
* `remote_credentials_used: true` (the field is closed to `false`);
* non-canonical method ids (the validator refuses any
  `method.method_id` other than the canonical
  `repository-recon/architecture-anchor-incremental`);
* auto-promotion flags set to `true` (the validator refuses any
  `qmr_revisions.auto_promote_*` set to `true`).

## Verification

```bash
python3 scripts/arsenal_evaluate.py repository-recon \
    --corpus evaluation/method-cases/corpus.manifest.json \
    --out .arsenal-eval/repository-recon-evaluation.v0.json

python3 scripts/arsenal_evaluate.py validate \
    --artifact .arsenal-eval/repository-recon-evaluation.v0.json

python3 scripts/test-arsenal-evaluate.py
python3 scripts/test-repository-recon-adapter.py
```

The adapter surface is exercised by
`scripts/test-repository-recon-adapter.py`, which proves:

* the default adapter is the internal fixture procedure;
* the shell adapter (Phase 1 placeholder) can be selected;
* a correct shell adapter produces the same evidence as the
  internal adapter (deterministic equivalence);
* a broken shell adapter produces strictly more misses (no
  silent fallback to the internal procedure);
* a malformed or missing findings file is rejected loudly;
* the corpus-level evaluation runs end-to-end through the
  shell adapter, the resulting artifact validates, and the
  run_digest is stable across two invocations.

## Graduation gap (ARS-W3 Phase 2)

ARS-W3 Phase 2 evaluates the productized Loadout Repository Recon
v1 target through the `loadout-runtime` adapter. The Phase 2
graduation gap enumerates what is still required before the
canonical QMR can be promoted from `experimental` to `qualified`
against the productized (Loadout) target:

1. **Missing `adapter` concept in the QMR contract.** The v0
   `engineering-system/qualified-method-record/v0` contract has
   `additionalProperties: false` and exposes a single
   `procedure_ref` (a SHA-256). It cannot simultaneously bind
   to multiple adapters. The QMR contract needs an `adapter`
   (or `target+adapter+adapter_version`) concept so a QMR can
   truthfully describe qualification against a specific adapter
   binding rather than a single canonical procedure.

2. **Catalog mismatch between the existing corpus and Loadout.**
   The existing Arsenal corpus expects Arsenal-canonical paths
   (`engineering/doctrine/CORE.md`, `arsenal/capabilities/recon.json`,
   `scripts/recon_method.py`, etc.) that Loadout's
   `runRepositoryRecon` does not catalog. When evaluated
   through the `loadout-runtime` adapter, the corpus produces
   FAILURE outcomes for those paths. This is the honest
   output-driven signal that Loadout's catalogue differs from
   Arsenal's. A QMR that truthfully described qualification
   against the Loadout target would need to bind to a corpus
   composed of paths Loadout actually catalogs.

3. **Single `procedure_ref` cannot bind to multiple adapters.**
   The canonical QMR's `procedure_ref` is a single SHA-256 of
   the canonical fixture procedure. The productized Loadout
   target has a different procedure interface digest. A QMR
   cannot truthfully carry both bindings; a contract evolution
   is required.

4. **No productized-vs-fixture status qualifier.** The QMR
   `status` vocabulary is `experimental | qualified`. Neither
   value distinguishes "qualified against an Arsenal fixture"
   from "qualified against the productized Loadout target".
   The contract needs a binding qualifier so a QMR can honestly
   declare which adapter it is qualified against.

5. **No behavioral efficacy evidence.** The canonical QMR
   `observed_failures` already declares
   `no-behavioral-efficacy-evidence-in-v0`. Behavioral efficacy
   requires a controlled model/harness run, which is out of
   scope for ARS-W3.

6. **No qualification receipt bound to a target and adapter.**
   The QMR `evaluation.qualification_gap` already declares
   `no-qualification-receipt-bound-to-capability`. Promotion to
   `qualified` requires a qualification receipt bound to
   (capability, target, adapter_version, suite, digests), which
   `scripts/arsenal_bench.py` has not yet emitted for
   `capability.recon` against the Loadout adapter.

The ARS-W3 closeout therefore reports `READY` for the Phase 2
adapter infrastructure (the `loadout-runtime` adapter
successfully invokes the W3 checkpoint, the artifact validates,
the run_digest is deterministic, and a broken candidate
produces strictly worse evaluation evidence) and `BLOCKED` for
the QMR promotion until items 1–4 are resolved. The canonical
QMR remains `experimental`.

### Phase 2 evaluation evidence (illustrative)

When the canonical corpus is run through the `loadout-runtime`
adapter (with Loadout's `runRepositoryRecon` from checkpoint
`d95927fbb675902d0fba992684b101ff60ff5a52`), the metrics are:

| Metric                       | Internal-fixture | loadout-runtime |
|------------------------------|------------------|-----------------|
| cases_total                  | 3                | 3               |
| assertions_evaluated         | 16               | 16              |
| assertions_supported         | 16               | 5               |
| assertions_missed            | 0                | 0               |
| assertions_failed            | 0                | 11              |

Loadout's procedure produces SUCCESS outcomes for the
common-path assertions (`AGENTS.md` presence, `README.md`
presence, `AGENTS.md` absence in the ambiguous case). The 11
FAILURE outcomes are all Arsenal-canonical paths Loadout does
not catalog (`engineering/doctrine/CORE.md`,
`arsenal/capabilities/recon.json`, `evaluation/method-records/...`,
`scripts/recon_method.py`, etc.). This is the documented catalog
mismatch in graduation gap item 2.

The artifact is stored at
`.arsenal-eval/repository-recon-evaluation.loadout.v0.json`.
