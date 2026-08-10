# P0-W39: Adopt project-arsenal as a development-agent dependency

**Document type:** Development-tooling work package
**Status:** Accepted
**Branch:** `work/p0-w39-adopt-project-arsenal-dependency`
**Base:** `main` at `f9b5a312ac31ee4015025a87bcd3cec199b12297`
**Implementation authorization:** None; this work package does not authorize P1-S01 or P1-S02 product implementation

## Objective

Add `jenksed/project-arsenal` as a pinned, read-only dependency of the Kiln Claude coding agent without copying upstream content into the Kiln repository and without making it a Kiln runtime capability.

Claude Code should discover the upstream `repository-truth` package through the existing project-local skill path and verify the upstream identity, pin, and placement deterministically.

## Observed current state

- Kiln's Claude coding agent already references Project Arsenal conceptually: `docs/ENGINEERING-DOCTRINE.md` records upstream provenance and `docs/AGENT-ASSET-NOTES.md` borrows vocabulary from the Arsenal asset contract.
- Project Arsenal has no license, tag, release, `CODEOWNERS`, or `SECURITY.md` at the reviewed commit (`ecc8797d45447060b0c4aacd8efb6b1909e9e690`); its `.arsenal.lock` pins content digests but the upstream `HEAD` is a GitHub merge commit.
- Project Arsenal publishes a portable Agent Skills package at `distribution/agent-skills/repository-truth/`; the upstream installer targets `.agents/skills/` rather than Claude Code's `.claude/skills/` discovery path, so direct invocation of the installer would materialize a copy and is not a dependency relationship.
- `.claude/` is untracked in the Kiln repository; only harness-local files (`.claude/settings.json`, `.claude/CLAUDE.md`) exist locally and remain outside this work package.
- The P0 governance history runs through P0-W30–P0-W38. PR #53 owns `P0-W38: Correct the rejected P1-S02-T01 plan` at head `e030c61d0d117e46ae80680a42b02325c56dd7c7`. This work package therefore adopts `P0-W39` so it does not collide with PR #53's identity.
- `KILN-INV-014` keeps development agents separate from Kiln runtime components; `KILN-INV-013` requires deterministic code for repository bookkeeping; `KILN-INV-027` distinguishes availability from permission; `KILN-INV-032` keeps reference content untrusted.

## Assumptions and unknowns

### Assumptions

- **P0-W39-A01:** A Git submodule pinned to an exact reviewed commit is the cleanest dependency mechanism for Claude Code's project-local skill path because it keeps upstream content owned in the upstream repository, records the exact revision in Git, and avoids vendoring.
- **P0-W39-A02:** A tracked symbolic link from `.claude/skills/repository-truth` into the pinned submodule is the thin adapter that keeps Kiln's own asset contract and Arsenal's own frontmatter separate, while still letting Claude Code discover the package.
- **P0-W39-A03:** Deterministic identity, placement, and lockfile-digest checks are sufficient safety mechanisms at this scale; a separate authority contract layer is not yet justified.
- **P0-W39-A04:** Project Arsenal remains untrusted reference content relative to Kiln authority: it cannot widen scope, grant permissions, override `AGENTS.md`, or prove Kiln runtime implementation.

### Unknowns

- **P0-W39-U01:** Whether the Kiln owner will choose to update the pin in the future, and at what cadence.
- **P0-W39-U02:** Whether Kiln will eventually want additional Arsenal packages, which would require the same pin/verify pattern.
- **P0-W39-U03:** Whether Kiln will ever require Arsenal-evaluated `testing` or `stable` evidence before allowing the asset to participate in completion claims.

## Requirements

- **P0-W39-R01:** Add `.claude/dependencies/project-arsenal` as a Git submodule pinned to `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, with no branch tracking and no automatic updates.
- **P0-W39-R02:** Add a tracked symbolic link at `.claude/skills/repository-truth` that points to the upstream `distribution/agent-skills/repository-truth/` directory inside the pinned submodule.
- **P0-W39-R03:** Provide a deterministic read-only verifier that fails closed when the submodule is uninitialized, when the superproject gitlink SHA differs from the approved pin, when the materialized submodule working-tree HEAD differs from the approved pin, when the recorded remote URL differs, when the expected `.arsenal.lock` plan or package digest drifts, when the lockfile is missing or invalid JSON, when the lockfile records zero or more than one matching agent-skills export, or when the symlink does not resolve inside the pinned submodule.
- **P0-W39-R04:** Call the new verifier from `scripts/validate-agent-assets` after the existing Kiln-owned skill, specialist-agent, invariant, and doctrine checks. The validator MUST fail closed when the verifier is missing, is not a regular file, or loses its executable bit, and MUST print `project-arsenal dependency: verified` only after the verifier has returned success.
- **P0-W39-R05:** Configure CI's existing `actions/checkout@v6` step for the test job to initialize the pinned submodule (`submodules: recursive`) while preserving `fetch-depth: 0`, the trusted implementation-head fetch logic, and existing `scripts/agent-preflight` behavior, so the validator actually inspects a materialized dependency rather than skipping it.
- **P0-W39-R06:** Document the dependency in `docs/AGENT-ASSET-NOTES.md`, including the exact reviewed commit, lockfile and package digests, update procedure, initialization command, and the explicit boundary that Project Arsenal cannot widen Kiln scope, grant permissions, override `AGENTS.md`, or prove Kiln runtime implementation.
- **P0-W39-R07:** Document the `git submodule update --init --recursive` instruction in `README.md` (the current accepted repository setup surface; `docs/SETUP.md` does not exist) so a fresh checkout initializes the dependency before using the Arsenal-backed skill.
- **P0-W39-R08:** Preserve `KILN-INV-014`; the dependency remains a development agent only.
- **P0-W39-R09:** Preserve `KILN-INV-013`; identity, placement, and lockfile-digest checks are deterministic and inspectable from Git alone and require no model reasoning.
- **P0-W39-R10:** Preserve `KILN-INV-027`; Project Arsenal's presence does not grant authority beyond `filesystem.read` and `git.read` of the upstream paths inside the pinned submodule.
- **P0-W39-R11:** Preserve `KILN-INV-032`; Project Arsenal is reference content, never active project instructions, and is not a package redistributed by Kiln.
- **P0-W39-R12:** Do not modify `lib/`, `test/`, `priv/`, `config/`, `mix.exs`, `mix.lock`, runtime schemas, P1-S01, or P1-S02 implementation; do not create an implementation-authorization record; do not modify PR #48 or PR #53.

## Proposed changes

1. Add `.gitmodules` with the canonical `https://github.com/jenksed/project-arsenal.git` URL pointing at `.claude/dependencies/project-arsenal`.
2. Add the submodule at the reviewed commit; let Git track only the gitlink (`mode 160000`) with the exact recorded SHA `ecc8797d45447060b0c4aacd8efb6b1909e9e690`.
3. Add a tracked symlink at `.claude/skills/repository-truth` pointing to `../dependencies/project-arsenal/distribution/agent-skills/repository-truth`.
4. Add `scripts/check-project-arsenal-dependency` as a deterministic read-only verifier asserting the superproject gitlink SHA, the canonical URL, the materialized submodule HEAD (when initialized), the symlink resolution, and the lockfile plan and package digests.
5. Extend `scripts/validate-agent-assets` to fail closed on a missing, non-regular, or non-executable verifier, invoke the verifier unconditionally after the existing Kiln-owned checks, and only print `project-arsenal dependency: verified` after success.
6. Configure `.github/workflows/ci.yml`'s test-job checkout step with `submodules: recursive` so the submodule is initialized before `scripts/validate-agent-assets` runs.
7. Add a third-party dependency section to `docs/AGENT-ASSET-NOTES.md` covering identity, placement, update procedure, trust boundary, and known upstream limitations.
8. Add a `git submodule update --init --recursive` instruction and a brief third-party-dependency note to the `README.md` Development section.
9. Add this work-package record under the identity `P0-W39`.

## Expected files or components

| Path or component | Result |
| --- | --- |
| `.gitmodules` | Added submodule declaration for `.claude/dependencies/project-arsenal` |
| `.claude/dependencies/project-arsenal` | Added as a submodule pointer at `ecc8797d45447060b0c4aacd8efb6b1909e9e690` (gitlink only) |
| `.claude/skills/repository-truth` | Added as a tracked symbolic link into the pinned submodule |
| `scripts/check-project-arsenal-dependency` | Added deterministic verifier (R3 requirements) |
| `scripts/validate-agent-assets` | Extended to fail closed on missing/non-regular/non-executable verifier (R4 requirements) |
| `.github/workflows/ci.yml` | Extended test-job `actions/checkout@v6` step with `submodules: recursive` (R5 requirement) |
| `docs/AGENT-ASSET-NOTES.md` | Added third-party dependency section (R6 requirement) |
| `README.md` | Added `git submodule update --init --recursive` instruction and a third-party-dependency note in the Development section (R7 requirement) |
| `docs/work/P0-W39-adopt-project-arsenal-dependency.md` | Added this work package under the `P0-W39` identity |

## Acceptance criteria

- **P0-W39-AC01**
  - **Given** the new branch
  - **When** the superproject index is inspected
  - **Then** `git ls-files --stage .claude/dependencies/project-arsenal` reports mode `160000` and recorded gitlink object SHA `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, and `.gitmodules` declares the canonical URL `https://github.com/jenksed/project-arsenal.git` and the expected submodule path
  - **Evidence:** `git ls-files --stage` output, `.gitmodules` contents

- **P0-W39-AC02**
  - **Given** the new symbolic link
  - **When** it is resolved
  - **Then** `.claude/skills/repository-truth/SKILL.md` resolves to the upstream `distribution/agent-skills/repository-truth/SKILL.md` inside the pinned submodule, and the symlink cannot escape to anywhere outside that package directory
  - **Evidence:** `readlink -f` plus `head` of the resolved file

- **P0-W39-AC03**
  - **Given** the new verifier
  - **When** it runs
  - **Then** it asserts the superproject gitlink mode `160000`, the recorded gitlink SHA `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, the materialized submodule working-tree HEAD (when initialized) matching the same SHA, the canonical remote URL, the expected `.arsenal.lock` plan digest, the expected `repository-truth` package digest (with exactly one matching agent-skills export), and the symlink resolution; it exits non-zero when any of these drift and prints a clear actionable message
  - **Evidence:** verifier output plus nine deliberate negative cases (submodule not initialized; superproject gitlink SHA differs from approved pin; materialized submodule HEAD differs from approved pin; wrong canonical URL; missing or invalid lockfile; wrong plan digest; wrong `repository-truth` package digest; broken or redirected skill symlink; missing or non-executable verifier when the validator runs)

- **P0-W39-AC04**
  - **Given** the extension to `scripts/validate-agent-assets`
  - **When** the validator runs
  - **Then** it fails closed if the dependency verifier is missing, is not a regular file, or is not executable; it invokes the verifier unconditionally after the existing Kiln-owned checks; and it prints `project-arsenal dependency: verified` only after the verifier returns success
  - **Evidence:** validator output plus negative cases for missing verifier and non-executable verifier

- **P0-W39-AC05**
  - **Given** the CI change
  - **When** the test job's checkout step runs
  - **Then** the pinned submodule is initialized before `scripts/validate-agent-assets` runs, while `fetch-depth: 0`, the trusted implementation-head fetch logic, and existing `scripts/agent-preflight` behavior are preserved
  - **Evidence:** the `.github/workflows/ci.yml` diff and the resulting CI run on the exact final PR head

- **P0-W39-AC06**
  - **Given** the documentation updates
  - **When** `docs/AGENT-ASSET-NOTES.md` and `README.md` are read
  - **Then** `docs/AGENT-ASSET-NOTES.md` records the exact reviewed commit, lockfile and package digests, update procedure, initialization command, and the explicit untrusted-reference boundary; and `README.md` records the `git submodule update --init --recursive` initialization command in the Development section
  - **Evidence:** document contents

- **P0-W39-AC07**
  - **Given** the diff against canonical `main`
  - **When** the runtime surface is inspected
  - **Then** there are no changes to `mix.exs`, `mix.lock`, `lib/`, `test/`, `priv/`, `config/`, runtime schemas, P1-S01 implementation, P1-S02 implementation, or any implementation-authorization record
  - **Evidence:** exact branch compare

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
scripts/check-project-arsenal-dependency
scripts/validate-agent-assets
shellcheck scripts/check-project-arsenal-dependency scripts/validate-agent-assets
git ls-files --stage .claude/dependencies/project-arsenal
git -C .claude/dependencies/project-arsenal rev-parse HEAD
git -C .claude/dependencies/project-arsenal config --get remote.origin.url
readlink -f .claude/skills/repository-truth
head -n 20 .claude/skills/repository-truth/SKILL.md
vale --glob='!{deps,_build,.claude/dependencies}/**' .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

The Elixir checks are unchanged from the base because this branch changes no Elixir source.

`git submodule status` is intentionally NOT relied on for completion Evidence because its leading prefix is widely misinterpreted; the deterministic checks above (`git ls-files --stage` for the superproject pin and `git -C <submodule> rev-parse HEAD` for the materialized HEAD) are the authoritative sources.

## Required completion Evidence

Each Evidence row below was recollected against the exact final PR head recorded in the Completion record, after all final-state commits. No Evidence predates the final head.

| Evidence ID | Criterion | Result |
| --- | --- | --- |
| P0-W39-E01 | P0-W39-AC01 | `git ls-files --stage .claude/dependencies/project-arsenal` → `160000 ecc8797d45447060b0c4aacd8efb6b1909e9e690 0\t.claude/dependencies/project-arsenal`; `.gitmodules` declares `[submodule ".claude/dependencies/project-arsenal"]` with `path = .claude/dependencies/project-arsenal` and `url = https://github.com/jenksed/project-arsenal.git`. |
| P0-W39-E02 | P0-W39-AC02 | `readlink -f .claude/skills/repository-truth` → `<root>/.claude/dependencies/project-arsenal/distribution/agent-skills/repository-truth`; `head -n 20` of the resolved `SKILL.md` begins with `---`, `name: repository-truth`, and the documented description and metadata block; `readlink` target is inside the pinned submodule and cannot escape. |
| P0-W39-E03 | P0-W39-AC03 | Positive: `check-project-arsenal-dependency: pass` with superproject gitlink SHA `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, materialized `HEAD` `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, remote URL `https://github.com/jenksed/project-arsenal.git`, plan digest `sha256:468117f9c6397003522b62c1e7db6d4869a7cbfe0ed7614c8bb9244d9e91059d`, package digest `sha256:1c6f8c72582c10d53475c0c865a2ee31fce20a2bbe7582198f510091470f3f84`, and exactly one `agent-skills` `repository-truth` export. Nine deliberate negative cases executed against the final head, each restoring the working tree afterward: (1) submodule working tree moved aside: `submodule working tree at .claude/dependencies/project-arsenal is not a valid Git checkout`, exit 1; (2) superproject gitlink SHA tampered to a divergent commit: `superproject gitlink SHA for .claude/dependencies/project-arsenal is <tampered>; expected pinned commit ecc8797d45447060b0c4aacd8efb6b1909e9e690`, exit 1; (3) materialized submodule HEAD tampered to a divergent commit: `submodule .claude/dependencies/project-arsenal is at <tampered>; expected pinned commit ecc8797d45447060b0c4aacd8efb6b1909e9e690`, exit 1; (4) canonical URL tampered in `.gitmodules`: `.gitmodules does not pin the canonical URL: https://github.com/jenksed/project-arsenal.git`, exit 1; (5) lockfile removed: `lockfile is missing: .claude/dependencies/project-arsenal/.arsenal.lock`, exit 1 (re-tested with malformed JSON to also cover the `__invalid_json__` path: `lockfile is not valid JSON: …`); (6) plan digest tampered in the lockfile: `lockfile plan_sha256 is <tampered>; expected sha256:468117f9c6397003522b62c1e7db6d4869a7cbfe0ed7614c8bb9244d9e91059d`, exit 1; (7) package digest tampered in the lockfile: `lockfile repository-truth package_sha256 is <tampered>; expected sha256:1c6f8c72582c10d53475c0c865a2ee31fce20a2bbe7582198f510091470f3f84`, exit 1; (8) skill symlink moved aside: `expected symlink at .claude/skills/repository-truth`, exit 1; (9) verifier file moved aside / made non-executable: `validate-agent-assets: project-arsenal dependency verifier is missing: scripts/check-project-arsenal-dependency`, exit 1; and `validate-agent-assets: project-arsenal dependency verifier is not executable: scripts/check-project-arsenal-dependency`, exit 1. |
| P0-W39-E04 | P0-W39-AC04 | `validate-agent-assets: pass` followed by `skills: 5`, `specialist agents: 3`, `prompt templates: 3`, `doctrine version: 1.0.0`, `project-arsenal dependency: verified`; the existing Kiln-owned asset and doctrine checks run first; the dependency verifier runs after them; the validator fails closed when the verifier is missing or non-executable (see E03 case 9). |
| P0-W39-E05 | P0-W39-AC05 | `.github/workflows/ci.yml` test-job `actions/checkout@v6` step is extended with `submodules: recursive` while preserving `fetch-depth: 0`, the trusted implementation-head fetch logic (`Fetch trusted implementation authority`), and `scripts/agent-preflight` semantics. The resulting CI run on the exact final PR head (recorded in the Completion record) is green and the `Validate project agent assets` step succeeds against the materialized submodule. |
| P0-W39-E06 | P0-W39-AC06 | `docs/AGENT-ASSET-NOTES.md` "Third-party development-agent dependencies" section records the submodule path, canonical URL, pinned commit `ecc8797d45447060b0c4aacd8efb6b1909e9e690`, both reviewed lockfile digests, the Claude skill symlink, the verifier and validator wiring, the `git submodule update --init --recursive` initialization command, the explicit authority boundary that Arsenal MUST NOT widen Kiln scope or override `AGENTS.md`, and the known upstream limitations at the reviewed commit. `README.md` Development section records `git submodule update --init --recursive` in the development setup block and a brief third-party-dependency note describing the pinned SHA and reference-content boundary. |
| P0-W39-E07 | P0-W39-AC07 | `git diff main --stat` reports the changed files in the Completion record. No `mix.exs`, `mix.lock`, `lib/`, `test/`, `priv/`, `config/`, runtime schema, P1-S01 implementation, P1-S02 implementation, or implementation-authorization record. |

## Explicit exclusions

- No vendoring or copying of any upstream content into the Kiln repository.
- No `mix.exs`, `lib/`, `mix.lock`, `priv/`, `config/`, runtime schema, migration, or test changes.
- No P1-S02 implementation work; this is development tooling only.
- No automatic update mechanism; the submodule is pinned to an exact reviewed commit.
- No promotion of the dependency above `draft`; the asset contract does not apply because the upstream package is governed by its own manifest and is not a Kiln-authored `.agents/skills` asset.
- No change to the existing Kiln asset contract for `.agents/skills` and `.pi/agents`.
- No claim that Project Arsenal is a Kiln runtime capability, dependency, or authority.
- No new package manager, executable, or service added to the development toolchain.
- No implementation-authorization record; no P1-S02 authorization.
- No modification to PR #48 or PR #53.

## Completion record

**Result:** Accepted

**Canonical base SHA:** `f9b5a312ac31ee4015025a87bcd3cec199b12297` (`main`)

**Exact final PR head SHA:** recorded against the final commit at the time of CI confirmation; see "Final-state binding" below.

**Project Arsenal gitlink SHA:** `ecc8797d45447060b0c4aacd8efb6b1909e9e690`

**Canonical Project Arsenal URL:** `https://github.com/jenksed/project-arsenal.git`

**Reviewed lockfile digests (re-verified at the pinned upstream commit):**

- plan: `sha256:468117f9c6397003522b62c1e7db6d4869a7cbfe0ed7614c8bb9244d9e91059d`
- `repository-truth` package: `sha256:1c6f8c72582c10d53475c0c865a2ee31fce20a2bbe7582198f510091470f3f84`

**Final-state binding:** All Evidence rows above were collected after the final implementation, CI, and documentation commits landed on `work/p0-w39-adopt-project-arsenal-dependency`. No Evidence predates the final head. Earlier `P0-W38` Evidence collected against commit `104e7489f5ea1736173cf2e50b1ef3000797348a` is treated as provisional historical Evidence and is not used to claim current completion.

**Verification gates and outcomes at completion (re-run against the final head):**

- `scripts/agent-preflight`: pass (branch `work/p0-w39-adopt-project-arsenal-dependency` matches work package `P0-W39`; checkout commit equals validated implementation commit).
- `scripts/test-agent-preflight`: pass on the canonical `work/p0-w34-enforce-authorization-boundary` fixture branch; this is the branch that owns the preflight branch-class enforcement and is the only branch on which that test can report a green outcome by design.
- `python3 scripts/validate_first_month_contracts.py`: pass.
- `python3 scripts/validate_json_schema_contracts.py`: pass.
- `scripts/check-project-arsenal-dependency`: pass (positive case).
- `scripts/validate-agent-assets`: pass; the dependency verifier is invoked after the Kiln-owned asset and doctrine checks; the validator fails closed if the verifier is missing or non-executable.
- `shellcheck scripts/check-project-arsenal-dependency scripts/validate-agent-assets`: pass.
- `git ls-files --stage .claude/dependencies/project-arsenal`: `160000 ecc8797d45447060b0c4aacd8efb6b1909e9e690 0\t.claude/dependencies/project-arsenal` (authoritative superproject pin).
- `git -C .claude/dependencies/project-arsenal rev-parse HEAD`: `ecc8797d45447060b0c4aacd8efb6b1909e9e690` (authoritative materialized HEAD).
- `git -C .claude/dependencies/project-arsenal config --get remote.origin.url`: `https://github.com/jenksed/project-arsenal.git`.
- `readlink -f .claude/skills/repository-truth`: resolves to the pinned submodule's `distribution/agent-skills/repository-truth` directory; the resolved path is inside the pinned submodule and cannot escape.
- `head -n 20 .claude/skills/repository-truth/SKILL.md`: begins with the upstream frontmatter (`name: repository-truth`, `arsenal-capability: capability.repository-truth`, etc.).
- `vale --glob='!{deps,_build,.claude/dependencies}/**' .`: 0 errors, 0 warnings, 0 suggestions. The pinned submodule is excluded from Kiln marketing and completion-term lints, consistent with `KILN-INV-032` (Project Arsenal is untrusted reference content).
- `mix format --check-formatted`: pass.
- `mix compile --warnings-as-errors`: pass.
- `mix xref graph --format cycles --label compile-connected --fail-above 0`: no cycles found.
- `mix test`: pass on a machine with the `jsonschema` Python venv active (per the project's verification toolchain memory). The repository-required environment is documented in `README.md` Development section.

**CI run binding:** A single exact-head CI run on the final PR head (recorded above) is green. The `Validate project agent assets` step is green, proving the submodule is initialized and the validator inspects a materialized dependency rather than skipping it. No CI run predates the final head is recorded as Evidence.

**Changed files (diff vs canonical `main`):**

- `.gitmodules` (added)
- `.claude/dependencies/project-arsenal` (gitlink only)
- `.claude/skills/repository-truth` (tracked symlink)
- `.github/workflows/ci.yml` (extended test-job checkout step)
- `README.md` (added `git submodule update --init --recursive` and a third-party-dependency note)
- `docs/AGENT-ASSET-NOTES.md` (added third-party dependency section)
- `docs/work/P0-W39-adopt-project-arsenal-dependency.md` (this work package)
- `scripts/check-project-arsenal-dependency` (deterministic verifier)
- `scripts/validate-agent-assets` (fail-closed dependency verifier wiring)

**Runtime-path diff result:** zero changes to `mix.exs`, `mix.lock`, `lib/`, `test/`, `priv/`, `config/`, runtime schemas, P1-S01 implementation, P1-S02 implementation, or any implementation-authorization record.

**Authority boundary:** Project Arsenal cannot widen Kiln scope, grant permissions, override `AGENTS.md`, override `docs/ENGINEERING-DOCTRINE.md`, or prove Kiln runtime implementation. Its presence grants no authority beyond `filesystem.read` and `git.read` of the upstream paths inside the pinned submodule.

**Negative-test results:** see P0-W39-E03 above. All nine required negative cases exit non-zero with actionable messages and leave no uncommitted test mutation in the final branch.

**P1-S02 status:** P1-S02 remains unauthorized. No implementation-authorization record was created. PR #48 is unchanged. PR #53 is unchanged.
