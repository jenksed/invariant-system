# Git Change Isolation

**Document type:** Specification  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W10  
**Implementation status:** Not implemented  
**Contract version:** `kiln.git/v0`

## Purpose

This specification defines how Kiln isolates, coordinates, verifies, and integrates Git changes.

Git remains the source of truth for commits, branches, refs, worktrees, and repository contents. Kiln is the source of truth for intent, authorization, logical ownership, policy, lifecycle coordination, Evidence, and Receipts.

Kiln does not replace Git. Kiln records enough Git state to recover work, enforce policy, bind Evidence to exact Repository state, and explain what happened.

## Accepted default

Kiln uses protected trunk-based development with short-lived task branches and one dedicated Git worktree for each independently mutating Run.

The default is:

```text
accepted Task
→ authorized mutating Run
→ short-lived task branch
→ one exclusive writable worktree
→ one coherent Change set
→ focused checks
→ independent verification
→ projected-merge checks
→ user or policy approval
→ protected trunk integration
→ Receipt and cleanup
```

This default does not apply to every Run.

- A read-only Run does not receive a branch only because it exists.
- A Child Run does not inherit its Parent Run's branch or write authority.
- A branch does not require a permanent OTP process.
- A worktree is not a Worker, Run, process, or Workspace.
- Direct writes to protected trunk are forbidden.
- The authoring Run cannot authorize its own merge.

## Goals

The design optimizes for:

- isolation;
- inspectability;
- recoverability;
- small reviewable changes;
- deterministic integration;
- exact Evidence binding;
- low operational complexity for one developer;
- local-first operation.

The design avoids:

- simultaneous mutation of one checkout;
- branch identity as agent identity;
- incomplete work leaking between Runs;
- permanent integration branches;
- stale Evidence after Repository changes;
- OTP supervision that mirrors branch ancestry;
- worktrees for harmless read-only work;
- Kiln-specific version-control semantics.

## Critical distinctions

| Distinction | Kiln rule |
| --- | --- |
| Repository and Workspace | A Repository is one version-controlled source tree. A Workspace is the host-local trust and operating boundary that can contain several Projects and Repositories. |
| Git working tree and Kiln Workspace | A Git working tree is one checkout. A Kiln Workspace is not a checkout and is not identified by one path. |
| Branch and Run | A branch is a Git ref. A Run is the durable execution unit. They have separate identities and lifecycles. |
| Worktree and process | A worktree is a filesystem checkout registered with Git. A process can use it but does not define or own it. |
| Change set and branch | A Change set is the bounded mutation produced or proposed by one Run. A branch can contain several commits and can outlive the active Run. |
| Patch Artifact and applied change | A Patch Artifact is immutable proposed content. It becomes an applied change only after validation and atomic application. |
| Commit and Receipt | A commit records Git content and ancestry. A Receipt records policy, Evidence, state bindings, outcomes, warnings, and unknowns. |
| Verification result and merge permission | Verification is Evidence. Merge permission is an authorization decision. Passing checks does not grant merge authority. |
| Logical ownership and filesystem access | Kiln ownership states who may mutate and integrate. Filesystem permissions are a separate operating-system control. |
| Git conflict and semantic conflict | Git detects textual and ref conflicts. Kiln must also detect incompatible behavior, schemas, dependencies, assumptions, and Evidence. |
| Branch dependency and OTP supervision | Branch ancestry records Git dependency. OTP supervision records runtime fault containment. One must not mirror the other. |
| Run parentage and branch ancestry | Parent and Child Runs record work lineage. A Child branch can start from trunk, another task branch, or no branch. |
| Read access and mutation authority | Read access permits inspection. Mutation authority permits a bounded write operation and requires a grant. |
| Authoring authority and integration authority | An author may create a Change set. A separate actor or policy gate authorizes integration. |
| Repository state and model Context | Repository state is observed from Git and the filesystem. Context is a bounded projection selected for one invocation. |

## Supported modes

### Independent task mode

**Priority:** Default and foundational.

Use when one Run owns one coherent independently reviewable change.

- one short-lived branch;
- one exclusive writable worktree;
- one mutation-owner Run;
- one Change set;
- integration through verification and a merge gate.

### Stacked change mode

**Priority:** Expansion.

Use only when one reviewable layer has a real dependency on another reviewable layer.

- each branch records its direct parent branch and parent commit;
- each layer has independent acceptance criteria;
- maximum default depth is three;
- an ancestor change invalidates affected descendant Evidence;
- integration follows parent-to-child order.

Do not use a stack only to split arbitrary files or commits.

### Candidate mode

**Priority:** Expansion.

Use when the problem is uncertain enough to justify independent competing implementations.

- every candidate starts from the same recorded base commit;
- every candidate receives the same Task contract and comparable checks;
- candidates do not inspect each other before evaluation;
- an independent evaluator compares structured results;
- one candidate is accepted by default;
- rejected candidates are preserved until evaluation provenance is sealed.

### Timeboxed integration mode

**Priority:** Expansion and exceptional.

Use only for tightly coupled work that cannot integrate safely through ordinary short-lived task branches.

The temporary integration branch must have:

- one named owner;
- one purpose;
- explicit source branches;
- one target branch;
- one creation condition;
- one expiration condition;
- a maximum default lifetime of three days;
- a synchronization policy;
- required integration checks;
- a final review boundary;
- a cleanup procedure.

It must not become `develop` or another permanent branch.

Prefer branch-by-abstraction or a disabled feature flag when incomplete work can safely coexist on trunk without changing active behavior.

### Patch-artifact mode

**Priority:** Foundational.

Use when a Child Run is restricted, untrusted, short-lived, or does not need direct Git mutation authority.

- the Run receives bounded source Context;
- the Run creates an immutable Patch Artifact;
- the Artifact records base commit and expected file hashes;
- an authorized Run validates and applies it;
- formatting and tests run after application;
- the resulting commit receives new Evidence.

## Run-to-Git mapping

| Run need | Git access | Branch | Worktree | Authority rule |
| --- | --- | --- | --- | --- |
| Pure reasoning with supplied Artifacts | No checkout | None | None | No Repository read grant is required beyond supplied Context. |
| Read-only Scout with safe shared access | Shared read-only access to active checkout | None | None | Policy must forbid mutation Tools and mutating Commands. |
| Read-only inspection that needs stable state | Read-only worktree at recorded commit | None or detached | Separate read-only worktree | Use when active checkout movement would invalidate the inspection. |
| Independent mutation | Read and write | Short-lived task branch | Exclusive writable worktree | One active mutation-owner lease. |
| Dependent reviewable mutation | Read and write | Branch based on direct parent task branch | Exclusive writable worktree | Stack contract records parent branch and commit. |
| Candidate implementation | Read and write | Sibling branch from common base | Exclusive writable worktree | Candidate group fixes one base commit and equal Task contract. |
| Restricted Child proposal | Bounded read only | None | Patch-only workspace | Child returns Patch Artifact; another Run applies it. |
| One-off state inspection or verification | Read only | Detached at exact commit | Temporary detached worktree | Remove after Evidence and Artifact retention checks. |
| High-risk or untrusted execution | Bounded checkout in isolated Environment | Optional task branch | Disposable container worktree | Container does not replace Capability policy or Evidence binding. |

### Mapping rules

1. Read-only Scout Runs MAY share read-only Repository access when isolation policy permits it.
2. Mutating Runs MUST NOT share a writable checkout.
3. A writable worktree MUST have one active mutation owner.
4. A Verifier MUST NOT repair the branch that it evaluates.
5. A Verifier MAY inspect the authoring worktree read-only or use a separate verification worktree.
6. Candidate Runs MUST start from the same recorded base commit.
7. Stacked branches MUST record their direct parent branch and parent commit.
8. A Child Run MUST NOT inherit its Parent Run's branch or write permission automatically.
9. Branch creation requires Capability and policy authorization.
10. Direct writes to protected trunk are forbidden.
11. The authoring Run MUST NOT authorize its own merge.
12. A branch MAY outlive its active Run, but Kiln MUST retain explicit ownership and lifecycle state.

## Branch contract

The machine-readable contract is defined in `docs/contracts/kiln-git-change.schema.json`.

A branch contract contains only facts that Kiln needs for policy, recovery, provenance, coordination, or user interaction.

### Durable facts

- `branch_contract_id`;
- Repository, Task, Run, and Change set identifiers;
- mode;
- branch name;
- base branch and base commit;
- direct parent branch, commit, and Change set when stacked;
- candidate group when applicable;
- allowed path scope;
- forbidden operations;
- required checks;
- policy snapshot;
- creation and expiration times;
- immutable Evidence references.

### Mutable coordination state

- lifecycle state;
- current mutation-owner Run;
- current worktree lease;
- integration owner;
- review and verification projection;
- cleanup status.

Mutable coordination state changes through durable events.

### Derived Git state

- current head commit;
- dirty state and fingerprint;
- changed paths;
- merge base;
- ahead and behind counts;
- upstream status;
- ref existence;
- worktree registration.

Git remains authoritative for these facts. Kiln observes and projects them.

### Policy inputs

- allowed paths;
- forbidden operations;
- required checks;
- Repository trust policy;
- permission profile;
- remote-operation allowance;
- expiration rule.

### Evidence references

- base-state observation;
- verification Evidence;
- projected-merge Evidence;
- integration decision;
- final Receipt.

### User-visible projections

- purpose;
- branch name;
- mode;
- owner;
- state;
- dirty status;
- verification state;
- integration readiness;
- expiration and cleanup state.

Kiln MUST NOT duplicate commit ancestry, tree content, or ref history as a parallel version-control database.

## Worktree lease

A writable worktree requires an exclusive lease.

The lease records:

- Repository;
- worktree identity;
- branch contract;
- branch;
- owning Run;
- permission profile;
- allowed mutation scope;
- acquisition time;
- last activity observation;
- expiration policy;
- active Worker identity when applicable;
- durable recovery state.

The lease is not a filesystem lock by itself. Kiln combines the durable lease with controlled command execution, path policy, Repository-scoped serialization, and external-mutation detection.

### Lease behavior

| Condition | Required behavior |
| --- | --- |
| Run crashes | Mark the active owner orphaned. Preserve the worktree. Revoke mutation authority until reconciliation. |
| Kiln crashes | Rebuild leases from durable records and Git observations. Do not assume that a prior process still owns the lease. |
| Operating system kills a Command | Record the termination fact. Reinspect dirty state before another mutation. |
| Branch changes externally | Mark the lease stale or conflicted and require reconciliation. |
| Worktree directory disappears | Mark orphaned and unavailable. Do not recreate over an unknown path automatically. |
| Worktree remains dirty after cancellation | Preserve it, mark cleanup blocked, and require user or authorized recovery action. |
| Lease expires | Stop new mutations. Preserve user work. Require renewal or handoff. |
| User opens worktree manually | Permit read access. Treat external writes as unowned mutations that trigger reconciliation. |
| Child requests write permission | Evaluate a new scoped grant and lease. Do not transfer the Parent lease. |
| Two Runs request the same branch | Grant at most one mutation lease. The other request waits, uses a new branch, or uses patch mode. |
| Repository moves or is deleted | Mark unavailable. Preserve durable records and require user-assisted relocation or closure. |

A process crash MUST NOT delete uncommitted user work.

## Managed change-environment lifecycle

The lifecycle applies to a branch contract and its managed worktree environment.

| State | Entry and valid transitions | Mutation authority | Durable record and event | Cleanup and recovery | User-visible meaning |
| --- | --- | --- | --- | --- | --- |
| Requested | A Run requests a change environment. Can move to Authorized, Rejected, or Canceled. | None | Request, scope, base intent, requester. `ChangeEnvironmentRequested`. | No Git cleanup. Replay policy decision after restart only when idempotent. | Waiting for policy or approval. |
| Authorized | Policy and grants permit provisioning. Can move to Provisioning, Canceled, or Expired. | None | Approval, grant, policy snapshot. `ChangeEnvironmentAuthorized`. | Revalidate base before provisioning. | Approved but not ready. |
| Provisioning | Repository coordinator creates branch or worktree. Can move to Ready, Orphaned, or Canceled. | Coordinator only | Operation ID and intended Git mutations. `WorktreeProvisioningStarted`. | Reconcile partial Git operations after restart. | Environment is being created. |
| Ready | Branch and worktree match the contract. Can move to Active, Canceled, or Stale. | Lease holder after activation | Base-state observation and lease availability. `WorktreeReady`. | Safe removal only when clean and unused. | Ready for the Run. |
| Active | Mutation lease is held. Can move to Dirty, Awaiting verification, Canceled, Stale, or Orphaned. | One owning Run | Lease acquisition and Git observations. `WorktreeLeaseAcquired`. | Preserve state after crash. Revoke authority until lease recovery. | Run can write within scope. |
| Dirty | Files differ from recorded head. Can move to Active, Awaiting verification, Canceled, Abandoned, or Stale. | One owning Run | Dirty fingerprint and changed paths. `DirtyStateObserved`. | Never remove automatically. | Uncommitted work exists. |
| Awaiting verification | Authoring stops and requests checks. Can move to Verification failed, Verification passed, Dirty, Stale, or Canceled. | No authoring mutation during fixed verification snapshot | State binding and verification request. `VerificationRequested`. | Recreate exact state or mark request stale. | Checks are pending. |
| Verification failed | Required Evidence failed. Can move to Active, Rejected, Canceled, or Abandoned. | Authoring can resume only through a new lease phase | Evidence references and failures. `VerificationFailed`. | Preserve worktree and failure Artifacts. | Change is not integration-ready. |
| Verification passed | Required Evidence covers exact state. Can move to Awaiting integration, Dirty, Stale, or Rejected. | No further mutation without invalidation | Evidence bindings. `VerificationPassed`. | Any state change invalidates affected Evidence. | Exact state passed required checks. |
| Awaiting integration | Independent verification and policy prerequisites are satisfied. Can move to Integrating, Stale, Rejected, or Canceled. | Integration authority only | Integration request and approval scope. `IntegrationRequested`. | Recheck trunk and projected merge after restart. | Ready for merge gate. |
| Integrating | Repository coordinator performs projected and actual integration. Can move to Merged, Verification failed, Stale, or Orphaned. | Integration authority only | Operation ID, projected state, method, target. `IntegrationStarted`. | Detect incomplete merge or ref update. Never guess success. | Merge is in progress. |
| Merged | Accepted trunk contains the Change set. Can move to Cleanup pending or Removed. | None for source branch | Accepted trunk commit and Receipt. `ChangeSetMerged`. | Cleanup is idempotent and must preserve retained Artifacts. | Change is integrated. |
| Rejected | Authorized evaluator or user rejects the Change set. Can move to Cleanup pending, Abandoned, or Active through a new decision. | None unless explicitly reopened | Rejection reason and actor. `ChangeSetRejected`. | Preserve until retention and provenance requirements are met. | Change will not integrate in current form. |
| Canceled | Authorized actor stops the attempt. Can move to Cleanup pending, Abandoned, or Active through explicit resume. | None | Cancellation and dirty-state observation. `ChangeEnvironmentCanceled`. | Clean state may be removed. Dirty state is preserved. | Work stopped before acceptance. |
| Abandoned | No active owner remains and work is intentionally left. Can move to Cleanup pending or Active through explicit adoption. | None | Owner release, reason, state fingerprint. `ChangeEnvironmentAbandoned`. | Preserve until user selects removal or adoption. | Work remains but has no active owner. |
| Stale | Base, head, parent, policy, or Evidence binding changed. Can move to Active, Awaiting verification, Rejected, or Canceled after reconciliation. | None until reconciliation | Staleness reason and affected Evidence. `ChangeEnvironmentStale`. | Rebase, recreate, or reject through explicit policy. | Recorded assumptions no longer match Git. |
| Orphaned | Durable state and active runtime or Git state disagree. Can move to Ready, Active, Abandoned, Cleanup pending, or manual intervention. | None | Reconciliation findings. `ChangeEnvironmentOrphaned`. | Preserve user work and require conservative recovery. | Kiln cannot prove current ownership. |
| Cleanup pending | Terminal work is eligible for cleanup. Can move to Removed, Abandoned, or Orphaned. | None | Retention checks and cleanup request. `CleanupRequested`. | Remove only after clean-state, branch, Artifact, and Receipt checks. | Safe cleanup is being evaluated. |
| Removed | Managed worktree is removed and branch is deleted or deliberately retained. Terminal. | None | Final observation and cleanup result. `ChangeEnvironmentRemoved`. | Replayed cleanup returns the recorded terminal result. | Managed environment no longer exists. |

## Repository state and staleness

Kiln records or derives:

- base branch;
- base commit;
- current head commit;
- dirty-tree fingerprint;
- changed paths;
- dependency fingerprint;
- worktree path reference;
- upstream status;
- ahead and behind counts;
- merge base;
- rebase and force-push observations;
- branch deletion;
- external Git mutations.

### Exact-state rule

Every verification result MUST identify the exact tested state.

- Committed verification records `tested_commit`.
- Uncommitted verification records `head_commit` and `dirty_tree_fingerprint`.
- Projected-merge verification records the synthetic or temporary projected merge commit.
- Dependency-sensitive verification records the dependency fingerprint.

### Invalidation rules

1. A new commit invalidates Evidence that does not cover that commit.
2. A dirty-tree change invalidates Evidence bound to the previous dirty fingerprint.
3. A rebase creates a new verification requirement.
4. A force-push creates a new verification requirement and a security event.
5. A changed ancestor invalidates affected stacked descendants.
6. A merge-base change invalidates assumptions that depend on the former base, even without textual conflicts.
7. A changed dependency fingerprint invalidates dependency-sensitive Evidence.
8. A branch deletion or external head move triggers reconciliation.
9. A policy or required-check revision invalidates integration readiness when the new policy applies.
10. Kiln MUST NOT claim that tests passed for a commit or dirty state that was not tested.

Stale Evidence remains historical Evidence. It is not current proof.

## Integration policy

### Flow

```text
Run produces a Change set
→ Kiln identifies exact source state
→ focused checks run
→ independent Verifier runs
→ branch updates against accepted trunk
→ projected merged state is created
→ integration checks run against projected state
→ policy authorizes or blocks integration
→ merge occurs
→ Receipt records accepted state
→ worktree and branch enter cleanup
```

### Request and approval

- The authoring Run, Project Steward, or user MAY request integration.
- The authoring Run MUST NOT approve its own integration.
- The initial implementation requires explicit user approval after current verification.
- Later policy automation MAY approve low-risk changes when the accepted policy defines exact conditions.

### Local and remote integration

Kiln supports both behind adapters.

- **Local:** create a projected merge, run checks, update local protected trunk under Repository-scoped serialization, and record the result.
- **Hosting provider:** submit or update a pull request and use provider checks or merge queues through an adapter.

Remote merge queues are optional projections. They do not own Kiln's Change set, Evidence, or permission semantics.

Offline integration uses local Git and local policy. Remote publication is a separate action.

### Merge methods

Initial default: squash one coherent Change set onto protected trunk.

Allowed by policy:

- **Squash:** default for one work package or one coherent Change set.
- **Merge commit:** use when preserving branch topology has lasting diagnostic or release value.
- **Fast-forward:** use only when policy, ancestry, and attribution remain clear.
- **Rebase and merge:** expansion feature; requires new Evidence after rewritten commits.

Force-push is not an integration method.

### Attribution

- Git commit authorship records human and tool-configured author data.
- Kiln records authoring Run, Agent definition, Worker, model invocation, Change set, and Evidence in the Receipt.
- Agent attribution MUST NOT impersonate a human author.
- Secrets, prompts, or private content MUST NOT enter commit messages or branch names.

### Merge gate

The merge gate serializes accepted trunk updates per Repository.

Before integration it MUST confirm:

- source branch and head still match the verified state;
- accepted trunk and merge base are current;
- required checks cover the projected merged state;
- independent verification is current;
- no unresolved policy, security, or semantic conflict exists;
- the integration actor has authority;
- the selected merge method is allowed.

A failed integration returns a structured result to the originating Run or Project Steward. It does not silently modify the authoring branch.

Rollback is represented as a new Revert Change set with its own Task, Run, Evidence, authorization, commit, and Receipt. Kiln does not erase accepted history.

## Conflict model

| Conflict class | Detection and handling |
| --- | --- |
| Textual merge conflict | Git reports overlapping textual edits. Block automatic integration. An authorized Run may propose a resolution and must produce new Evidence. |
| File-ownership conflict | Two active contracts claim incompatible mutation scope. Block the later lease or require explicit coordination. |
| Overlapping changed regions | Diff analysis finds overlapping hunks without a Git conflict. Require semantic review or deterministic composition proof. |
| Dependency conflict | Dependency manifests, lockfiles, or version constraints diverge. Re-resolve in one authorized integration state and rerun dependency-sensitive checks. |
| Schema and migration conflict | Ordering, compatibility, or data-transition assumptions conflict. Require explicit migration plan and integration verification. |
| Behavioral conflict | Changes merge textually but violate tests, contracts, performance, or runtime behavior. Treat failed Evidence as blocking. |
| Competing architectural assumptions | Branches implement incompatible accepted or proposed decisions. Route to user or architecture review. Do not auto-resolve. |
| Stale generated files | Source and generated outputs disagree. Regenerate from the accepted source under a controlled Command and verify. |
| Lockfile conflict | Use the ecosystem's deterministic resolver in the projected merged state. Do not select arbitrary conflict markers or combine entries manually without proof. |
| Verification conflict | Different checks or evaluators disagree. Preserve all results, classify authority and scope, and block until policy resolves the contradiction. |

A model may resolve a conflict only when:

- the conflict is within its authorized scope;
- both source states are available;
- the intended requirements are known;
- the proposed resolution is independently verified;
- the resolution creates new Evidence.

## Patch-artifact workflow

```text
Child receives bounded source Context
→ Child creates exact Patch Artifact
→ Artifact records base commit and expected file hashes
→ authorized Run inspects it
→ paths and scope are validated
→ patch applies atomically
→ focused formatting and tests run
→ resulting commit receives new Evidence
```

### Initial patch contract

- Format: UTF-8 unified Git diff with rename metadata when required.
- Base: exact commit and expected preimage hashes for every modified or deleted file.
- Paths: normalized Repository-relative paths only.
- Path policy: reject traversal, absolute paths, symlink escape, forbidden paths, and undeclared scope.
- Conflict detection: fail before mutation when a preimage hash or base condition differs.
- Rename handling: require explicit old and new paths and validate both scopes.
- Binary policy: reject inline binary changes in the initial implementation. A later mode may use content-addressed binary Artifacts with explicit approval.
- Application: validate completely, apply to a temporary index or isolated worktree, then make the result visible atomically.
- Rollback: reset the temporary application state. Never discard unrelated user work.
- Attribution: retain producing Run, Agent, model invocation, patch digest, applying Run, and resulting commit.
- Receipt linkage: link the Patch Artifact, application result, checks, commit, and final Change set.

Patch mode is preferred when the Child is untrusted, has narrow scope, does not need iterative compilation, or must not hold a writable checkout.

## Candidate evaluation

A candidate group requires:

- one Task contract;
- one base commit;
- independent Context packages;
- no cross-candidate mutation or inspection before evaluation;
- comparable required checks;
- structured evaluation criteria;
- an evaluator that authored no candidate;
- explicit accepted and rejected results;
- cleanup and retention policy.

The evaluator compares:

- requirement satisfaction;
- reproduced Evidence;
- diff size;
- public-interface changes;
- complexity;
- security;
- performance;
- dependency changes;
- maintainability;
- reversibility.

Kiln prefers one accepted candidate. It does not combine fragments from several candidates unless a new authorized integration Change set records the adapted provenance and receives fresh Evidence.

## Stacked-change policy

A stack requires:

- a real dependency between reviewable layers;
- one direct parent branch and commit per child;
- default maximum depth of three;
- explicit restacking method;
- descendant invalidation when an ancestor changes;
- independent acceptance criteria and Evidence per layer;
- parent-to-child integration order.

Restacking rewrites descendant state. It invalidates affected Evidence and requires new verification.

Run parentage does not determine stack ancestry. A Child Run can author an independent trunk-based branch, and a Root Run can coordinate a stacked branch without owning its worktree.

## Timeboxed integration branches

A timeboxed integration branch is allowed only when ordinary trunk integration cannot provide a credible test boundary.

The contract must state:

- owner;
- purpose;
- source branches;
- target branch;
- creation condition;
- expiration condition;
- maximum lifetime;
- synchronization cadence;
- required integration tests;
- final review boundary;
- cleanup procedure.

The branch becomes stale when its target merge base changes beyond the recorded synchronization policy.

Branch-by-abstraction or a disabled feature flag is safer when partial work can enter trunk without activating incomplete behavior. Use an integration branch when coupled changes require a combined pre-trunk state and cannot be hidden safely.

## Naming policy

### Branch names

Runtime-managed branch names use:

```text
kiln/<task-short-id>-<change-short-id>-<slug>
```

Example:

```text
kiln/t142-c7f3-lsp-handshake
```

Rules:

- lowercase ASCII letters, digits, hyphens, and slashes only;
- maximum 80 characters;
- stable Task and Change set short identifiers;
- short controlled slug from accepted Task metadata;
- no model names, agent personas, prompts, user prose, secrets, credentials, or sensitive paths;
- uniqueness checked against local refs and managed contracts.

The Kiln Repository itself continues to use the development branch classes in `docs/BRANCHING-AND-WORK-PLANNING.md`.

### Worktree names and paths

Managed worktree directory names use:

```text
wt-<repository-short-id>-<change-short-id>
```

Paths are stored outside model Context by default. Models receive an opaque worktree Resource reference unless an absolute path is required for a controlled Command.

## Security and permission matrix

| Operation | Capability | Default | Notes |
| --- | --- | --- | --- |
| Read Repository content | `repository.read` | Allow for trusted active Repository within scope | Apply path, trust, and symlink policy. |
| Inspect Git status and refs | `git.inspect` | Allow within registered Repository | Read-only; record material observations. |
| Create branch | `git.branch.create` | Confirmation or accepted Task policy | Requires base validation and naming policy. |
| Create worktree | `git.worktree.create` | Confirmation or accepted mutation policy | Repository coordinator serializes it. |
| Modify files | `repository.write` | Deny unless Run has scoped grant and lease | Enforce allowed paths. |
| Stage changes | `git.index.write` | Deny unless Run owns mutation lease | Staging does not grant commit authority. |
| Commit | `git.commit` | Confirmation or Task policy | Record Change set and exact parent. |
| Rebase | `git.rebase` | Confirmation required | Invalidates Evidence. |
| Merge locally | `git.merge` | User approval in initial implementation | Author cannot self-authorize. |
| Push | `git.remote.push` | Deny by default | Separate from local integration. |
| Force-push | `git.remote.force_push` | Explicit one-time approval only | Record security event and invalidate Evidence. |
| Delete branch | `git.branch.delete` | Allowed only after retention and state checks | Never delete dirty or unmerged work silently. |
| Remove worktree | `git.worktree.remove` | Allowed only after lease and dirty-state checks | Preserve user work. |
| Change remote configuration | `git.remote.configure` | Deny by default | User-managed setup operation. |
| Change Git hooks | `git.hooks.write` | Deny by default | Untrusted hooks do not execute implicitly. |
| Change branch protection | `git.protection.write` | Outside normal agent authority | Hosting-provider administrative action. |

Additional rules:

- Children do not inherit Git mutation authority.
- Repository trust policy affects command, hook, submodule, filter, and configuration behavior.
- Git hooks from untrusted Repositories MUST NOT execute implicitly.
- Credentials MUST NOT appear in Context, logs, Artifacts, Receipts, telemetry, branch names, or command arguments visible to models.
- Remote operations use separate Capabilities and approvals from local Git operations.
- Environment isolation does not replace Capability policy.

## Repository-scoped serialization

Kiln uses one coordinator per active Repository when Repository-global Git mutations or subscriptions require concurrent ownership.

It does not use one global lock for all Repositories.

### Serialized operations

- create or remove a worktree;
- prune worktree metadata;
- create, move, or delete managed branches;
- update shared refs;
- rebase;
- merge and projected-merge publication;
- garbage collection;
- fetch or synchronize remotes;
- change remote configuration;
- recover incomplete Git operations.

### Concurrent operations

The following MAY run concurrently when they use immutable or read-only state:

- read files from separate worktrees;
- inspect refs and status;
- compute diffs and fingerprints;
- run checks in separate read-only or exclusive worktrees;
- read Objects by commit;
- parse source and index semantics.

### Lock rules

- Lock scope is one Repository and one operation class when safe.
- Ref and worktree mutations share a Repository mutation queue in the initial implementation.
- Operations have bounded timeouts and explicit cancellation outcomes.
- A timed-out operation does not imply rollback or success.
- Idempotency keys identify retried operations.
- The coordinator observes actual Git state before and after each mutation.
- Operations acquire locks in one fixed order: Repository mutation queue, then worktree lease, then external provider adapter.
- No operation waits for model reasoning while it holds a Git mutation lock.
- User override can cancel or take control, but it must create an event and trigger reconciliation.

## Elixir and OTP component map

| Component | Responsibility | Durable state | Transient state | Process and supervision | Git mutation authority | Recovery and failure behavior |
| --- | --- | --- | --- | --- | --- | --- |
| `Kiln.Git.RepositoryState` structs | Represent observed refs, commits, dirty fingerprints, and upstream state. | Stored observations and Evidence references. | None. | Data only. | No. | Rebuild from Git. |
| `Kiln.Git.BranchContract` structs | Validate branch mode, scope, parent, checks, and policy inputs. | Contract and events. | None. | Data only. | No. | Reload from SQLite. |
| `Kiln.Git.WorktreeLease` structs | Represent exclusive mutation ownership. | Lease record and lifecycle events. | Active owner projection. | Data plus lease manager while active. | No direct mutation. | Reconcile owner and Git state. |
| `Kiln.Git.Adapter` behaviour | Define normalized Git operations and observations. | Operation request and result records. | Command handles. | No permanent process. | Through authorized calls only. | Return explicit unknown, partial, and failed states. |
| `Kiln.Hosting.Adapter` behaviour | Hide GitHub or other hosting APIs. | External mappings and operation results. | Connections and rate-limit state. | Adapter-specific supervised clients. | Remote operations only with grants. | Retry idempotently or return blocked state. |
| `Kiln.RepositoryCoordinator` | Serialize Repository-global mutations, subscriptions, and reconciliation. | Operation IDs, queue events, last reconciled state. | Queue, timers, subscribers. | One process per active Repository under a DynamicSupervisor. | Yes, after policy authorization. | Restart, reconstruct queue, inspect Git, mark uncertain operations orphaned. |
| `Kiln.WorktreeLeaseManager` | Acquire, renew, release, expire, and recover writable leases. | Lease records and events. | Timers and active owner monitors. | One service per active Repository or part of coordinator. | May request worktree operations; cannot bypass policy. | Preserve dirty work and revoke uncertain ownership. |
| `Kiln.Git.OperationSupervisor` | Run bounded Git CLI operations. | Operation specs and terminal results. | Tasks, Ports, buffers, cancellation. | `Task.Supervisor` or controlled Command supervisor. | Executes only normalized authorized operations. | Record exit, timeout, cancellation, and unknown state. |
| `Kiln.Git.Reconciler` | Compare durable records with actual refs, worktrees, locks, and dirty states. | Findings and reconciliation events. | Scan state. | Task or short-lived supervised process. | Only safe automatic repairs. | Preserve user work and request approval for destructive actions. |
| `Kiln.Git.EvidenceBinder` | Bind checks to commit, dirty fingerprint, dependency state, and projected merge. | Immutable Evidence records. | None. | Data or deterministic service. | No. | Recompute currentness from observations. |
| `Kiln.Git.IntegrationGate` | Evaluate current Evidence, policy, authority, and projected merge before integration. | Decision, Evidence references, Receipt references. | Temporary evaluation state. | Process only during active integration. | Requests merge through coordinator. | Fail closed and return structured blockers. |
| SQLite and Ecto transactions | Persist contracts, leases, events, operations, Evidence, and Receipts atomically. | Canonical durable records. | Transaction state. | Shared store process as already accepted. | No direct Git mutation. | Transaction rollback does not imply Git rollback; reconciliation closes the gap. |
| ETS projections | Cache active branch, lease, and readiness views. | None. | Reconstructible indexes. | Owned by coordinator or projection service. | No. | Rebuild after restart. |
| Internal event bus or Phoenix.PubSub | Publish state updates to clients. | Source events remain in SQLite. | Subscriptions. | Shared supervised service. | No. | Subscribers resync from event sequence. |
| `:telemetry` | Emit operation and lifecycle measurements. | No canonical product state. | Handler state. | Existing instrumentation path. | No. | Telemetry loss does not change product truth. |

### Process rules

Do not create:

- one process per inactive branch;
- one process per commit;
- one process per Git object;
- one process for static policy data;
- a supervision tree that mirrors branch ancestry;
- a process hierarchy that mirrors the Run graph.

### Supervision diagram

```text
Kiln.Application
├── Kiln.Store
├── Kiln.RepositoryRegistry
├── Kiln.RepositorySupervisor
│   └── Kiln.RepositoryCoordinator[repository_id]
│       ├── Worktree lease state and timers
│       ├── Repository subscriptions and projections
│       └── reconciliation scheduling
├── Kiln.Git.OperationSupervisor
│   └── bounded Git operation Tasks or Commands
└── Kiln.SessionSupervisor
    └── Session and active Run processes

Run graph: durable work lineage
Branch graph: Git ancestry and dependency
Supervision tree: runtime lifecycle and fault containment
```

These three graphs are intentionally different.

## Durable and transient state

| Class | Examples | Rule |
| --- | --- | --- |
| Durable intent and policy | Task, branch contract, allowed paths, required checks, policy snapshot, approval | Persist exact revision and actor. |
| Durable ownership | mutation-owner Run, lease acquisition, release, handoff, integration owner | Persist events and current projection. |
| Durable Git observations | base and head commits, merge base, dirty fingerprint, changed paths, worktree registration | Persist material observations with time and source. Git remains authoritative. |
| Durable Evidence | verification binding, projected-merge result, conflict finding, integration decision | Immutable and state-bound. |
| Durable provenance | Change set, Patch Artifact, commit, accepted trunk commit, Receipt | Persist identifiers, digests, and relationships. |
| Transient runtime state | PID, Port, Task, monitor, timer, stream buffer, CLI process handle | Never use as durable identity. |
| Reconstructible projection | active lease map, ahead/behind counts, readiness, cleanup eligibility | Rebuild from records and Git observations. |
| User-visible convenience | display slug, local path label, preferred diff view | Non-authoritative. Paths remain outside model Context by default. |

## Observability and Evidence

Instrument and record:

- branch creation;
- worktree creation;
- lease acquisition, renewal, expiration, release, and recovery;
- Git command execution;
- external mutation detection;
- commit creation;
- rebase and force-push;
- Evidence invalidation;
- integration request and attempt;
- projected merge;
- merge and rejection;
- cancellation;
- cleanup;
- orphan recovery.

The system must answer:

- Which Run changed this file?
- Which branch contained the change?
- Which base commit did it start from?
- Which commit or dirty fingerprint was tested?
- Which Verifier accepted it?
- Which policy permitted integration?
- Was the worktree dirty?
- Did the branch change after verification?
- What was merged?
- What was rejected?
- Which Artifacts and Receipts prove the result?

Telemetry MUST NOT contain source contents by default.

## Startup recovery and reconciliation

At startup, Kiln compares durable records with actual Git state.

It detects:

- registered worktrees that no longer exist;
- existing worktrees absent from Kiln records;
- branches deleted or moved externally;
- changed branch heads;
- dirty abandoned worktrees;
- expired leases;
- incomplete merge, rebase, cherry-pick, revert, or apply operations;
- stale lock files;
- orphaned Run ownership;
- already completed operations replayed after restart.

### Automatic actions

- rebuild read-only projections;
- mark expired leases inactive;
- mark Evidence stale when bindings differ;
- recognize an already completed idempotent operation when exact postconditions match;
- clear Kiln-owned stale coordination state that does not affect user work;
- resume subscriptions from durable event sequence.

### Safe but reported actions

- register an unmanaged clean worktree as observed but not owned;
- mark missing paths unavailable;
- mark externally moved refs stale;
- mark incomplete operations orphaned;
- preserve and quarantine dirty abandoned worktrees from automatic cleanup.

### Approval-required actions

- adopt an unmanaged writable worktree;
- renew or transfer an orphaned mutation lease;
- abort or continue an incomplete Git operation;
- rebase, reset, clean, delete, prune, or remove a dirty worktree;
- delete an unmerged branch;
- repair external ref movement;
- run destructive garbage collection.

### Forbidden automatic actions

- delete uncommitted work;
- force-reset a user branch;
- claim an incomplete operation succeeded;
- rerun a non-idempotent Git mutation without postcondition inspection;
- execute untrusted hooks;
- expose credentials to model Context or telemetry.

Recovery prefers preservation of user work over aggressive cleanup.

## Initial implementation boundary

The smallest useful implementation includes:

- one local Repository;
- conceptual protected `main`;
- independent task mode only;
- one exclusive writable worktree per mutating Run;
- shared read-only access for safe Scout Runs;
- Patch Artifacts for restricted Child Runs;
- Git CLI behind a controlled native adapter;
- one Repository-scoped mutation coordinator;
- durable branch-contract, worktree, lease, operation, and Change-set records;
- exact commit-bound or dirty-fingerprint-bound verification Evidence;
- independent read-only verification;
- manual user-approved local merge;
- deterministic cleanup and crash reconciliation.

### First useful vertical slice

1. Register one trusted local Repository.
2. Accept one Task that requires a small source change.
3. Authorize one mutating Run.
4. Create one short-lived branch and exclusive worktree.
5. Acquire one scoped lease.
6. Modify allowed paths and create one commit.
7. Run focused checks and record Evidence for that commit.
8. Run an independent read-only Verifier.
9. Recheck against current `main` and create a projected merged state.
10. Ask the user for merge approval.
11. Squash the Change set onto local protected `main`.
12. Seal a Receipt and remove the clean managed worktree.
13. Restart Kiln and reconstruct the completed lifecycle accurately.

## Deferred capabilities

Defer unless a later accepted requirement justifies them:

- hosting-provider automation;
- remote merge queues;
- automated push and publication;
- stacked branches;
- candidate tournaments;
- timeboxed integration branches;
- cross-Repository atomic changes;
- automatic conflict resolution;
- automatic force-push;
- multi-user branch ownership;
- distributed locking;
- binary Patch Artifacts;
- submodule mutation;
- signed commits and attestations;
- Git replacement abstractions.

## Acceptance criteria

The design is accepted when it answers these questions:

1. **When does a Run need a branch?** Only when it owns or coordinates a Git-backed mutation that requires independent review, isolation, or lifecycle tracking.
2. **When does a Run need a worktree?** When it needs a stable separate checkout. A mutating Run gets an exclusive writable worktree. Stable read-only inspection may get a detached read-only worktree.
3. **Can read-only Runs share Repository access?** Yes, when policy removes mutation authority and active-checkout movement does not invalidate the task.
4. **Who owns a writable checkout?** Exactly one active mutation-owner Run through one lease.
5. **How is simultaneous mutation prevented?** Scoped grants, exclusive leases, controlled Commands, path policy, and Repository-scoped serialization.
6. **How does a Child request write authority?** It submits a new Capability request. It does not inherit the Parent lease or branch.
7. **When is patch mode safer?** When the Child is restricted, untrusted, narrow in scope, or does not need iterative execution.
8. **How are candidates compared?** Same Task and base, independent contexts, comparable checks, and a non-author evaluator using structured criteria.
9. **When are stacks justified?** Only for real reviewable dependencies that cannot merge independently.
10. **How is Evidence tied to a commit?** Each result records the exact commit or head plus dirty fingerprint and relevant dependency state.
11. **What invalidates verification?** New commits, dirty-state changes, rebases, force-pushes, changed ancestors, changed merge bases, changed dependencies, or applicable policy changes.
12. **How are external changes detected?** Through Git observation before and after operations, subscriptions where reliable, and startup reconciliation.
13. **How does Kiln recover after a crash?** It reconstructs durable contracts and leases, inspects Git, marks uncertainty, preserves work, and resumes only after safe reconciliation.
14. **Which operations require serialization?** Worktree and ref mutation, rebase, merge, fetch synchronization, garbage collection, and recovery of incomplete Git operations.
15. **Which concepts require OTP processes?** Active Repository coordination, lease timing and monitoring, bounded Git operations, subscriptions, and active integration lifecycle.
16. **Which concepts remain data?** Branch contracts, branches, commits, Change sets, Evidence, Receipts, policies, and inactive leases.
17. **How do the graphs differ?** Run graph is work lineage, branch graph is Git ancestry, and supervision tree is runtime lifecycle.
18. **How does a branch reach trunk?** Exact-state checks, independent verification, projected-merge checks, policy approval, serialized merge, Receipt, and cleanup.
19. **How are rejected and abandoned worktrees handled?** Preserve them until retention, provenance, dirty-state, and user-decision requirements permit removal.
20. **What is the smallest implementation?** One local Repository, independent task branches, one exclusive worktree per mutating Run, patch mode, commit-bound Evidence, user-approved local merge, and conservative recovery.

## Required changes to later planning

Later planning prompts and Phase 1 reconciliation MUST:

- introduce Repository-state observation before Evidence freshness and completion readiness;
- define branch-contract, worktree, lease, Git-operation, and reconciliation persistence;
- place the controlled Git CLI adapter behind the Capability broker without exposing raw Git catalogs to models;
- prove Repository-scoped serialization before concurrent mutating Runs;
- prove one independent Verifier before automated integration;
- compile Verifier Context independently from authoring Context;
- bind verification and Context items to exact Repository state;
- keep remote hosting providers behind adapters;
- defer stacks, candidates, and integration branches until independent task mode is proven;
- update the Phase 1 acceptance scenario to include isolated mutation, stale-Evidence invalidation, projected merge, manual approval, cleanup, and restart recovery.

## Closeout record

### Files inspected

- `README.md`
- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/BRANCHING-AND-WORK-PLANNING.md`
- `docs/CAPABILITY-INTEGRATION.md`
- `docs/CONTEXT-SYSTEM.md`
- `docs/INTERNAL-DOMAIN-MODEL.md`
- `docs/PLANNING-BASELINE.md`
- `docs/PLAN-RECONCILIATION.md`
- `docs/PROJECT-INVARIANTS.md`
- `docs/PROTOCOL-CAPABILITY-MAP.md`
- `docs/ROADMAP.md`
- `docs/RUN-MODEL.md`
- `docs/SECURITY-MODEL.md`
- `docs/contracts/README.md`
- accepted ADRs 0001 through 0012
- accepted P0-W05 through P0-W09 work-package records

### Files changed by P0-W10

- this specification;
- Git change contract schema;
- ADR 0013;
- P0-W10 work-package record;
- branching and work-planning authority;
- roadmap, README, ADR index, and contract index.

### Existing decisions preserved

- Git and the filesystem own Repository truth.
- Run is the primary durable execution unit.
- Parent-child Run lineage does not define OTP supervision.
- Capabilities and explicit grants define authority.
- Child and Verifier Runs receive independent Context and grants.
- Change sets, Claims, Evidence, and Receipts remain distinct.
- External protocols remain adapters.
- Git normally uses a native adapter backed by the Git CLI.

### New decisions accepted

- protected trunk with short-lived task branches is the default;
- every independently mutating Run uses one exclusive writable worktree;
- read-only Runs do not receive branches by default;
- patch mode is foundational for restricted children;
- authoring and integration authority are separate;
- Repository-global Git mutations use Repository-scoped serialization;
- verification is bound to exact commit or dirty state;
- cleanup preserves uncertain or dirty user work.

### Decisions modified

- Branch names no longer identify Runs or agents. They identify Git work coordinates and link to contracts.
- Stacked branches remain supported but are no longer the normal planning default.
- Verification before merge now includes projected-merge Evidence.

### Decisions rejected

- shared writable checkout;
- permanent `develop` branch;
- branch-per-Run by default;
- OTP process-per-branch;
- author self-approval for integration;
- automatic conflict resolution without requirements and independent verification;
- silent cleanup of dirty or orphaned work;
- A2A for local Child Run Git coordination;
- Git replacement semantics.

### Unknowns

- final Elixir module names and whether lease management is part of the Repository coordinator;
- dirty-tree fingerprint algorithm;
- file-region overlap algorithm;
- best projected-merge implementation on all supported Git versions;
- useful lease expiration defaults;
- first hosting-provider adapter;
- whether filesystem enforcement needs an operating-system sandbox helper.

### Deferred questions

- stack restacking user experience;
- candidate-evaluation automation;
- remote merge queue integration;
- multi-Repository transactions;
- multi-user ownership and distributed locks;
- signed commits, in-toto export, and SLSA provenance;
- binary patch transport.

### Evidence for conclusions

- The internal domain model defines Repository state as observed Git and filesystem truth, Change set as data, and Run lineage as separate from OTP supervision.
- The Run model requires independent inspectability, permissions, interruption, and Evidence.
- The Capability model selects a native Git adapter backed by the Git CLI and keeps raw implementation catalogs behind the broker.
- The Context model requires independent Child and Verifier packages and exact source-state bindings.
- The security model requires explicit Capabilities, conservative defaults, and honest separation between policy mediation and operating-system isolation.
- The protocol map classifies Git worktrees as foundational internal isolation and reserves A2A for independent external agents.
