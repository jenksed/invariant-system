# Engineering System

This directory contains the canonical engineering doctrine and reusable project-governance assets used to make that doctrine part of everyday AI-assisted engineering work.

## Purpose

The doctrine should govern planning, implementation, review, verification, and completion across projects without being coupled to a single coding agent or product.

The operating principle is:

> Think broadly. Implement narrowly. Constrain deliberately. Verify with evidence.

## Contents

- `doctrine/CORE.md` — compact constitutional core intended for frequent agent context.
- `doctrine/ENGINEERING_DOCTRINE.md` — full doctrine, decision heuristics, limits, and tradeoff philosophy.
- `templates/AGENTS.md` — vendor-neutral repository instruction template.
- `templates/CLAUDE.md` — Claude-specific adapter that imports the repository's `AGENTS.md`.
- `../agent_workflows/install_engineering_doctrine.md` — reusable workflow for installing or auditing the doctrine in another repository.

## Authority Model

1. The full doctrine is the canonical rationale and decision framework.
2. The constitutional core is the compact always-on representation.
3. A project's `AGENTS.md` specializes the doctrine for that repository.
4. Agent-specific files such as `CLAUDE.md` should import or reference the project contract rather than duplicate it.
5. Non-negotiable requirements should be backed by deterministic enforcement where practical: tests, compilers, schemas, permissions, hooks, policy checks, CI, or verification scripts.

## Versioning

Doctrine assets include a `Doctrine-Version` field. Projects should record the version they adopt so future tooling can detect drift and support deliberate upgrades.

Current doctrine version: **1.0.0**

## Planned Follow-up

Once the written contract is stable, add tooling for:

- project bootstrap/install;
- doctrine-version drift checks;
- language-specific verification packs;
- CI policy checks;
- repository audits for missing or conflicting agent instructions.

Those mechanisms should be implemented only after their required behavior is proven by actual project adoption.
