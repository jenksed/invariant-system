---
name: repository-truth
description: "Establishes the actual read-only state of a software repository before planning, continuation, recovery, or implementation. Use when inheriting a repo, resuming work, reconciling status claims, or when documentation, branches, tests, or completion claims may be stale."
compatibility: "Requires repository read access and a coding-agent harness capable of reading files and Git state. Read-only shell or test execution is optional. Repository mutation requires separate authorization after the audit is complete."
metadata:
  arsenal-capability: "capability.repository-truth"
  arsenal-version: "0.1.0"
  arsenal-source-asset: "agent.repository-truth-audit"
  arsenal-source: "agent_workflows/repository_truth_audit.md"
  arsenal-distribution: "agent-skills"
  arsenal-generated: "true"
  arsenal-lifecycle: "draft"
  arsenal-evaluation: "unassessed"
---

# Repository Truth

Establish the actual read-only state of a repository before planning, continuation, recovery, or implementation.

## Canonical behavior

Read [`references/repository_truth_audit.md`](references/repository_truth_audit.md) in full and execute it as the authoritative workflow for this capability.

This `SKILL.md` is a generated discovery and packaging adapter. It does not replace the canonical Arsenal workflow. If generated adapter text and the bundled canonical reference ever disagree, the bundled canonical reference controls.

Do not hand-edit this package. Regenerate it with `python3 scripts/arsenal_compile.py build`.

## Capability contract

- Capability: `capability.repository-truth`
- Version: `0.1.0`
- Lifecycle: `draft`
- Evaluation: `unassessed`
- Primary asset: `agent.repository-truth-audit`
- Mutation class: `read-only`

## Authority boundary

- Required authority: `filesystem.read`, `git.read`
- Optional authority: `shell.execute`
- Forbidden authority: `filesystem.write`, `network.write`, `git.write`, `tracker.write`, `secrets.read`, `cloud.remote`, `production.mutate`
- Allowed execution surfaces: `repository-read`, `local-process`
- Prohibited execution surfaces: `remote-sandbox`, `shared-nonproduction`, `staging`, `production`

Compilation never grants authority beyond this contract. Runtime execution must continue to honor the canonical capability and workflow boundaries.

## Expected outputs

- `current_state_report` — Evidence-backed repository state, claim comparison, drift, risks, and validation results.
- `continuation_point` — Exact defensible point from which planning or execution should continue.

## Provenance

See [`arsenal-manifest.json`](arsenal-manifest.json) for exact source digests, qualification state, authority, and compiler/export provenance.
