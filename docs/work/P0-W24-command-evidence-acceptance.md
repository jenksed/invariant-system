# P0-W24: Command execution, Evidence, Artifacts, Receipts, and acceptance

**Document type:** Focused planning work package  
**Status:** In progress  
**Branch:** `work/p0-w24-command-evidence-acceptance`  
**Depends on:** P0-W21 through P0-W23 and OD-02 integrated  
**Scope:** Registered Command execution, macOS process ownership, output Artifacts, criterion Evidence, Receipt aggregation, user acceptance, and completion blocking only  
**Build authorization:** Not issued

## Objective

Define one non-shell registered Command path and one truthful proof path from execution through criterion-bound Evidence, user acceptance, completion, and Receipt delivery.

## Entry evidence

- P0-W21 owns operation intent, terminal-or-unknown result, lifecycle, journal, restart, orphan, and final completion transaction.
- P0-W22 owns provider, Context, Tool, Repository-read, disclosure, and secret policy.
- P0-W23 owns Patch, Approval, mutation, rollback, and resulting Repository observation.
- OD-02 selects Apple Silicon macOS 15.0 or later on local APFS as the only supported first-month host.
- Production source contains no Command Worker, process-group helper, Artifact store, criterion Evidence, Receipt, acceptance, or completion evaluator.

## Requirements

- Define one versioned registered Command contract with absolute executable, argv vector, working directory, environment, timeout, output, write, network, secret, and result rules.
- Prohibit shell strings and arbitrary model commands.
- Define one macOS process-group host boundary, TERM/KILL escalation, descendant observation, and unknown cleanup behavior.
- Define bounded stdout and stderr capture with immutable Artifact externalization.
- Define Artifact identity, sensitivity, trust, completeness, integrity, and active first-month retention.
- Define criterion Evidence subject, method, state binding, status, freshness, contradiction, completeness, and invalidation.
- Define aggregate completion evaluation and exact blocking rules.
- Define user acceptance binding and P0-W21 finalization inputs.
- Define a Receipt as a post-completion aggregation record with no authority.
- Consume upstream authorities and OD-02 without widening them.
- Keep all changes planning-only.

## Expected files

- `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`
- `docs/decisions/0026-use-registered-process-group-commands-on-macos.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W24-command-evidence-acceptance.md`

## Acceptance criteria

- One Command and Worker contract exists.
- macOS process-group launch, signaling, timeout, cancellation, and cleanup proof are explicit.
- Argument, environment, working-directory, executable, network, write, and secret handling are explicit.
- Artifact capture and retention are explicit.
- Evidence is bound to criterion and exact observed state.
- Freshness, contradiction, incompleteness, blocked, unknown, and failed results block completion.
- Exit zero, model confidence, a summary, or a Receipt cannot imply proof.
- User acceptance binds the current aggregate evaluation.
- P0-W21 finalization remains atomic and authoritative.
- Receipt sealing and delivery do not create completion.
- No CLI syntax, TUI, implementation, broad telemetry, attestation, remote execution, or Wave B scope enters.
- Exact final-head CI passes.

## Required completion evidence

- P0-W24-E01: upstream integration and OD-02 Evidence.
- P0-W24-E02: registered Command and macOS process-group contract.
- P0-W24-E03: output and Artifact contract.
- P0-W24-E04: Evidence and criterion-evaluation contract.
- P0-W24-E05: acceptance, completion, and Receipt sequence.
- P0-W24-E06: failure and contradiction matrices.
- P0-W24-E07: planning-only compare and exact final-head CI.

## Explicit exclusions

P0-W24 does not implement Commands or add a helper binary; change lifecycle, provider, Context, Patch, or mutation authority; define CLI commands; add a shell, arbitrary command execution, container, sandbox, remote Worker, telemetry exporter, attestation, or Wave B work; or issue build authorization.
