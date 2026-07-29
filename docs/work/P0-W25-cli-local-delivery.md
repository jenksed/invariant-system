# P0-W25: CLI product contract and local delivery

**Document type:** Focused planning work package  
**Status:** Implemented and verified on branch  
**Branch:** `work/p0-w25-cli-local-delivery`  
**Depends on:** P0-W21 through P0-W24 and OD-01/OD-02 integrated  
**Scope:** Complete first-month CLI, structured output, configuration, diagnostics, restart interaction, arm64 macOS packaging, installation, versioning, and support expectations only  
**Build authorization:** Not issued

## Objective

Assemble the accepted lifecycle, provider, Context, Patch, Command, Evidence, acceptance, and Receipt decisions into one complete CLI-first product contract for Apple Silicon macOS.

## Accepted planning decisions

P0-W25 proposes:

1. One foreground CLI named `kiln`; no daemon.
2. Text output by default and one versioned JSON result envelope.
3. Stable exits for usage, denied, blocked, stale, failed, unknown, store, unsupported host, and Receipt delivery failure.
4. Project, disclosure, Command-registration, Session, status, Context, investigation, Patch, verification, Evidence, acceptance, Receipt, cancellation, and recovery commands.
5. No `--yes`, auto-Approval, auto-acceptance, or configuration bypass.
6. Digest-bound interactive and noninteractive Approval and acceptance.
7. Default `$KILN_HOME` at `~/Library/Application Support/Kiln`.
8. Explicit host, store, helper, runtime, credential-reference, and unsupported-control diagnostics.
9. One arm64 macOS Mix release containing ERTS, Kiln, Exqlite, and the command-host helper.
10. `.tar.gz`, SHA-256, and canonical build manifest.
11. User-local side-by-side installation and explicit upgrade; no auto-update.
12. No root, daemon, Homebrew, public installer, notarization claim, universal binary, or cross-platform support claim.
13. `Kiln.version/0` derives from application or release metadata rather than a separate literal.
14. The CLI exposes accepted operations and does not own their semantics.

## Files changed

- `docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md`
- `docs/decisions/0027-ship-an-arm64-macos-mix-release-first.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W24-command-evidence-acceptance.md`
- `docs/work/P0-W25-cli-local-delivery.md`

Review-head compare against `main`:

- six Markdown files;
- 999 additions and 97 deletions;
- no source, tests, dependency, configuration, release files, installer, JSON Schemas, CI, scripts, preflight, Skills, prompts, agents, or scaffolding.

## Acceptance evidence

| Criterion | Result | Evidence |
| --- | --- | --- |
| Every first-month action and failure maps to CLI or startup | Pass | command and workflow sections |
| Text and JSON output explicit | Pass | output section |
| Approval and acceptance cannot be bypassed | Pass | Patch and completion sections |
| Stable exit and error envelopes | Pass | output and error sections |
| Startup, doctor, config, secrets, host, paths, logging, recovery | Pass | startup, config, diagnostics, logging, recovery sections |
| Mix release, target, package, checksum, install, upgrade, version, manifest | Pass | packaging and version sections |
| Upstream semantics unchanged | Pass | ownership audit |
| No TUI, daemon, broad installer, implementation, or Wave B | Pass | authority and exclusions |
| Review-head validation | Pass | CI `30422848272` on `b8c5425f7dddee600c0574b020ff5255d2efbbd5` |
| Exact closeout-head validation | Pending | final CI after this update |

## External evidence

Official Mix documentation supports a self-contained release and requires matching target architecture, operating system/vendor, and ABI for ERTS and native dependencies. That supports one arm64 macOS package and rejects a cross-platform claim.

## Verification

Review head `b8c5425f7dddee600c0574b020ff5255d2efbbd5` passed GitHub CI run `30422848272`.

The run passed Vale, current preflight behavior tests, Project agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, cycle detection, and ExUnit.

The current preflight result proves obsolete P0 mechanics only. It does not prove P1 ticket compatibility.

## Gate verdict

P0-W25 passes on this branch after exact closeout-head CI.

Owner acceptance and integration remain required.

## Exact next action

After final CI passes, merge P0-W25 and run Prompt 6-A against the integrated first-month planning state.
