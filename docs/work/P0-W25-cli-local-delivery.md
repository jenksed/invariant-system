# P0-W25: CLI product contract and local delivery

**Document type:** Focused planning work package  
**Status:** Implemented, verified, accepted, and integrated  
**Integrated through:** Pull request 33, merge commit `aabfc49a9b0ba294b4e0f6558fbe8fed38263784`  
**Final design head:** `4f03a5d785849b7a4ce7b46d0060404270292971`  
**Scope:** Complete first-month CLI, structured output, configuration, diagnostics, restart interaction, arm64 macOS packaging, installation, versioning, and support expectations only  
**Build authorization:** Not issued

## Accepted decisions

P0-W25 established:

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

## Files integrated

- `docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md`
- `docs/decisions/0027-ship-an-arm64-macos-mix-release-first.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W24-command-evidence-acceptance.md`
- `docs/work/P0-W25-cli-local-delivery.md`

The final branch contained six Markdown files, 1,022 additions, and 97 deletions. It changed no source, tests, dependency, configuration, release files, installer, JSON Schemas, CI, scripts, preflight, Skills, prompts, agents, or scaffolding.

## Verification

- Review head `b8c5425f7dddee600c0574b020ff5255d2efbbd5`: CI `30422848272`, success.
- Final head `4f03a5d785849b7a4ce7b46d0060404270292971`: CI `30422908234`, success.

Both passed Vale, current preflight behavior tests, Project agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, cycle detection, and ExUnit.

## Gate verdict

**P0-W25 passed and is integrated.**

Build authorization remains denied.

## Exact next action

Run Prompt 6-A against the integrated first-month planning state.
