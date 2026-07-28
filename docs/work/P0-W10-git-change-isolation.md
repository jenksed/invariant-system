# P0-W10: Git change isolation

- **Status:** In progress
- **Branch:** `work/p0-w10-git-change-isolation`
- **Depends on:** P0-W05 through P0-W09
- **Scope:** Planning and contracts only

## Objective

Define how Kiln isolates, coordinates, verifies, integrates, recovers, and explains Git-backed source changes.

## Observed current state

- Git and the filesystem own Repository truth.
- Run is the primary durable execution unit.
- Parent-child Run lineage is separate from OTP supervision.
- Change sets are immutable proposed or observed Repository mutations.
- Capabilities, grants, Repository trust policy, and Privacy policy define authority.
- Git normally uses a native adapter backed by the Git CLI.
- Child and Verifier Runs receive independent Context and grants.
- Git worktrees are classified as foundational internal isolation infrastructure.
- Existing development branch guidance uses trunk-based work packages but does not define the Kiln runtime branch, worktree, lease, integration, or recovery model.

## Requirements

- **P0-W10-R01:** Accept or replace the protected-trunk, short-lived task branch, exclusive-worktree default.
- **P0-W10-R02:** Define independent, stacked, candidate, timeboxed integration, and Patch Artifact modes.
- **P0-W10-R03:** Define Run-to-checkout, Run-to-branch, and Run-to-worktree mapping.
- **P0-W10-R04:** Define machine-readable branch, worktree lease, Change set, Patch Artifact, verification, and integration contracts.
- **P0-W10-R05:** Define managed change-environment lifecycle and recovery.
- **P0-W10-R06:** Bind Evidence to exact Repository state and define invalidation.
- **P0-W10-R07:** Separate authoring, verification, and integration authority.
- **P0-W10-R08:** Define Repository-scoped Git mutation serialization.
- **P0-W10-R09:** Define conflict classes and safe resolution conditions.
- **P0-W10-R10:** Map the design to Elixir and OTP without process-per-noun architecture.
- **P0-W10-R11:** Define initial implementation boundary and later-plan changes.
- **P0-W10-R12:** Preserve user work during crash recovery and cleanup.

## Proposed changes

- Add `docs/GIT-CHANGE-ISOLATION.md`.
- Add `docs/contracts/kiln-git-change.schema.json`.
- Add ADR 0013.
- Update branching guidance to separate Kiln Repository development policy from product runtime semantics.
- Update roadmap and indexes.

## Acceptance criteria

- **P0-W10-AC01:** The specification clearly states when a Run needs no checkout, shared read-only access, a detached worktree, an exclusive writable worktree, a branch, or Patch Artifact mode.
- **P0-W10-AC02:** One writable worktree cannot have two active mutation owners.
- **P0-W10-AC03:** A Child Run inherits neither branch nor mutation authority.
- **P0-W10-AC04:** A Verifier cannot repair the branch that it evaluates.
- **P0-W10-AC05:** Every verification result binds to an exact commit or dirty-tree fingerprint.
- **P0-W10-AC06:** Rebase, force-push, ancestor movement, merge-base change, or dirty-state change invalidates affected Evidence.
- **P0-W10-AC07:** Repository-global mutations are serialized per Repository, not globally.
- **P0-W10-AC08:** Crash recovery preserves dirty and uncertain user work.
- **P0-W10-AC09:** The integration gate checks projected merged state and requires separate authorization.
- **P0-W10-AC10:** The Elixir component map distinguishes data, active processes, durable state, transient state, and mutation authority.
- **P0-W10-AC11:** JSON Schema Draft 2020-12 validation passes.
- **P0-W10-AC12:** No production code is added.

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix test
```

Contract verification:

```bash
python -m json.tool docs/contracts/kiln-git-change.schema.json
```

A Draft 2020-12 validator MUST validate representative examples for each top-level contract type before P0-W10 is reported as fully verified.

## Required Evidence

- **P0-W10-E01:** Git change-isolation specification covers all required modes and distinctions.
- **P0-W10-E02:** Branch contract and lease schema parse and validate.
- **P0-W10-E03:** ADR 0013 records the accepted default and rejected alternatives.
- **P0-W10-E04:** Roadmap and branching authorities link to the specification.
- **P0-W10-E05:** Diff contains documentation and JSON contracts only.
- **P0-W10-E06:** Repository checks pass or failures are recorded accurately.

## Exclusions

This work does not implement:

- Git adapters;
- worktree provisioning;
- SQLite migrations;
- Repository coordinators;
- worktree lease processes;
- merge automation;
- hosting-provider adapters;
- merge queues;
- stacked or candidate workflows;
- automatic conflict resolution;
- remote publication;
- operating-system sandboxing.
