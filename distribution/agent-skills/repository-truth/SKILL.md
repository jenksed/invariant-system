---
name: repository-truth
description: Establishes the actual read-only state of a software repository before planning, continuation, recovery, or implementation. Use when inheriting a repo, resuming work, reconciling status claims, or when documentation, branches, tests, or completion claims may be stale.
compatibility: Requires repository read access and a coding-agent harness capable of reading files and Git state. Read-only shell or test execution is optional. Repository mutation requires separate authorization after the audit is complete.
metadata:
  arsenal-id: agent.repository-truth-audit
  arsenal-source: agent_workflows/repository_truth_audit.md
  arsenal-distribution: agent-skills
  arsenal-pilot: ARS-00B
---

# Repository Truth

Establish reality before planning or changing code.

## Canonical behavior

Read [`references/repository_truth_audit.md`](references/repository_truth_audit.md) in full and execute it as the authoritative workflow for this skill.

This `SKILL.md` is a discovery and packaging adapter. It does not replace the canonical Arsenal workflow. If this file and the bundled canonical reference ever disagree, the bundled canonical reference controls.

## Invocation boundary

- Start read-only.
- Recover repository path, intended branch, objective, governing files, and status claims from available context when possible.
- Do not mutate the repository merely because the user asked what state it is in.
- Do not convert a passing build or convenient test into a broader completion claim.
- If the user separately authorizes implementation, finish and report Repository Truth first, then hand off to the next capability.

## Expected result

Return the canonical workflow's evidence-backed current-state summary, repository map, claim-versus-evidence comparison, validation results, documentation drift, risks/blockers, exact continuation point, and recommended next actions.
