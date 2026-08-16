# P0-W41: Accept corrected P1-S02-T01 plan

**Document type:** Implementation plan (governance)
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process authority)
**Branch:** `work/p0-w41-accept-p1-s02-t01-plan`
**Depends on:** P0-W38 integrated at `e57678874a36de1700aa666413b51aae31ea9b12` via PR #56; owner acceptance of the corrected P1-S02-T01 plan

## Objective

Record the explicit owner acceptance of the corrected `P1-S02-T01: Durable Artifact and Evidence substrate` plan, distinguish owner acceptance from implementation authorization, mark the corrected plan as Accepted in the governing path, and establish the exact Accepted-state plan digest that a later, separate implementation-authorization record must bind. No runtime implementation, migration, schema, dependency, or configuration path is touched.

## Observed current state

| Observation | Evidence | Result |
| --- | --- | --- |
| Reviewed canonical Repository base | `e57678874a36de1700aa666413b51aae31ea9b12` | observed |
| Reviewed Proposed-state plan digest | `fb4dcad0d278ca096c383d835b19dc9bc1d66ca9dc66c7feaddc6daa728ea072` | observed at P0-W38 integration |
| T01 plan path | `docs/work/P1-S02-T01-artifact-evidence-substrate.md` | governing path |
| Corrected-plan carrier PR | PR #56 | integrated at `e5767887` |
| Closed/unmerged historical carrier PR | PR #53 | closed without merge |
| Closed/unmerged rejected implementation PR | PR #48 | rejected at `7ba158bddff76ade9aca79cb8501e675bd0cded9` |
| Active T01 authorization record | absent under `docs/authorizations/` | unauthorized |
| Runtime on canonical `main` | no P1-S02 implementation path present | unchanged |

## Owner decision

The owner explicitly ACCEPTED the corrected `P1-S02-T01: Durable Artifact and Evidence substrate` plan whose Proposed-state SHA-256 is exactly `fb4dcad0d278ca096c383d835b19dc9bc1d66ca9dc66c7feaddc6daa728ea072` as reviewed against canonical `main` `e57678874a36de1700aa666413b51aae31ea9b12`.

This acceptance does **not**:

- authorize implementation;
- start implementation;
- create a T01 authorization record;
- restore or reuse PR #48;
- authorize T02 or later work;
- accept any runtime implementation;
- complete P1-S02.

Accepted ≠ authorized ≠ implemented ≠ verified ≠ complete.

The substantive technical contract of the corrected T01 plan was reviewed and accepted under P0-W38 and is not reopened by this governance package. Only the minimum lifecycle and acceptance metadata is updated here.

## Assumptions and unknowns

### Assumptions

- **P0-W41-A01:** The owner's acceptance refers to the corrected T01 plan integrated through PR #56 and not to any other document at the same path.
- **P0-W41-A02:** The corrected plan's substantive technical contract is preserved exactly. Only minimum lifecycle and acceptance metadata change between the reviewed Proposed-state and the resulting Accepted-state.
- **P0-W41-A03:** PR #48 remains rejected Evidence and is not a source of accepted implementation; PR #53 remains historical and unmerged; PR #56 is the integrated correction carrier.

### Unknowns

- **P0-W41-U01:** The future authorization base SHA cannot exist until this governance package itself merges and produces a new canonical `main` SHA.
- **P0-W41-U02:** The future implementation-authorization time, owner attestation, branch, and exact implementation head do not exist yet.
- **P0-W41-U03:** The exact Accepted-state plan digest `accepted_plan_sha256` is determined by this package; the future authorization record must bind that exact value.

## Requirements

- **P0-W41-R01:** The corrected T01 plan must be marked Accepted at its governing path with the minimum possible metadata change. The substantive technical contract must not be redesigned, simplified, expanded, or otherwise altered.
- **P0-W41-R02:** The exact reviewed Proposed-state digest, the reviewed canonical base, and PR #56 must be recorded in this acceptance package.
- **P0-W41-R03:** `accepted_plan_sha256` of the Accepted-state T01 plan must be computed after the metadata update and recorded here; this value must differ from the Proposed-state digest solely because of lifecycle and acceptance metadata changes.
- **P0-W41-R04:** This package must not create `docs/authorizations/P1-S02-T01.authorization` and must not start, reuse, or restore any implementation branch.
- **P0-W41-R05:** PR #48 must remain rejected, PR #53 must remain historical and unmerged, and PR #56 must remain the integrated correction carrier.
- **P0-W41-R06:** The governance documents (`AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, `docs/ROADMAP.md`) must be synchronized to state that the corrected T01 plan is Accepted, no implementation is authorized, no T01 authorization record exists, no P1-S02 runtime work may begin yet, and the next governance action is a separate T01 implementation-authorization package.
- **P0-W41-R07:** The future T01 implementation authorization must bind `accepted_plan_sha256`, the new canonical `main` SHA produced by this package's merge, the trusted owner, and the bounded T01-v2 scope.

## Security boundary

Allowed:

- governance and planning Markdown;
- minimum lifecycle and acceptance metadata update on the existing T01 plan;
- creation of this `P0-W41-accept-p1-s02-t01-plan.md` package;
- synchronization of current governance status text in `AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md`;
- read-only inspection of the rejected PR #48, the historical PR #53, and the integrated PR #56.

Denied:

- `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` changes;
- creation of `docs/authorizations/P1-S02-T01.authorization` or any other authorization record;
- any Artifact, Evidence, migration, provider, Repository read, Patch, Command, Gate, completion, Receipt, Child, TUI, or later P1-S02 runtime work;
- reuse, restoration, rebase, cherry-pick, or modification of PR #48 code or branch;
- merge of this pull request;
- alteration of Git transport, worktree state, remotes, SSH configuration, credentials, certificates, Git config, or proxies.

Authority inputs are canonical `origin/main` at `e57678874a36de1700aa666413b51aae31ea9b12`, the accepted authority order in `AGENTS.md`, the integrated PR #56, the historical PR #53, and the rejected PR #48. This package performs no product network, secret, process, or filesystem effect beyond normal local Git and the publication of a governance-only diff.

## Proposed changes

1. Create this `P0-W41-accept-p1-s02-t01-plan.md` governance package.
2. Update only the minimum lifecycle and acceptance metadata of `docs/work/P1-S02-T01-artifact-evidence-substrate.md` to record owner acceptance; preserve the substantive technical contract.
3. Compute `accepted_plan_sha256` from the updated T01 plan and record it in this package.
4. Synchronize `AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md` to reflect the accepted-but-not-authorized state and the next governance action.
5. Verify the runtime-path diff is empty and no authorization record exists.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `docs/work/P0-W41-accept-p1-s02-t01-plan.md` | governance package and acceptance Evidence | Proposed |
| `docs/work/P1-S02-T01-artifact-evidence-substrate.md` | minimum lifecycle and acceptance metadata update only | Proposed |
| `AGENTS.md` | exact next authority state after acceptance | Proposed |
| `README.md` | current implementation and planning status | Proposed |
| `docs/IMPLEMENTATION-AUTHORIZATION.md` | accepted-but-not-authorized result | Proposed |
| `docs/IMPLEMENTATION-SLICES.md` | accepted T01 plan without authorization | Proposed |
| `docs/PLANNING.md` | exact next governance action | Proposed |
| `docs/ROADMAP.md` | exact next action | Proposed |

No other path is authorized.

## Acceptance criteria

- **P0-W41-AC01**
  - **Given** the reviewed Proposed-state digest `fb4dcad0d278ca096c383d835b19dc9bc1d66ca9dc66c7feaddc6daa728ea072` and reviewed base `e57678874a36de1700aa666413b51aae31ea9b12`;
  - **When** the corrected T01 plan is marked Accepted;
  - **Then** the only changes versus the Proposed-state plan are lifecycle and acceptance metadata, and the substantive technical contract is unchanged.
  - **Evidence:** line-by-line T01 diff classification and recorded `accepted_plan_sha256`.
- **P0-W41-AC02**
  - **Given** the final branch diff;
  - **When** runtime paths are inspected;
  - **Then** no `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` path is changed and `docs/authorizations/P1-S02-T01.authorization` remains absent.
  - **Evidence:** empty runtime-path diff and authorization-absence check.
- **P0-W41-AC03**
  - **Given** PR #48, PR #53, and PR #56;
  - **When** authority language and PR references are inspected;
  - **Then** PR #48 is described as closed/unmerged rejected implementation Evidence, PR #53 as closed/unmerged historical predecessor, and PR #56 as the integrated correction carrier.
  - **Evidence:** governance text scan.
- **P0-W41-AC04**
  - **Given** the synchronized governance documents;
  - **When** state text is reviewed;
  - **Then** the corrected T01 plan is described as Accepted, no implementation is authorized, no T01 authorization record exists, no P1-S02 runtime work may begin yet, and the next governance action is a separate T01 implementation-authorization package.
  - **Evidence:** synchronized text in `AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md`.
- **P0-W41-AC05**
  - **Given** the exact branch head;
  - **When** the complete governance validation suite runs;
  - **Then** every applicable deterministic check passes.
  - **Evidence:** command results and exact-head CI.

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
scripts/check-project-arsenal-dependency
scripts/validate-agent-assets
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
vale --glob='!{deps,_build,.claude/dependencies}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
test ! -e docs/authorizations/P1-S02-T01.authorization
git diff --name-only e57678874a36de1700aa666413b51aae31ea9b12 -- lib test priv config mix.exs mix.lock
git diff --check
```

Every command except `scripts/test-agent-preflight` must exit `0` when run from the developer's named checkout. `scripts/test-agent-preflight` has a pre-existing named-branch structural harness defect fixed to a historical W34 branch identity; it exits non-zero from any non-W34 named checkout, including this one, and that single local failure is not P0-W41 regression Evidence. The same script is invoked by CI in a state where the flaw does not manifest; the CI step must pass for merge. The runtime-path diff command must print no path. Exact-head remote CI is external integration Evidence bound to the final candidate head and is recorded in PR and CI metadata, not in this tracked record.

## Accepted-state plan digest

After the minimum lifecycle and acceptance metadata update, the SHA-256 of the Accepted-state T01 plan at `docs/work/P1-S02-T01-artifact-evidence-substrate.md` is:

```text
accepted_plan_sha256: b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5
```

The future T01 implementation-authorization record MUST bind this exact value.

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P0-W41-E01 | P0-W41-AC01 | T01 diff classification showing only lifecycle/acceptance metadata changed; recorded `accepted_plan_sha256` |
| P0-W41-E02 | P0-W41-AC02 | empty runtime-path diff and absent authorization record |
| P0-W41-E03 | P0-W41-AC03 | PR #48, PR #53, PR #56 references in synchronized text |
| P0-W41-E04 | P0-W41-AC04 | synchronized governance text in six documents |
| P0-W41-E05 | P0-W41-AC05 | full local validation and exact-head CI |

## Explicit exclusions

- No runtime implementation, test, migration, runtime JSON Schema, dependency, or configuration change.
- No `docs/authorizations/P1-S02-T01.authorization` creation.
- No start, reuse, restoration, rebase, cherry-pick, or modification of PR #48 or any implementation branch.
- No T02 or later planning authorization.
- No merge of this pull request.
- No substantive change to the corrected T01 plan's technical contract.

## Completion record

**Result:** Corrected T01 plan owner-accepted as Proposed-state `fb4dcad0d278ca096c383d835b19dc9bc1d66ca9dc66c7feaddc6daa728ea072` reviewed against canonical `main` `e57678874a36de1700aa666413b51aae31ea9b12`. Accepted-state plan digest and verification results are recorded in this section after commit preparation.

### Verified Repository state

- Reviewed canonical base: `e57678874a36de1700aa666413b51aae31ea9b12` (current `main`; post-PR #56).
- Reviewed Proposed-state plan digest: `fb4dcad0d278ca096c383d835b19dc9bc1d66ca9dc66c7feaddc6daa728ea072`.
- Integrated correction carrier: PR #56 at `e57678874a36de1700aa666413b51aae31ea9b12`.
- Closed/unmerged historical predecessor: PR #53.
- Closed/unmerged rejected implementation Evidence: PR #48 at `7ba158bddff76ade9aca79cb8501e675bd0cded9`.
- T01 authorization record: absent.
- Runtime-path diff vs. reviewed canonical base: empty.
- Final closeout commit: governance-only; must receive fresh full CI on this branch head before PR readiness.

### Local verification results

- `scripts/agent-preflight`: pass (governance branch).
- `scripts/check-project-arsenal-dependency`: pass.
- `scripts/validate-agent-assets`: pass.
- `python3 scripts/validate_first_month_contracts.py`: pass.
- `python3 scripts/validate_json_schema_contracts.py`: pass.
- `vale --glob='!{deps,_build,.claude/dependencies}/**' .`: pass.
- `mix format --check-formatted`: pass.
- `mix compile --warnings-as-errors`: pass.
- `mix xref graph --format cycles --label compile-connected --fail-above 0`: pass.
- `mix test`: pass.
- `test ! -e docs/authorizations/P1-S02-T01.authorization`: pass (absent).
- `git diff --name-only e57678874a36de1700aa666413b51aae31ea9b12 -- lib test priv config mix.exs mix.lock`: pass (empty).
- `git diff --check`: pass.
- `scripts/test-agent-preflight`: known pre-existing named-branch structural harness defect; this single local failure is not P0-W41 regression Evidence. The same script is invoked by CI in a state where the defect does not manifest; the CI step must pass for merge.

Exact-head remote CI for the final branch head is external integration Evidence and is recorded in PR and CI metadata. Historical CI does not substitute for current exact-head CI.

### Failures and warnings

- `scripts/test-agent-preflight` has a pre-existing final source-root assertion fixed to the historical W34 branch name. It passes in a detached-head source-root state and in CI but exits non-zero from any non-W34 named branch checkout. This package does not modify that development-tool path; the flaw is recorded here for transparency and is not P0-W41 regression Evidence. The same script is invoked by CI in a state where the flaw does not manifest.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W41-AC01 | Pass | P0-W41-E01 | only lifecycle and acceptance metadata changed; substantive technical contract preserved; `accepted_plan_sha256` recorded |
| P0-W41-AC02 | Pass | P0-W41-E02 | runtime-path diff empty; authorization record absent |
| P0-W41-AC03 | Pass | P0-W41-E03 | PR #48 rejected/unmerged, PR #53 historical/unmerged, PR #56 integrated |
| P0-W41-AC04 | Pass | P0-W41-E04 | six governance documents synchronized to accepted-but-not-authorized state |
| P0-W41-AC05 | Pass | P0-W41-E05 | local validation passes applicable deterministic checks; known `scripts/test-agent-preflight` named-branch defect recorded; exact-head CI lives in PR and CI metadata |

### Required next action

After this governance package merges, the next legitimate action is a separate, governance-only T01 implementation-authorization package. That future package must create `docs/authorizations/P1-S02-T01.authorization` on canonical `main` and bind:

- `accepted_plan_sha256` recorded in this package's Completion record;
- the new canonical `main` SHA produced by this P0-W41 merge;
- the trusted owner;
- the bounded T01-v2 scope.

No T01 implementation branch, runtime commit, PR #48 reuse, or P1-S02-T02 work may begin before that future authorization is integrated on canonical `main`. PR #48 must remain closed and unmerged.
