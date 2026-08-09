# P0-W38: Adopt project-arsenal as a development-agent dependency

**Document type:** Development-tooling work package
**Status:** Proposed
**Branch:** `work/p0-w38-adopt-project-arsenal-dependency`
**Base:** `main`
**Implementation authorization:** None; this work package does not authorize P1-S01 or P1-S02 product implementation

## Objective

Add `jenksed/project-arsenal` as a pinned, read-only dependency of the Kiln Claude coding agent without copying upstream content into the Kiln repository and without making it a Kiln runtime capability.

Claude Code should discover the upstream `repository-truth` package through the existing project-local skill path and verify the upstream identity, pin, and placement deterministically.

## Observed current state

- Kiln's Claude coding agent already references Project Arsenal conceptually: `docs/ENGINEERING-DOCTRINE.md` records upstream provenance and `docs/AGENT-ASSET-NOTES.md` borrows vocabulary from the Arsenal asset contract.
- Project Arsenal has no license, tag, release, `CODEOWNERS`, or `SECURITY.md` at the reviewed commit (`ecc8797d45447060b0c4aacd8efb6b1909e9e690`); its `.arsenal.lock` pins content digests but the upstream `HEAD` is a GitHub merge commit.
- Project Arsenal publishes a portable Agent Skills package at `distribution/agent-skills/repository-truth/`; the upstream installer targets `.agents/skills/` rather than Claude Code's `.claude/skills/` discovery path, so direct invocation of the installer would materialize a copy and is not a dependency relationship.
- `.claude/` is untracked in the Kiln repository; only `.claude/settings.json` (CodeGraph MCP allow and prompt hook) and `.claude/CLAUDE.md` (CodeGraph instructions) exist locally.
- P1-S02 work is not currently authorized (`docs/IMPLEMENTATION-AUTHORIZATION.md`); the current work-plan surface is P0 governance and scaffolding (P0-W30 through P0-W37).
- `KILN-INV-014` keeps development agents separate from Kiln runtime components; `KILN-INV-013` requires deterministic code for repository bookkeeping; `KILN-INV-027` distinguishes availability from permission; `KILN-INV-032` keeps reference content untrusted.

## Assumptions and unknowns

### Assumptions

- **P0-W38-A01:** A Git submodule pinned to an exact reviewed commit is the cleanest dependency mechanism for Claude Code's project-local skill path because it keeps upstream content owned in the upstream repository, records the exact revision in Git, and avoids vendoring.
- **P0-W38-A02:** A tracked symbolic link from `.claude/skills/repository-truth` into the pinned submodule is the thin adapter that keeps Kiln's own asset contract and Arsenal's own frontmatter separate, while still letting Claude Code discover the package.
- **P0-W38-A03:** Deterministic identity and placement are sufficient safety mechanisms at this scale; a separate authority contract layer is not yet justified.
- **P0-W38-A04:** Project Arsenal remains untrusted reference content relative to Kiln authority: it cannot widen scope, grant permissions, override `AGENTS.md`, or prove Kiln runtime implementation.

### Unknowns

- **P0-W38-U01:** Whether the Kiln owner will choose to update the pin in the future, and at what cadence.
- **P0-W38-U02:** Whether Kiln will eventually want additional Arsenal packages, which would require the same pin/verify pattern.
- **P0-W38-U03:** Whether Kiln will ever require Arsenal-evaluated `testing` or `stable` evidence before allowing the asset to participate in completion claims.

## Requirements

- **P0-W38-R01:** Add `.claude/dependencies/project-arsenal` as a Git submodule pinned to `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, with no branch tracking and no automatic updates.
- **P0-W38-R02:** Add a tracked symbolic link at `.claude/skills/repository-truth` that points to the upstream `distribution/agent-skills/repository-truth/` directory inside the pinned submodule.
- **P0-W38-R03:** Provide a deterministic read-only verifier that fails clearly when the submodule is uninitialized, when the pinned commit or remote URL differs, when the expected `.arsenal.lock` digests drift, or when the symlink does not resolve inside the pinned submodule.
- **P0-W38-R04:** Call the new verifier from `scripts/validate-agent-assets` after the existing Kiln-owned skill, specialist-agent, invariant, and doctrine checks.
- **P0-W38-R05:** Document the dependency in `docs/AGENT-ASSET-NOTES.md`, including the exact reviewed commit, lockfile and package digests, update procedure, initialization command, and the explicit boundary that Project Arsenal cannot widen Kiln scope, grant permissions, override `AGENTS.md`, or prove Kiln runtime implementation.
- **P0-W38-R06:** Preserve `KILN-INV-014`; the dependency remains a development agent only.
- **P0-W38-R07:** Preserve `KILN-INV-013`; identity and placement checks are deterministic and inspectable from Git alone.
- **P0-W38-R08:** Preserve `KILN-INV-027`; Project Arsenal's presence does not grant authority beyond `filesystem.read` and `git.read` of the upstream paths inside the pinned submodule.
- **P0-W38-R09:** Preserve `KILN-INV-032`; Project Arsenal is reference content, never active project instructions, and is not a package redistributed by Kiln.
- **P0-W38-R10:** Do not add `mix.exs`, `lib/`, `mix.lock`, runtime schemas, tests, P1-S01, or P1-S02 implementation.

## Proposed changes

1. Add `.gitmodules` with the canonical `https://github.com/jenksed/project-arsenal.git` URL pointing at `.claude/dependencies/project-arsenal`.
2. Add the submodule at the reviewed commit; let Git track only the gitlink (`mode 160000`).
3. Add a tracked symlink at `.claude/skills/repository-truth` pointing to `../dependencies/project-arsenal/distribution/agent-skills/repository-truth`.
4. Add `scripts/check-project-arsenal-dependency` as a deterministic read-only verifier.
5. Extend `scripts/validate-agent-assets` to invoke the new verifier after the existing asset and doctrine checks.
6. Add a third-party dependency section to `docs/AGENT-ASSET-NOTES.md` covering identity, placement, update procedure, trust boundary, and known upstream limitations.
7. Document the submodule initialization command in the appropriate repository setup location so a fresh checkout initializes the dependency before using the Arsenal-backed skill.
8. Add this work-package record.

## Expected files or components

| Path or component | Result |
| --- | --- |
| `.gitmodules` | Added submodule declaration for `.claude/dependencies/project-arsenal` |
| `.claude/dependencies/project-arsenal` | Added as a submodule pointer at `ecc8797d45447060b0c4aacd8efb6b1909e9e690` (gitlink only) |
| `.claude/skills/repository-truth` | Added as a tracked symbolic link into the pinned submodule |
| `scripts/check-project-arsenal-dependency` | Added deterministic verifier |
| `scripts/validate-agent-assets` | Extended to call the new verifier after existing checks |
| `docs/AGENT-ASSET-NOTES.md` | Added third-party dependency section |
| `README.md` or `docs/SETUP.md` (whichever is current) | Added `git submodule update --init --recursive` instruction in the development setup area |
| `docs/work/P0-W38-adopt-project-arsenal-dependency.md` | Added this work package |

## Acceptance criteria

- **P0-W38-AC01**
  - **Given** the new branch
  - **When** the diff against `main` is inspected
  - **Then** `.gitmodules` declares the canonical URL and target path, and `git ls-files --stage .claude/dependencies/project-arsenal` reports mode `160000`
  - **Evidence:** diff and `git ls-files` output

- **P0-W38-AC02**
  - **Given** the new symbolic link
  - **When** it is resolved
  - **Then** `.claude/skills/repository-truth/SKILL.md` resolves to the upstream `distribution/agent-skills/repository-truth/SKILL.md` inside the pinned submodule
  - **Evidence:** `readlink -f` plus `head` of the resolved file

- **P0-W38-AC03**
  - **Given** the new verifier
  - **When** it runs
  - **Then** it asserts the submodule's recorded commit, the remote URL, the expected `.arsenal.lock` digests, and the symlink resolution; it exits non-zero when any of these drift and prints a clear actionable message
  - **Evidence:** verifier output plus deliberate negative cases (tampered commit, drifted digest, broken symlink)

- **P0-W38-AC04**
  - **Given** the extension to `scripts/validate-agent-assets`
  - **When** the validator runs
  - **Then** it invokes the new verifier after the existing checks and only proceeds when the verifier passes
  - **Evidence:** validator output

- **P0-W38-AC05**
  - **Given** the documentation update
  - **When** `docs/AGENT-ASSET-NOTES.md` is read
  - **Then** the third-party dependency section records the exact reviewed commit, lockfile and package digests, update procedure, initialization command, and the explicit untrusted-reference boundary
  - **Evidence:** document contents

- **P0-W38-AC06**
  - **Given** the diff against `main`
  - **When** the runtime surface is inspected
  - **Then** there are no changes to `mix.exs`, `mix.lock`, `lib/`, runtime schemas, tests, or P1-S02 implementation
  - **Evidence:** exact branch compare

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
scripts/check-project-arsenal-dependency
scripts/validate-agent-assets
shellcheck scripts/check-project-arsenal-dependency scripts/validate-agent-assets
git submodule status -- .claude/dependencies/project-arsenal
git ls-files --stage .claude/dependencies/project-arsenal
readlink -f .claude/skills/repository-truth
head -n 20 .claude/skills/repository-truth/SKILL.md
vale --glob='!{deps,_build}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

The Elixir checks are unchanged from the base because this branch changes no Elixir source.

## Required completion Evidence

| Evidence ID | Criterion | Result |
| --- | --- | --- |
| P0-W38-E01 | P0-W38-AC01 | `git ls-files --stage` line and `.gitmodules` contents |
| P0-W38-E02 | P0-W38-AC02 | `readlink -f` and first lines of the resolved `SKILL.md` |
| P0-W38-E03 | P0-W38-AC03 | verifier output plus three negative cases (uninitialized submodule, tampered commit, broken symlink) |
| P0-W38-E04 | P0-W38-AC04 | validator output |
| P0-W38-E05 | P0-W38-AC05 | `docs/AGENT-ASSET-NOTES.md` section text |
| P0-W38-E06 | P0-W38-AC06 | exact branch compare against `main` |

## Explicit exclusions

- No vendoring or copying of any upstream content into the Kiln repository.
- No `mix.exs`, `lib/`, `mix.lock`, runtime schema, migration, or test changes.
- No P1-S02 implementation work; this is development tooling only.
- No automatic update mechanism; the submodule is pinned to an exact reviewed commit.
- No promotion of the dependency above `draft`; the asset contract does not apply because the upstream package is governed by its own manifest and is not a Kiln-authored `.agents/skills` asset.
- No change to the existing Kiln asset contract for `.agents/skills` and `.pi/agents`.
- No claim that Project Arsenal is a Kiln runtime capability, dependency, or authority.
- No new package manager, executable, or service added to the development toolchain.

## Completion record

**Result:** Pending

The package is complete only after the submodule, symlink, and verifier are in place; the verifier passes both positive and negative cases; `scripts/validate-agent-assets` invokes it; `docs/AGENT-ASSET-NOTES.md` records the dependency, update procedure, and trust boundary; and the diff against `main` contains no runtime or P1-S02 changes.
