# Root Run Lifecycle and Durable Journal

**Document type:** Focused lifecycle and persistence authority  
**Decision status:** Proposed by P0-W21; owner acceptance required  
**Integration status:** Proposed on `work/p0-w21-root-run-lifecycle-journal`  
**Implementation status:** Not implemented  
**Build authorization:** Not issued

## Authority

This specification owns first-month decisions for:

- persisted Session, Task, and Root Run state;
- Run transitions and transition authority;
- invalid, duplicate, stale, and out-of-order action behavior;
- workflow-step and external-operation separation;
- the append-oriented SQLite journal;
- transaction, sequence, revision, idempotency, projection, migration, startup, corruption, and restart behavior;
- conservative unknown-effect and orphan classification;
- completion-state transaction prerequisites.

When this specification conflicts with general lifecycle or journal examples in `docs/ARCHITECTURE.md`, `docs/RUN-MODEL.md`, `docs/SESSION-MODEL.md`, `docs/IMPLEMENTATION-SLICES.md`, `docs/SLICE-ACCEPTANCE-GATES.md`, or current JSON Schemas, this specification controls the first-month subset.

Those documents remain authoritative for product identity, scope, and later capabilities. Prompt 6 must normalize the retained Schema and conformance subset after all first-month focused rounds pass.

## Accepted constraints

P0-W21 preserves these accepted decisions:

- one active Project and Repository;
- one Session with one initial Task and exactly one Root Run;
- no separate Root Task;
- Run identity is not process, provider, Tool, Command, branch, worktree, protocol, or transcript identity;
- Git and the filesystem remain Repository source truth;
- SQLite records Kiln work facts and recovery state only;
- transcript records are separate from authoritative work state;
- no process exists merely because a domain record exists;
- no automatic repeat after an uncertain external effect;
- Child Runs, Attention, TUI, worktrees, protocols, and remote execution remain outside this round.

# 1. Decision summary

P0-W21 accepts these focused decisions:

1. Persist only observable first-month Session, Task, and Run states.
2. Keep workflow step, pending user decision, external-operation state, and Evidence state separate from Run status.
3. Start a Session atomically in `active`, its Task in `in_progress`, and its Root Run in `ready`.
4. Do not persist unobservable `created`, `accepted`, or `starting` states.
5. Use seven first-month Run states: `ready`, `running`, `waiting_for_user`, `orphaned`, `completed`, `failed`, and `canceled`.
6. Keep `completed`, `failed`, and `canceled` terminal.
7. Permit `orphaned` to leave only through explicit reconciliation.
8. Use one immutable append-oriented journal and one rebuildable current projection per Session.
9. Do not adopt a general event-sourcing framework, event bus, message broker, or one table per noun.
10. Use direct Exqlite with one supervised connection, one writer, WAL mode, `synchronous=FULL`, foreign keys, a two-second busy timeout, and immediate write transactions.
11. Let Kiln own numbered forward SQL migrations and checksums.
12. Treat an unobserved external-operation intent as uncertain after restart. Do not repeat it automatically.
13. Final completion must atomically align Run, Task, Session, user acceptance, and the proof reference supplied by P0-W24.

# 2. Persisted state model

## 2.1 Session states

The first-month persisted Session states are:

```text
active
completed
abandoned
```

Rules:

- Session start creates `active` directly after all start prerequisites pass.
- `completed` means the initial Task is satisfied, the Root Run is completed, required proof is current, no unknown effect remains, and user acceptance is recorded.
- `abandoned` means the only Root Run ended as `failed` or `canceled` and the first-month Session will not create another attempt.
- `archived` is a later retention state. It is not required in the first-month runtime contract.
- waiting, interruption, operation, and orphan facts do not become Session states.

## 2.2 Task states

The first-month persisted Task states are:

```text
in_progress
satisfied
abandoned
```

Rules:

- The user accepts the objective, criteria, constraints, and exclusions before Session start. The transaction therefore creates the initial Task as `in_progress`.
- `satisfied` requires the accepted completion transaction.
- `abandoned` accompanies a terminal failed or canceled Root Run in the first-month one-attempt product.
- Proposed, accepted, ready, blocked, rejected, and superseded Task states remain planning or later-scope concepts until a real multi-Task or revision workflow needs them.
- A blocked criterion or operation is not a Task status. It is a current workflow or proof fact.

## 2.3 Root Run states

The first-month persisted Root Run states are:

```text
ready
running
waiting_for_user
orphaned
completed
failed
canceled
```

### `ready`

Kiln can accept the next valid application action. There is no active external operation and no unresolved pending user decision.

### `running`

Kiln is advancing one accepted workflow action or owns one nonterminal external-operation intent.

`running` does not identify a process. A transient Worker can own the live Resource.

### `waiting_for_user`

One durable pending decision exists. The projection identifies:

- `decision_id`;
- decision kind;
- exact subject and revision;
- permitted responses;
- requested actor;
- requested time;
- safe next action.

No decision is inferred from silence or model output.

### `orphaned`

Kiln cannot prove the terminal result or effect of a material external operation.

`orphaned` is blocked, not terminal success. It cannot become complete through a summary, timeout, process death, or user assertion without the required reconciliation observation.

### `completed`

The attempt reached accepted completion through the atomic completion transaction.

### `failed`

The attempt cannot continue under its current contract, all material effects are known, and no unknown effect remains.

### `canceled`

An authorized user cancellation ended the attempt, all material effects are known or reconciled, and no unknown effect remains.

## 2.4 States not used in the first-month Run contract

Do not add these persisted Run states during P1-S01 or P1-S02:

- `created`;
- `queued`;
- `starting`;
- `waiting_for_tool`;
- `waiting_for_command`;
- `waiting_for_child`;
- `waiting_for_permission`;
- `paused`;
- `verifying`;
- `stale`;
- `reconciling`.

Reasons:

- Session start is atomic. A durable but unusable `created` Run has no first-month user value.
- Tool and Command activity belongs to an external-operation record.
- Verification is a workflow step and proof state.
- Evidence staleness belongs to Evidence.
- Child and Attention states belong to P0-W27.
- Reconciliation is an action and workflow step while the Run remains `orphaned`.

# 3. Workflow, decision, operation, and Evidence separation

## 3.1 Workflow step

The current projection stores one workflow step:

```text
intent
investigation
proposal
approval
application
verification
acceptance
reconciliation
```

A workflow step is not a Run state. It identifies the current product stage and allowed application actions.

P0-W22 through P0-W25 define the exact commands and data for their steps. They must not add Run states to model their activity.

## 3.2 Pending user decision

A pending decision is durable data. It is present only while the Run is `waiting_for_user`.

The decision record owns the exact subject and responses. The Run status does not encode approval, denial, acceptance, or rejection details.

## 3.3 External operation

The first-month operation boundary supports only the accepted operation classes:

```text
model_invocation
patch_application
command_execution
```

P0-W22, P0-W23, and P0-W24 own their exact request and result contracts.

The common durable operation states are:

```text
intent_recorded
started
succeeded
failed
canceled
unknown
```

Rules:

- `intent_recorded` is durable before Kiln dispatches the operation.
- `started` is an optional observation that the live boundary was crossed. It does not replace the prior intent.
- `succeeded`, `failed`, and `canceled` require a terminal observation defined by the owning round.
- `unknown` records that Kiln cannot prove a terminal result.
- Any `intent_recorded` or `started` operation without a terminal observation at restart is treated as uncertain until reconciliation.
- No operation is repeated automatically from an intent or started record.

## 3.4 Evidence state

Evidence freshness, completeness, contradiction, criterion result, and completion readiness remain separate persisted facts.

P0-W24 owns their exact contract. P0-W21 only requires that the completion transition reference one current proof evaluation bound to the same Session revision and Repository state.

# 4. Run transition contract

## 4.1 Transition table

| From | To | Authority | Required facts | Result |
| --- | --- | --- | --- | --- |
| Session start | `ready` | user start action plus deterministic validation | accepted objective and criteria, valid Project and Repository observation, policy snapshot | atomically create Session, Task, and Root Run |
| `ready` | `running` | workflow application | expected revision, allowed action, durable operation intent when an external effect can occur | action can advance |
| `running` | `ready` | workflow application | deterministic step or terminal known operation result; no pending decision | next action is available |
| `running` | `waiting_for_user` | workflow application | one durable pending decision with exact subject and responses | user action required |
| `waiting_for_user` | `ready` | authorized user response | matching decision ID, subject revision, allowed response | decision is recorded and cleared |
| `ready` | `completed` | completion finalization action | current proof reference, user acceptance, no open or unknown operation, matching revision and Repository state | atomically complete Run, Task, and Session |
| `ready` | `failed` | workflow application | unrecoverable known failure, no open or unknown operation | atomically fail Run and abandon Task and Session |
| `running` | `failed` | workflow application | terminal known failure, no open or unknown operation | atomically fail Run and abandon Task and Session |
| `ready` | `canceled` | user | no open or unknown operation | atomically cancel Run and abandon Task and Session |
| `running` | `canceled` | user plus operation owner | terminal cancellation observation, no unknown effect | atomically cancel Run and abandon Task and Session |
| `waiting_for_user` | `canceled` | user | no open or unknown operation | atomically cancel Run and abandon Task and Session |
| `running` | `orphaned` | restart or operation observation | one nonterminal operation cannot be classified | append unknown operation and orphan transition |
| `ready` | `orphaned` | reconciliation observer | current Repository or external observation exposes a prior unknown effect | append observation and orphan transition |
| `orphaned` | `ready` | explicit reconciliation action | every unknown operation is classified; safe next action is explicit | continue without automatic repeat |
| `orphaned` | `failed` | explicit reconciliation action | effects are known and current contract cannot continue | fail and abandon |
| `orphaned` | `canceled` | user after reconciliation | effects are known and user ends work | cancel and abandon |

No transition goes directly from `orphaned` to `completed`.

No transition leaves `completed`, `failed`, or `canceled`.

## 4.2 Invalid requests

Every state-changing application action includes:

- `action_id`;
- `session_id`;
- `run_id` when applicable;
- `expected_session_revision`;
- `idempotency_key`;
- actor identity and kind;
- action kind;
- canonical request digest;
- causation and correlation references when present.

Return these deterministic outcomes:

| Condition | Outcome |
| --- | --- |
| valid action and expected revision | commit and return new projection |
| same idempotency key and same request digest | return the prior committed result with no new journal entry |
| same idempotency key and different request digest | `IDEMPOTENCY_CONFLICT` |
| expected revision is older or newer than current | `STALE_REVISION` with current revision |
| state or workflow step disallows action | `INVALID_TRANSITION` |
| actor lacks authority | `DENIED` |
| referenced decision or operation is not current | `STALE_SUBJECT` |
| SQLite writer is busy after the accepted timeout | `STORE_BUSY` and no committed state |
| store is unavailable, corrupt, or unsupported | `STORE_BLOCKED` |
| commit response is uncertain | reopen and query the idempotency key before any retry |

Invalid, denied, stale, and duplicate requests do not append failure events merely because the request was rejected. They return structured application results. Security audit requirements can add a separate bounded audit record later without changing domain truth.

# 5. Atomic application transactions

## 5.1 Session start

One `BEGIN IMMEDIATE` transaction:

1. verifies no conflicting active Session under the first-month limit;
2. verifies the expected Project and Repository observation reference;
3. checks the idempotency key and request digest;
4. appends `session_started/v1`;
5. builds the Session projection with:
   - Session `active`;
   - Task `in_progress`;
   - Root Run `ready`;
   - workflow step `intent`;
   - objective and criteria revision;
   - Project, Repository, and policy references;
6. writes the projection and digest;
7. writes the action result;
8. commits.

The transaction does not create separate persisted `created` or `accepted` states.

## 5.2 Objective, criteria, constraint, or exclusion revision

One transaction:

1. checks expected Session revision;
2. validates the revision is allowed by the current workflow and later authority rules;
3. appends one accepted revision entry;
4. applies invalidation references supplied by later rounds when required;
5. updates the projection;
6. stores the action result;
7. commits.

A later round can restrict when a revision is allowed. It cannot update prior journal entries.

## 5.3 Begin an external operation

One transaction:

1. checks expected Session revision and authority reference;
2. validates no conflicting nonterminal operation;
3. appends `external_operation_intent_recorded/v1` with operation class, request digest, state binding, authority reference, and idempotency reference;
4. transitions the Run to `running` if it is `ready`;
5. updates the projection and action result;
6. commits before dispatch.

Dispatch happens only after the transaction commits.

## 5.4 Observe an external operation

One transaction:

1. identifies the current operation and expected revision;
2. appends a terminal observation or `unknown` classification;
3. records references to later-round result data;
4. transitions the Run to `ready`, `waiting_for_user`, `failed`, or `orphaned` as permitted;
5. updates the projection and action result;
6. commits.

## 5.5 Request and answer user input

The request transaction appends the pending decision and moves `running` to `waiting_for_user`.

The response transaction:

1. matches decision ID, subject, actor, allowed response, and expected revision;
2. records the response;
3. clears the pending decision;
4. moves the Run to `ready`;
5. commits.

A later workflow action can then move `ready` to `running`.

## 5.6 Fail or cancel

A failure or cancellation transaction must first prove that no operation remains unknown.

It atomically:

- records the terminal reason and observations;
- moves the Root Run to `failed` or `canceled`;
- moves the Task to `abandoned`;
- moves the Session to `abandoned`;
- updates the projection and action result.

If an effect is unknown, the action records `orphaned` instead.

## 5.7 Reconcile orphaned work

A reconciliation transaction:

- records fresh observations for every unknown operation;
- records the user's selected next action when required;
- never deletes the original intent or unknown classification;
- moves the Run to `ready`, `failed`, or `canceled` only when all required effects are classified.

## 5.8 Complete work

P0-W24 supplies the exact proof and acceptance contract.

The finalization transaction must include:

- expected current Session revision;
- exact objective and criteria revision;
- exact Repository and required Environment state reference;
- current completion-evaluation reference and digest;
- current user acceptance decision;
- proof that no operation is open or unknown;
- required warnings, exclusions, and unsupported controls.

It atomically:

- records user acceptance;
- moves Task `in_progress` to `satisfied`;
- moves Root Run `ready` to `completed`;
- moves Session `active` to `completed`;
- stores the completion result reference;
- updates the projection and action result.

P0-W24 can add required proof fields. It must not make completion non-atomic or allow another Run state to imply completion.

# 6. Journal contract

## 6.1 Purpose

The journal exists for:

- restart reconstruction;
- ordered audit of accepted work facts;
- duplicate-action prevention;
- current-projection rebuild;
- external-effect intent and observation boundaries;
- conservative reconciliation.

It is not:

- a complete transcript;
- a token stream;
- a message broker;
- a general event bus;
- a distributed log;
- a source-code store;
- an Artifact store;
- a general event-sourcing framework.

## 6.2 State database

Use one local file:

```text
$KILN_HOME/state.sqlite3
```

The SQLite file owns Kiln work state. The Repository, Git objects, source files, provider service, and external processes remain outside its transaction boundary.

## 6.3 Minimum tables

The first state store needs these responsibilities. Exact SQL names can vary only if the mapping remains one-to-one and documented.

### `store_metadata`

Stores:

- store format identifier `kiln-state/v1`;
- store identity;
- created time;
- current application compatibility range.

### `schema_migrations`

Stores:

- migration version;
- file name;
- SHA-256 checksum;
- applied time.

### `journal_entries`

Stores the immutable ordered work facts.

### `action_commits`

Stores one idempotency record and canonical result for each committed application action.

### `session_projections`

Stores one rebuildable current projection, schema version, Session revision, last sequence, and projection digest per Session.

### `transcript_records`

Stores bounded interaction records separately. Transcript writes cannot update domain projections.

Do not create separate first-month tables for every Session, Task, Run, workflow step, decision, operation, Evidence, or Receipt noun unless an accepted implementation ticket proves a concrete query or integrity need that the journal and projection cannot meet.

## 6.4 Journal entry envelope

Every entry contains:

```text
entry_id
entry_schema
entry_type
payload_schema
sequence
session_id
session_revision
action_id
actor_kind
actor_id
idempotency_key
request_digest
causation_entry_id | null
correlation_id | null
recorded_at
payload
payload_digest
```

Rules:

- `entry_id` is an opaque Kiln-generated UUIDv7.
- `sequence` is one SQLite-assigned global monotonic integer.
- `session_revision` is monotonic and unique inside one Session.
- `recorded_at` is UTC and informational. Sequence defines order.
- `entry_type` and `payload_schema` are versioned strings.
- `payload` uses canonical UTF-8 JSON.
- `payload_digest` is SHA-256 over the canonical payload bytes plus its schema identifier.
- Payloads contain references and bounded facts. Large, binary, sensitive, or unbounded content remains in Artifacts or the authoritative external system.
- Entries are never updated or deleted. A correction appends a new fact.

## 6.5 Initial entry types

P1-S01 requires:

```text
session_started/v1
objective_revised/v1
criteria_revised/v1
constraints_revised/v1
run_transitioned/v1
pending_decision_recorded/v1
user_decision_recorded/v1
session_abandoned/v1
```

The first-month external-effect boundary also reserves:

```text
external_operation_intent_recorded/v1
external_operation_started/v1
external_operation_observed/v1
external_operation_reconciled/v1
completion_recorded/v1
```

These names do not define provider, Patch, Command, Evidence, or Receipt payloads. Their owning focused rounds must supply bounded payload schemas without changing the common envelope or state rules.

## 6.6 Action idempotency

`action_commits` contains:

```text
action_id
session_id
idempotency_key
request_digest
expected_session_revision
first_sequence
last_sequence
result_schema
result
result_digest
committed_at
```

Unique constraints:

- `action_id` is globally unique;
- `(session_id, idempotency_key)` is unique;
- `(session_id, session_revision)` is unique in `journal_entries`;
- `sequence` is globally unique.

Retry rules:

- Same key and same request digest returns the stored result.
- Same key and different request digest is a conflict.
- No automatic retry occurs after an uncertain commit response until the store is reopened and the key is queried.

# 7. Projection contract

## 7.1 Current projection

The Session projection is one canonical structured document that contains the current first-month work state and references.

It includes:

- Session, Task, and Root Run identity and state;
- current workflow step;
- objective, criteria, constraints, and exclusions revision;
- Project, Repository, policy, and authority references;
- pending decision;
- current external operation;
- warnings, failures, unknowns, and unsupported controls;
- later Context, Patch, Command, Evidence, Artifact, Receipt, and completion references when their rounds define them;
- Session revision and last journal sequence;
- projection schema and digest.

It excludes:

- full transcript content;
- full source files;
- complete Artifact payloads;
- hidden model reasoning;
- process handles;
- provider connections;
- client-local display state.

## 7.2 Pure reducer

One pure reducer owns each accepted entry type.

The reducer takes:

```text
current projection or empty state
+ one validated journal entry
→ new projection or deterministic error
```

It does not:

- access SQLite;
- read the Repository;
- invoke a provider;
- execute a Command;
- mutate files;
- consult the transcript;
- infer missing facts.

## 7.3 Rebuild

Startup or a validation command can rebuild a projection from sequence zero.

Rules:

- unknown entry or payload versions block startup for the affected store;
- invalid sequence or Session revision blocks startup;
- reducer failure blocks startup;
- a valid rebuilt projection with a different cached digest replaces the cached projection and records a local integrity warning;
- rebuilding does not append journal entries or change domain facts;
- the cached projection is never more authoritative than the journal.

# 8. Transcript separation

A transcript record contains interaction metadata and bounded content or an Artifact reference.

It can reference Session, Run, actor, time, and sequence. It does not use the journal Session revision and cannot change:

- objective or criteria;
- Task or Run state;
- authority;
- pending decision;
- operation state;
- Evidence;
- acceptance;
- completion.

A transcript write failure does not roll back an already committed domain action. The action result reports the transcript failure separately.

# 9. SQLite boundary

## 9.1 Selected library

Use direct Exqlite through its DBConnection-compatible API.

Do not add Ecto or `ecto_sqlite3` for the first store.

Reason:

- the store has a small explicit schema;
- journal transactions and replay are central;
- no relational domain model or query builder is required;
- direct SQL keeps migration and transaction ownership visible;
- Exqlite provides a supervised connection, transactions, busy timeout, query interruption, and current SQLite builds without adding an ORM boundary.

ADR-0022 records this dependency choice.

## 9.2 Connection ownership

The application supervisor starts one Exqlite connection process for `state.sqlite3`.

Rules:

- pool size is one;
- all state writes use this connection;
- the Exqlite process owns the database connection Resource;
- `Kiln.Store` owns SQL, transaction, migration, and mapping functions but is not a GenServer;
- Session, Task, Run, journal entry, action, and projection do not receive processes;
- no second writer connection is opened in the first month.

## 9.3 Connection settings

Use these initial settings:

```text
mode: readwrite + create
journal_mode: WAL
synchronous: FULL
foreign_keys: ON
busy_timeout: 2000 ms
default_transaction_mode: IMMEDIATE
wal_autocheckpoint: 1000 pages
```

Rules:

- WAL is valid only on the local host filesystem. A network filesystem is unsupported.
- WAL permits concurrent reads but still has one writer.
- `FULL` is selected because work-state durability is more important than maximum write throughput.
- `BEGIN IMMEDIATE` acquires the write transaction at the start. If it cannot acquire it within the busy timeout, the action returns `STORE_BUSY` before partial application work.
- The first-month product does not disable journaling, foreign keys, or synchronous durability.
- Performance tuning beyond these settings requires measured Evidence.

## 9.4 File handling

The database, `-wal`, and `-shm` files form one live SQLite state set.

Do not copy, move, back up, or inspect only `state.sqlite3` while a connection is open and claim a complete snapshot. A later backup feature must use SQLite's supported backup or serialization mechanism or close and checkpoint the store safely.

# 10. Migration and startup contract

## 10.1 Migration ownership

Kiln owns forward SQL migrations under:

```text
priv/store/migrations/
```

Naming:

```text
0001_initial_state.sql
0002_<purpose>.sql
```

Each migration has one stable checksum. Applied checksums are immutable.

The first month does not require down migrations. Recovery uses a store backup or a newer compatible binary, not an automatic destructive downgrade.

## 10.2 Startup sequence

Startup performs these steps before exposing writable work:

1. resolve and validate `$KILN_HOME` and the local database path;
2. open the Exqlite connection with the accepted settings;
3. verify the store format metadata or initialize a new empty store;
4. run `PRAGMA quick_check`;
5. read migration versions and checksums;
6. block if the store has a future unsupported migration;
7. block if an applied migration checksum differs;
8. acquire an immediate transaction and apply each pending migration in order;
9. rebuild or validate current projections;
10. scan nonterminal external-operation intents;
11. append unknown and orphan facts for operations that cannot be classified;
12. expose the store as ready.

The startup state is one of:

```text
ready
busy
migration_blocked
integrity_blocked
version_blocked
unavailable
```

These are store startup results. They are not Run states.

## 10.3 Migration failure

- A migration executes inside its own immediate transaction.
- If a statement fails, the migration transaction rolls back.
- Kiln records no applied version.
- Startup remains blocked.
- Kiln does not edit the migration, skip it, or continue with a partially upgraded Schema.

## 10.4 Corruption and integrity failure

When SQLite or `quick_check` reports corruption, not-a-database, unsupported format, or an unreadable WAL state:

- stop writable startup;
- preserve all files;
- report the exact path and SQLite result class without secrets;
- do not auto-repair, recreate, truncate, or replace the store;
- do not infer Session or operation state from the transcript;
- require an explicit recovery action outside the first-month automatic path.

# 11. Partial write and commit uncertainty

SQLite provides atomic transactions, but a caller can lose the connection before it receives the commit result.

Rules:

1. Every state-changing action has an idempotency key and request digest.
2. The action result is written in the same transaction as journal entries and the projection.
3. After an uncertain commit response, reconnect.
4. Query `(session_id, idempotency_key)`.
5. If the committed action exists with the same digest, return its stored result.
6. If it does not exist and store integrity passes, the action did not commit and can be offered for explicit retry.
7. If store integrity cannot be established, return `STORE_BLOCKED`.
8. Never submit the effect or state action again before this query.

# 12. Restart and external-effect matrix

| Durable state before crash | Startup classification | Automatic action |
| --- | --- | --- |
| no operation intent | restore projection | none |
| operation intent exists; no terminal observation | operation `unknown`; Run `orphaned` | do not repeat |
| operation started; no terminal observation | operation `unknown`; Run `orphaned` | do not repeat |
| terminal operation result committed | restore terminal operation state | continue from projection |
| pending user decision committed | Run `waiting_for_user` | show the same decision |
| completion transaction committed | Session and Run completed | show completed state |
| completion request sent but action commit uncertain | query idempotency key | return committed result or explicit retry option |
| projection cache missing or stale; journal valid | rebuild projection | replace cache and warn |
| unknown entry version | startup blocked | require compatible binary or migration |
| migration incomplete but not recorded | SQLite rollback; migration pending | retry migration only through startup contract |
| corrupt or unreadable store | startup blocked | preserve files; no inference |

# 13. Authority matrix

| Action | Request authority | Commit authority | Live owner when required |
| --- | --- | --- | --- |
| start Session | user | workflow application after validation | none |
| revise objective or criteria | user | workflow application | none |
| advance deterministic workflow | workflow application | workflow application | none |
| record external-operation intent | workflow application with accepted authority reference | workflow application | none before dispatch |
| invoke model | P0-W22 contract | later terminal observation | transient model Worker |
| apply Patch | user Approval plus P0-W23 contract | later terminal observation | P0-W23 selected owner |
| execute Command | P0-W24 registration and authority | later terminal observation | transient Command Worker |
| request user decision | workflow application | workflow application | none |
| answer decision | authorized user | workflow application | none |
| classify orphan | explicit observation and reconciliation authority | workflow application | operation-specific observer |
| fail | workflow application | workflow application | none |
| cancel | user and operation-specific cancellation contract | workflow application | live Worker when present |
| complete | user acceptance plus P0-W24 proof | workflow application | none |

The model cannot request a state transition directly. It can return a Claim or Tool request that the workflow application validates under the owning contract.

# 14. Retention boundary

Through the active first-month Session, retain:

- all journal entries;
- all action-commit records;
- current and rebuildable projections;
- migration history;
- bounded transcript records or their Artifact references;
- external-operation intent and result references;
- completion and abandonment facts.

Do not compact or delete journal entries during an active Session.

Long-term retention, archival, deletion, export, and compaction remain deferred. P0-W24 can add active-Session Artifact and proof retention. It cannot delete work-state journal facts required for restart and audit.

# 15. Failure matrix

| Failure | Durable result | User-visible result | Retry rule |
| --- | --- | --- | --- |
| invalid transition | none | `INVALID_TRANSITION` | correct request |
| stale revision | none | `STALE_REVISION` plus current revision | refresh first |
| idempotency duplicate, same digest | prior result | replayed committed result | no new write |
| idempotency duplicate, different digest | none | `IDEMPOTENCY_CONFLICT` | new key after correction |
| writer busy | none | `STORE_BUSY` | explicit retry after state refresh |
| migration failure | prior Schema remains | `MIGRATION_BLOCKED` | fix with accepted migration change |
| future Schema | none | `VERSION_BLOCKED` | use compatible newer Kiln |
| corruption | none | `INTEGRITY_BLOCKED` | explicit recovery only |
| projection mismatch, journal valid | cache replaced | warning and restored state | no user retry |
| unknown entry | none | `VERSION_BLOCKED` | compatible reducer required |
| external effect uncertain | unknown operation and orphaned Run | reconciliation required | no automatic repeat |
| terminal known operation failure | operation failed; Run ready or failed per owning contract | exact failure and next action | explicit allowed action only |

# 16. Implementation boundary

After later Prompt 8 authorization, P0-W21 makes these units safe to implement:

- first-month Session, Task, and Root Run records;
- pure state and transition validation;
- action request, expected revision, and idempotency handling;
- direct Exqlite connection and store startup;
- migrations and store metadata;
- journal append transactions;
- current Session projection and pure replay;
- transcript separation;
- restart reconstruction and conservative orphan classification;
- P1-S01 lifecycle, persistence, duplicate, migration, corruption, and restart fixtures.

P0-W21 does not unlock:

- MiniMax or fake-provider implementation;
- Context, Tool, or Repository source-read implementation;
- Patch proposal, Approval, application, or rollback;
- Command execution;
- Evidence, Artifact, Receipt, or completion evaluator implementation;
- complete CLI delivery;
- Child Runs or later scope.

# 17. Prompt 3 dispositions

P0-W21 changes the planning direction for:

- IU-02: add only the Exqlite connection as the first justified live child after authorization;
- IU-06: replace broad core lifecycle assumptions with this first-month state and transition subset;
- IU-07: select direct Exqlite, one connection, Kiln-owned migrations, immutable journal, and rebuildable projection;
- IU-13: journal stores Artifact references only; Artifact bytes remain outside this store contract;
- `kiln-core.schema.json`: first-month Run status, required Agent binding, broad Client, Environment, and later states require Prompt 6 reduction;
- `kiln-evidence.schema.json`: journal and Checkpoint overlap must not create a second state owner.

# 18. Candidate Prompt 6 scaffolding

Prompt 6 can evaluate:

- Session, Task, Run, workflow-step, decision, and operation state types;
- pure transition validator;
- action request and structured error types;
- journal-entry and action-commit Schemas;
- projection Schema and pure reducer behaviour;
- migration manifest and checksum validator;
- store startup result type;
- idempotency and expected-revision contract tests;
- valid, invalid, duplicate, stale, busy, migration, corruption, replay, restart, and orphan fixtures.

Prompt 6 must not create a general event framework, full future Schema package, product implementation, or fake passing gate.

# 19. External evidence

Current official sources reviewed on 2026-07-28:

- Exqlite v0.39 documentation: `https://exqlite.hexdocs.pm/`
- Exqlite connection options and transaction modes: `https://exqlite.hexdocs.pm/Exqlite.Connection.html`
- SQLite transaction behavior: `https://www.sqlite.org/lang_transaction.html`
- SQLite WAL behavior and one-writer rule: `https://www.sqlite.org/wal.html`
- SQLite result codes, including busy, interrupt, I/O, and corruption: `https://www.sqlite.org/rescode.html`
- SQLite atomic commit behavior: `https://www.sqlite.org/atomiccommit.html`

These sources support the selected connection, transaction, durability, and failure boundaries. They do not prove Kiln implementation.

# 20. Completion gate

P0-W21 passes only when:

- this focused authority is accepted and internally consistent;
- every first-month Run state and valid transition is explicit;
- invalid, stale, duplicate, denied, busy, and uncertain requests have deterministic outcomes;
- Session, Task, Run, workflow, decision, operation, and Evidence facts have separate owners;
- atomic application transactions are explicit;
- one immutable journal envelope, action idempotency record, projection owner, and transcript boundary exist;
- direct Exqlite, one connection, pragmas, migration, startup, corruption, and partial-commit handling are explicit;
- restart and unknown-effect behavior is conservative;
- completion requires current proof and user acceptance without defining P0-W24 semantics;
- no provider, Patch, Command, Evidence platform, CLI, Child, or deferred scope enters the round;
- the planning-only final head passes all current Repository checks.

Passing P0-W21 does not authorize implementation.
