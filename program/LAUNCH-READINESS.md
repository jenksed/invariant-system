# Simultaneous Launch Readiness

> SUPERSEDED — see program/SUPERSESSION-NOTICE.md.
> Preserved as provenance; not active authority for monorepo work.

The program manager may recommend launch only when every required box is satisfied.

## Product and contract gate

- [x] Owner accepts Decision 0001.
- [x] Engineering-system bootstrap is merged.
- [x] Loadout bootstrap is merged.
- [x] Contract v0 documents are readable and internally consistent.
- [x] Each product package names its producer, consumer, and non-responsibilities.

## Repository gate

- [x] Arsenal launch SHA recorded and equals current `main`.
- [x] Loadout launch SHA recorded and equals current `main`.
- [x] Kiln PR #62 is merged.
- [x] Kiln canonical `main` SHA and authorized T01 branch SHA are recorded.
- [x] Unrelated ECC PRs are explicitly quarantined from launch authority.

## Agent environment gate

- [x] The combined prompt requires one isolated checkout/worktree per product before writers start.
- [x] The combined prompt requires MiniMax M3 with thinking enabled and stops if unavailable.
- [x] The combined prompt requires each agent to read its repository instructions before mutation.
- [x] The combined prompt runs repository verification preflight before mutation.
- [x] The combined prompt rejects committed credentials and requires approved injection.

## Work-package gate

- [x] ARS-01 is owner-approved and pinned.
- [x] LOD-01 is owner-approved and pinned.
- [x] KIL-01 is owner-approved and pinned.
- [x] No owned-path collision exists.
- [x] Every package has explicit prohibited changes and stop conditions.
- [x] Fixture dependencies exist before launch.

## Final owner gate

- [x] Program manager prepares one combined launch prompt.
- [ ] Owner authorizes simultaneous launch.

## Launch command status

**READY / HOLD.** Static preparation is complete. Do not launch product agents until the owner sends the exact authorization token required by the combined prompt. The prompt then runs environment preflight and must stop before mutation if any pinned fact has drifted.
