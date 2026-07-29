# P0-W25: CLI product contract and local delivery

**Document type:** Focused planning work package  
**Status:** In progress  
**Branch:** `work/p0-w25-cli-local-delivery`  
**Depends on:** P0-W21 through P0-W24 and OD-01/OD-02 integrated  
**Scope:** Complete first-month CLI, structured output, configuration, diagnostics, restart interaction, arm64 macOS packaging, installation, versioning, and support expectations only  
**Build authorization:** Not issued

## Objective

Assemble the accepted lifecycle, provider, Context, Patch, Command, Evidence, acceptance, and Receipt decisions into one complete CLI-first product contract for Apple Silicon macOS.

## Requirements

- Map every user action to an accepted application command or query.
- Define objective and criteria input, Session start, status, investigation, Context inspection, Patch review, Approval, application, verification, Evidence inspection, acceptance, Receipt, cancellation, and recovery.
- Define interactive and noninteractive behavior without bypass flags.
- Define one stable structured output envelope and exit-code set.
- Define configuration, credential references, `$KILN_HOME`, Project records, and diagnostic output.
- Define errors, safe next actions, restart reconstruction, orphan interaction, and receipt delivery failures.
- Define Apple Silicon macOS installation and Mix-release packaging.
- Define version and build manifests and disposition `Kiln.version/0`.
- Preserve all semantic authorities from P0-W21 through P0-W24.
- Keep TUI, daemon, background service, auto-update, Homebrew, cross-platform packaging, implementation, and Wave B out.

## Expected files

- `docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md`
- `docs/decisions/0027-ship-an-arm64-macos-mix-release-first.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W24-command-evidence-acceptance.md`
- `docs/work/P0-W25-cli-local-delivery.md`

## Acceptance criteria

- Every first-month action and failure has one CLI command or explicit automatic startup behavior.
- Text and JSON output are explicit.
- Approval and acceptance cannot be bypassed by `--yes`, environment, model output, or configuration.
- Stable exit codes and error envelopes exist.
- Startup, doctor, configuration, secrets, supported host, state path, logging, and recovery are explicit.
- Mix release, target triple, package layout, checksum, install, upgrade, rollback limitation, version, and build manifest are explicit.
- No CLI command redesigns lifecycle, persistence, provider, Patch, Command, Evidence, acceptance, or Receipt semantics.
- No TUI, daemon, broad installer ecosystem, auto-update, implementation, or Wave B scope enters.
- Exact final-head CI passes.

## Required completion evidence

- P0-W25-E01: upstream authorities and OD-02 Evidence.
- P0-W25-E02: complete CLI command and workflow map.
- P0-W25-E03: text, JSON, error, exit, and interactive contract.
- P0-W25-E04: configuration, secret, diagnostic, restart, and recovery contract.
- P0-W25-E05: Mix-release packaging and local delivery contract.
- P0-W25-E06: upstream ownership audit.
- P0-W25-E07: planning-only compare and exact final-head CI.

## Explicit exclusions

P0-W25 does not implement a CLI or package; add dependencies, source, tests, config, release files, installer scripts, Schemas, CI, preflight, Skills, prompts, or agents; create a TUI, daemon, service, web UI, Homebrew formula, notarized public distribution, auto-update, remote access, or Wave B scope; or issue build authorization.
