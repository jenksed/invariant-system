---
name: repository-truth
description: "Repository Truth read-only audit of a software repository's actual state. Use when status documents, branches, tests, or completion claims may be stale or contested."
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
  arsenal-invocation: "agent"
---

# Repository Truth

Establish the actual read-only state of a repository before planning, continuation, recovery, or implementation.

## When to use

- Inheriting a repository whose current state is unknown or contested
- Resuming work after a session boundary where status documents may have drifted
- Reconciling completion or roadmap claims against the actual implementation before planning or recovery

## Do not use when

- Implementing new behavior where the current state is already verified and bounded
- Diagnosing a specific runtime failure whose reproduction is the priority

## Canonical behavior

Read the bundled reference(s) listed below in full and execute them as the authoritative workflow for this capability.

This `SKILL.md` is a generated discovery and packaging adapter. It does not replace the canonical Arsenal workflow. If generated adapter text and any bundled reference ever disagree, the bundled reference controls.

Do not hand-edit this package. Regenerate it with `python3 scripts/arsenal_compile.py build`.

## Bundled resources

The following files are bundled with this package and are loaded on demand by the runtime. Always-loaded instructions content (if any) is embedded directly in this body; everything else is read on demand.

- Primary reference: [`references/repository_truth_audit.md`](references/repository_truth_audit.md)


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

Invocation boundary: this capability is `agent`-invoked and may be exposed to autonomous model invocation.

## Expected outputs

- `current_state_report` — Evidence-backed repository state, claim comparison, drift, risks, and validation results.
- `continuation_point` — Exact defensible point from which planning or execution should continue.

## Provenance

See [`arsenal-manifest.json`](arsenal-manifest.json) for exact source digests, qualification state, authority, and compiler/export provenance.
