# P0-W34: Enforce the implementation authorization boundary

**Document type:** Implementation plan
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process enforcement)
**Branch:** `work/p0-w34-enforce-authorization-boundary`
**Depends on:** P0-W33 merged at `ad319d7`; Project Arsenal KFT-0 read-only field trial; owner authorization to perform this governance-only repair

## Objective

Repair the authority conflict exposed by KFT-0 without implementing or accepting P1-S02 runtime work. Make the difference between a proposed plan, an accepted plan, and an authorized implementation package mechanically enforceable; reconcile the current authority documents; correct the P1-S02-T01 plan's contradictory lifecycle and gate references; close the P0-W33 work record; and define portable retention requirements for owner-machine Evidence.

## Observed current state

| Observation | Evidence | Result |
| --- | --- | --- |
| `main` is the P0-W33 merge | `ad319d7c748a6b723b9cff4187fa06c60bc3cf06` | observed |
| P1-S01 is integrated and owner-accepted | PR #46, merge `db02198` | accepted |
| P1-S02 remains planned and unauthorized in Repository authority | `AGENTS.md`, `docs/PLANNING.md`, `docs/ROADMAP.md` | authoritative |
| PR #48 contains P1-S02-T01 candidate implementation | branch head `60367874bfc3c0e6d8cbd736f58e1ae17938943b` | available, not authorized or accepted |
| PR #48's plan remains Proposed while its completion record claims implementation and verification | `docs/work/P1-S02-T01-artifact-evidence-substrate.md` | contradictory |
| `scripts/agent-preflight` validates branch grammar and headings but accepts Proposed ticket plans | source and `scripts/test-agent-preflight` | enforcement gap |
| P1-S02-T01 reuses `P1-S02-G01` through `G03` with meanings that conflict with the accepted aggregate gate register | T01 plan and `docs/SLICE-ACCEPTANCE-GATES.md` | identifier conflict |
| P0-W33's completion record remains unpopulated after merge | `docs/work/P0-W33-reconcile-p1-s01-closeout.md` | stale |
| Required owner-machine manifests are ignored local output and are not retrievable from a fresh checkout | `artifacts/p1-s01/README.md` and KFT-0 retrieval | portability gap |
| The first P0-W34 preflight revision accepts untracked, self-issued plans and records and does not validate key order, timestamp values, or whitespace-only identity/scope | PR #49 review at `79426582` | blocking enforcement defect |
| Pull-request CI validates authority-source ancestry against GitHub's synthetic merge checkout rather than the immutable PR head | PR #49 re-review at `99822a25`; synthetic merge `01b343af` | blocking implementation-identity defect |

## Assumptions and unknowns

### Assumptions

- **P0-W34-A01:** The owner's instruction to proceed authorizes this governance-only P0-W34 package; it does not retroactively authorize P1-S02-T01.
- **P0-W34-A02:** A tracked per-work-package authorization record plus trusted Repository provenance is the smallest deterministic boundary that can carry owner, scope, base SHA, plan digest, authorization time, and proof that the implementation branch did not self-issue the authority.
- **P0-W34-A03:** PR #48 can remain open as candidate implementation while authority is repaired, provided no document represents it as accepted or authorized.

### Unknowns

- **P0-W34-U01:** Whether the owner will later accept the T01 plan unchanged, amend it, or reject the candidate implementation.
- **P0-W34-U02:** Where the legacy final P1-S01 owner-machine manifest will be durably uploaded; this package can define the retention contract but cannot reconstruct the missing file.
- **P0-W34-U03:** Whether exact-state Evidence at the P1-S01 closeout remains sufficient for every later documentation-only successor; later adjudication must state applicability explicitly.

## Requirements

- **P0-W34-R01:** The branch shall remain governance/development-tooling only and shall not modify Kiln runtime source, tests, migrations, dependencies, or PR #48.
- **P0-W34-R02:** Repository authority shall state that PR #48 is candidate implementation produced before valid repository authorization and is neither accepted nor merge-authorized.
- **P0-W34-R03:** A ticket or slice implementation branch shall fail preflight unless its governing plan and matching authorization record are committed unchanged in the explicit implementation commit, identical to active trusted Repository authority at canonical `origin/main`, and sourced from a trusted commit ancestral to the actual implementation head rather than a synthetic test merge.
- **P0-W34-R04:** An authorization record shall bind work ID, state, an owner registered by trusted Repository authority, exact base SHA, governing-plan SHA-256, valid RFC 3339 authorization time, and non-whitespace bounded scope in one enforced canonical key order.
- **P0-W34-R05:** Preflight tests shall prove rejection of Proposed plans, missing records, digest mismatch, malformed base SHA, unauthorized state, locally created, untracked, staged-only, implementation-branch-created, or synthetic-merge-laundered authority, arbitrary owners, reordered keys, invalid timestamp values, whitespace-only owner or scope, and branch-class spoofing, plus acceptance of complete trusted ticket and slice records whose actual implementation heads descend from authority.
- **P0-W34-R06:** The T01 plan shall remain Proposed, identify PR #48 as candidate-only, remove premature completion Claims, and use accepted aggregate gate identifiers without claiming that T01 satisfies an aggregate gate alone.
- **P0-W34-R07:** `AGENTS.md`, `docs/PLANNING.md`, `docs/ROADMAP.md`, and `README.md` shall agree on the exact next action and authorization boundary.
- **P0-W34-R08:** The P0-W33 completion record shall name its actual branch head, merge, PR, scope, and CI Evidence.
- **P0-W34-R09:** The Artifact location contract shall distinguish ignored local output from durably retrievable Evidence and record the legacy P1-S01 locator gap honestly.
- **P0-W34-R10:** No P1-S02 implementation shall be authorized, accepted, merged, or modified by this package.
- **P0-W34-R11:** Pull-request CI shall freshly fetch canonical `main`, the immutable `github.event.pull_request.head.sha`, and required history before it evaluates implementation authority against that actual head rather than GitHub's synthetic merge checkout.

## Proposed changes

1. Add `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/authorizations/README.md`, and `docs/authorizations/TRUSTED-OWNERS` as the human and machine contract for active implementation authorization records.
2. Extend `scripts/agent-preflight` to require accepted lifecycle state, trusted owner identity, canonical record syntax, valid field semantics, tracked files, exact trusted-main blobs, and an ancestral authority-source commit for ticket and slice work packages.
3. Extend `scripts/test-agent-preflight` with isolated Git repositories that prove trusted positive paths and protected-negative authorization paths without modifying the caller's worktree or index.
4. Reconcile authority and exact-next-action text in `AGENTS.md`, `README.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md`.
5. Correct the P1-S02-T01 plan lifecycle, candidate status, base, and aggregate gate contribution.
6. Close P0-W33's completion record with exact integrated Evidence.
7. Strengthen `artifacts/p1-s01/README.md` with durable retrieval requirements and the known legacy gap.
8. Fetch canonical `main` and the immutable pull-request head before preflight; bind authority validation to that actual implementation commit while preserving synthetic-merge compile and test coverage.

## Expected files or components

- `docs/work/P0-W34-enforce-authorization-boundary.md` — governing plan.
- `docs/IMPLEMENTATION-AUTHORIZATION.md` — authorization authority and lifecycle.
- `docs/authorizations/README.md` — record format and validation contract.
- `docs/authorizations/TRUSTED-OWNERS` — exact trusted owner identities.
- `scripts/agent-preflight` — accepted-plan and authorization enforcement.
- `scripts/test-agent-preflight` — protected regression matrix.
- `.github/workflows/ci.yml` — fresh trusted-main fetch before preflight.
- `AGENTS.md`, `README.md`, `docs/PLANNING.md`, `docs/ROADMAP.md` — synchronized current authority.
- `docs/work/P1-S02-T01-artifact-evidence-substrate.md` — Proposed candidate-only plan correction.
- `docs/work/P0-W33-reconcile-p1-s01-closeout.md` — exact closeout record.
- `artifacts/p1-s01/README.md` — portable Evidence contract and known legacy gap.

## Acceptance criteria

- **P0-W34-AC01:** Given a ticket or slice plan with any status other than Accepted; When preflight runs; Then it fails before implementation proceeds.
- **P0-W34-AC02:** Given a ticket or slice plan without a matching valid authorization record, trusted owner, trusted-main identity, or authority source ancestral to the actual implementation head; When preflight runs; Then it fails and identifies the missing or invalid authority property even when a synthetic merge makes the authority source ancestral to the checkout.
- **P0-W34-AC03:** Given an Accepted plan and valid exact authorization record integrated on trusted `main`; When the actual implementation head descends from that authority source and preflight runs against that explicit head; Then it passes the authority gate.
- **P0-W34-AC04:** Given the final governance diff; When authority text is inspected; Then P1-S02 remains unauthorized and PR #48 is candidate-only pending explicit adjudication.
- **P0-W34-AC05:** Given the corrected T01 plan; When compared with the aggregate gate register; Then its gate identifiers exist, its contributions are labeled prerequisite-only, and no completion Claim remains.
- **P0-W34-AC06:** Given the P1-S01 Artifact contract; When read from a fresh checkout; Then it explains the durable locator requirement and identifies the legacy final-manifest retrieval gap.
- **P0-W34-AC07:** Given the final branch; When complete Repository validation runs; Then every available required check passes and the diff contains no Kiln runtime files.

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
bash -n scripts/agent-preflight scripts/test-agent-preflight
scripts/validate-agent-assets
vale --glob='!{deps,_build}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
git diff --name-only ad319d7 -- lib test priv mix.exs config
```

The final command must produce no paths. Changes under `scripts/` are development-process enforcement, not Kiln runtime.

## Required completion Evidence

- **P0-W34-E01:** final branch head and compare against `ad319d7`.
- **P0-W34-E02:** `scripts/agent-preflight` pass for P0-W34.
- **P0-W34-E03:** `scripts/test-agent-preflight` pass including untracked, locally self-issued, staged-only, implementation-branch-issued, synthetic-merge-laundered, arbitrary-owner, branch-spoofing, syntax, semantic-value, and provenance negatives.
- **P0-W34-E04:** standard Repository validation results.
- **P0-W34-E05:** empty runtime-path diff for `lib`, `test`, `priv`, `mix.exs`, and `config`.
- **P0-W34-E06:** exact PR #48 head and candidate-only authority statement.
- **P0-W34-E07:** durable Evidence contract and legacy P1-S01 gap statement.

## Explicit exclusions

- No P1-S02 runtime implementation, amendment, acceptance, authorization, merge, or rebase.
- No modification to PR #48 or its branch.
- No `lib/`, `test/`, `priv/`, `mix.exs`, `mix.lock`, or `config/` changes.
- No provider, Repository capability, Context, Tool, Patch, Command, Gate runtime, completion, Receipt, release, Child, TUI, MCP, or Wave B work.
- No reconstruction or unsupported publication Claim for the missing P1-S01 owner-machine manifest.
- No generalized capability broker or Project Arsenal runtime integration.

## Completion record

**Current result:** Reopened for the pull-request-head binding defect found at prior closeout head `99822a253667551aa4ae554c472ff548402738bd`. The repair is implemented and locally verified; exact-head CI and final Repository closeout are pending. P1-S02 remains planned and unauthorized. PR #48 remains candidate-only and was not modified, accepted, authorized, rebased, merged, or represented as completion Evidence.

### Verified Repository state

- Base: `ad319d7c748a6b723b9cff4187fa06c60bc3cf06`.
- Branch: `work/p0-w34-enforce-authorization-boundary`.
- Pull request: PR #49, draft during repair and closeout.
- Prior enforcement head: `ec5d59c44a55a0625f5a302b0303c9bc9ad6ed4c`; [CI run 31291135022](https://github.com/jenksed/kiln/actions/runs/31291135022) succeeded but did not bind ancestry to the actual PR head.
- Prior closeout head: `99822a253667551aa4ae554c472ff548402738bd`; [CI run 31291218226](https://github.com/jenksed/kiln/actions/runs/31291218226) failed once in the P1-S01 corruption fixture and passed on attempt 2, but both attempts retained the same PR-head binding defect.
- Replacement enforcement head and exact-head CI: pending commit and CI Evidence.
- Candidate PR #48 head: `60367874bfc3c0e6d8cbd736f58e1ae17938943b`.
- Closeout rule: the commit that adds this completion record is documentation-only and must receive a fresh exact-head CI run before merge; that final head and run belong in the PR body because a commit cannot contain its own SHA.

### Acceptance status

| Criterion | Status | Evidence | Result |
| --- | --- | --- | --- |
| P0-W34-AC01 | Local pass; CI pending | P0-W34-E03 | Proposed-plan fixture rejected for non-Accepted lifecycle state |
| P0-W34-AC02 | Local pass; CI pending | P0-W34-E03 | synthetic merge makes authority source A ancestral to checkout M, but validation bound to independent actual head B fails because A is not B's ancestor |
| P0-W34-AC03 | Local pass; CI pending | P0-W34-E03 | trusted ticket and slice fixtures pass with actual implementation heads created after and descending from authority |
| P0-W34-AC04 | Pass | P0-W34-E01, E06 | authority diff preserves P1-S02 as unauthorized and PR #48 as candidate-only |
| P0-W34-AC05 | Pass | P0-W34-E01 | T01 remains Proposed and references P1-S02-G06, G10, and G16 as prerequisite-only contributions |
| P0-W34-AC06 | Pass | P0-W34-E07 | Artifact contract states the durable-locator requirement and legacy retrieval gap |
| P0-W34-AC07 | Pending | P0-W34-E01, E04, E05 | local required checks and runtime-path compare pass; replacement exact-head CI has not run |

### Completion Evidence

- **P0-W34-E01:** The current uncommitted compare from `ad319d7` contains governance documents, development scripts, and CI configuration only. No Kiln runtime file changed. Replacement commit identity remains pending.
- **P0-W34-E02:** `scripts/agent-preflight` passes locally for the P0-W34 planning branch and reports checkout commit and validated commit separately.
- **P0-W34-E03:** `scripts/test-agent-preflight` passes locally. Its isolated Git fixtures prove trusted ticket and slice positive paths; the synthetic-merge regression constructs authority A, independent implementation B with byte-identical authority blobs, and merge M with both parents, proves A is ancestral to M, demonstrates why M would pass if misidentified as implementation, and rejects B for the exact non-ancestry reason. Existing protected negatives remain covered.
- **P0-W34-E04:** Replacement exact-head CI is pending. Historical runs remain visible above and are not represented as proof of this repair.
- **P0-W34-E05:** `git diff --name-only ad319d7 -- lib test priv mix.exs mix.lock config` produced no paths locally; the PR compare contains no path in that runtime set.
- **P0-W34-E06:** Repository authority names PR #48 at exact head `60367874bfc3c0e6d8cbd736f58e1ae17938943b` as candidate-only. P1-S02 has no active authorization record.
- **P0-W34-E07:** `artifacts/p1-s01/README.md` distinguishes ignored local manifests from durable locators and states that the legacy final owner-machine manifest is not retrievable from a fresh checkout.

### Verification executed

Local verification passed:

```text
scripts/agent-preflight
scripts/test-agent-preflight
bash -n scripts/agent-preflight scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
scripts/validate-agent-assets
git diff --check
git diff --name-only ad319d7 -- lib test priv mix.exs mix.lock config
```

Local JSON Schema, Vale, and Elixir/Mix checks are unavailable in this environment. Replacement exact-head CI must execute those checks before closeout; no unavailable local check is represented as locally executed.

### Remaining unknowns

- P0-W34-U01 remains: the owner has not adjudicated the corrected T01 plan or PR #48 candidate diff.
- P0-W34-U02 remains: the legacy P1-S01 final owner-machine manifest has no durable retrievable locator.
- P0-W34-U03 remains: later authority must explicitly adjudicate applicability of exact-state P1-S01 Evidence to documentation-only successors when relevant.
