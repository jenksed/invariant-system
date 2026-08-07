# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

`kiln` is a local-first, single-developer coding execution ledger and control plane built with Elixir/OTP. The product moves one accepted objective through `Intent → Investigation → Implementation → Verification → Completion`. The core model is `Workspace → Project → Session → Task → Root Run` (Child Runs are a deferred v0.1 capability). Git and the filesystem are authoritative for source state; SQLite records Kiln work facts only.

**Build authorization has not been issued.** This repository is in a planning/reconciliation phase. Do not begin Phase 1 implementation work without an explicit authorization pass. Plans live in `docs/work/`, decisions in `docs/decisions/`, and invariants in `docs/PROJECT-INVARIANTS.md` (`KILN-INV-*`).

## Authoritative reading order (before any work)

1. `AGENTS.md` — project identity, planning boundary, non-negotiable principles, Elixir/OTP rules, domain rules, change discipline.
2. `README.md` — product scope and delivery target summary.
3. `docs/PLANNING-COMPLETION-BASELINE.md` — current planning status and blockers.
4. `docs/PROJECT-INVARIANTS.md` — must-preserve constraints (`KILN-INV-001`+).
5. `docs/AGENT-FRIENDLY-CODEBASE.md` — earned-namespace, process, documentation, and test rules.
6. `docs/ENGINEERING-QUALITY-RULES.md` — prose and documentation standards.
7. `docs/decisions/0001…0022` — accepted ADRs; one per material architecture change.
8. The accepted plan in `docs/work/<WORK-ID>-<purpose>.md` for the current branch.

## Toolchain

Pinned via `mise.toml`: Erlang `28.4`, Elixir `1.20.2-otp-28`, Vale `3.14.2`.

```bash
mise install            # install pinned toolchain
mix deps.get            # fetch dependencies (only :exqlite ~> 0.39 today)
```

## Branching and work-package grammar

Work branches follow `docs/BRANCHING-AND-WORK-PLANNING.md`:

- `work/p<phase>-w<##>-<purpose>` — planning package
- `work/p<phase>-s<##>-<purpose>` — slice package
- `work/p<phase>-s<##>-t<##>-<purpose>` — ticket package
- Also: `fix/*`, `spike/*`, `docs/*`, `chore/*`, `release/*`, `hotfix/*`, or `agent/bootstrap-project-foundation`.

`main`/`master`/`develop` are protected; implementation work does not run on them. Run `scripts/agent-preflight` to validate the branch, required context files, and the matching plan's required headings before starting work. **The current preflight enforces obsolete P0 work-package grammar; reconciliation is pending — do not bypass it.**

## Common commands

```bash
scripts/agent-preflight                  # branch/plan/heading conformance gate
scripts/test-agent-preflight             # preflight self-test
scripts/check                            # full local validation (the canonical local CI)
scripts/validate-agent-assets            # agent-asset conformance checks
python3 scripts/validate_first_month_contracts.py
python3 scripts/validate_json_schema_contracts.py
vale --glob='!{deps,_build}/**' .        # prose lint
mix format --check-formatted             # formatting (alias: in scripts/check)
mix compile --warnings-as-errors         # build (alias: in scripts/check)
mix xref graph --format cycles \
    --label compile-connected --fail-above 0   # forbidden compile-time cycles
mix test                                 # unit/integration tests
mix test test/path/to/file_test.exs      # single test file
mix test test/path/to/file_test.exs:42   # single test by line (ExUnit)
```

`scripts/check` runs the same sequence CI runs (`scripts/test-agent-preflight` → contract validators → `validate-agent-assets` → vale → `mix format --check-formatted` → `mix compile --warnings-as-errors` → cycle check → `mix test`).

`mix check` is the mix alias for `format --check-formatted && compile --warnings-as-errors && test`.

## Repository layout

Source layout is **earned, not pre-created.** Do not scaffold future-slice namespaces; create a directory/module only when its accepted ticket requires it.

```text
mix.exs                          # Mix project, deps (only :exqlite 0.39), check alias
lib/kiln.ex                      # Public domain boundary (currently Kiln.version/0)
lib/kiln/application.ex          # OTP supervisor; opens Kiln.Store only when configured
lib/kiln/store/                  # SQLite storage: canonical, connection, journal, migrations, uuid, error
lib/kiln/journal/                # Append-only event journal: entry, reducer, replay
lib/kiln/projections/            # Read-model projections rebuilt from the journal
lib/kiln/domain/                 # Pure domain types: run, task, session, transition, action, operation, decision, project_observation, error, id
lib/kiln/conformance/            # Conformance scaffolding (provider, command_host, first_month)
lib/kiln/restart.ex              # Durable-state recovery
test/                            # Mirrors lib/ paths; support/ and fixtures/ for shared helpers
docs/decisions/                  # ADRs (0001…); supersede older ones with a new ADR, never silently
docs/work/                       # Per-branch work plans (file name must match branch identifier)
docs/PLANNING-COMPLETION-BASELINE.md
docs/PROJECT-INVARIANTS.md       # KILN-INV-001… invariants register
docs/ARCHITECTURE.md             # Integrated architecture
docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md
scripts/                         # Shell gates; check is the canonical local CI entry
.github/workflows/ci.yml         # Mirrors scripts/check + prose lint
.github/CODEOWNERS               # Single owner (@jenksed); /docs/decisions, /docs/PROJECT-INVARIANTS.md, /AGENTS.md require owner review
.github/pull_request_template.md # Use as-is: Work package, Acceptance table, Verification table, Completion statement
```

## Architectural rules that govern code changes

These are the load-bearing constraints. The full set (KILN-INV-*) lives in `docs/PROJECT-INVARIANTS.md`.

- **Git and the filesystem are source truth.** SQLite records Kiln work facts only; it does not replace source history.
- **A Run is not** an Agent, a model request, a Tool call, a Command, a process, a branch, or a transcript. Conversation content can belong to a Run; it cannot become canonical objective, mutation, Evidence, or completion state.
- **Run lifecycle:** `created → ready → running → waiting_for_user | waiting_for_command | verifying → completed | failed | canceled | orphaned`. Blocked/stale/unknown effects never collapse to `PASS`.
- **A model proposes; it does not approve or apply Patches.** Patch application requires exact base-state validation and explicit user Approval of the Patch digest.
- **A successful Command does not imply every criterion passed.** Evidence must identify subject, method, state binding, freshness, completeness.
- **A Receipt cannot grant authority** or create a passing result. It references Evidence and decisions.
- **No permanent process** for a Run, Session, Task, Capability, Artifact, or Evidence record. Create a process only when it owns a live concern (mutable shared state, Resource lifetime, scheduling, timing, cancellation, streaming, subscriptions, external communication, or fault isolation). First-month processes are limited to: the application supervisor, a transient model invocation Worker, and a transient Command Worker.
- **Do not persist** PIDs, references, Ports, Tasks, anonymous functions, sockets, provider handles, or DB connection handles as domain identity. Use explicit Kiln identifiers.
- **No atoms from external input. No arbitrary sleeps for synchronization** — use monitors, explicit messages, controlled clocks, or bounded polling.
- **Choose the smallest integration boundary** that preserves semantics, cancellation, security, Evidence, testing, and replacement (direct function → library → deterministic CLI → direct API/SDK → local service/socket → dedicated adapter → protocol client → protocol server → MCP). MCP is not a sandbox, Repository boundary, or permission system.
- **Configuration enters through a defined boundary** — do not scatter `Application.get_env/3` calls through domain modules.
- **Tagged results at expected failure boundaries:** `{:ok, value}` / `{:error, reason}`. Don't rescue broad exceptions into success-shaped values.

## Workflow: before / during / after editing

Before editing a file:
1. `scripts/agent-preflight` (or stop and report the known conformance mismatch).
2. Read the accepted plan and list applicable `KILN-INV-*` and `ADR-*` identifiers.
3. Inspect current source, tests, Git state, and dependency direction (`mix xref callers`, `mix xref trace` for shared boundaries).
4. State the expected mutation surface, narrow verification, and the complete required gate.

During work: separate observed / inferred / proposed / assumed / unknown. Keep the change localized; do not reformat unrelated code or scaffold future-slice namespaces. Update the plan when material facts change; stop when Evidence invalidates the plan.

Before completion: inspect the final diff, run narrow checks, run the full `scripts/check`, request the applicable read-only reviewer (OTP, integrity, or verifier), link criteria to current Evidence, and report failures / warnings / unknowns / exclusions. State the completion as `Complete`, `Implemented but unverified`, or `Blocked` — never claim verification that did not run.

## Pull requests

Use `.github/pull_request_template.md` verbatim. Each PR carries a single work-package identifier that matches the branch, plan file, requirements, acceptance criteria, Evidence identifiers, and completion report. A material architecture change requires an ADR; do not reverse an accepted ADR without a superseding ADR.

## Commit message convention

Commit messages describe the change; they do not attribute the change to a coding agent. Do not append `Co-Authored-By:` trailers for Claude or any other AI coding tool, and do not reference the assistant in the subject or body. The branch, the work-package plan, the PR body, and the completion record already carry authorship.
