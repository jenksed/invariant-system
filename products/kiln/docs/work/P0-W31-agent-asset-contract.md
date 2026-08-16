# P0-W31: Establish the development-agent asset contract

**Document type:** Development-tooling work package  
**Status:** In progress  
**Branch:** `work/p0-w31-agent-asset-contract`  
**Base:** `main`, which contains the merged P0-W30 work  
**Implementation authorization:** None; this work package does not authorize P1-S01 or P1-S02 product implementation

## Objective

Give Kiln's development-agent assets a declared invocation mode and an evidence-bound lifecycle status, and enforce both deterministically instead of by convention.

This package also carries the doctrine provenance check that P0-W30 deliberately excluded, because both changes belong to the same validator.

## Observed current state

- `.agents/skills/*/SKILL.md` declared only `name`, `description`, and `compatibility`.
- `.pi/agents/*.md` declared only `name`, `description`, `tools`, and `thinking`.
- No asset declared how it is invoked, so the difference between a deliberate orchestration step and an automatically selectable discipline was implicit.
- No asset declared a lifecycle status, so a widely used asset and an untested one were indistinguishable.
- `scripts/validate-agent-assets` checked presence, skill naming, and the specialist no-write rule. It did not check any field values against an allowed set.
- `docs/ENGINEERING-DOCTRINE.md` records upstream provenance and a `Doctrine-Version`, and P0-W30 left that record unenforced so its own branch stayed documentation-only.
- P0-W30 merged to `main` through pull request 43 as merge commit `4f32815`, so the doctrine provenance record this package enforces is now part of the base rather than a stacked dependency.
- The repository holds no recorded evaluation evidence for any development-agent asset.

## Assumptions and unknowns

### Assumptions

- **P0-W31-A01:** A reduced four-mode invocation set and three-state lifecycle set are sufficient for Kiln's current eight assets.
- **P0-W31-A02:** Frontmatter plus the existing Bash validator is proportionate at this scale; a machine-readable registry and generated catalog are not yet justified.
- **P0-W31-A03:** Every current asset is honestly `draft`, because no evaluation evidence exists to support a higher status.

### Unknowns

- **P0-W31-U01:** Which assets will earn `testing` or `stable`, and what recorded evaluation evidence will justify promotion?
- **P0-W31-U02:** Whether asset count will grow enough to justify a registry and generated catalog.
- **P0-W31-U03:** Whether drift of the adopted doctrine text, rather than deletion of its provenance record, needs its own detection mechanism.

## Requirements

- **P0-W31-R01:** Every project-local skill and specialist-agent definition declares `invocation`.
- **P0-W31-R02:** Every project-local skill and specialist-agent definition declares `status`.
- **P0-W31-R03:** `scripts/validate-agent-assets` rejects a missing or out-of-set value for either field.
- **P0-W31-R04:** `scripts/validate-agent-assets` requires `docs/ENGINEERING-DOCTRINE.md` to declare a semantic `Doctrine-Version` and retain its provenance record.
- **P0-W31-R05:** `docs/AGENT-ASSET-NOTES.md` defines both fields and states that status is an evidence claim.
- **P0-W31-R06:** Status values reflect recorded evidence, so every current asset stays `draft`.
- **P0-W31-R07:** Preserve the existing boundary that these assets build Kiln and are not Kiln runtime capabilities.
- **P0-W31-R08:** Do not add product runtime code, dependencies, migrations, schemas, or tests.

## Proposed changes

1. Add `invocation` and `status` to the five project-local skills and the three specialist-agent definitions.
2. Extend `scripts/validate-agent-assets` with allowed-set validation for both fields.
3. Move the doctrine version and provenance check into the same validator.
4. Document both fields, their allowed values, and the promotion rule in `docs/AGENT-ASSET-NOTES.md`.
5. Add this work-package record.

## Expected files or components

| Path or component | Result |
| --- | --- |
| `.agents/skills/kiln-work-package/SKILL.md` | Added `invocation: human`, `status: draft` |
| `.agents/skills/kiln-evidence-closeout/SKILL.md` | Added `invocation: human`, `status: draft` |
| `.agents/skills/kiln-integrity-review/SKILL.md` | Added `invocation: agent`, `status: draft` |
| `.agents/skills/kiln-elixir-otp/SKILL.md` | Added `invocation: agent`, `status: draft` |
| `.agents/skills/kiln-dependency-review/SKILL.md` | Added `invocation: agent`, `status: draft` |
| `.pi/agents/kiln-integrity-reviewer.md` | Added `invocation: composed`, `status: draft` |
| `.pi/agents/kiln-otp-reviewer.md` | Added `invocation: composed`, `status: draft` |
| `.pi/agents/kiln-verifier.md` | Added `invocation: composed`, `status: draft` |
| `scripts/validate-agent-assets` | Added enum validation and the doctrine provenance check |
| `docs/AGENT-ASSET-NOTES.md` | Added the asset contract section |
| `docs/work/P0-W31-agent-asset-contract.md` | Added this work package |

## Acceptance criteria

- **P0-W31-AC01**
  - **Given** any project-local skill or specialist-agent definition
  - **When** `scripts/validate-agent-assets` runs
  - **Then** it fails when `invocation` or `status` is missing or outside its allowed set
  - **Evidence:** validator output plus deliberate negative-case runs

- **P0-W31-AC02**
  - **Given** the adopted Engineering Doctrine
  - **When** `scripts/validate-agent-assets` runs
  - **Then** it fails when the doctrine does not declare a semantic `Doctrine-Version` or does not retain its provenance record
  - **Evidence:** validator output plus deliberate negative-case runs

- **P0-W31-AC03**
  - **Given** the eight current assets
  - **When** their status values are read
  - **Then** each is `draft`, because no recorded evaluation evidence exists
  - **Evidence:** asset frontmatter

- **P0-W31-AC04**
  - **Given** this branch diff
  - **When** it is compared with its base
  - **Then** it contains only development-agent assets, development validation, and documentation, and no product runtime implementation
  - **Evidence:** exact branch compare

## Deterministic verification

```bash
scripts/agent-preflight
scripts/test-agent-preflight
scripts/validate-agent-assets
shellcheck scripts/validate-agent-assets
vale --glob='!{deps,_build}/**' .
```

Because this branch changes no Elixir source, the Elixir checks are unchanged from the base. Repository CI remains authoritative for the exact head.

## Required completion Evidence

| Evidence ID | Criterion | Result |
| --- | --- | --- |
| P0-W31-E01 | P0-W31-AC01 | five negative cases each exited non-zero with a naming message |
| P0-W31-E02 | P0-W31-AC02 | two negative cases each exited non-zero |
| P0-W31-E03 | P0-W31-AC03 | frontmatter of the eight assets |
| P0-W31-E04 | P0-W31-AC04 | exact branch compare against the base |

## Explicit exclusions

- No machine-readable asset registry.
- No generated asset catalog.
- No new validation language or dependency.
- No promotion of any asset above `draft`.
- No drift detection for the adopted doctrine body.
- No product runtime code, dependency, migration, Schema, or test.
- No change to the specialist no-write boundary.
- No claim that these assets are Kiln runtime capabilities.

## Completion record

**Result:** In progress

The package is complete only after both fields exist on every asset, the validator rejects missing and invalid values, the doctrine provenance check runs in the same validator, the fields are documented, and the branch review finds no product runtime change.
