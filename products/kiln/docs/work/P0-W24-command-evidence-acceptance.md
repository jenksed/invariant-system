# P0-W24: Command execution, Evidence, Artifacts, Receipts, and acceptance

**Document type:** Focused planning work package  
**Status:** Implemented, verified, accepted, and integrated  
**Integrated through:** Pull request 32, merge commit `4e9fe904c31c57a4c76a3569319db4504e08d682`  
**Final design head:** `94e543e62e68929e0fcdfccf687fcd97e5d2d64d`  
**Scope:** Registered Command execution, macOS process ownership, output Artifacts, criterion Evidence, Receipt aggregation, user acceptance, and completion blocking only  
**Build authorization:** Not issued

## Accepted decisions

P0-W24 established:

1. Versioned registered non-shell Commands with absolute executable, argv schema, registered cwd, and minimal environment.
2. One active Command on OD-02 Apple Silicon macOS.
3. A small macOS process-group helper for spawn, TERM, KILL, wait, and liveness proof.
4. Unknown operation when descendant cleanup cannot be proved.
5. Separate bounded stdout and stderr with immutable Artifact externalization.
6. No automatic first-month Artifact deletion.
7. Evidence bound to one criterion, exact Repository state, host profile, method, and observations.
8. Separate status, freshness, completeness, and contradiction.
9. Every required criterion current, complete, non-contradicted, and passing before acceptance.
10. Exit zero, model confidence, summaries, and Receipts are insufficient proof by themselves.
11. User acceptance binds the exact current aggregate evaluation.
12. P0-W21 remains the atomic completion owner.
13. Receipt sealing follows completion; Receipt failure blocks delivery and the aggregate demo, not committed completion truth.

## Files integrated

- `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`
- `docs/decisions/0026-use-registered-process-group-commands-on-macos.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W24-command-evidence-acceptance.md`

The final branch contained five Markdown files, 1,191 additions, and 56 deletions. It changed no production source, tests, dependencies, configuration, JSON Schemas, CI, scripts, preflight, Skills, prompts, agents, helper binary, or scaffolding.

## Verification

- Review head `24d5202eefb3eca59d2b70cb587159b2adcdaeac`: CI `30422362363`, success.
- Final head `94e543e62e68929e0fcdfccf687fcd97e5d2d64d`: CI `30422421220`, success.

Both passed Vale, current preflight behavior tests, Project agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, cycle detection, and ExUnit.

## Gate verdict

**P0-W24 passed and is integrated.**

Build authorization remains denied.

## Exact next action

Run P0-W25 on current `main`.
