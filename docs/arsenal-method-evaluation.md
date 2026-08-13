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

## Adapter surface (ARS-W3 Phase 1)

The evaluator can be configured to invoke an external procedure
through the adapter package at `evaluation/adapters/`. The
default is the internal fixture procedure
(`internal-fixture-procedure`); the Wave 3 Phase 1 placeholder
for the eventual Loadout productized procedure is
`shell-loadout-recon`, which reads pre-emitted findings from a
JSON file.

| Adapter name                  | Module                                                                  | Phase | Description |
|-------------------------------|-------------------------------------------------------------------------|-------|-------------|
| `internal-fixture-procedure`  | `evaluation.adapters.internal_fixture_adapter`                          | v0    | The canonical internal procedure. Default. |
| `shell-loadout-recon`         | `evaluation.adapters.shell_loadout_adapter`                             | W3-P1 | Reads findings from a JSON file. Phase 1 placeholder for the eventual Loadout ``loadout run --plan <plan>`` invocation. |

Adapter contract (Wave 3 frozen invariants):

1. An adapter MUST NOT import Loadout source code.
2. An adapter MUST NOT depend on Loadout runtime (no shell-out to
   Loadout until Phase 2 when Loadout's interface is concrete and
   stable).
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
      "name": "internal-fixture-procedure",
      "input": null,
      "module": "evaluation.adapters.internal_fixture_adapter:InternalFixtureProcedureAdapter"
    }
  }
}
```

The `provenance.adapter` block is mandatory on every artifact,
so every emitted artifact is self-describing about which procedure
produced the findings.

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

## Graduation gap (ARS-W3 Phase 1)

ARS-W3 Phase 1 introduces the adapter surface so the evaluator
can invoke an external Repository Recon procedure. The Phase 1
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

2. **No runtime adapter for Loadout.** Phase 1 only ships a
   `shell-loadout-recon` adapter that reads pre-emitted findings
   from a JSON file. Phase 2 must add a runtime adapter (e.g.
   `LoadoutRuntimeAdapter`) that invokes the Loadout
   `loadout run --plan <plan>` CLI through a stable, documented
   interface. Phase 1 deliberately stops short of this because
   Loadout's interface is not yet concrete.

3. **No actual evaluation against the Loadout Phase 1 checkpoint.**
   The Loadout Repository Recon v1 checkpoint SHA is supplied
   separately. Phase 1 does not yet invoke the procedure; it
   only prepares the adapter infrastructure.

4. **No behavioral efficacy evidence.** The canonical QMR
   `observed_failures` already declares
   `no-behavioral-efficacy-evidence-in-v0`. Behavioral efficacy
   requires a controlled model/harness run, which is out of
   scope for ARS-W3.

5. **No qualification receipt bound to a target and adapter.**
   The QMR `evaluation.qualification_gap` already declares
   `no-qualification-receipt-bound-to-capability`. Promotion to
   `qualified` requires a qualification receipt bound to
   (capability, target, adapter_version, suite, digests), which
   `scripts/arsenal_bench.py` has not yet emitted for
   `capability.recon` against the Loadout adapter.

The ARS-W3 closeout therefore reports `READY` for the adapter
infrastructure and `BLOCKED` for the QMR promotion until items
1–3 are resolved. The canonical QMR remains `experimental`.
