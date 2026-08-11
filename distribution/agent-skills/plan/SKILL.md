---
name: plan
description: "Execution Plan with acceptance gates converts a broad objective and current state into a dependency-aware, phased plan with proof-based completion criteria. Use when work must be split into releases or phases, dependencies determine order, or another agent must execute without rediscovering the project."
compatibility: "Requires repository read access and a coding-agent harness capable of reading files and Git state. Read-only shell or test execution is optional. Implementation work is out of scope for this skill; subsequent capabilities (Resume, TDD, Verify) execute the plan once it exists."
metadata:
  arsenal-capability: "capability.plan"
  arsenal-version: "0.1.0"
  arsenal-source-asset: "agent.execution-plan"
  arsenal-source: "agent_workflows/execution_plan_with_acceptance_gates.md"
  arsenal-distribution: "agent-skills"
  arsenal-generated: "true"
  arsenal-lifecycle: "draft"
  arsenal-evaluation: "unassessed"
  arsenal-invocation: "agent"
---

# Plan

Convert a broad objective and current project state into a dependency-aware, phased execution plan with proof-based acceptance gates.

## When to use

- An objective is too broad to execute safely as a single task and needs dependency-aware phasing
- A specification or set of decisions must become a concrete implementation sequence with validation gates
- Multiple agents or sessions must execute the work without rediscovering dependencies or completion criteria
- An existing plan is vague, fragmented, organized as an undifferentiated backlog, or has drifted from current state

## Do not use when

- The work is a small, isolated change that can be implemented and verified directly
- The primary need is to discover the product strategy or decide whether the objective should exist
- The user needs only a brainstorm, idea list, or prioritization matrix rather than an executable plan
- The required output is a design specification, ADR, or research report rather than an execution plan

## Canonical behavior

Read the bundled reference(s) listed below in full and execute them as the authoritative workflow for this capability.

This `SKILL.md` is a generated discovery and packaging adapter. It does not replace the canonical Arsenal workflow. If generated adapter text and any bundled reference ever disagree, the bundled reference controls.

Do not hand-edit this package. Regenerate it with `python3 scripts/arsenal_compile.py build`.

## Bundled resources

The following files are bundled with this package and are loaded on demand by the runtime. Always-loaded instructions content (if any) is embedded directly in this body; everything else is read on demand.

- Primary reference: [`references/execution_plan_with_acceptance_gates.md`](references/execution_plan_with_acceptance_gates.md)


## Capability contract

- Capability: `capability.plan`
- Version: `0.1.0`
- Lifecycle: `draft`
- Evaluation: `unassessed`
- Primary asset: `agent.execution-plan`
- Mutation class: `read-only`

## Authority boundary

- Required authority: `filesystem.read`
- Optional authority: `git.read`, `shell.execute`
- Forbidden authority: `filesystem.write`, `git.write`, `network.write`, `tracker.write`, `secrets.read`, `cloud.remote`, `production.mutate`
- Allowed execution surfaces: `repository-read`, `local-process`
- Prohibited execution surfaces: `remote-sandbox`, `shared-nonproduction`, `staging`, `production`

Compilation never grants authority beyond this contract. Runtime execution must continue to honor the canonical capability and workflow boundaries.

Invocation boundary: this capability is `agent`-invoked and may be exposed to autonomous model invocation.

## Expected outputs

- `execution_plan` — Dependency-aware phased plan with deliverables, acceptance gates, migrations, rollback, and risks.
- `acceptance_gates` — Proof-based validation methods tied to each phase and to overall completion.
- `decision_record` — Reversible vs irreversible decisions, assumptions, unknowns, and stopping conditions.

## Provenance

See [`arsenal-manifest.json`](arsenal-manifest.json) for exact source digests, qualification state, authority, and compiler/export provenance.
