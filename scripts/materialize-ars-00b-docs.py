#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"expected exactly one {label} block, found {count}")
    return text.replace(old, new, 1)


readme = ROOT / "README.md"
text = readme.read_text(encoding="utf-8")
old_try = '''## Try Arsenal today

**Status: AVAILABLE, repository-native.**

Arsenal does not yet ship a universal installer or `arsenal` CLI. Do not invent one.

The simplest real path today is to use a canonical asset directly with your coding agent.

For example, start with Repository Truth:

1. Open [`agent_workflows/repository_truth_audit.md`](agent_workflows/repository_truth_audit.md).
2. Give that workflow to the agent working in your target repository.
3. Ask it to establish the actual read-only state of the repository **before planning or changing code**.
4. Use the resulting evidence as the starting point for the next capability or implementation step.

If you are adopting Arsenal into a repository, also inspect:

- [`engineering/doctrine/CORE.md`](engineering/doctrine/CORE.md)
- [`engineering/templates/AGENTS.md`](engineering/templates/AGENTS.md)
- [`agent_workflows/install_engineering_doctrine.md`](agent_workflows/install_engineering_doctrine.md)
- [`agent_workflows/setup_project_arsenal.md`](agent_workflows/setup_project_arsenal.md)

**Building next:** ARS-00B will turn one flagship capability into a much lower-friction distribution/quickstart path. That pilot will teach the later compiler what a useful package actually needs.
'''
new_try = '''## Try Arsenal today

**Status: AVAILABLE — Repository Truth distribution pilot.**

Arsenal still does not ship a universal `arsenal` CLI. The first low-friction portable package is **Repository Truth** as an Agent Skill.

### Codex project-local quickstart

```bash
git clone https://github.com/jenksed/project-arsenal.git
cd project-arsenal
scripts/install-repository-truth-skill --project /path/to/target-repository
```

Then start or restart Codex in the target repository and ask:

> Establish repository truth for this repository before planning or changing code.

The installer targets:

`<target-repository>/.agents/skills/repository-truth`

It is idempotent when the installed package is identical and refuses to overwrite a divergent installation.

The portable package lives at [`distribution/agent-skills/repository-truth/`](distribution/agent-skills/repository-truth/). Its bundled canonical workflow is deterministically checked against [`agent_workflows/repository_truth_audit.md`](agent_workflows/repository_truth_audit.md).

See the full [`Repository Truth quickstart`](docs/use/repository-truth-quickstart.md) for manual installation, user-global installation, limitations, and the compiler-regression contract.

If you are adopting Arsenal more broadly into a repository, also inspect:

- [`engineering/doctrine/CORE.md`](engineering/doctrine/CORE.md)
- [`engineering/templates/AGENTS.md`](engineering/templates/AGENTS.md)
- [`agent_workflows/install_engineering_doctrine.md`](agent_workflows/install_engineering_doctrine.md)
- [`agent_workflows/setup_project_arsenal.md`](agent_workflows/setup_project_arsenal.md)

**Next:** ARS-01 introduces Capability Contract v2. ARS-03 will later be required to reproduce this manually proven distribution shape rather than inventing packaging from theory.
'''
text = replace_once(text, old_try, new_try, "README Try Arsenal")
text = replace_once(
    text,
    "- Repository Truth;\n",
    "- Repository Truth;\n- Repository Truth Agent Skills distribution pilot + Codex project-local installer;\n",
    "README AVAILABLE Repository Truth",
)
text = replace_once(
    text,
    "- ARS-00B flagship quickstart / portable distribution pilot;\n",
    "",
    "README BUILDING ARS-00B",
)
readme.write_text(text, encoding="utf-8")

roadmap = ROOT / "docs/roadmap/capability-system.md"
text = roadmap.read_text(encoding="utf-8")
text = replace_once(
    text,
    "Current frontier: **ARS-00A — Public Surface & Unified Roadmap**",
    "Current frontier: **ARS-01 — Capability Contract v2**",
    "roadmap frontier",
)
text = replace_once(
    text,
    "### ARS-00A — README / Operator Console + unified roadmap\n\n**Status:** current slice.",
    "### ARS-00A — README / Operator Console + unified roadmap\n\n**Status:** delivered by PR #11.",
    "ARS-00A status",
)
old_b = '''### ARS-00B — Flagship quickstart and distribution pilot

Deliver:

- choose one flagship capability, initially Repository Truth unless repository evidence suggests a better tracer;
- create the smallest real path from discovery → use → useful result in an existing coding harness;
- document what is manual, what is portable, and what requires harness-specific packaging;
- preserve the pilot as a future compiler regression fixture.

Proof:

- a new user can invoke one flagship capability without inventing setup steps;
- the quickstart uses only shipped files/commands;
- distribution limitations are explicit.

Do **not** wait for the full compiler before learning what a useful package actually requires.
'''
new_b = '''### ARS-00B — Flagship quickstart and distribution pilot

**Status:** delivered by the Repository Truth Agent Skills pilot.

Delivered:

- Repository Truth selected as the flagship tracer;
- portable Agent Skills package under `distribution/agent-skills/repository-truth/`;
- thin `SKILL.md` discovery adapter with canonical Arsenal identity/provenance metadata;
- bundled canonical reference snapshot that must remain byte-for-byte identical to `agent_workflows/repository_truth_audit.md`;
- Codex project-local install path at `<repo>/.agents/skills/repository-truth`;
- optional user-global install path at `~/.agents/skills/repository-truth`;
- safe installer that is idempotent for identical state and refuses divergent overwrite;
- deterministic package/spec/source-drift verifier;
- repository-native quickstart and external-format source audit;
- CI acceptance for package shape, install layout, idempotence, non-clobber behavior, and Arsenal Integrity.

Proof:

- the first independent GitHub Actions run passed package validation and the project-local Codex installation contract;
- the installed reference is compared byte-for-byte with the canonical Arsenal workflow;
- the installer proves identical reinstall succeeds without mutation;
- a deliberately divergent installed `SKILL.md` causes exit `3` and remains untouched;
- distribution limitations are explicit: Agent Skills is an export format, Codex project-local is the first verified harness path, and outcome efficacy remains an ARS-02 question.

Compiler regression contract:

ARS-03 must be able to reproduce the ARS-00B package shape from canonical capability data without hand-maintained behavioral divergence.
'''
text = replace_once(text, old_b, new_b, "ARS-00B section")
text = replace_once(
    text,
    "## ARS-01 — Capability Contract v2\n\n**Goal:**",
    "## ARS-01 — Capability Contract v2\n\n**Status:** next slice.\n\n**Goal:**",
    "ARS-01 heading",
)
roadmap.write_text(text, encoding="utf-8")

print("ARS-00B public docs materialized")
