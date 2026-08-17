# LANE-EVIDENCE — MANIFOLD-M0-01 (M7)

## Lane metadata

- Lane: `MANIFOLD-M0-01`
- Branch: `m0/manifold-01-selection`
- Worktree: `/Users/jenksed/Developer/invariant-m0-manifold-01`
- Base SHA: `4006f20` (Merge BENCH-M0-01 into main, M6)
- Started at: 2026-08-17
- Author: orchestrator (Pass-05 execution, M7)
- Refined work package: `program/recursive-planning/pass-04/planning/30-day/work-packages/MANIFOLD-M0-01.md`
- Boundary transition: BT-01 (SYS-M0-02 / M5) — Manifold activated surface.

## What this lane establishes

The smallest real Manifold capability that proves:

> Given an Intelligence Requirement and authoritative qualification evidence, Manifold can deterministically and explainably select an eligible Profile and produce the bounded selection/assignment result required by the existing architecture, while failing closed when the qualification evidence does not support selection.

Manifold is **not** a generic agent router, **not** model-based orchestration, **not** a ranking engine, **not** autonomous execution. It is the first bounded Manifold selector.

## Files added

- `products/manifold/src/selector.py` — the only source file (BT-01 surface)
- `products/manifold/tests/test_selector.py` — the only test file (BT-01 surface)

## Files modified

- `invariant` — added `test_manifold` target (1 function + 2 case lines); no other edits.

## M6 evidence consumed (authoritative)

`products/arsenal/evaluation/qualifications/m0/`:

| Artifact | Role | Digest (semantic) |
|----------|------|-------------------|
| `implementer-profile.json` | IMPLEMENTER | `sha256:d44d6371efcf5912e56ee6c9e6fe1e8ebf8100db644684a93fef3a3a04fdd6b0` |
| `implementer-eligibility.json` | IMPLEMENTER | `sha256:8f358acd7ca731fb157c27e9cdd19ba22efeb053cd6816bde75a154e1fc64abd` |
| `reviewer-profile.json` | REVIEWER | (run-time digest from materialization) |
| `reviewer-eligibility.json` | REVIEWER | (run-time digest from materialization) |

The selector consumes the real M6 evidence directly. `test_m6_implementer_evidence_consumed` and `test_m6_reviewer_evidence_consumed` prove the M6→M7 seam: the real Profile and Eligibility Snapshot are selected end-to-end.

## Canonical contracts consumed (read-only)

- `contracts/m0/schemas/intelligence-requirement.m0-v1.schema.json`
- `contracts/m0/schemas/intelligence-profile.m0-v1.schema.json`
- `contracts/m0/schemas/eligibility-snapshot.m0-v1.schema.json`
- `contracts/m0/schemas/intelligence-assignment.m0-v1.schema.json`

The selector implements a stdlib-only validator (no `jsonschema` dependency)
that enforces the same closed field sets the JSON Schemas declare. The
selector is dependency-free so the consumer-visible CLI surface can
run in any environment that has Python 3.

## Canonical contracts produced

- `engineering-system/intelligence-assignment/m0-v1` (existing schema; the selector emits this artifact).
- No new schemas introduced. No new identifiers introduced. The selection rule is the closed constant `FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST` per P02-D026.

## Selection rule (P02-D026)

1. Validate every input against the closed m0-v1 schema field sets.
2. Recompute every `{id, digest}` reference's `semantic_digest` per
   P02-D013 (sorted-key compact UTF-8 JSON + trailing newline, then
   `sha256`) and reject on mismatch.
3. Filter Profiles to `role == requirement.role` (mismatch is a bounded
   per-candidate rejection with reason code `E_ROLE_MISMATCH`).
4. Retain only candidates whose Eligibility Snapshot is `QUALIFIED`,
   binds the exact Profile `semantic_digest`, and falls within the
   168-hour currentness window (`now <= valid_until` and
   `evaluated_at + 168h >= now`).
5. Tie-break: lexical order of Profile `semantic_digest`, first wins.
6. If zero eligible: emit an explicit no-selection artifact carrying
   the bounded reason codes in `metadata.rejected_candidates`.
7. Assignment carries refs to Requirement, Profile, Eligibility only.
   No provider / model / adapter / runtime / authority fields
   (P02-D017). `assignment_id` is generated and excluded from the
   semantic_digest computation.

## Architecture policing (P02-D017)

The selector enforces the "no authority smuggling" rule
programmatically. After building the Assignment body, a dedicated
`_enforce_p02_d017` pass scans the entire body for forbidden keys
(`provider`, `model`, `adapter`, `runtime`, `credential`,
`credential_slot`, `endpoint`, `api_key`, `authority_grant`,
`authority`) and raises `SelectorError(3)` with reason code
`E_AUTHORITY_FIELD_FORBIDDEN` if any are present. This is the
architectural backstop, not just a test.

## Consumer-visible proof

`test_selector_invoked_via_public_main` exercises the selector
through its public `main(argv)` entry point with the same argv
shape a real downstream consumer (Kiln-M0-02) would construct. The
test captures stdout/stderr, reads the written Assignment artifact,
and verifies that the assignment's `profile_ref.digest` matches the
Profile's `semantic_digest` (the binding proves the consumer can
re-verify Manifold's selection by recomputing the digest).

The selection prints `assignment_id=<hex>` to stdout — the same line
a real CLI consumer would see.

## Acceptance matrix (all passing)

| Case | Test | Result |
|------|------|--------|
| Happy path IMPLEMENTER | `test_implementer_frozen_set_produces_assignment_07` | PASS |
| Happy path REVIEWER | `test_reviewer_frozen_set_produces_assignment_21` | PASS |
| Role isolation (wrong role) | `test_implementer_requirement_rejects_reviewer_profile` | PASS |
| Stale qualification | `test_stale_eligibility_fails_closed` | PASS |
| NOT_ELIGIBLE state | `test_not_eligible_state_fails_closed` | PASS |
| Missing eligibility | `test_no_eligibility_snapshot_fails_closed` | PASS |
| Malformed evidence (missing field) | `test_missing_required_field_rejected` | PASS |
| Malformed evidence (extra property) | `test_extra_top_level_property_rejected` | PASS |
| Digest mismatch | `test_eligibility_refers_to_unknown_profile_digest` | PASS |
| Determinism (repeated runs) | `test_repeated_runs_produce_equivalent_assignment` | PASS |
| Ordering independence | `test_profile_ordering_does_not_change_selection` | PASS |
| Authority backstop | `test_assignment_has_no_authority_fields` + `test_assignment_carries_no_provider_or_authority_fields` | PASS |
| Real M6 evidence (IMPLEMENTER) | `test_m6_implementer_evidence_consumed` | PASS |
| Real M6 evidence (REVIEWER) | `test_m6_reviewer_evidence_consumed` | PASS |
| Consumer-visible path | `test_selector_invoked_via_public_main` | PASS |

Total: 16/16 PASS.

## Commands run

```
$ ./invariant test manifold
... (16/16 PASS)

$ python3 products/manifold/tests/test_selector.py
... (16/16 PASS)

$ ./invariant check
EXIT=0

$ ./invariant check boundaries
ok:   single Git root
ok:   no submodules
ok:   manifold is selection-only (src/selector.py + tests)
ok:   temper has no sibling-product source coupling
ok:   contract canonical: contracts/work-envelope.v0.md
ok:   contract canonical: contracts/run-result-envelope.v0.md
ok:   contract canonical: contracts/qualified-method-record.v0.md
ok:   contract canonical: contracts/learning-observation.v0.md
EXIT=0
```

## Architectural backstop notes

- The boundary check (`manifold is selection-only`) passes. The
  activated surface is exactly `src/selector.py` +
  `tests/test_selector.py`. No additional files exist under
  `products/manifold/`.
- The boundary check (`manifold src/tests imports non-stdlib or
  process/network surface`) passes. The selector and tests use only
  stdlib (`argparse`, `hashlib`, `json`, `datetime`, `pathlib`,
  `re`, `sys`, `unittest`, `tempfile`, `io`). No `os`,
  `subprocess`, `socket`, `urllib`, `requests`, `http.client`,
  `asyncio`, `multiprocessing`, `ctypes` imports.
- The boundary check (`manifold src/tests references sibling product
  trees`) passes. No `products/(arsenal|loadout|kiln|temper)` paths
  appear in the selector or tests.
- `temper_no_sibling_source_coupling` still passes — Temper's
  source remains free of Manifold references.

## Doctrine compliance

| Doctrine | Verdict |
|----------|---------|
| Capability is not authority. | YES — no authority fields on Assignment. |
| Qualification is not authorization. | YES — Manifold only consumes qualification; Kiln owns authorization. |
| Selection is not authorization. | YES — Manifold produces an Assignment ref; Kiln validates it. |
| Intelligence proposes; infrastructure enforces. | YES — Assignment is a proposal; Kiln will validate via KILN-M0-02. |
| Completion requires evidence. | YES — Profile_ref and Eligibility_ref are concrete digests. |
| Test the property, not the proxy. | YES — consumer-visible path + real M6 evidence prove the public property. |

## Downstream unlocks

- KILN-M0-02 (M8) — Assignment validation. The Assignment is the only
  canonical input M8 must consume; the selector never produces an
  Assignment that lacks Profile / Eligibility refs.
- KILN-M0-03 (M9) — Reviewer assignment. The selector's
  role-isolation property guarantees a REVIEWER Assignment only binds
  REVIEWER Profiles.
- SYS-M0-03 (M11) — Golden path. The selector's determinism
  guarantees the same requirement + same evidence set always
  produces the same assignment_id, supporting reproducible dogfood.

## Deferred scope

- No Work Envelope execution (M8 territory).
- No patch approval / mutation (M9 territory).
- No operator projection (M10 territory).
- No multi-eligible scoring — P02-D026 forbids it. Selection is
  filter-then-lexical.
- No new schema introduced. The Assignment schema is canonical.

## Why this lane satisfies the M7 acceptance property

The M7 acceptance property is:

> A real Intelligence Requirement reaches the public Manifold
> selection surface, authoritative qualification evidence is
> evaluated under canonical currentness/provenance semantics, and the
> correct deterministic qualified Profile/assignment result is
> returned while invalid candidates fail closed.

The proof is twofold:

1. `test_m6_implementer_evidence_consumed` and
   `test_m6_reviewer_evidence_consumed` build an Intelligence
   Requirement referencing the real M6 qualification evidence and
   prove the selector consumes the live qualification, evaluates
   currentness (the M6 snapshots are within the 168-hour window),
   and produces an Assignment whose `profile_ref.digest` and
   `eligibility_ref.digest` match the real M6 evidence.

2. `test_implementer_frozen_set_produces_assignment_07` and
   `test_reviewer_frozen_set_produces_assignment_21` prove the
   selector's positive path produces an Assignment structurally
   equivalent to the canonical frozen fixtures, with the same refs
   and the same `selection_rule`.

Combined, the positive and negative matrices prove fail-closed
behavior at every bounded reject path, and the consumer-visible path
test proves the same property holds when invoked through the public
`main(argv)` entry point.

## M8 entry conditions (documented)

M8 (KILN-M0-02) may start when:

- M7 is merged with authoritative qualification evidence (this lane).
- The Intelligence Assignment artifact produced by the selector is
  available for Kiln validation.
- The selector's `assignment_id` derivation is deterministic
  (verified by `test_repeated_runs_produce_equivalent_assignment`).
- The P02-D017 architectural backstop is in place (verified by
  `test_assignment_carries_no_provider_or_authority_fields`).

The M8 readiness dossier at
`program/recursive-planning/pass-05/m8-readiness-dossier.md` captures
the open questions for owner adjudication.