# Command, Evidence, and Acceptance

**Document type:** Focused execution and proof authority  
**Decision status:** Proposed by P0-W24; owner acceptance required  
**Integration status:** Proposed on `work/p0-w24-command-evidence-acceptance`  
**Implementation status:** Not implemented  
**Supported host:** OD-02 Apple Silicon macOS 15.0 or later  
**Build authorization:** Not issued

## Authority

This specification owns first-month decisions for:

- registered non-shell Commands;
- Command request, Worker, process-group, timeout, cancellation, output, and terminal-result behavior;
- immutable Artifacts and first-month retention;
- criterion-bound Evidence;
- freshness, completeness, contradiction, and aggregate evaluation;
- user acceptance subject;
- inputs to P0-W21 completion finalization;
- post-completion Receipt aggregation and delivery state.

It does not own lifecycle, journal, provider, Context, Repository reads, Patch, Approval, mutation, CLI syntax, TUI, delegation, remote execution, telemetry export, or attestations.

# 1. Decision summary

1. Execute only versioned registered Commands.
2. A Command is an absolute executable plus an argument-vector contract, never a shell string.
3. The model cannot register, widen, or execute a Command directly.
4. Resolve and fingerprint the executable at registration and revalidate it before execution.
5. Construct a minimal environment from fixed values and explicit non-secret or secret references. Do not inherit the complete user environment.
6. Allow one active Command operation in the first-month Session.
7. Use a small bundled macOS host helper that launches the executable in a new process group through `posix_spawn` and exposes group identity for TERM, KILL, wait, and liveness probes.
8. A normal Elixir Port does not by itself prove descendant ownership or cleanup.
9. On timeout or cancellation, signal the process group with SIGTERM, wait five seconds, then SIGKILL, wait five seconds, and probe the group.
10. If the process group cannot be proved gone, classify the operation as unknown and orphan the Run under P0-W21.
11. Capture bounded live stdout and stderr while externalizing complete retained output as immutable Artifacts within limits.
12. A Command result is an observation, not criterion proof.
13. Evidence binds one criterion to one exact Repository state, host profile, method, and current observations.
14. Evidence status is `pass`, `fail`, `blocked`, or `unknown`; freshness and contradiction are separate facts.
15. Completion requires every required criterion to have current, complete, non-contradicted `pass` Evidence.
16. Exit zero, model confidence, a summary, or a Receipt does not imply verification.
17. User acceptance binds the exact aggregate evaluation, Repository state, Patch result, warnings, and Session revision.
18. P0-W21 owns the atomic completion transaction.
19. Seal the Receipt after completion. Receipt failure blocks delivery, not the truth of the already committed completion.
20. No automatic deletion occurs during the first-month product. Retain all active and terminal Session Artifacts, Evidence, evaluations, and Receipts until a later accepted retention policy exists.

# 2. Registered Command

## 2.1 Registration

```text
command_id
command_version
name
purpose
executable_path
executable_identity
fixed_argv
parameter_schema
working_directory_policy
environment_policy
secret_reference_policy
network_requirement
write_policy
timeout_policy
output_policy
result_adapter
criterion_eligibility
supported_host_profile
registration_digest
```

The registration is Project-owned configuration accepted before use. Repository text encountered during a Run cannot register or modify it.

## 2.2 Executable identity

The registration records:

```text
canonical_absolute_path
file_kind
file_digest
byte_count
owner_uid
mode_summary
resolved_shebang_interpreter | null
interpreter_digest | null
observed_at
```

Rules:

- no PATH lookup during execution;
- a script requires a supported absolute shebang interpreter and both identities are recorded;
- symlink executables are resolved at registration and revalidated without following a changed link at execution;
- executable or interpreter identity change blocks execution until registration is reaccepted;
- code signing identity can be recorded as diagnostic metadata but is not required proof in the first contract.

## 2.3 Arguments

The final argv is:

```text
fixed_argv ++ validated_parameter_values
```

Parameter types are limited to:

- enum;
- bounded integer;
- bounded UTF-8 literal without NUL;
- canonical relative Repository path passing P0-W22 controls;
- accepted Artifact path supplied by Kiln.

Rules:

- no shell interpolation;
- no command substitution;
- no redirection or pipe syntax;
- no unbounded free-form command tail;
- model output cannot bypass the parameter schema;
- the final argv digest is part of the Command request and result.

## 2.4 Working directory

A registration selects one:

```text
repository_root
registered_subdirectory
kiln_temporary_directory
```

The exact canonical directory and digest are recorded in the request. It must be on the OD-02 local APFS profile. Symlink or state change blocks dispatch.

## 2.5 Environment

Construct the environment from:

- fixed registration values;
- host profile values required by the runtime;
- accepted Project values;
- explicit secret references resolved at dispatch.

Initial allowlist can include only registered needs such as:

```text
HOME
PATH
TMPDIR
LANG
LC_ALL
MIX_ENV
ERL_AFLAGS
```

Each included key has an origin and disclosure class.

Rules:

- no complete inherited environment;
- default secret set is empty;
- secret values are never journal, Artifact metadata, stdout preview, Evidence, Receipt, or CLI content;
- stdout and stderr pass secret screening before live display;
- a Command requiring an unapproved secret is blocked;
- `HOME` can be redirected to a Kiln-owned temporary home when the registered tool permits it;
- PATH is constructed from exact registered toolchain directories.

## 2.6 Write policy

A Command declares:

```text
read_only
registered_output_paths
```

The first verification Command may write only to accepted generated or temporary paths. Kiln records pre- and post-Repository observations.

OD-02 does not provide an operating-system sandbox. Therefore:

- declared write scope is policy plus observation, not a kernel guarantee;
- a Command whose safety requires enforced filesystem isolation is blocked as unsupported;
- unexpected tracked or relevant untracked source changes invalidate Evidence and can create an unknown effect when the complete effect cannot be classified;
- verification never authorizes source mutation.

## 2.7 Network policy

A registration declares:

```text
not_required
required
```

The first supported host does not enforce network denial. Effective network control is `unsupported`.

Rules:

- a verification Command should declare `not_required`;
- Kiln cannot claim the Command had no network access;
- a criterion requiring proved network isolation is blocked;
- Commands requiring network access are outside the first-month verification path unless separately approved by a later decision.

## 2.8 Limits

```text
maximum_active_commands: 1
maximum_argv_items: 128
maximum_argument_bytes: 65_536
maximum_environment_items: 64
maximum_environment_bytes: 65_536
maximum_timeout_ms: 900_000
term_grace_ms: 5_000
kill_grace_ms: 5_000
maximum_live_stdout_bytes: 262_144
maximum_live_stderr_bytes: 262_144
maximum_retained_stdout_bytes: 16_777_216
maximum_retained_stderr_bytes: 16_777_216
```

Exceeding retained output limits produces a complete `truncated` classification with byte counts and blocks any criterion that requires complete output.

# 3. Request and Worker

## 3.1 Request

```text
command_request_id
operation_id
session_id
run_id
command_id
command_version
registration_digest
argv
argv_digest
working_directory
working_directory_digest
environment_manifest
environment_digest
secret_reference_ids
repository_state_digest
host_profile_digest
timeout_ms
authority_reference
idempotency_key
created_at
request_digest
```

P0-W21 records the `command_execution` operation intent before dispatch.

## 3.2 Worker ownership

One transient `Kiln.Command.Worker` owns:

- the Elixir Port connected to the host helper;
- stdout and stderr streams;
- timer state;
- helper PID and process-group ID;
- cancellation escalation;
- final wait status and cleanup probes.

The Run, Command registration, request, result, Artifact, and Evidence record do not receive permanent processes.

## 3.3 macOS process-group helper

The bundled helper uses macOS POSIX process APIs to:

1. validate the executable and working directory supplied by Kiln;
2. use `posix_spawn` with `POSIX_SPAWN_SETPGROUP` and pgroup `0` so the child becomes leader of a new process group;
3. connect stdin to `/dev/null` unless registration permits bounded input;
4. connect stdout and stderr to separate pipes;
5. report child PID and process-group ID through a versioned control record;
6. wait for the leader and report wait status;
7. support a signal mode that calls `killpg` for the exact group;
8. support a probe mode that uses signal `0` or equivalent group observation;
9. return structured errno and unsupported results.

The helper is not a general shell or Command runner. It accepts only the exact prevalidated launch or signal structure.

Apple documents process-group creation through `posix_spawnattr_setpgroup` and group signaling through `killpg`. The implementation ticket must prove actual behavior on the OD-02 host.

# 4. Timeout, cancellation, and cleanup

## 4.1 Normal completion

A known terminal completion requires:

- leader wait status observed;
- stdout and stderr pipes closed;
- host helper control channel closed normally;
- process-group probe reports no remaining member;
- output finalization succeeds or reports explicit truncation or Artifact failure;
- post-Repository observation completes.

## 4.2 Timeout

At timeout:

1. record timeout requested locally;
2. invoke the helper signal mode with SIGTERM for the exact process group;
3. wait up to five seconds;
4. if group remains, invoke SIGKILL;
5. wait up to five seconds;
6. probe group liveness;
7. collect wait and output observations;
8. record known `timed_out` only when the group is proved gone;
9. otherwise record unknown through P0-W21.

## 4.3 User cancellation

Cancellation uses the same TERM/KILL/probe sequence.

A known `canceled` result requires the group is gone and all material output and Repository effects are classified.

## 4.4 Worker or BEAM loss

On restart, P0-W21 finds a nonterminal Command operation.

Reconciliation uses:

- helper and group identity when safely retained;
- current group probe;
- retained output files;
- result manifest;
- pre- and post-Repository observations;
- host process observations that do not require broad process scanning.

Rules:

- never reuse a stale process-group ID without validating operation identity and current ownership evidence;
- if the group is proved absent and a terminal result manifest exists, record that result;
- if the group may remain or identity cannot be proved, operation is unknown;
- do not rerun automatically;
- P0-W26 can deepen runtime recovery after actual Evidence.

# 5. Output and Command result

## 5.1 Capture

Stdout and stderr are separate byte streams.

Rules:

- live display is bounded and sanitized for control sequences;
- raw retained bytes remain immutable Artifacts when within limits;
- invalid UTF-8 is allowed in raw output but preview uses escaped or replacement-safe rendering;
- no output is interpreted as authority or a Tool call;
- secret screening can suppress live excerpts while preserving a restricted Artifact;
- truncation records first retained bytes, total observed count when known, and completeness `truncated`.

## 5.2 Result

```text
command_result_id
command_request_id
operation_id
status
exit_kind
exit_code | null
signal | null
process_group_cleanup
started_at
completed_at
duration_ms
stdout_artifact_id | null
stderr_artifact_id | null
stdout_completeness
stderr_completeness
repository_before_digest
repository_after_digest | null
unexpected_repository_changes
host_profile_digest
warnings
result_adapter_output | null
result_digest
```

`status` is:

```text
succeeded
failed
timed_out
canceled
blocked
unknown
```

Exit code zero permits `succeeded` as a Command result. It does not produce criterion `pass` without a criterion evaluator.

## 5.3 Result adapters

A versioned result adapter can parse bounded known formats such as:

- ExUnit text summary;
- compiler diagnostics;
- JUnit-compatible test report;
- SARIF;
- a Project-specific deterministic report.

Adapter output records parser version, source Artifact, completeness, parse warnings, and structured digest.

Parser failure does not discard raw output. It can block criteria that require structured completeness.

# 6. Artifact contract

## 6.1 Identity

```text
artifact_id
artifact_schema
content_digest
media_type
byte_count
storage_path
creator_operation_id
session_id
run_id
repository_state_binding | null
host_profile_binding | null
sensitivity
trust
completeness
created_at
integrity_status
```

Artifacts are content-addressed and immutable.

## 6.2 Storage

Store under Kiln-owned local APFS paths beneath `$KILN_HOME/artifacts/`.

Rules:

- use SHA-256 content identity;
- write to temporary file, sync, verify digest, and replace into final same-directory path;
- do not store Artifact bytes in the work-state journal;
- journal and projections store references and bounded metadata;
- a missing, corrupt, or mismatched required Artifact blocks Evidence and completion;
- secret Artifacts are never provider-disclosed without a separate permitted path, which is absent in the first product.

## 6.3 Trust and sensitivity

`trust`:

```text
kiln_generated
registered_command_output
provider_output
user_supplied
repository_observation
```

`sensitivity`:

```text
public
project
sensitive
secret
unknown
```

Unknown sensitivity defaults to no provider disclosure and bounded local display.

## 6.4 Retention

The first-month product performs no automatic Artifact deletion or compaction.

Retain:

- every Artifact referenced by active or terminal Session state;
- rollback and mutation recovery data required by P0-W23;
- Command output used by Evidence;
- completion evaluations;
- Receipts.

A later accepted retention policy must preserve audit and recovery invariants before deletion.

# 7. Criterion and Evidence

## 7.1 Criterion

A required criterion contains:

```text
criterion_id
criterion_revision
text
required
verification_method
freshness_rule
completeness_requirement
accepted_at
criterion_digest
```

The criterion exists before Session start. Revision invalidates prior evaluation as defined by W21 and this specification.

## 7.2 Evidence item

```text
evidence_id
criterion_id
criterion_revision
method
status
subject
repository_state_digest
host_profile_digest | null
command_result_id | null
artifact_references
observation_digest
completeness
freshness
contradiction
observed_at
invalidated_at | null
warnings
rationale
record_digest
```

`status`:

```text
pass
fail
blocked
unknown
```

`completeness`:

```text
complete
partial
truncated
missing
unknown
```

`freshness`:

```text
current
stale
unknown
```

`contradiction`:

```text
none
present
unknown
```

## 7.3 Methods

Initial methods:

```text
registered_command
repository_observation
deterministic_validator
user_observation
```

Model opinion and free-form summary are not Evidence methods.

User observation can satisfy only a criterion explicitly accepted as manually observable. It cannot override machine failure, unknown effect, stale state, or contradiction.

## 7.4 State binding

Evidence binds the exact subject and state it evaluates.

A source criterion after Patch application normally binds:

- Patch result and digest;
- resulting Repository state digest;
- criterion revision;
- Command registration and result when used;
- host profile;
- required Artifacts and adapters.

Any change to bound source, criterion, Command registration, host profile, required Artifact, or evaluator invalidates or stales the Evidence.

## 7.5 Freshness

A criterion defines its freshness rule. Initial rules are:

- `same_repository_state`;
- `same_patch_and_repository_state`;
- `same_command_registration_and_repository_state`;
- `manual_same_repository_state`.

Time alone does not refresh stale Evidence. Re-observation or re-execution is required.

## 7.6 Contradiction

A contradiction exists when current valid observations for the same criterion and state support incompatible results, such as:

- one current test report passes and another current required report fails;
- Repository observation disagrees with a Command adapter;
- expected output is missing while a summary claims it exists;
- output truncation prevents confirming a claimed pass.

Contradiction blocks aggregate passing. It is not resolved by choosing the favorable item or by model explanation.

# 8. Criterion evaluation

One deterministic evaluator produces:

```text
criterion_evaluation_id
criterion_id
criterion_revision
repository_state_digest
result
supporting_evidence_ids
contradicting_evidence_ids
missing_requirements
warnings
evaluated_at
evaluation_digest
```

`result`:

```text
pass
fail
blocked
unknown
stale
contradicted
```

Rules:

- `pass` requires at least one accepted method satisfying the criterion, complete required data, current state, and no contradiction;
- `fail` requires a current complete observation that the criterion is not satisfied;
- `blocked` means a prerequisite or effective control is unavailable;
- `unknown` means the result cannot be classified;
- `stale` means relevant Evidence exists but does not bind current state;
- `contradicted` means current observations conflict.

No favorable Evidence can hide a required failure.

# 9. Aggregate completion evaluation

```text
completion_evaluation_id
session_id
run_id
objective_revision
criteria_revision
patch_id
patch_digest
repository_state_digest
host_profile_digest
criterion_evaluations
open_operations
unknown_effects
required_warnings
unsupported_controls
result
evaluated_at
evaluation_digest
```

`result`:

```text
ready_for_user_acceptance
not_ready
unknown
```

`ready_for_user_acceptance` requires:

- exact accepted Patch target is current Repository state;
- every required criterion result is `pass`;
- all supporting Evidence is current and complete;
- no contradiction exists;
- no operation is open or unknown;
- no Run is orphaned;
- required Artifacts pass integrity checks;
- host profile matches OD-02;
- all warnings and unsupported controls are explicit;
- no unapproved source change exists.

Any other state is `not_ready` or `unknown` and cannot request final acceptance.

# 10. User acceptance and completion

## 10.1 Acceptance request

The durable user decision binds:

```text
decision_id
kind: completion_acceptance
completion_evaluation_id
completion_evaluation_digest
repository_state_digest
patch_digest
criteria_revision
session_revision
warnings_digest
unsupported_controls_digest
requested_at
permitted_responses
```

Responses:

```text
accept
reject
```

No model or workflow component can answer for the user.

## 10.2 Revalidation

Before finalization, revalidate:

- decision subject and Session revision;
- completion evaluation is still current;
- Repository and Patch digests match;
- no new operation, warning, contradiction, or unknown exists;
- required Artifacts remain intact;
- host profile remains compatible.

A changed fact invalidates the acceptance request.

## 10.3 P0-W21 finalization

The P0-W21 atomic completion transaction remains authoritative.

It receives:

- accepted response;
- current completion evaluation reference and digest;
- Repository and Patch state;
- objective and criteria revisions;
- proof no open or unknown operation exists;
- warnings and unsupported controls.

The transaction atomically records user acceptance and completes Run, Task, and Session.

P0-W24 does not add a completion state or separate completion database owner.

# 11. Receipt and delivery

## 11.1 Receipt

After the completion transaction commits, Kiln seals a bounded Receipt:

```text
receipt_id
receipt_schema
session_id
run_id
completion_record_reference
objective_revision
criteria_revision
patch_id
patch_digest
approval_reference
repository_before_digest
repository_after_digest
provider_invocation_references
command_result_references
artifact_references
criterion_evaluation_references
completion_evaluation_reference
user_acceptance_reference
host_profile_digest
warnings
unsupported_controls
completed_at
sealed_at
manifest_digest
```

The Receipt references facts; it does not create or change them.

## 11.2 Receipt rules

- only references required to explain the completed work are included;
- large content remains in Artifacts;
- secrets and hidden reasoning are excluded;
- Receipt digest is SHA-256 over canonical manifest bytes;
- sealing validates all references and digests;
- a Receipt cannot turn stale, failed, blocked, unknown, or contradicted Evidence into pass;
- a Receipt cannot approve, accept, complete, integrate, or deliver code by itself.

## 11.3 Delivery state

Delivery is separate from Run completion.

```text
receipt_pending
receipt_ready
receipt_failed
```

If Receipt sealing fails after committed completion:

- completion remains true;
- delivery is `receipt_failed` or `receipt_pending`;
- preserve completion and Evidence;
- allow explicit local Receipt rebuild from immutable references;
- do not rerun Commands or mutate source automatically;
- the first-month aggregate demo does not pass until a valid Receipt exists.

# 12. Failure matrix

| Condition | Command | Evidence or workflow result |
| --- | --- | --- |
| unregistered Command | not dispatched | blocked |
| executable changed | not dispatched | blocked; registration review required |
| invalid argv or cwd | not dispatched | blocked |
| missing secret | not dispatched | blocked |
| process exits zero, output complete | succeeded | evaluate criteria separately |
| process exits nonzero | failed | affected criteria fail or remain blocked |
| timeout, group proved gone | timed_out | affected criteria fail or blocked |
| cancellation, group proved gone | canceled | affected criteria blocked |
| group cleanup unproved | unknown | Run orphaned; completion blocked |
| output truncated | known result with truncation | criteria requiring completeness blocked |
| Artifact corrupt or missing | known Artifact failure | Evidence blocked or unknown |
| unexpected source change | result warning or unknown | Patch state invalidated; completion blocked |
| network isolation required | not run | blocked as unsupported on OD-02 |
| current Evidence contradicts | result retained | criterion contradicted |
| all criteria pass but Repository changes | prior Evidence stale | rebuild and reverify |
| model says work is correct | no effect | not Evidence |
| Receipt exists without current Evidence | no effect | completion blocked before acceptance |
| Receipt sealing fails after completion | completion unchanged | delivery blocked |

# 13. Upstream ownership audit

- P0-W21 remains lifecycle, operation, orphan, and completion transaction owner.
- P0-W22 remains provider, Context, Repository-read, disclosure, and secret owner.
- P0-W23 remains Patch, Approval, mutation, rollback, and resulting state owner.
- OD-02 remains host and support owner.

This round adds no Run state, journal owner, Patch mutation rule, provider Tool, or support platform.

# 14. Implementation boundary

After Prompt 8-A authorization, this round can make these units safe to implement:

- Command registration and request types;
- macOS process-group helper contract;
- transient Command Worker;
- timeout, cancellation, and cleanup observation;
- output capture and Artifact storage;
- result adapters;
- Criterion, Evidence, criterion evaluation, and aggregate evaluation;
- user acceptance subject;
- Receipt sealing and delivery status;
- deterministic success, failure, timeout, cancellation, truncation, contradiction, staleness, unknown, and Receipt fixtures.

It does not unlock complete CLI delivery, remote execution, containers, TUI, Child Runs, telemetry, or attestations.

# 15. Candidate Prompt 6-A scaffolding

Prompt 6-A can evaluate:

- registered Command, request, result, and status types;
- host-helper protocol and fake helper fixtures;
- argument, environment, write, network, timeout, and output validators;
- Artifact metadata and integrity types;
- Criterion, Evidence, criterion evaluation, completion evaluation, acceptance request, Receipt, and delivery types;
- no-shell, changed-executable, invalid-argv, missing-secret, timeout, cancellation, group-leak, truncation, Artifact-corruption, stale-Evidence, contradiction, incomplete-proof, and Receipt-failure fixtures.

It must not create a real Command runner, helper binary, product CLI, or fake passing aggregate gate.

# 16. External evidence

Official Apple documentation reviewed on 2026-07-28:

- `killpg(2)` documents signaling a process group;
- `kill(2)` documents negative process IDs for group signaling and signal `0` for validity checks;
- `posix_spawnattr_setpgroup(3)` documents creating or joining a process group with `POSIX_SPAWN_SETPGROUP`.

These APIs make a macOS process-group helper feasible. They do not prove Kiln implementation or descendant cleanup; the authorized ticket must prove those outcomes on the OD-02 host.

# 17. Completion gate

P0-W24 passes only when:

- one registered non-shell Command contract exists;
- one macOS process-group ownership and cleanup contract exists;
- environment, arguments, cwd, secrets, write, network, timeout, and output behavior are explicit;
- Artifact identity, integrity, sensitivity, trust, completeness, and retention are explicit;
- Evidence, freshness, completeness, contradiction, criterion evaluation, and aggregate evaluation are explicit;
- every non-passing condition blocks acceptance;
- user acceptance binds current proof;
- P0-W21 finalization remains authoritative;
- Receipt is aggregation and delivery only;
- upstream and OD-02 authority remain unchanged;
- no CLI, implementation, deferred platform, or Wave B scope enters;
- the exact planning-only head passes Repository validation.

Passing P0-W24 does not issue build authorization.
