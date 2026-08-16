# Repository Truth Quickstart

Status: ARS-00B distribution pilot, compiler-backed by ARS-03

Repository Truth is the first Project Arsenal capability packaged for low-friction use outside this repository.

The canonical behavior remains:

`agent_workflows/repository_truth_audit.md`

The distributable Agent Skill is:

`distribution/agent-skills/repository-truth/`

The package is an adapter, not a new source of truth. Its bundled `references/repository_truth_audit.md` must remain byte-for-byte identical to the canonical Arsenal workflow.

## What this pilot proves

ARS-00B intentionally proved one useful distribution path before compiler automation. ARS-03 now regenerates that same path deterministically from canonical capability and asset data.

Current supported tracer:

- format: Agent Skills;
- canonical Arsenal asset: `agent.repository-truth-audit`;
- first concrete harness path: Codex project-local skill discovery;
- project-local destination: `<repo>/.agents/skills/repository-truth`;
- installer behavior: copy-only, idempotent when identical, refuse divergent overwrite;
- behavioral source: bundled canonical Arsenal reference.

This does not claim every Agent Skills-compatible harness has the same installation path or discovery behavior.

## Quickstart: Codex project-local

### 1. Obtain Project Arsenal

Clone or update Project Arsenal so this pilot package and installer are available.

```bash
git clone https://github.com/jenksed/project-arsenal.git
cd project-arsenal
```

If you already have the repository, update it normally instead of cloning a duplicate.

### 2. Install Repository Truth into the target repository

```bash
scripts/install-repository-truth-skill --project /path/to/target-repository
```

The installer writes only:

```text
<target-repository>/.agents/skills/repository-truth/
├── SKILL.md
├── arsenal-manifest.json
└── references/
    └── repository_truth_audit.md
```

It does not modify `AGENTS.md`, source code, dependencies, Git configuration, or project settings.

If an identical skill is already installed, the installer exits successfully without changing it.

If the destination exists but differs, the installer exits `3` and refuses to overwrite it.

### 3. Start or restart Codex in the target repository

Skill discovery is session/runtime behavior. Restart or reopen the coding-agent session after installation so the harness can refresh its discovered skills.

The pilot uses the shared project-local Agent Skills directory:

`.agents/skills/`

### 4. Invoke the behavior

Ask the agent:

> Establish repository truth for this repository before planning or changing code.

An explicitly discovered `repository-truth` skill may also be invoked through the harness's skill-selection surface when available. The quickstart does not depend on a specific picker UI.

### 5. Check the result

A useful Repository Truth result should include, as applicable:

- current-state summary;
- repository map;
- claim-versus-evidence comparison;
- validation results;
- documentation drift;
- risks and blockers;
- exact continuation point;
- recommended next actions.

The audit begins read-only. Passing builds or tests are evidence only for the claims they actually establish.

## Manual installation

The installer is convenience, not magic. The equivalent project-local copy is:

```bash
mkdir -p /path/to/target-repository/.agents/skills
cp -R distribution/agent-skills/repository-truth \
  /path/to/target-repository/.agents/skills/repository-truth
```

Prefer the installer when possible because it checks the target Git repository and refuses divergent overwrite.

## User-global Codex installation

The pilot installer also supports:

```bash
scripts/install-repository-truth-skill --user
```

which targets:

`~/.agents/skills/repository-truth`

Project-local installation is the primary ARS-00B acceptance path because it is easier to bind to a specific repository and avoids depending on user-level indexing behavior in a particular desktop build.

## Other Agent Skills-compatible harnesses

The package itself follows the open Agent Skills layout: `SKILL.md` plus optional bundled references.

Other harnesses may install the same package through different directories, upload flows, plugin systems, or workspace management surfaces. ARS-00B does not pretend those distribution mechanisms are identical.

Harness-specific packaging remains an adapter concern. ARS-03 now uses this pilot as its first compiler regression fixture: `python3 scripts/arsenal_compile.py verify` reconstructs the expected package and fails on manual drift.

## Why the package contains a canonical snapshot

An installed skill cannot assume the Project Arsenal repository remains available beside it.

Therefore ARS-00B bundles the authoritative workflow under:

`references/repository_truth_audit.md`

The repository verifier requires that file to be byte-identical to:

`agent_workflows/repository_truth_audit.md`

This gives the installed package autonomy while keeping Arsenal's canonical asset authoritative.

The ARS-03 compiler now generates or refreshes that snapshot deterministically rather than maintaining it by hand.

## What ARS-00B does not prove

This pilot does not prove that Repository Truth improves engineering outcomes versus baseline. That belongs to ARS-02 Arsenal Bench.

It does not define Capability Contract v2. That belongs to ARS-01.

It does not define a universal multi-format distribution CLI or plugin system. ARS-03 v0 proves the compiler contract with Agent Skills only; additional format adapters require their own evidence-backed packaging contracts.

## Pilot acceptance

The repository gate must prove:

- valid Agent Skills name/description/frontmatter shape;
- compact discovery adapter;
- byte-identical canonical reference snapshot;
- real project-local `.agents/skills/repository-truth` install layout;
- idempotent reinstall when identical;
- refusal to overwrite divergent installed state;
- Arsenal Integrity remains green.
