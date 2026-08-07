# project-arsenal

A reusable library of high-leverage prompts, agent workflows, engineering guidance, research patterns, foundational methods, and AI-assisted operating systems.

## Start here

- `CATALOG.md` — generated human-readable capability catalog.
- `arsenal/registry.json` + `arsenal/registry.d/*.json` — canonical merged machine-readable asset registry and relationships.
- `arsenal/ASSET_CONTRACT.md` — asset kinds, lifecycle states, invocation metadata, and integrity rules.
- `arsenal/INVOCATION_MODEL.md` — harness-neutral human/agent/reference/composed invocation semantics.
- `foundations/` — reusable methods that sit below individual prompts and future skill/runtime packaging.
- `workflows/` — composed playbooks that connect reusable assets.
- `briefs/` — preserved generation-source artifacts; not finished runnable prompts.

Run the integrity check with:

```bash
python3 scripts/arsenal_audit.py
```

Regenerate the catalog after registry changes with:

```bash
python3 scripts/arsenal_audit.py --write-catalog
```

## Arsenal

- `agent_workflows/` — reusable workflows for planning, execution, verification, repository audits, handoffs, triage, routing, and governance adoption.
- `engineering/` — canonical Engineering Doctrine, compact constitutional core, and reusable `AGENTS.md` / `CLAUDE.md` templates.
- `foundations/` — harness-neutral methods such as decision-tree grilling, Wayfinding, domain language, context boundaries, and rejected-decision memory.
- `software_engineering/` — reusable engineering disciplines for diagnosis, TDD, review, prototyping, specification, decomposition, architecture, and operational procedures.
- `job_search/` — job-search and career workflows.
- `learning/` — structured learning prompts and systems.
- `product_strategy/` — product and strategy workflows.
- `prompt_design/` — prompt architecture, testing, critique, generation, and agent-writing references.
- `research/` — research workflows and prompts.
- `writing/` — reusable writing systems.
- `docs/source_audits/` — provenance and conceptual-adoption audits for external source material.

## Lifecycle

Lifecycle status is an evidence claim:

`source → draft/unverified → testing → stable → deprecated`

A prompt is not `stable` because its prose looks good. Evaluation evidence must earn that status.

## Engineering Doctrine

Project Arsenal maintains a versioned Engineering Doctrine intended to govern AI-assisted software work across repositories.

Start with:

- `engineering/doctrine/CORE.md`
- `engineering/doctrine/ENGINEERING_DOCTRINE.md`
- `engineering/templates/AGENTS.md`
- `engineering/templates/CLAUDE.md`
- `agent_workflows/install_engineering_doctrine.md`

Operating principle:

> **Think broadly. Implement narrowly. Constrain deliberately. Verify with evidence.**

## Foundational planning methods

Use `agent_workflows/grill_decision_tree.md` when consequential ambiguity can be resolved inside one working session.

Escalate to `agent_workflows/wayfind.md` only when the destination is meaningful but dependent research, prototypes, tasks, or human decisions create real multi-session fog. Wayfinding maps decision work; it does not replace later implementation decomposition.

For a foggy software effort, `workflows/wayfind_to_delivery.md` connects Wayfinding → spec synthesis → tracer-bullet implementation tickets → delivery/review/evidence.
