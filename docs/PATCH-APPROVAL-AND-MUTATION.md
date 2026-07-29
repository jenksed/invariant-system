# Patch, Approval, and Mutation

**Document type:** Focused Patch and mutation authority  
**Decision status:** Proposed by P0-W23; owner acceptance required  
**Integration status:** Proposed on `work/p0-w23-patch-approval-mutation`  
**Implementation status:** Not implemented  
**Upstream authorities:** P0-W21 and P0-W22  
**Build authorization:** Not issued

## Authority

This specification owns first-month decisions for:

- Patch proposal representation;
- Patch canonicalization and digest;
- Repository and per-path base binding;
- Patch preview and review facts;
- user Approval and denial;
- one mutation owner and checkout lease;
- mutation preparation, rollback data, progress observation, deterministic application, and post-state validation;
- partial mutation and rollback behavior;
- restart classification after uncertain filesystem effects.

It does not own:

- Session, Task, or Run lifecycle;
- journal envelope, operation states, projections, migrations, restart state, orphan transitions, or completion transactions;
- provider, Context, Tool, Repository-read, disclosure, or secret-screening policy;
- registered Command execution, formatting, tests, or process trees;
- criterion Evidence, Receipt, user acceptance, or completion evaluation;
- CLI syntax or presentation.

P0-W21 controls durable operation intent, terminal-or-unknown observation, orphan handling, and state transitions. P0-W22 controls canonical Repository roots, path eligibility, state observation, source reads, and `change.propose`.

# 1. Decision summary

P0-W23 accepts these focused decisions:

1. The authoritative first-month Patch is a canonical manifest of complete UTF-8 text after-images.
2. A generated unified diff is required for human review but is not the mutation authority.
3. Support only `add`, `replace`, and `delete` operations on regular files.
4. Represent rename as delete-plus-add. Do not infer rename identity.
5. Deny binary content, symlinks, special files, mode changes, submodule changes, Git metadata changes, and files outside the selected checkout.
6. Bind every proposal to one exact W22 Repository observation and one exact before state per affected path.
7. Compute one SHA-256 Patch digest over canonical manifest bytes and referenced after-image digests.
8. Invalidate the proposal on any bound Repository-state, path, policy, criteria, or proposal change.
9. Require explicit user Approval for the exact Patch digest, base state, path set, warnings, and Session revision.
10. Approval is one-time, expires after 30 minutes, and is consumed when the P0-W21 external-operation intent commits.
11. The model cannot approve, apply, extend, or reuse a Patch.
12. Use one in-process mutation coordinator and one selected-checkout lease. No concurrent writer is allowed.
13. Materialize a complete rollback bundle and durable progress manifest under `$KILN_HOME` before the first file effect.
14. Stage replacement content on the same filesystem and use atomic single-path replacement where supported.
15. Do not claim multi-file atomicity. Observe every operation and final target state explicitly.
16. On application failure, attempt deterministic reverse-order rollback.
17. A proved base restoration is a known failed application. A proved target state is a known successful application. Any unclassified or mixed state is unknown and follows P0-W21 orphan rules.
18. Never retry or reapply automatically after uncertain mutation.
19. Patch application does not format, test, stage, commit, push, merge, publish, or deploy.

# 2. Patch proposal

## 2.1 Identity

```text
patch_id
patch_schema: kiln.patch/v1
session_id
run_id
proposal_operation_id
objective_revision
criteria_revision
repository_observation_id
base_repository_state_digest
operations
summary
rationale
assumptions
warnings
created_at
patch_digest
```

The proposal is immutable after digest calculation.

## 2.2 Operation contract

Each operation contains:

```text
operation_index
operation_kind
path
before
_after
```

`operation_kind` is:

```text
add
replace
delete
```

### `before`

For `replace` and `delete`:

```text
exists: true
file_kind: regular
content_digest
byte_count
line_ending
text_encoding: utf-8
```

For `add`:

```text
exists: false
```

### `_after`

For `add` and `replace`:

```text
exists: true
file_kind: regular
content_artifact_id
content_digest
byte_count
line_ending
text_encoding: utf-8
```

For `delete`:

```text
exists: false
```

The field is named `_after` in the planning contract to avoid accidental use of `after` as a prose status. Prompt 6-A can select the final implementation field name while preserving semantics.

## 2.3 Supported content

First-month Patches support:

- regular files only;
- valid UTF-8 text;
- LF or CRLF line endings recorded explicitly;
- complete file after-images;
- empty text files;
- new parent directories under the canonical root when every path segment is non-symlink and permitted.

They do not support:

- binary content;
- NUL bytes;
- invalid UTF-8;
- symlinks or hard-link creation;
- sockets, devices, FIFOs, or special files;
- executable-bit or other mode changes;
- ownership or extended-attribute changes;
- sparse-file semantics;
- submodule or `.git` changes;
- case-only rename semantics;
- filesystem links;
- patching outside the selected checkout.

## 2.4 Limits

```text
maximum_operations: 32
maximum_paths: 32
maximum_single_after_image_bytes: 1_048_576
maximum_total_after_image_bytes: 4_194_304
maximum_single_before_image_bytes_for_rollback: 1_048_576
maximum_total_rollback_bytes: 4_194_304
maximum_generated_preview_bytes: 1_048_576
maximum_path_bytes: 1_024
```

If the required rollback data exceeds a limit, application is blocked. Kiln does not apply a Patch it cannot roll back under this contract.

A later accepted decision can add a large-file or binary path. It cannot silently widen these limits.

## 2.5 Path rules

Every path must pass P0-W22 canonical-root controls.

Additional mutation rules:

- paths are unique within one Patch;
- operations are sorted by normalized path for canonicalization;
- `.git/`, `$KILN_HOME`, mandatory secret paths, and denied Project paths are never writable;
- a path cannot be both an ancestor and descendant operation when the ancestor operation would remove or replace a directory;
- directory deletion is not a Patch operation;
- parent directories can be created only when absent and empty of conflicting objects;
- every parent segment is checked again immediately before mutation;
- no operation follows a symlink at proposal or application time.

## 2.6 Base binding

The Patch binds:

```text
repository_id
canonical_root_identity
repository_observation_id
base_repository_state_digest
head_commit | null
branch | null
detached
ignore_policy_digest
project_policy_revision
objective_revision
criteria_revision
per_path_before_state
```

The W22 Repository state digest is the common base reference. Per-path before digests are mandatory defense in depth.

Application blocks when:

- the current Repository state digest differs;
- any affected path has changed kind, existence, digest, or parent topology;
- HEAD, branch, detached state, accepted dirty fingerprint, ignore policy, Project policy, objective, or criteria changed;
- a new denied path or secret classification applies;
- the selected checkout identity changed.

The first-month product invalidates on any bound Repository-state change, including changes outside the write set. This is stricter than necessary but preserves one-user, one-task truth and avoids merging concurrent local edits.

## 2.7 Canonicalization and digest

Canonical Patch bytes use:

- one versioned schema identifier;
- UTF-8;
- normalized relative paths;
- deterministic operation order;
- deterministic object-key order;
- exact integer values;
- explicit nulls only where the schema allows;
- no insignificant whitespace;
- referenced content digests rather than embedded large text.

```text
patch_digest = SHA-256(
  canonical_manifest_bytes
  || ordered_after_image_digests
)
```

The Patch digest changes when any operation, path, before fact, after digest, limit snapshot, warning, objective, criterion, policy, or Repository binding changes.

## 2.8 Human review preview

Kiln generates a unified diff preview from the exact before and after images.

The preview includes:

- Patch digest;
- base Repository state digest;
- operation count and total bytes;
- added, replaced, and deleted paths;
- line additions and deletions when calculable;
- complete warnings and unsupported controls;
- truncation status;
- exact content Artifact references when preview is too large.

The preview cannot be parsed back as the authoritative Patch.

No fuzzy application, offset search, whitespace relaxation, context matching, or reject-file behavior exists.

# 3. Proposal creation

## 3.1 Sources

A proposal can originate from:

- normalized `change.propose` output from P0-W22;
- a deterministic local user request accepted by the workflow;
- a later authorized import path.

Model output is untrusted proposal input. Kiln must parse, normalize, validate, materialize after-images, observe before state, calculate warnings, and create the canonical Patch.

## 3.2 Validation before review

Before presenting a proposal, Kiln verifies:

- exact current Repository binding;
- every path and parent;
- operation support and limits;
- before existence, kind, digest, size, and encoding;
- after content digest, size, and encoding;
- no duplicate or conflicting path;
- no secret or mandatory-denied path;
- no hidden mutation outside the manifest;
- deterministic preview generation;
- Patch digest stability.

A failed validation produces no approvable Patch.

# 4. Approval contract

## 4.1 Authority

Only the authorized local user can approve or deny a Patch.

The model, provider, Tool, workflow application, Agent persona, transcript, and Receipt cannot approve.

## 4.2 Approval request

The durable pending decision references:

```text
decision_id
kind: patch_approval
patch_id
patch_digest
base_repository_state_digest
session_revision
objective_revision
criteria_revision
path_set_digest
preview_digest
warnings_digest
requested_actor
requested_at
expires_at
permitted_responses
```

Permitted responses:

```text
approve
deny
```

There is no approve-with-modifications response. A modification creates a new Patch and decision.

## 4.3 Approval record

```text
approval_id
decision_id
actor_id
patch_id
patch_digest
base_repository_state_digest
session_revision
path_set_digest
warnings_digest
approved_at
expires_at
status
```

`status` is:

```text
active
consumed
invalidated
expired
```

## 4.4 Lifetime

Approval expires at the earliest of:

- 30 minutes after approval;
- Session revision change;
- objective or criteria revision;
- Repository state change;
- Patch or preview digest change;
- Project policy or path-policy change;
- mutation lease acquisition by another operation, which should not occur under the first-month limit;
- explicit user invalidation;
- application intent commit, which consumes the Approval.

Clock expiry is checked before intent commit. A clock change cannot extend an already calculated UTC expiry.

## 4.5 Consumption

Approval is consumed atomically when the P0-W21 `patch_application` external-operation intent commits.

The intent references:

- Approval ID and digest;
- Patch ID and digest;
- Repository state digest;
- Session revision;
- mutation lease identity;
- rollback-plan identity;
- application idempotency key.

After intent commit:

- the Approval cannot authorize another operation;
- repeated dispatch must resolve through operation and idempotency observation;
- failure before the first file effect still uses the consumed operation identity;
- a new attempt requires fresh Repository observation, Patch validation, and Approval.

## 4.6 Denial

Denial records the exact decision and Patch digest.

It:

- clears the pending decision through P0-W21;
- invalidates the Approval request;
- performs no mutation;
- returns the workflow to a safe proposal state;
- does not create a failed Run;
- cannot be overridden by model output.

# 5. Mutation ownership

## 5.1 Coordinator

One transient mutation Worker executes one Patch application under the application supervisor.

`Kiln.Mutation` owns pure validation and orchestration functions but is not a permanent process per Patch.

## 5.2 Lease

Before intent commit, the workflow reserves one logical lease:

```text
lease_id
repository_id
canonical_root_identity
operation_id
patch_digest
acquired_at
```

Rules:

- at most one active mutation lease exists;
- the lease is bound to the selected checkout;
- provider and Command Workers do not own it;
- the model cannot acquire it;
- an existing lease blocks a new mutation;
- process death does not prove lease release or effect completion;
- restart resolves the associated P0-W21 operation before a new lease is available.

The first month has no operating-system lock shared with unrelated programs. Kiln therefore re-observes state immediately before every effect and reports external interference honestly.

# 6. Application preparation

## 6.1 Order

Application uses these phases:

```text
validate
→ prepare rollback bundle
→ prepare staged after-images
→ commit durable operation intent and consume Approval
→ dispatch mutation Worker
→ observe current base again
→ apply operations deterministically
→ observe target state
→ record terminal success or begin rollback
→ observe rollback or unknown state
```

No filesystem effect occurs before rollback and staging preparation and durable operation intent.

## 6.2 Rollback bundle

Before intent commit, Kiln creates an immutable rollback bundle under:

```text
$KILN_HOME/mutations/<operation_id>/rollback/
```

It contains or references:

- manifest schema and digest;
- Patch and base digests;
- every path;
- original existence and kind;
- original content bytes for replace and delete;
- original content digest and byte count;
- original line ending;
- parent directories created by the planned add;
- preparation time;
- complete-bundle digest.

The bundle is written outside the Repository and fsynced according to the supported-host contract before intent commit.

If the bundle cannot be fully written and verified, application does not begin.

## 6.3 Staged after-images

After-images are copied or materialized under:

```text
$KILN_HOME/mutations/<operation_id>/staged/
```

Rules:

- each staged file digest must match the Patch;
- content remains valid UTF-8 and within limits;
- staging does not alter the Repository;
- final same-filesystem temporary files are prepared inside a Kiln-controlled hidden temporary directory under the Repository root only after intent commit;
- temporary paths are never model-selected;
- temporary paths are cleaned when effects are known.

## 6.4 Progress manifest

Operation-specific progress is stored at:

```text
$KILN_HOME/mutations/<operation_id>/progress.json
```

It contains:

```text
operation_id
patch_digest
base_repository_state_digest
rollback_bundle_digest
phase
last_completed_operation_index
per_path_observations
updated_at
progress_digest
```

`phase` is operation-local observation, not a Run or journal state:

```text
prepared
applying
observing_target
rolling_back
observing_base
cleaned
```

The manifest is replaced atomically after each completed path effect when the supported host provides atomic same-directory replacement.

The manifest supports reconciliation. It is not more authoritative than actual Repository observation.

# 7. Deterministic application

## 7.1 Operation order

Apply in this order:

1. `add` and `replace`, sorted by normalized path;
2. `delete`, sorted by descending path depth and normalized path.

Before each operation:

- revalidate root and parent topology;
- reject symlink changes;
- compare current path state with the expected before state or the expected intermediate state from already completed operations;
- verify no unplanned changed path is introduced by Kiln;
- update progress to identify the next operation.

## 7.2 Add

- path must be absent;
- all existing parents must be real directories and non-symlinks;
- new parent directories are created deterministically and recorded;
- after-image is materialized to a same-directory temporary regular file;
- content digest is verified;
- temporary file is atomically renamed to the target path where supported;
- target kind and digest are observed;
- progress is committed.

If the target appears before rename, application stops and begins reconciliation or rollback. Kiln does not overwrite an unexpected file.

## 7.3 Replace

- target must be a regular file matching the exact before digest;
- replacement is materialized to a same-directory temporary file;
- content digest is verified;
- temporary file atomically replaces the target where supported;
- target kind and digest are observed;
- progress is committed.

The first contract does not preserve or change executable mode. Files requiring mode preservation or change are blocked until a later accepted contract.

## 7.4 Delete

- target must be a regular file matching the exact before digest;
- deletion occurs only after every add and replace succeeded;
- parent directories are not removed except empty directories created by this operation and removed during rollback or cleanup;
- absence is observed;
- progress is committed.

## 7.5 Target observation

After all operations, Kiln observes:

- every target path existence, kind, and content digest;
- every affected parent topology;
- current W22 Repository state digest;
- unexpected paths created by Kiln;
- temporary files;
- rollback and progress bundle integrity.

Application is successful only when every operation matches the Patch after state and no unknown mutation effect remains.

The terminal result references the resulting Repository observation. It does not imply formatting, verification, Evidence, acceptance, or completion.

# 8. Failure and rollback

## 8.1 Known failure before file effects

Examples:

- stale base;
- expired or invalid Approval;
- lease conflict;
- rollback preparation failure;
- staging failure;
- denied path;
- unsupported filesystem control.

No Repository effect occurred. Record a known failed operation result through P0-W21. A new attempt requires a new workflow action and fresh Approval when applicable.

## 8.2 Failure after a file effect

Stop forward application immediately.

Attempt rollback in reverse effect order:

1. restore deleted files from rollback content;
2. restore replaced files from rollback content;
3. remove added files only when their current digest matches the Patch after digest;
4. remove only empty parent directories created by the operation;
5. observe every original path and base state.

Rollback never overwrites a path whose current state matches neither known before nor known after state without explicit reconciliation.

## 8.3 Rollback success

Rollback is successful only when:

- every affected path matches the exact before state;
- created directories are removed or proved harmless and empty;
- no temporary mutation file remains;
- the current Repository state digest matches the accepted base;
- rollback bundle integrity remains valid.

Then the Patch application is a known failure with proved base restoration. It can return to a safe proposal or investigation action under later workflow rules.

## 8.4 Rollback failure

If any path cannot be restored or classified:

- stop automatic mutation;
- preserve rollback, staged, and progress data;
- observe all affected paths;
- record the operation result as unknown through P0-W21;
- leave the Run orphaned;
- show exact known-before, known-after, and observed digests;
- require explicit reconciliation.

There is no automatic cleanup that destroys recovery data.

# 9. Restart and reconciliation

## 9.1 Startup input

P0-W21 identifies a nonterminal `patch_application` operation.

The mutation reconciler reads:

- operation intent;
- Patch manifest and digest;
- Approval and lease references;
- rollback bundle;
- staged after-images;
- progress manifest;
- current Repository observation;
- per-path current states.

## 9.2 Per-path classification

Each affected path is classified:

```text
before
_after
absent_expected
unknown
```

Rules:

- `before`: exact original existence, kind, and digest;
- `_after`: exact target existence, kind, and digest;
- `absent_expected`: absence matches the applicable before or after operation side;
- `unknown`: any other state, including an external edit.

## 9.3 Whole-operation classification

| Observation | Classification | Automatic action |
| --- | --- | --- |
| all paths match before; no temp effect | known no-effect or rolled-back failure | no reapply; offer fresh action |
| all paths match after; target observation complete | known applied result | record success observation; continue to later verification |
| mixed before and after; rollback bundle valid | partial effect | attempt rollback only when every current path is known before or after |
| any path unknown | unknown effect | no mutation; orphan and require reconciliation |
| rollback restores exact base | known failed result | preserve failure and return safe next action |
| rollback cannot prove base | unknown effect | orphan |
| progress missing but files prove target | known applied result with warning | record observation |
| progress missing and files prove base | known no-effect with warning | no retry automatically |
| recovery data missing or corrupt | unknown effect | preserve Repository; orphan |

## 9.4 Reconciliation choices

The operator can choose only actions enabled by observed state:

```text
accept_observed_target
restore_base_from_verified_bundle
keep_observed_state_and_fail
cancel_after_verified_reconciliation
```

A choice cannot classify unobserved content. Kiln must verify the resulting exact state before recording terminal operation observation.

P0-W26 can deepen interruption UX and platform cleanup after runtime Evidence. It cannot weaken the exact-state rules.

# 10. Staleness and invalidation matrix

| Change | Patch status | Approval status |
| --- | --- | --- |
| Patch manifest or after image changes | new Patch required | invalidated |
| affected path content or existence changes | stale | invalidated |
| unrelated bound Repository state changes | stale in first month | invalidated |
| HEAD, branch, detached state, or dirty fingerprint changes | stale | invalidated |
| objective or criteria revision changes | stale | invalidated |
| Project path, secret, or mutation policy changes | stale | invalidated |
| preview digest changes | new review required | invalidated |
| warning set changes | new review required | invalidated |
| Session revision changes | stale | invalidated |
| 30-minute approval expiry passes | Patch can be re-reviewed | expired |
| application intent commits | immutable subject | consumed |

There is no automatic rebase or reapproval.

# 11. Failure matrix

| Failure | Repository effect | Operation result | Next action |
| --- | --- | --- | --- |
| proposal invalid | none | no application operation | correct proposal |
| Patch stale before intent | none | known blocked | rebuild Patch |
| Approval denied | none | no application | revise or stop |
| Approval expired | none | known blocked | re-review |
| lease conflict | none | known blocked | resolve current operation |
| rollback bundle preparation fails | none | known failure | fix local condition |
| staging fails | none | known failure | fix local condition |
| base changes after intent but before first effect | none | known failure | fresh Patch and Approval |
| one operation fails; rollback proves base | reverted | known failed | inspect and retry only through new action |
| target state proves complete after connection loss | applied | known success | continue to verification |
| mixed state; rollback proves base | reverted | known failed | inspect |
| mixed or external state cannot be classified | uncertain | unknown | orphan and reconcile |
| recovery data corrupt | uncertain | unknown | preserve files and reconcile |
| cleanup fails after target proved | applied plus warning | known success with retained recovery data | later cleanup action |

# 12. Security invariants

The first-month implementation must prove:

1. The model cannot approve or apply a Patch.
2. Approval binds exact Patch, base, paths, warnings, and Session revision.
3. Approval is one-time and consumed at intent commit.
4. No effect occurs before rollback and staging data are complete.
5. Only one selected checkout and one mutation lease exist.
6. Every path passes W22 controls at proposal and application time.
7. No fuzzy Patch, shell, Git staging, hook, formatter, Command, commit, push, merge, publish, or deploy occurs.
8. Binary, symlink, special-file, mode, and submodule mutation is denied.
9. A failed operation cannot silently discard rollback data.
10. A mixed or unclassified state cannot be reported as success or known failure.
11. No uncertain mutation is retried automatically.
12. Patch success means only exact target files were observed. It does not imply verification or completion.

# 13. Upstream ownership audit

## 13.1 P0-W21

This round consumes:

- `patch_application` operation class;
- durable intent before dispatch;
- terminal or unknown observation;
- idempotency and expected revision;
- orphan and reconciliation requirements.

It does not add or change:

- Session, Task, or Run states;
- transition authority;
- journal envelope or projection;
- migration or store startup;
- completion transaction rules.

## 13.2 P0-W22

This round consumes:

- canonical selected checkout;
- Repository observation and state digest;
- path, symlink, file, encoding, and secret controls;
- `change.propose` as proposal input;
- Artifact references for bounded content.

It does not change:

- provider or Context package;
- Tool projection;
- Repository search or read behavior;
- hosted disclosure policy.

Any conflict resolves in favor of the upstream focused authority.

# 14. Implementation boundary

After Prompt 8-A authorization, this round can make these units safe to implement:

- Patch manifest and canonical digest;
- complete after-image Artifact validation;
- generated review preview;
- Patch staleness validation;
- Approval request, record, expiry, invalidation, and consumption;
- single mutation lease;
- rollback bundle and progress manifest;
- add, replace, and delete application;
- exact target and base observation;
- rollback and restart reconciliation fixtures.

It does not unlock:

- Command execution or formatting;
- criterion Evidence or completion;
- complete CLI;
- worktrees, concurrent writers, writing Children, or Wave B.

# 15. Prompt 3 dispositions

P0-W23 changes planning direction for:

- IU-10: one complete-after-image Patch contract and exact Approval binding;
- IU-11: no managed worktree or concurrent writer in the first month;
- IU-12: Command execution stays separate and follows in P0-W24;
- IU-13: rollback, staged content, preview, and Patch payloads use Artifact references;
- `kiln-git-change.schema.json`: reduce worktree, branch, merge, and broad Git-operation fields;
- `kiln-execution-plane.schema.json`: reduce broad Patch transactions, Environments, and shell behavior;
- `kiln-evidence.schema.json`: Patch observations cannot become criterion Evidence automatically.

# 16. Candidate Prompt 6-A scaffolding

Prompt 6-A can evaluate:

- Patch manifest, operation, base, and digest types;
- supported-operation and limit validators;
- deterministic preview fixture contract;
- Approval request, record, expiry, invalidation, and consumption types;
- mutation lease type;
- rollback bundle and progress manifest types;
- stale-base, path-escape, symlink, binary, secret, oversize, duplicate-path, expired-Approval, partial-apply, rollback-success, rollback-failure, crash, known-target, and unknown-state fixtures.

It must not implement filesystem mutation, create fake success, add a shell, run Commands, stage Git, or introduce worktrees.

# 17. Completion gate

P0-W23 passes only when:

- one complete-after-image Patch contract exists;
- one canonical digest and exact base binding exist;
- supported operations and limits are explicit;
- unified diff is review-only;
- Approval authority, subject, lifetime, invalidation, denial, consumption, and replay are explicit;
- one mutation owner and lease exist;
- rollback and staging data precede effects;
- application order, per-path observation, target validation, and cleanup are explicit;
- partial failure, rollback, restart, and unknown-effect behavior are explicit;
- W21 and W22 authority remain unchanged;
- no Command, Evidence, CLI, Child, worktree, Git publication, or implementation scope enters;
- the exact final planning-only head passes Repository validation.

Passing P0-W23 does not issue build authorization.
