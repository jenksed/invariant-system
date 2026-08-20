---
title: Two-Track Branch Reconciliation Ledger
description: Evidence-based disposition of every origin branch relative to the proposed pre-Graph and Graph tracks.
status: partial
verified_at_commit: 5e7b0134d5e901603904ca5b1f4f3f16d4a472ec
source_paths:
  - README.md
  - docs/qualification/two-track-qualification.md
  - docs/reference/current-system-inventory.md
audience:
  - developer
  - operator
---

# Two-Track Branch Reconciliation Ledger

This records the disposition analysis that preceded publication of the
two-track documentation/tooling successors. It accounts for every branch under
`refs/remotes/origin` observed at the start of 2026-08-20; the SHA values below
are that audit snapshot, not a live remote-ref listing. The symbolic
`origin/HEAD` entry is not a separate branch.

## Classification

| Code | Meaning |
| --- | --- |
| A | active main line / main candidate |
| B | active dev line / dev candidate |
| C | selective backport to main |
| D | selective port to dev |
| E | experiment/research — preserve |
| F | historical/evidence — preserve |
| G | fully contained — retirement candidate |
| H | preservation only |
| I | unknown/blocked |

“Retirement candidate” never means authorized deletion. Branch ancestry counts
were computed against A0 `0c6ed3a` and B0 `5e7b013`; content inspection, not
date or count alone, determined the recommendation.

## Remote branch matrix

| Remote branch | Tip | Class | Relationship and recommendation |
| --- | --- | --- | --- |
| `origin/main` | `1dcb546` | A | Published conservative baseline; ancestor of A0 by 24 commits. Keep until A1 qualifies. |
| `origin/dev` | `1dcb546` | B | Published dev baseline currently equal to main; keep until B1 qualifies. |
| `origin/work/temper-workbench-alpha` | `0c6ed3a` | A | Exact A0 historical candidate. Preserve as the pre-Graph comparison point; build A1 separately. |
| `origin/experiment/m4-a-graph-projection` | `11ba660` | B | Exact eight-commit Graph delta from A0; fully contained by B0 but valuable named lineage. |
| `origin/integration/dev-m4-q1c` | `5e7b013` | B | Exact B0 historical candidate. Preserve; build B1 separately. |
| `origin/repair/m4-q1c-integration-hygiene` | `5e7b013` | G | Exact duplicate pointer to B0; retirement candidate only after owner review. |
| `origin/docs/invariant-documentation-foundation` | `f26cd4d` | G | Fully contained by A0 and B0. |
| `origin/pr-1-docs` | `f26cd4d` | G | Exact duplicate of the contained docs tip. |
| `origin/gov/kiln-m0-preflight-compat` | `c73c689` | G | Fully contained by both candidates. |
| `origin/post-wp09/workbench-foundation` | `7ea3e96` | G | Fully contained by both candidates. |
| `origin/work/wp-07-kiln-daemon` | `a8471f8` | G | Daemon lineage fully contained by both. |
| `origin/work/wp-09-temper-rpc` | `7556960` | G | RPC lineage fully contained by both. |
| `origin/work/m11-e3-deterministic` | `5b1cc19` | G | Fully contained by both; current local checkout dirtiness is separate and was not modified. |
| `origin/work/m11-e4-provider-bounded` | `f5703b9` | G | Fully contained by both. |
| `origin/m12-a-ci` | `aec49ae` | G | Its composed golden-path proof is already contained by both despite the older-looking side lineage. |
| `origin/tmp-do-not-use` | `fed26fc` | G | Fully contained; name and history support eventual retirement, not deletion in this pass. |
| `origin/integration/dev-reconciliation` | `e46dce1` | C/D | One unique documentation commit (branch policy, ledger, qualification index) on published main. Selectively reconcile current facts into both successors; do not merge wholesale. |
| `origin/process/risk-scaled-verification` | `4b570b5` | C/D | One unique process-doc commit. Review for both tracks; process policy is not Graph-specific. |
| `origin/m11-closeout-final` | `392f790` | F | Unique dogfood acceptance mutation plus historical closeout and Arsenal packet on an older base. Preserve evidence; separately adjudicate any still-relevant runtime change. |
| `origin/m12-b-recovery` | `66a3bc0` | D | One unique recovery test commit; its own record proves only part of its target. Rebase/requalify selectively on dev, then decide whether the stable property belongs on main too. |
| `origin/m12-c-artifact` | `c07f6e6` | D | Unique artifact-model design and identity tests. Selectively port and requalify; avoid treating old-lineage docs as canonical runtime truth. |
| `origin/m12-d-temper` | `b3c796e` | D | Unique operator-surface contract, no promoted runtime. Use as design input for the Temper/Temper-Elixir decision. |
| `origin/m12-e-provider-qual` | `7d3f67e` | D/E | Provider-qualification property documents. Route through Arsenal/Bench and dev review; existence grants no execution or promotion authority. |
| `origin/work/wp-08-persistent-session` | `d7d9f48` | F | One unique closeout/evidence commit; runtime ancestry is already in both candidates. Preserve the evidence rather than merging it as code. |
| `origin/research/arsenal-program-foundation` | `e2568cf` | E | Six unique research/evaluation commits. Preserve; selectively review stable harness/evidence infrastructure for dev. Main admission requires independent maturity evidence. |
| `origin/roadmap/t3-competitive-pathfinder` | `421b7d9` | F | Unique historical program/remote-environment plan. Preserve as program provenance. |
| `origin/ecc-tools/invariant-system-1787026413551` | `42a35dd` | E | Twelve generated tooling commits on a remote side lineage. Preserve; do not port wholesale. |
| `origin/experiment/m4-r0-zig-render` | `4eaabf3` | E | One unique experiment/report commit from A0; explicitly `MORE_EVIDENCE_REQUIRED`. Do not merge into either candidate. |
| `origin/preservation/m11-e3-determinism-stash-20260820-163629` | `e17ba70` | H | Preserved two-commit stash representation. Never apply wholesale or delete as part of reconciliation. |

## Candidate-B-only change classification

| Commit/change | Classification | Recommendation |
| --- | --- | --- |
| `58d5208` headless Graph projection | GRAPH-DEPENDENT | Dev successor only, after truth/ownership gate |
| `483cd15` CellFrame/M3 Graph view/attention derivation | GRAPH-ADJACENT | Dev; keep attention in Temper-side projection |
| `3228d99` work map/proof/inspector | GRAPH-DEPENDENT | Dev operator surface, subject to product decision |
| `e9970e7`, `dcab585`, `503492f`, `11ba660` truth, live/navigation/WHY/closure repairs | GRAPH-DEPENDENT/ADJACENT | Dev, pinned-runtime requalification required |
| `a1054a6` M3 dogfood fixture compile repair | GENERAL FIX — SHOULD BACKPORT TO MAIN | Apply semantically to A1, not as an assumed clean cherry-pick |
| `75805b1` qualification/security/hygiene changes | MIXED | Backport advisory and integration hygiene; keep Graph file moves with dev |
| `1842da3` regression/preflight repair | GENERAL FIX — SHOULD BACKPORT TO MAIN | Backport to A1 |
| `e89430c` root doctor parser and credential-safe trace | GENERAL FIX — SHOULD BACKPORT TO MAIN | Backport to A1; A0's doctor exit defect demonstrates need |
| `5e7b013` scan `products/`, not repository root | GENERAL FIX — SHOULD BACKPORT TO MAIN | Backport to A1; catches product contamination without flagging unrelated root worktrees |
| `docs/security/ADVISORY-COWLIB-2.19.0.md` | GENERAL DOCUMENTATION; remediation still open | Carry to both, then update dependency and qualification evidence |

The integration-hygiene work is generally valuable, but commit `75805b1` also
relocates Graph renderer files. Cherry-picking it wholesale onto A0 would
accidentally introduce Graph concerns. Backport by reviewed semantic patch or a
new focused commit.

## Preserved MiniMax stash comparison

The preserved branch changes `minimax_m3_adapter.ex` from a terminal-only
boundary to an early `:httpc` implementation with a 1 MiB response bound and no
retry. Both A0 and B0 carry a later, substantially evolved adapter (Finch/tool
call/provider-representation behavior); comparing the preserved version to the
candidates shows 121 insertions and 668 deletions relative to the later shape.

Disposition: **fully superseded implementation; provider-specific historical
experiment; useful design evidence**. It is not still-required executable work.
Preserve the branch and do not apply the stash.

## AI developer-tooling audit

The ECC branch adds `.agents` skill material, `.claude` commands/identity/skill
content, and `.codex` config/agent definitions. No secret literal or personal
machine path was found, and its identity content is style/time-oriented rather
than a human credential. It is nevertheless unsuitable for wholesale
promotion:

- generated guidance describes this polyglot monorepo as a single-package
  JavaScript/camelCase project and derives history largely from docs commits;
- `.codex` configuration enables live web and several `npx` MCP servers,
  making it provider/tool dependent;
- the generated state is large relative to the existing root `AGENTS.md` and
  project-local Arsenal skill; and
- nothing in it should become required product runtime or grant model authority.

Keep this an experiment. If useful, hand-author a minimal provider-independent
project skill from currently accurate repository rules and qualify it on both
tracks. Repository hygiene treats `.agents/`, `.claude/`, and `.codex/` as
potential intentional source; only `.claude/settings.local.json` is ignored.
`.codegraph/` is local generated state and is ignored.

## Runtime-qualification ref operations

The owner later authorized publication of documentation/tooling successors on
the two branch lines. That authorization does not qualify the runtime bases.
There is still no safe command that can label either line a qualified runtime
successor because accepted A1/B1 runtime identities do not yet exist. Further
qualification can start from exact immutable tips through the guarded helper:

```bash
./invariant track create main ../invariant-main-candidate-a0
./invariant track create dev ../invariant-dev-candidate-b0
./invariant track test main ../invariant-main-candidate-a0 qualification
./invariant track test dev ../invariant-dev-candidate-b0 qualification
```

These are detached historical comparison worktrees, not A1/B1 branches. Create
successor branches only when beginning authorized fixes; the helper deliberately
does not create or move a branch ref.

After runtime fixes, independent qualification, and human acceptance produce
exact `A1_SHA` and `B1_SHA`, require fast-forward ancestry and dry runs before
any release-status update or further promotion:

```bash
git fetch origin
git merge-base --is-ancestor origin/main A1_SHA
git merge-base --is-ancestor origin/dev B1_SHA
git push --dry-run origin A1_SHA:main
git push --dry-run origin B1_SHA:dev
# Only after reviewing the dry runs and receiving explicit authority:
git push origin A1_SHA:main
git push origin B1_SHA:dev
```

Do not replace `A1_SHA`/`B1_SHA` until the qualification record names exact
objects. Never use force push for this reconciliation.

## Human decision boundaries

The owner must decide:

1. whether Temper Elixir is a retained experiment, parallel renderer, or future
   replacement, and which public contract/API is permitted to consume Kiln
   Graph facts;
2. whether canonical Graph derivation stays in Kiln while freshness, labels,
   attention, header priority, and layout move fully to Temper;
3. whether and how to remediate `cowlib 2.19.0` without weakening gates;
4. which unique M12 and Arsenal research properties earn selective admission;
5. whether to accept an A1/B1 pair after clean OTP-28 and Lab evidence; and
6. only later, whether fully contained or duplicate refs may be retired.
