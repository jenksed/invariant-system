# Qualified Method Record — Contract Traceability

Status: accepted
Owner: ARS-01

This document maps each field on a Project Arsenal Qualified Method Record
to the corresponding clause in the accepted
`engineering-system/contracts/qualified-method-record.v0.md` contract and
to the Project Arsenal surface that enforces it.

| Field                  | Contract clause (engineering-system/qualified-method-record/v0) | Project Arsenal surface                                                                                 |
|------------------------|-----------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| `schema`               | The schema identity must be `engineering-system/qualified-method-record/v0`. | `scripts/arsenal_method_record.py` `_validate_against_schema` (const check) and direct equality test. |
| `method_id`            | Stable method identifier; project-arsenal uses `repository-recon/<name>` for Repository Recon methods. | Schema regex `^[a-z][a-z0-9.\-/]+$`; uniqueness enforced in `validate_directory`.                       |
| `method_version`       | Semantic version of the method.                                  | Schema regex `^\d+\.\d+\.\d+(-[A-Za-z0-9.-]+)?$`.                                                       |
| `status`               | Enum: `experimental` or `qualified`. `qualified` means qualified for the declared context only. | Schema enum; status-confidence coherence checked by `_compute_record_digest` chain + `_validate_against_schema`. |
| `qualified_for`        | Declares the user-visible outcome, contexts, and exclusions. Negative knowledge is first-class. | Non-empty `contexts` and `exclusions` enforced in `validate_record`.                                 |
| `inputs` / `outputs`   | Named inputs/outputs.                                            | Schema array constraints.                                                                               |
| `procedure_ref`        | Provenance digest of the procedure. `sha256:fixture-only` is permitted only when the record is a fixture. | Schema regex; experimental records carry a real SHA-256 of the canonical sources.                       |
| `evaluation`           | Evidence base: refs, models, repositories, observed strengths and failures, confidence. | Schema required-set + `observed_failures` non-empty for experimental and qualified records.            |
| `evaluation.confidence`| `bounded`, `limited`, `unqualified-fixture`, `qualified-for-declared-context`. `qualified` records must use the last. | Schema enum + allOf const.                                                                             |
| `evaluation.qualification_gap` | Optional explicit gap statement.                       | Schema min-length; used by the canonical record to enumerate the qualification gap honestly.           |
| `provenance.arsenal_commit` | The Arsenal commit SHA the record was authored against. `null` is permitted for fixture and experimental records. | Schema type union; `qualified` records carry a real SHA (validator does not yet enforce this explicitly — fixture/experimental paths are documented but `qualified` is unreachable today). |
| `provenance.record_digest`  | SHA-256 of the record itself, computed via the documented canonicalization. `sha256:fixture-only` is permitted only when the record is explicitly a fixture. | Schema regex `^(sha256:[A-Fa-f0-9]{64}|sha256:fixture-only)$` plus the fixture-scoped allOf branch that constrains fixtures to `sha256:fixture-only`. `_compute_record_digest` (SHA-256 over JSON with sort_keys + canonical separators, replacing the digest field with the 64-zero placeholder) runs only for non-fixture records. |
| Runtime authority tokens (`filesystem.write`, `network.write`, `git.write`, `production.mutate`, `cloud.remote`) | The record cannot grant filesystem, network, Git, or production authority. | Substring check in `validate_record` rejects the presence of any of these tokens in the record body.   |

## Canonicalization rule for `provenance.record_digest`

```text
serialized = json.dumps(record_with_record_digest_replaced_by_zero_digest,
                        sort_keys=True, separators=(",", ":"))
record_digest = "sha256:" + sha256(serialized.encode("utf-8")).hexdigest()
```

The 64-zero placeholder breaks the self-reference. The validator and the
record author must apply the same rule; otherwise the validator reports
`INVALID_DIGEST`.

## Status classification policy

The validator emits one of two statuses:

| Status        | When emitted                                                                                          |
|---------------|--------------------------------------------------------------------------------------------------------|
| `experimental`| At least one observed case exists, evidence is bounded, qualification gate has NOT been satisfied. This is the only honest classification when current evidence cannot justify `qualified`. |
| `qualified`   | The qualification gate declared in the canonical evaluation suite is satisfied for the declared context. Unreachable for ARS-01 v0 because no qualification receipt exists for `capability.recon`. |

## Honesty policy

A record that overstates evidence inflates confidence and risks promotion
of a method that has not earned it. ARS-01 enforces the following:

1. The default status is `experimental`.
2. Promoting to `qualified` requires a qualification receipt bound to the
   method's underlying capability, target, adapter, and suite digests.
3. Observed failures and exclusions are first-class; the record cannot
   omit them to claim qualification.
4. The validator refuses runtime-authority tokens; the record is
   evidence, not authority.

## Receipts consumed by ARS-01

ARS-01 does not consume any qualification receipt; no qualification
receipt exists for `capability.recon` today. The qualified method
record is therefore classified `experimental` and the qualification gap
is documented explicitly.

## QMR status vs capability lifecycle / evaluation status

The QMR `status` field (`experimental` / `qualified`) is a closed
vocabulary for **method maturity** — what Arsenal has observed about a
method in a declared context. It is distinct from the capability's
`lifecycle` and `evaluation.status` values, which are owned by
`arsenal/capabilities/<id>.json` (canonical capability fragment) and
by the qualification receipts under `evaluation/qualifications/`. The
two projections are independent:

- A method may be `experimental` while its capability is `draft` /
  `unassessed`.
- A method may be `qualified` for a declared context while its
  capability remains `testing` / `candidate` overall.
- A `qualified` method does NOT promote its capability. Capability
  promotion remains a separate decision with its own evidence.

The QMR is evidence, not authority. The record binds to the capability
via provenance digests and `evidence_refs`; it does not redefine
`capability.lifecycle` or `capability.evaluation.status`. See
`docs/arsenal-lifecycle.md` for the canonical narrative and
`arsenal/source-model.json` facts (`method-record.qualification-status`
vs `capability.current-lifecycle` / `capability.current-evaluation`)
for the source-of-truth attribution.

## Method-evaluation binding (ARS-04)

ARS-04 (`scripts/arsenal_evaluate.py`) evaluates the canonical
Repository Recon method against a bounded local-repository corpus
and emits an evaluation artifact. The artifact binds to the
canonical QMR through the `method.method_record_digest` field and
emits a `run_digest` that mirrors the QMR's
`provenance.record_digest` canonicalization rule. A revised QMR
emitted by ARS-04 is always `status: experimental`; ARS-04 does
not promote the method or its underlying capability. The QMR
remains evidence; capability lifecycle and evaluation status are
still owned by the canonical capability fragment and the
qualification receipts. See `docs/arsenal-method-evaluation.md`
for the canonical narrative.
