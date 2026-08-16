# ADR 0013: Use protected trunk and exclusive writable worktrees

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W10
- **Date:** 2026-07-28

## Context

Kiln must support delegated and parallel Repository work without allowing simultaneous mutation of one checkout, losing attribution, mixing incomplete work, or treating branches and OTP processes as Run identity.

Git already owns commits, refs, branches, worktrees, and content history. Kiln owns Tasks, Runs, Capabilities, authorization, logical ownership, Evidence, Receipts, and recovery coordination.

A simple one-developer operating model must provide isolation and exact Evidence without creating a permanent integration branch or a replacement version-control system.

## Decision

Kiln uses protected trunk-based development with short-lived task branches and one dedicated Git worktree for each independently mutating Run.

The accepted rules are:

1. A Run does not receive a branch only because it exists.
2. Read-only Runs MAY share read-only Repository access when policy permits it.
3. Mutating Runs MUST NOT share a writable checkout.
4. A writable worktree has one active mutation-owner Run through an exclusive lease.
5. A Child Run does not inherit its Parent Run's branch or Git authority.
6. Direct writes to protected trunk are forbidden.
7. The authoring Run cannot authorize its own integration.
8. Verification Evidence binds to an exact commit or head plus dirty-tree fingerprint.
9. Repository-global Git mutations pass through Repository-scoped serialization.
10. Patch Artifact mode is foundational for restricted or untrusted Child Runs.
11. Stacked, candidate, and timeboxed integration modes remain expansion features.
12. A branch, commit, Change set, Receipt, and Run remain distinct concepts.
13. Run lineage, branch ancestry, and OTP supervision remain separate graphs.
14. Recovery preserves dirty or uncertain user work instead of cleaning it automatically.
15. Git remains the version-control authority. Kiln does not create parallel VCS semantics.

The detailed contract, lifecycle, security, integration, conflict, recovery, and Elixir mapping are defined in [Git Change Isolation](../GIT-CHANGE-ISOLATION.md).

## Consequences

- Independent mutation requires worktree provisioning and cleanup overhead.
- Kiln must persist branch contracts, worktree leases, Git-operation events, state observations, Evidence bindings, and reconciliation findings.
- The first mutating Child Run requires Git isolation before it can be accepted.
- Verification and integration require exact source-state checks.
- Repository coordinators can serialize Git mutations without serializing independent read-only work or work across different Repositories.
- Branches can outlive active Runs without requiring permanent branch processes.
- Hosting-provider automation remains replaceable behind an adapter.

## Rejected positions

- one shared writable checkout for parallel Runs;
- branch-per-Run regardless of mutation need;
- using branch names as Agent or Run identity;
- one OTP process per branch, commit, or Git object;
- a permanent `develop` branch;
- self-approved integration by the authoring Run;
- automatic force-push;
- automatic conflict resolution without known requirements and independent verification;
- deleting dirty or orphaned work after a crash;
- using A2A for local Child Run coordination;
- replacing Git with Kiln-specific commits, branches, or merge semantics.

## Review triggers

Review this decision when:

- one exclusive worktree per mutating Run creates measured unacceptable overhead;
- operating-system enforcement is required because policy mediation cannot prevent cross-worktree writes;
- multi-user or remote execution requires distributed ownership;
- cross-Repository atomic changes become a product requirement;
- a hosting-provider merge queue becomes the accepted integration authority;
- Patch Artifact mode cannot represent a required restricted-child workflow;
- dogfooding shows that the maximum stack depth or timeboxed integration lifetime must change.
