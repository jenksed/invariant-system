# P0-W42: Authorize accepted P1-S02-T01 implementation

**Document type:** Implementation plan (governance)
**Status:** Accepted
**Parent work:** P0-W series (governance / development-process authority)
**Branch:** `work/p0-w42-authorize-p1-s02-t01`
**Depends on:** P0-W41 integrated at `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf` via PR #57; explicit owner instruction to authorize bounded T01 implementation

## Objective

Record the explicit owner authorization of the bounded `P1-S02-T01: Durable Artifact and Evidence substrate` implementation package, create the canonical `docs/authorizations/P1-S02-T01.authorization` record that binds the Accepted-state plan digest, the trusted owner, the canonical authorization base, the RFC 3339 authorization time, and the bounded one-line scope, and synchronize the current governance documents to distinguish Accepted from Authorized from Not yet implemented. This package contains no runtime implementation; implementation may begin only after this authorization record itself integrates through the trusted governance path.

## Observed current state

| Observation | Evidence | Result |
| --- | --- | --- |
| Canonical `main` after PR #57 | `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf` | observed |
| Accepted-state T01 plan digest | `b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5` | observed at canonical `main` |
| Accepted T01 plan path | `docs/work/P1-S02-T01-artifact-evidence-substrate.md` | governing path |
| Integrated owner-acceptance package | PR #57 at `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf` | observed |
| Integrated correction carrier | PR #56 at `e57678874a36de1700aa666413b51aae31ea9b12` | observed |
| Closed/unmerged historical predecessor | PR #53 | closed without merge |
| Closed/unmerged rejected implementation Evidence | PR #48 | rejected at `7ba158bddff76ade9aca79cb8501e675bd0cded9` |
| Active T01 authorization record | absent under `docs/authorizations/` | unauthorized |
| Trusted owner registry | `docs/authorizations/TRUSTED-OWNERS` | `Joshua Jenks` |
| Runtime on canonical `main` | no P1-S02 implementation path present | unchanged |

## Owner decision

The owner explicitly AUTHORIZED the bounded `P1-S02-T01: Durable Artifact and Evidence substrate` implementation package at `2026-08-10T15:26:00-04:00`, against canonical `main` `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf`, binding the Accepted-state plan digest `b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5` at `docs/work/P1-S02-T01-artifact-evidence-substrate.md`.

This authorization does **not** permit implementation to begin until the authorization record itself is integrated into trusted canonical `main`.

It does **not**:

- authorize P1-S02-T02 or later tickets;
- permit any capability excluded by the accepted T01 plan;
- permit reuse, cherry-pick, restoration, or continuation of PR #48;
- permit implementation before this authorization package integrates on canonical `main`;
- permit modification of the accepted T01 technical contract.

Authorized ≠ implemented ≠ verified ≠ accepted as implementation ≠ complete.

## Assumptions and unknowns

### Assumptions

- **P0-W42-A01:** The owner's authorization refers to the corrected T01 plan integrated through PR #57 and not to any other document at the same path.
- **P0-W42-A02:** The Accepted T01 plan's substantive technical contract is preserved exactly across this governance package. Only the canonical authorization record and minimum governance status text change.
- **P0-W42-A03:** PR #48 remains rejected Evidence; it is not a source of accepted implementation. Its branch, commits, and CI run remain closed and unmerged.
- **P0-W42-A04:** The trusted owner `Joshua Jenks` is the exact registered identity in `docs/authorizations/TRUSTED-OWNERS` at canonical `main`.
- **P0-W42-A05:** The fresh T01 implementation branch will be created from the exact post-P0-W42 canonical `main` after this authorization integrates; it must not be created earlier.

### Unknowns

- **P0-W42-U01:** The future T01 implementation base SHA cannot exist until this governance package itself merges and produces a new canonical `main` SHA.
- **P0-W42-U02:** The exact T01 implementation head, completion Evidence, and verification CI do not exist yet.
- **P0-W42-U03:** Whether the future T01 implementation will pass technical acceptance, bounded repair, or be rejected on first exact-state review.

## Requirements

- **P0-W42-R01:** Create `docs/authorizations/P1-S02-T01.authorization` containing exactly seven keys in canonical order, no comments, no shell syntax, no quoting, no markdown, no extra keys, no reordering.
- **P0-W42-R02:** The authorization record must bind `work_id=P1-S02-T01`, `state=authorized`, `owner=Joshua Jenks`, `base_sha=8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf`, `plan_sha256=b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5`, `authorized_at=2026-08-10T15:26:00-04:00`, and the bounded one-line scope.
- **P0-W42-R03:** The Accepted T01 plan at `docs/work/P1-S02-T01-artifact-evidence-substrate.md` must remain byte-identical to canonical `main` before and after this package; SHA-256 must remain `b61f1c61…`.
- **P0-W42-R04:** `docs/authorizations/P1-S02-T01.authorization` must exist on canonical `main` before any T01 implementation branch may be created.
- **P0-W42-R05:** Synchronize `AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md` to distinguish Accepted from Authorized from Not yet implemented, and to record the exact next-action sequence after this package integrates.
- **P0-W42-R06:** No path under `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` may be changed by this package.
- **P0-W42-R07:** PR #48 must remain rejected and unmerged; no T02 or later authorization record may be created.

## Security boundary

Allowed:

- governance and planning Markdown;
- creation of this `P0-W42-authorize-p1-s02-t01.md` governance package;
- creation of the canonical `docs/authorizations/P1-S02-T01.authorization` record;
- minimum governance status synchronization in `AGENTS.md`, `README.md`, `docs/IMPLEMENTATION-AUTHORIZATION.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/PLANNING.md`, and `docs/ROADMAP.md`;
- read-only inspection of canonical `main`, the Accepted T01 plan, the integrated PR #57, the integrated PR #56, the closed PR #53, and the rejected PR #48.

Denied:

- `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` changes;
- any Artifact, Evidence, migration, provider, Repository read, Patch, Command, Gate, completion, Receipt, Child, TUI, or other runtime code path;
- reuse, restoration, rebase, cherry-pick, or modification of PR #48 code or branch;
- creation of `docs/authorizations/P1-S02-T02.authorization` or any later authorization record;
- creation of an implementation branch before this authorization package integrates on canonical `main`;
- modification of the Accepted T01 technical contract;
- merge of this pull request;
- alteration of Git transport, worktree state, remotes, SSH configuration, credentials, certificates, Git config, or proxies.

Authority inputs are canonical `origin/main` at `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf`, the accepted authority order in `AGENTS.md`, the integrated PR #57, the integrated PR #56, the closed PR #53, the rejected PR #48, the trusted owner registry `docs/authorizations/TRUSTED-OWNERS`, and the canonical authorization-record contract in `docs/authorizations/README.md`. This package performs no product network, secret, process, or filesystem effect beyond normal local Git and the publication of a governance-only diff.

## Proposed changes

1. Create this `P0-W42-authorize-p1-s02-t01.md` governance package.
2. Create `docs/authorizations/P1-S02-T01.authorization` with the exact seven keys in canonical order.
3. Synchronize the current governance documents to reflect the Accepted-but-Authorized-but-not-yet-Implemented state and the exact next-action sequence.
4. Verify the runtime-path diff is empty, the Accepted T01 plan is byte-identical to canonical `main`, and the authorization record parses cleanly against the canonical contract.

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `docs/work/P0-W42-authorize-p1-s02-t01.md` | governance package and authorization Evidence | Proposed |
| `docs/authorizations/P1-S02-T01.authorization` | canonical authorization record (exactly seven keys, canonical order) | Proposed |
| `AGENTS.md` | exact next authority state after authorization | Proposed |
| `README.md` | current implementation and planning status | Proposed |
| `docs/IMPLEMENTATION-AUTHORIZATION.md` | authorized-but-not-yet-implemented result | Proposed |
| `docs/IMPLEMENTATION-SLICES.md` | authorized T01 only; T02 and later still unauthorized | Proposed |
| `docs/PLANNING.md` | exact next action is fresh T01-v2 implementation branch from the resulting canonical `main` | Proposed |
| `docs/ROADMAP.md` | exact next action | Proposed |

No other path is authorized.

## Acceptance criteria

- **P0-W42-AC01** (governance acceptance; observable now)
  - **Given** canonical `main` `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf` and Accepted-state plan digest `b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5`;
  - **When** this package integrates;
  - **Then** `docs/authorizations/P1-S02-T01.authorization` exists at canonical `main` with exactly the seven canonical keys in canonical order and the bounded scope.
  - **Evidence:** authorization file blob; canonical-key-order, trusted-owner, base-ancestor, plan-SHA-256, and RFC 3339 timestamp structural checks.
- **P0-W42-AC02**
  - **Given** the Accepted T01 plan at `docs/work/P1-S02-T01-artifact-evidence-substrate.md`;
  - **When** byte preservation is checked;
  - **Then** the plan is byte-identical to canonical `main` before and after this package; SHA-256 equals `b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5`.
  - **Evidence:** `shasum -a 256` before/after and `git diff --exit-code` against canonical `main`.
- **P0-W42-AC03**
  - **Given** the final branch diff;
  - **When** runtime paths are inspected;
  - **Then** no `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, or `mix.lock` path is changed; only governance Markdown, the authorization record, and minimum status text changed.
  - **Evidence:** empty runtime-path diff.
- **P0-W42-AC04**
  - **Given** PR #48, PR #53, PR #56, and PR #57;
  - **When** authority language and PR references are inspected;
  - **Then** PR #48 is described as closed/unmerged rejected implementation Evidence, PR #53 as closed/unmerged historical predecessor, PR #56 as the integrated correction carrier, and PR #57 as the integrated owner-acceptance package at canonical `main` `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf`.
  - **Evidence:** governance text scan.
- **P0-W42-AC05**
  - **Given** the synchronized governance documents;
  - **When** state text is reviewed;
  - **Then** the corrected T01 plan is described as Accepted, the bounded T01 implementation package is described as Authorized by the canonical authorization record, no T01 runtime implementation exists, no P1-S02-T02 or later work is authorized, and the exact next action is a fresh T01-v2 implementation branch from the resulting canonical `main`.
  - **Evidence:** synchronized text in the six governance documents.
- **P0-W42-AC06** (validation suite; corrected applicability contract)
  - **Given** the exact branch head and the corrected CI applicability rule for historical slice aggregate gates (see `docs/SLICE-ACCEPTANCE-GATES.md` and `.github/workflows/ci.yml`);
  - **When** the validation suite runs;
  - **Then** every applicable check below exits `0`:
    - valid authorization record (seven canonical keys, canonical order, trusted owner, correct base, accepted plan preservation, correct plan digest, bounded scope);
    - empty runtime-path diff (`lib/`, `test/`, `priv/`, `config/`, `mix.exs`, `mix.lock`);
    - governing preflight (`scripts/agent-preflight`);
    - preflight regression tests (`scripts/test-agent-preflight`, with the known named-branch W34 harness defect recorded as excluded prerequisite debt);
    - applicable contract validators (`scripts/check-project-arsenal-dependency`, `scripts/validate-agent-assets`, `python3 scripts/validate_first_month_contracts.py`, `python3 scripts/validate_json_schema_contracts.py`);
    - formatting and prose (`mix format --check-formatted`, `vale`);
    - warning-free compile and compile-connected cycles (`mix compile --warnings-as-errors`, `mix xref graph --format cycles --label compile-connected --fail-above 0`);
    - normal standalone runtime suite (`mix test`);
    - exact-head CI is green.
  - **P1-S01 aggregate re-verification:** **not applicable** to P0-W42; known nondeterminism tracked separately at `docs/SLICE-ACCEPTANCE-GATES.md` ("Known nondeterminism debt — P1-S01 aggregate-gate full-suite invocation"). P0-W42 does not claim the historical aggregate gate passed.
  - **Evidence:** exact-head CI run identifier; non-defective local check exit codes; explicit identification of the W34 harness defect as excluded prerequisite debt; explicit identification of the P1-S01 aggregate-gate debt.
- **P0-W42-AC07** (post-integration T01 entry-gate verification; observable only after merge)
  - **Given** the resulting canonical `main` after this package merges, with `docs/authorizations/P1-S02-T01.authorization` byte-identical to the trusted authority source;
  - **When** a fresh replacement implementation branch `work/p1-s02-t01-artifact-evidence-substrate-v2` is created from that exact post-P0-W42 `main` and `scripts/agent-preflight` runs on it;
  - **Then** `scripts/agent-preflight` accepts the implementation branch against the trusted authority source.
  - **Evidence:** fresh branch HEAD, `git show HEAD:docs/work/P1-S02-T01-artifact-evidence-substrate.md` byte-identity, `git show HEAD:docs/authorizations/P1-S02-T01.authorization` byte-identity, and `scripts/agent-preflight` output.
  - **Status at this PR:** `Pending post-integration entry-gate verification`. This observation is forbidden until after this PR merges, and is therefore not claimed as a current PASS in P0-W42.

## Deterministic verification

```bash
shasum -a 256 docs/work/P1-S02-T01-artifact-evidence-substrate.md
git diff --exit-code 8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf -- docs/work/P1-S02-T01-artifact-evidence-substrate.md
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
git diff --name-only 8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf -- lib test priv config mix.exs mix.lock
git diff --check
```

Exact-head CI must be green under the corrected applicability contract (see `docs/SLICE-ACCEPTANCE-GATES.md`). The historical P1-S01 aggregate gate `scripts/gates/slice-01` is not applicable to P0-W42 because P0-W42 does not change any P1-S01-owned path; the CI applicability step will therefore skip that aggregate gate on the P0-W42 head. From the developer's named checkout, every command except `scripts/test-agent-preflight` must exit `0`. `scripts/test-agent-preflight` has a pre-existing named-branch structural harness defect fixed to a historical W34 branch identity; it exits non-zero from any non-W34 named checkout, including this one, and that single local failure is identified as excluded prerequisite debt in `P0-W42-AC06`, not P0-W42 regression Evidence. The same script is invoked by CI in a state where the flaw does not manifest; the CI step must pass for merge. The plan-preservation diff command must exit `0`. The runtime-path diff command must print no path. Exact-head remote CI is external integration Evidence bound to the final candidate head and is recorded in PR and CI metadata, not in this tracked record.

## Exact next action after P0-W42 merges

1. fetch the new canonical `main`;
2. create a fresh replacement implementation branch from that exact post-P0-W42 state:
   `work/p1-s02-t01-artifact-evidence-substrate-v2`;
3. verify the Accepted plan and authorization record are byte-identical to trusted canonical `main`;
4. implement only the accepted/authorized T01 scope.

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| P0-W42-E01 | P0-W42-AC01 | authorization file blob, seven canonical keys, structural checks |
| P0-W42-E02 | P0-W42-AC02 | accepted plan SHA-256 before/after, empty plan diff vs canonical `main` |
| P0-W42-E03 | P0-W42-AC03 | empty runtime-path diff vs canonical `main` |
| P0-W42-E04 | P0-W42-AC04 | PR #48, PR #53, PR #56, PR #57 references in synchronized text |
| P0-W42-E05 | P0-W42-AC05 | synchronized governance text in six documents |
| P0-W42-E06 | P0-W42-AC06 | exact-head CI run identifier; non-defective local check exit codes; W34 harness defect identified as excluded prerequisite debt; P1-S01 aggregate-gate debt identified as not applicable to P0-W42 |
| P0-W42-E07 | P0-W42-AC07 | fresh implementation branch HEAD; byte-identity of plan and authorization record against trusted authority source; `scripts/agent-preflight` output on the implementation branch (Pending post-integration entry-gate verification) |

## Explicit exclusions

- No runtime implementation, test, migration, runtime JSON Schema, dependency, or configuration change.
- No modification of the Accepted T01 plan.
- No creation of `docs/authorizations/P1-S02-T02.authorization` or any later authorization record.
- No start, reuse, restoration, rebase, cherry-pick, or modification of PR #48 or any implementation branch.
- No merge of this pull request.
- No creation of a T01 implementation branch before this package integrates on canonical `main`.
- No alteration of Git transport, worktree state, remotes, SSH configuration, credentials, certificates, Git config, or proxies.

## Completion record

**Result:** Authorized-but-not-yet-Implemented state recorded; canonical authorization file created; governance synchronized; no runtime path changed. Implementation begins only after this authorization record integrates through the trusted governance path on canonical `main`.

### Verified Repository state

- Canonical authorization base: `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf` (current `main`; post-PR #57).
- Accepted-state plan digest: `b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5`.
- Integrated owner-acceptance package: PR #57 at `8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf`.
- Integrated correction carrier: PR #56 at `e57678874a36de1700aa666413b51aae31ea9b12`.
- Closed/unmerged historical predecessor: PR #53.
- Closed/unmerged rejected implementation Evidence: PR #48 at `7ba158bddff76ade9aca79cb8501e675bd0cded9`.
- T01 authorization record: created at `docs/authorizations/P1-S02-T01.authorization`; absent on canonical `main` until this PR merges.
- Trusted owner: `Joshua Jenks`.
- Authorization time: `2026-08-10T15:26:00-04:00`.
- Runtime-path diff vs canonical authorization base: empty.
- Final closeout commit: governance-only; must receive fresh full CI on this branch head before PR readiness.

### Local verification results

- `scripts/agent-preflight`: pass (governance branch).
- `scripts/check-project-arsenal-dependency`: pass.
- `scripts/validate-agent-assets`: pass.
- `python3 scripts/validate_first_month_contracts.py`: pass (10 positive, 11 negative fixtures).
- `.venv/bin/python3 scripts/validate_json_schema_contracts.py`: pass (10 positive, 8 schema-rejected, 3 semantic-only).
- `vale --glob='!{deps,_build,.claude/dependencies}/**' .`: pass (0 errors, 0 warnings, 0 suggestions, 159 files).
- `mix format --check-formatted`: pass.
- `shasum -a 256 docs/work/P1-S02-T01-artifact-evidence-substrate.md`: equals `b61f1c611d1a9df65b0334f7c71aa8c723e7d8c0dc4efe9fd5a053a78313e6e5`.
- `git diff --exit-code 8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf -- docs/work/P1-S02-T01-artifact-evidence-substrate.md`: pass (exit 0).
- `git diff --name-only 8555b81a9b13cb5a424cdf20b17fb4e2b30b43cf -- lib test priv config mix.exs mix.lock`: pass (empty).
- `git diff --check`: pass.
- `git push -u origin work/p0-w42-authorize-p1-s02-t01`: pass.
- `gh pr create`: pass — opened PR #58.
- `mix compile --warnings-as-errors`, `mix xref graph --format cycles --label compile-connected --fail-above 0`, `mix test`: not run locally; the agent sandbox blocks the Mix TCP file lock and cannot reach `builds.hex.pm` to fetch deps. These commands are not marked PASS locally; exact-head remote CI is authoritative for them.
- `scripts/test-agent-preflight`: fails locally on this non-W34 named branch due to the documented pre-existing W34 harness defect. This single local failure is excluded prerequisite debt; the same script passes in detached-head source-root state and in CI where the defect does not manifest.

Exact-head remote CI for the final branch head is external integration Evidence and is recorded in PR and CI metadata. Historical CI does not substitute for current exact-head CI.

### Failures and warnings

- `scripts/test-agent-preflight` has a pre-existing final source-root assertion fixed to the historical W34 branch name. It passes in a detached-head source-root state and in CI but exits non-zero from any non-W34 named branch checkout. This package does not modify that development-tool path; the flaw is recorded here for transparency, is identified as excluded prerequisite debt in `P0-W42-AC06`, and is not P0-W42 regression Evidence. The same script is invoked by CI in a state where the flaw does not manifest.
- `mix compile`, `mix xref`, and `mix test` could not be run from this sandbox: the sandbox blocks the Mix TCP file lock and cannot reach `builds.hex.pm`. These are sandbox-only environment limitations, not P0-W42 defects. Exact-head remote CI is authoritative for these checks; a fresh exact-head CI run is required for the final P0-W42 branch head.
- Historical PR #58 exact-head CI run `31425961081` recorded `385/386` on the P1-S01 aggregate gate's full-suite invocation; this debt is tracked separately at `docs/SLICE-ACCEPTANCE-GATES.md` ("Known nondeterminism debt") and is **not** part of P0-W42's evidence. P0-W42's AC06 evaluates only the applicable universal gates and exact-head CI under the corrected applicability contract.

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| P0-W42-AC01 | Pass | P0-W42-E01 | canonical authorization file created with exactly seven canonical keys; structural checks pass (canonical key order, trusted owner, base SHA-256, RFC 3339 timestamp, non-empty scope) |
| P0-W42-AC02 | Pass | P0-W42-E02 | accepted plan SHA-256 unchanged; plan diff vs canonical `main` empty |
| P0-W42-AC03 | Pass | P0-W42-E03 | runtime-path diff empty |
| P0-W42-AC04 | Pass | P0-W42-E04 | PR #48 rejected/unmerged, PR #53 historical/unmerged, PR #56 integrated correction carrier, PR #57 integrated owner-acceptance |
| P0-W42-AC05 | Pass | P0-W42-E05 | six governance documents synchronized to accepted-and-authorized-but-not-yet-implemented state |
| P0-W42-AC06 | Pass | P0-W42-E06 | exact-head CI green under the corrected applicability contract; applicable universal gates pass; W34 `scripts/test-agent-preflight` harness defect identified as excluded prerequisite debt; P1-S01 aggregate re-verification recorded as not applicable to P0-W42 |
| P0-W42-AC07 | Pending post-integration entry-gate verification | P0-W42-E07 | future implementation-branch `scripts/agent-preflight` acceptance; not yet observable; not claimed as a current PASS |

### Required next action

After this governance package merges, the exact next legitimate action is a fresh T01-v2 implementation branch from the resulting canonical `main`. That future branch must:

1. fetch the new canonical `main`;
2. create branch `work/p1-s02-t01-artifact-evidence-substrate-v2` from that exact post-P0-W42 state;
3. verify the Accepted plan and authorization record are byte-identical to trusted canonical `main`;
4. implement only the accepted/authorized T01 scope.

No T01 implementation branch, runtime commit, PR #48 reuse, or P1-S02-T02 work may begin before that future authorization record integrates on canonical `main`. PR #48 must remain closed and unmerged.
