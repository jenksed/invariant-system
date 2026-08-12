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
| `provenance.record_digest`  | SHA-256 of the record itself, computed via the documented canonicalization. | `_compute_record_digest` (SHA-256 over JSON with sort_keys + canonical separators, replacing the digest field with the 64-zero placeholder). |
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
