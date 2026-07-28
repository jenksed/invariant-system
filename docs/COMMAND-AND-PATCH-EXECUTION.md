# Deterministic Command and Patch Execution

**Document type:** Focused specification  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W15  
**Implementation status:** Not implemented  
**Contract version:** `kiln.execution_plane/v0`

This document is part of the authoritative P0-W15 execution-plane design. `docs/TRUSTWORTHY-EXECUTION-PLANE.md` defines the governing hierarchy and isolation policy.

## Deterministic command runner

### Command registry

The Command registry is the only ordinary entry point for Project execution.

A registration contains:

```text
command key and version
purpose
executable locator and expected digest when practical
supported Environment classes
argument schema and restrictions
working-directory policy
environment-variable policy
network policy
secret bindings
required Capabilities
side-effect class
Repository path scope
timeout and termination policy
output and Artifact policy
structured-result adapters
expected exit-code semantics
platform compatibility
registration source and digest
```

Registrations are Kiln-owned or explicitly accepted Project configuration. A Repository file cannot make a registration accepted solely by declaring one.

Examples of intent-level registrations can include:

```text
project.test.focused
project.test.all
project.compile
project.format.paths
project.lint.paths
project.security.scan
project.build
project.database.migrate.disposable
browser.test.scenario
```

The model sees intent-level Tools, not the full executable catalog.

### Command authorization flow

```text
receive intent-level Command request
→ resolve accepted registration and version
→ validate Task and Run state
→ validate Capability grants
→ validate Repository and path scope
→ select the least sufficient Environment
→ resolve executable without a shell
→ validate argv against the registration schema
→ build cwd, environment, network, secret, and Resource policies
→ freeze an immutable execution request
→ start the owned process tree
→ stream bounded output
→ capture complete output and structured reports as Artifacts
→ terminate or clean up all owned Resources
→ observe Repository and Environment state
→ normalize the result
→ create Evidence and Receipt references
```

### Executable resolution

The runner resolves one executable from an accepted registration.

It records:

- configured locator;
- resolved path or container entrypoint;
- executable version when available;
- executable or image digest when practical;
- resolution source;
- platform;
- resolution timestamp.

The runner does not search arbitrary Repository paths or execute a file only because it has an executable bit.

### Argument restrictions

Arguments are an ordered array. They are not one shell command string.

A registration can constrain:

- fixed values;
- enums;
- regular expressions;
- integers and bounded ranges;
- relative paths inside an accepted scope;
- repeated option groups;
- mutually exclusive flags;
- required flag-value pairs;
- maximum item count and byte length;
- forbidden flags;
- whether response files are permitted;
- whether stdin can carry content.

Path arguments are canonicalized and policy-checked before execution.

Arguments that can load plugins, execute configuration, change output paths, enable network, select arbitrary scripts, or broaden filesystem access require explicit registration support.

### Working-directory restrictions

The working directory is an opaque accepted Resource reference resolved by the runner.

It must be:

- inside the active Project checkout, leased worktree, or accepted container workspace;
- inside the registration's permitted directory set;
- bound to the observed Repository or Environment state;
- revalidated before process start.

The model cannot submit an arbitrary absolute host path.

### Environment policy

Environment values have these sources:

```text
system_required
project_accepted
literal_non_secret
secret_reference
runtime_generated
explicitly_removed
```

The execution request records names, sources, and digests where useful. It does not persist secret values.

The runner starts from a minimal base instead of inheriting every variable from Kiln or the user's terminal.

Variables that influence executable loading, dynamic libraries, package managers, shells, credentials, proxies, configuration homes, or hooks require explicit policy.

### Timeouts and lifecycle

Each registration defines:

- start timeout;
- inactivity timeout when meaningful;
- wall-clock timeout;
- graceful termination period;
- force-termination period;
- attached Resource cleanup timeout.

A user can request a narrower timeout without new authority. A broader timeout requires policy or Approval when it exceeds the registration limit.

### Output limits

Output handling separates:

```text
bounded live display
bounded normalized summary
complete raw Artifact
structured-result Artifacts
```

Initial defaults:

```text
maximum combined live buffer: 1 MiB
maximum retained tail per stream in result: 64 KiB
maximum single line before chunking: 64 KiB
maximum UI update rate: 10 updates per second
maximum ordinary raw log Artifact: 256 MiB
```

Limits are configurable by registration and policy.

Truncation never changes the actual exit status. The result records which streams or records were truncated and where complete output is stored.

### Structured exit result

A Command result includes:

```text
command and request identifiers
Run and Tool-call identifiers
registration key and version
Environment identity and fingerprint
Repository state before and after
executable resolution
redacted argv projection and argv digest
working-directory reference
network mode
secret-reference identifiers
start, end, and duration
start outcome
exit code when observed
termination signal when observed
timeout, cancellation, and cleanup state
process-tree cleanup result
side-effect state
stdout and stderr digests and Artifact references
bounded relevant output
structured-result references
warnings, denials, and omissions
Evidence and Receipt references
```

A Command can end as:

```text
exited
failed_to_start
timed_out
canceled
killed
orphaned
```

`exited` does not imply success. The registration and verification policy interpret the exit code and structured result.

### Side-effect classes

Each registration declares one class:

```text
read_only
repository_write
derived_data_write
service_state
external_effect
unknown
```

A registration with `unknown` side effects is not selected for ordinary automatic execution.

Post-execution observation verifies declared Repository and Artifact effects. Unexpected writes create a policy violation, Evidence, and Attention.

### Unrestricted shell escape hatch

Kiln retains an exceptional shell path for commands that cannot reasonably use a registration.

It requires:

- explicit user Approval for the exact shell program and command digest;
- a dedicated `command.shell.unrestricted` Capability grant;
- a selected Environment and working directory;
- declared network, secrets, and write scope;
- a timeout and process-tree policy;
- visible risk and non-repeatability warnings;
- complete redacted transcript Artifact;
- pre- and post-execution Repository observations;
- a dedicated security audit event;
- no reuse of Approval when the command string changes.

The shell escape hatch is never exposed to the model as a routine Tool. A model can propose text for user review, but it cannot authorize or silently execute it.

## Transactional patch engine

### Purpose

The Patch engine converts an immutable proposed change into an inspected, applied, observable Repository mutation.

The normal flow is:

```text
propose change
→ bind the proposal to an exact base state
→ validate paths and operation types
→ inspect the deterministic patch projection
→ detect conflicts and policy violations
→ prepare rollback information
→ stage all writes
→ apply the transaction
→ observe changed state
→ format affected files through registered Commands
→ run focused validation
→ retain rollback, Evidence, and Artifact references
```

Formatting and validation are later Commands. They are not hidden inside the atomic filesystem commit.

### Patch proposal

A proposal records:

- proposal identifier;
- producing Run and Worker;
- target Repository;
- base commit and dirty-tree fingerprint;
- expected file hashes;
- allowed path scope;
- ordered operations;
- changed-region declarations;
- proposal digest;
- producer Claims;
- source Artifact references;
- creation time.

A Patch Artifact from an isolated Child remains proposed content. It receives no authority to apply itself.

### Supported operations

The initial engine supports:

```text
exact text patch
create file
delete file
move file
rename preview
replace exact region
structured framework operation
AST-aware edit through an accepted adapter
```

A transaction can contain several operations when they form one coherent Change set.

### Exact patches

An exact text patch includes:

- target path;
- expected base hash;
- before and after ranges;
- context lines or byte ranges;
- line-ending and encoding assumptions;
- new content digest.

Fuzzy application is disabled by default. A mismatch becomes a conflict rather than silently applying to a similar location.

### File creation

Creation requires:

- a path that does not exist at the frozen base state;
- an allowed file type and mode;
- bounded content;
- parent-directory policy;
- expected encoding or binary classification;
- a content digest.

The engine does not overwrite an unexpected existing file.

### File deletion

Deletion requires:

- expected file identity and hash;
- explicit operation type;
- path-scope authorization;
- rollback content or an immutable source reference;
- confirmation policy for high-risk or large deletions.

### Moves and rename previews

A move records source and target paths, expected source hash, expected target absence, case-sensitivity assumptions, and cross-filesystem behavior.

A rename preview reports:

- source and proposed target;
- affected imports, references, manifests, routes, tests, or generated paths when deterministically known;
- case-only rename risks;
- collision and portability warnings;
- planned changed-region records.

Preview does not mutate the Repository.

### Conflict detection

The engine rejects or blocks when:

- the Repository base state changed;
- an expected file hash changed;
- a target path appeared or disappeared unexpectedly;
- a symlink, special file, or mount boundary violates policy;
- the operation leaves the allowed path scope;
- another Run owns the mutation lease;
- line ending, encoding, or file mode conflicts are material;
- an AST adapter cannot identify exactly one target;
- the transaction contains internally inconsistent operations;
- the worktree has unowned changes in affected paths.

A conflict never becomes an applied state because a model says the patch is probably safe.

### Changed-region tracking

Every operation records changed regions before and after application.

A region can use:

- line range;
- byte range;
- symbol identity;
- syntax-node identity and query version;
- whole-file identity for creation or deletion;
- move identity.

Region records support focused formatting, validation, review, Evidence freshness, and later explanations.

Changed-region tracking does not replace complete file hashes or Git diffs.

### AST-aware edits

An AST-aware adapter is justified when it can provide a narrower and more deterministic operation than text replacement.

The adapter must:

- declare supported language and syntax version;
- accept an exact source digest;
- identify one deterministic target;
- produce a preview and exact resulting bytes;
- preserve unsupported syntax or fail closed;
- record parser, query, and adapter versions;
- return changed-region and formatting requirements;
- remain replaceable behind the Patch contract.

AST-aware does not mean semantically correct. Active-project verification remains required.

### Structured framework operations

A framework operation represents a known deterministic transformation, such as adding a route entry, migration file, configuration key, or supervised child specification.

It must still produce:

- an immutable Patch Artifact;
- exact paths and hashes;
- a deterministic preview;
- rollback information;
- the same application and Evidence flow as other patches.

A generator that executes Project code or installs dependencies is a Command, not a pure Patch operation.

### Atomic application

The engine prepares the complete transaction before replacing target files.

The implementation should use platform primitives that minimize partial visibility, such as same-filesystem staged files and atomic renames, while recording where a platform cannot provide a multi-file atomic commit.

Required behavior:

1. freeze base observations and lease;
2. validate every operation without mutation;
3. create rollback records;
4. stage resulting content under a Kiln-owned or worktree-local transaction area allowed by policy;
5. fsync or equivalent where the durability profile requires it;
6. apply operations in the deterministic transaction order;
7. stop and roll back completed operations when a later operation fails and rollback is safe;
8. observe final paths, hashes, modes, Git state, and dirty fingerprint;
9. delete temporary transaction files only after durable records exist.

The result distinguishes:

```text
applied
rolled_back
conflicted
failed
orphaned
```

`rolled_back` means Kiln observed that the pre-transaction state was restored. An attempted rollback without proof becomes `orphaned` or `effects_unknown`.

### Rollback information

Rollback records include:

- pre-transaction Repository state;
- each affected path and original hash;
- original content Artifact or recoverable Git object reference;
- original file mode and relevant metadata;
- move source and target identities;
- transaction operation order;
- completed-operation marker;
- rollback attempt and observation results;
- retention policy.

Rollback data is not a promise that every external effect can be undone. Patch transactions do not hide separately executed Commands or service mutations.

### Formatting and focused validation

After a successful application, Kiln selects registered formatters only for affected supported files.

Formatting creates a new observed change state and changed-region record. It can expand the final diff and must remain visible.

Focused validation uses:

- changed paths and symbols;
- dependency and manifest changes;
- accepted Project test mapping;
- compiler and linter registrations;
- acceptance criteria;
- risk classification.

Focused checks do not eliminate required complete checks when Project policy requires them.
