# project-arsenal

A reusable library of high-leverage prompts, agent workflows, engineering guidance, research patterns, and AI-assisted operating systems.

## Start here

- `CATALOG.md` — generated human-readable capability catalog.
- `arsenal/registry.json` — canonical machine-readable asset registry and relationships.
- `arsenal/ASSET_CONTRACT.md` — asset kinds, lifecycle states, and integrity rules.
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

- `agent_workflows/` — reusable workflows for planning, execution, verification, repository audits, handoffs, and governance adoption.
- `engineering/` — canonical Engineering Doctrine, compact constitutional core, and reusable `AGENTS.md` / `CLAUDE.md` templates.
- `job_search/` — job-search and career workflows.
- `learning/` — structured learning prompts and systems.
- `product_strategy/` — product and strategy workflows.
- `prompt_design/` — prompt architecture, testing, critique, and generation assets.
- `research/` — research workflows and prompts.
- `writing/` — reusable writing systems.

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
