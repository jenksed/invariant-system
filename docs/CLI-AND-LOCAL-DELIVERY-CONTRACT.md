# CLI and Local Delivery Contract

**Document type:** Focused interface and delivery authority  
**Decision status:** Proposed by P0-W25; owner acceptance required  
**Integration status:** Proposed on `work/p0-w25-cli-local-delivery`  
**Implementation status:** Not implemented  
**Supported host:** Apple Silicon macOS 15.0 or later  
**Build authorization:** Not issued

## Authority

This specification owns first-month decisions for:

- CLI command names and user workflow;
- text and JSON presentation;
- input, confirmation, error, exit, and safe-next-action behavior;
- configuration and credential references;
- startup diagnostics and restart interaction;
- local arm64 macOS packaging, installation, version, and upgrade expectations.

It does not own lifecycle, journal, provider, Context, Tools, Repository reads, Patch, Approval semantics, mutation, Command execution, Evidence, completion, Receipt semantics, TUI, or delegation.

# 1. Decision summary

1. The permanent first interface is one CLI named `kiln`.
2. Every invocation starts the local application, validates the host and store, executes one foreground action or query, and exits. There is no daemon.
3. Text is the default output. Every command supports `--format json` with one versioned envelope.
4. The CLI exposes accepted application operations; it does not own domain state.
5. Use explicit subcommands for Project setup, Session start, investigation, Patch review and Approval, mutation, verification, Evidence, acceptance, Receipt, cancellation, and recovery.
6. There is no `--yes`, auto-approve, auto-accept, or configuration bypass.
7. Interactive Approval and acceptance require the user to confirm a short digest. Noninteractive calls require the complete subject digest and actor confirmation fields.
8. Use stable exit codes that separate usage, denied, blocked, stale, failed, unknown/orphaned, store, and unsupported-host outcomes.
9. Default `$KILN_HOME` to `~/Library/Application Support/Kiln` when unset.
10. Keep Project policy and registration data under `$KILN_HOME`, not in the active Repository, unless a later accepted portable manifest is added.
11. Resolve `MINIMAX_API_KEY` only at provider dispatch. The CLI never prints or stores its value.
12. Package the first product as an arm64 macOS Mix release containing ERTS, application code, Exqlite native code, and the command-host helper.
13. Build on the supported target profile and publish a `.tar.gz`, SHA-256 checksum, and build manifest.
14. Install under `~/Library/Application Support/Kiln/releases/<version>/` with a user-controlled launcher link at `~/.local/bin/kiln`.
15. No Homebrew formula, auto-update, system daemon, root install, cross-platform package, code-signing claim, or notarization claim exists initially.
16. `kiln --version` reads the release and build manifest. `Kiln.version/0` derives from application metadata rather than a separate literal.

# 2. Global invocation contract

## 2.1 Form

```text
kiln [global-options] <command> [command-options]
```

Global options:

```text
--format text|json
--kiln-home PATH
--no-color
--non-interactive
--help
--version
```

Rules:

- `--kiln-home` is a local operator override and cannot be supplied by provider output or Repository content;
- relative `$KILN_HOME` is rejected;
- structured output implies no color and no interactive prompt;
- `--non-interactive` blocks any action that requires missing user input;
- help and version do not open the state store unless required to report compatibility diagnostics;
- unknown flags are usage errors.

## 2.2 Startup sequence

Except for pure help and version:

1. resolve the OD-02 host profile;
2. resolve and validate `$KILN_HOME`;
3. verify local APFS requirements for authoritative state;
4. acquire the single local process/store startup boundary;
5. run P0-W21 store integrity, migration, projection, and nonterminal-operation reconstruction;
6. detect orphan or pending user work;
7. load accepted Project configuration when required;
8. execute the requested query or application action;
9. flush output and exit.

A startup block prevents the requested action. The CLI prints the exact failure class and safe next action.

# 3. Output contract

## 3.1 Text output

Text output is concise and ordered:

```text
status line
subject identity and digest
primary facts
warnings and unsupported controls
safe next actions
```

Rules:

- no hidden success beneath warnings;
- no spinner or progress animation when stdout is not a TTY;
- live provider and Command output is clearly labeled and bounded;
- secrets, hidden reasoning, and raw control sequences are never displayed;
- paths are shown relative to the Project root when possible;
- unknown and orphaned state uses explicit language.

## 3.2 JSON envelope

```json
{
  "schema": "kiln.cli.result/v1",
  "command": "patch.inspect",
  "status": "ok",
  "result": {},
  "warnings": [],
  "errors": [],
  "next_actions": [],
  "session_revision": 12,
  "repository_state_digest": "sha256:...",
  "emitted_at": "..."
}
```

`status`:

```text
ok
denied
blocked
stale
failed
unknown
unsupported
```

Rules:

- stdout contains exactly one JSON document for non-streaming commands;
- streaming commands use newline-delimited JSON events when `--stream-json` is explicitly selected;
- diagnostics go inside the envelope, not stderr, in JSON mode;
- schema versions are explicit;
- no localized field names;
- unknown fields can be added only compatibly within the versioned envelope.

## 3.3 Exit codes

```text
0  requested query or action completed successfully
2  usage or input validation error
3  authority denied or user denial recorded
4  blocked prerequisite or unsupported effective control
5  stale revision, stale subject, or idempotency conflict
6  known operation or verification failure
7  unknown effect, orphaned Run, or unclassified result
8  state store unavailable, busy, corrupt, migration-blocked, or version-blocked
9  unsupported host or architecture
10 Receipt or delivery failure after committed completion
```

A nonzero exit cannot be hidden by text that sounds successful.

# 4. Configuration and Project setup

## 4.1 Paths

Default:

```text
$KILN_HOME = ~/Library/Application Support/Kiln
```

Layout:

```text
config.json
state.sqlite3
artifacts/
mutations/
commands/
projects/
logs/
tmp/
releases/
```

The exact SQLite, Artifact, mutation, and release boundaries remain owned by their focused specifications.

## 4.2 `kiln doctor`

```text
kiln doctor [--deep]
```

Reports:

- macOS version and build;
- architecture;
- filesystem and local mount status;
- `$KILN_HOME` permissions and free space;
- state-store startup and integrity status;
- release, ERTS, OTP, Elixir, Git, Exqlite, SQLite, and helper versions;
- command-host helper digest and process-group probe capability;
- locale and encoding;
- Project Repository status when selected;
- MiniMax credential reference present or absent, never value;
- network enforcement `unsupported`;
- filesystem isolation and sandbox controls actually effective;
- warnings and next actions.

`--deep` can run non-mutating helper and store fixtures. It cannot invoke MiniMax, apply a Patch, or run a Project verification Command.

## 4.3 `kiln project init`

```text
kiln project init --repo PATH --name NAME
```

Creates one Project record after showing:

- canonical root;
- Git and dirty state;
- path and filesystem profile;
- accepted instruction sources;
- disclosure default `deny`;
- no registered verification Command yet;
- no source mutation until later Approval.

It performs no Repository write.

## 4.4 Project policy commands

```text
kiln project show
kiln project disclosure show
kiln project disclosure set --policy-file PATH
kiln project command list
kiln project command register --file PATH
kiln project command inspect COMMAND_ID
```

Policy and Command registration files are local trusted operator inputs. The CLI validates and stores canonical normalized records beneath `$KILN_HOME`.

A model cannot call these commands.

## 4.5 Credential status

```text
kiln provider status
```

Reports provider, model, endpoint, credential reference name, resolution status, and disclosure requirements.

There is no command that prints, copies, exports, or persists the credential value.

# 5. Session and workflow commands

## 5.1 Start

```text
kiln session start \
  --repo PATH \
  (--objective TEXT | --objective-file PATH) \
  (--criterion TEXT ... | --criteria-file PATH)
```

Optional:

```text
--constraint TEXT
--exclude TEXT
```

Rules:

- objective must be nonempty bounded UTF-8 text;
- at least one required criterion exists;
- criteria receive stable IDs before confirmation;
- the CLI displays objective, criteria, constraints, exclusions, Repository state, disclosure mode, provider, registered Command, and unsupported host controls;
- interactive start requires `start <short-session-digest>`;
- noninteractive start requires `--session-digest FULL_DIGEST --actor local-user`;
- start maps to P0-W21 atomic Session creation.

## 5.2 Status and inspection

```text
kiln status
kiln session show
kiln run show
kiln history [--limit N]
```

Shows:

- Session, Task, Root Run states;
- workflow step;
- current revision;
- Repository state;
- pending decision;
- active or unknown operation;
- current Patch, Command, Evidence, completion evaluation, and Receipt references;
- warnings, unsupported controls, and safe next actions.

It never infers state from transcript text.

## 5.3 Investigation

```text
kiln context build
kiln context inspect [--show-excerpts]
kiln investigate
```

`context build` creates and validates the sealed W22 package without provider dispatch.

`context inspect` displays manifest, files, ranges, limits, exclusions, Tool projection, provider destination, and disclosure decisions. `--show-excerpts` is local-only and still hides secret-blocked content.

`investigate`:

- requires workflow step `investigation` or `proposal`;
- revalidates Context;
- records provider operation intent before dispatch;
- streams visible output only;
- executes only selected W22 Tools;
- returns normalized provider result and proposed change when present;
- never applies a Patch or advances past required user review automatically.

## 5.4 Patch inspection

```text
kiln patch list
kiln patch inspect PATCH_ID
kiln patch preview PATCH_ID
```

Displays:

- Patch and base digests;
- path operations;
- byte and line changes;
- generated unified diff or Artifact reference;
- warnings and unsupported operations;
- staleness;
- approval status and expiry;
- exact safe next actions.

## 5.5 Patch Approval and denial

```text
kiln patch approve PATCH_ID
kiln patch deny PATCH_ID [--reason TEXT]
```

Interactive Approval requires:

```text
approve <short-patch-digest>
```

Noninteractive Approval requires:

```text
--patch-digest FULL_DIGEST
--base-digest FULL_DIGEST
--actor local-user
```

Rules:

- there is no `--yes`;
- the CLI reprints warnings and path set before prompt;
- stale, expired, changed, or invalid Patch cannot be approved;
- denial performs no mutation;
- Approval semantics remain P0-W23-owned.

## 5.6 Apply

```text
kiln patch apply PATCH_ID
```

Requirements:

- active exact Approval;
- current Repository and Session revisions;
- no other operation or lease;
- complete rollback and staging preparation;
- supported host and filesystem.

The command displays operation progress, but does not run formatting or verification afterward automatically.

Result is one exact target observation, proved rollback failure state, known pre-effect failure, or unknown/orphaned state.

## 5.7 Verification

```text
kiln verify run [COMMAND_ID]
kiln command status
kiln command cancel
```

`verify run`:

- selects the accepted registered Command when omitted and unambiguous;
- displays executable identity, argv, cwd, environment key names, timeout, write policy, network limitation, and affected criteria;
- records operation intent and executes through P0-W24;
- streams bounded output;
- creates Command result, Artifacts, and criterion evaluations;
- does not request acceptance unless aggregate readiness is achieved.

`command cancel` requires interactive confirmation or exact operation ID in noninteractive mode. Known cleanup and unknown results follow P0-W24.

## 5.8 Evidence

```text
kiln evidence list
kiln evidence show EVIDENCE_ID
kiln criteria show
kiln completion inspect
```

`completion inspect` displays every criterion result, supporting and contradicting Evidence, freshness, completeness, missing requirements, Repository state, warnings, unsupported controls, and aggregate result.

It never collapses failed or unknown criteria into a favorable summary.

## 5.9 Final acceptance

```text
kiln completion accept
kiln completion reject [--reason TEXT]
```

Interactive acceptance requires:

```text
accept <short-evaluation-digest>
```

Noninteractive acceptance requires:

```text
--evaluation-digest FULL_DIGEST
--repository-digest FULL_DIGEST
--actor local-user
```

Rules:

- no `--yes`;
- only `ready_for_user_acceptance` can be accepted;
- the CLI shows Patch, criteria, warnings, unsupported controls, and delivery expectations;
- revalidation occurs immediately before P0-W21 finalization;
- reject records the decision without completion.

## 5.10 Receipt

```text
kiln receipt show
kiln receipt verify
kiln receipt export --output PATH
kiln receipt rebuild
```

`receipt rebuild` is allowed only after committed completion and uses immutable references. It cannot rerun provider, Patch, or Command effects.

Export writes one canonical JSON manifest plus optional referenced Artifact inventory. It never exports secrets or hidden reasoning.

# 6. Cancellation and recovery

## 6.1 Session cancellation

```text
kiln run cancel [--reason TEXT]
```

The CLI checks current operations. It cannot mark canceled while an effect is unknown. Operation-specific cancellation runs first.

## 6.2 Recovery inspection

```text
kiln recover inspect
```

Displays:

- orphan cause;
- operation class and identity;
- durable intent and observations;
- current Repository and process facts;
- rollback, staged, output, and progress Artifacts;
- exact known-before, known-after, and observed digests;
- permitted reconciliation actions.

## 6.3 Recovery actions

```text
kiln recover resolve --action ACTION --operation OPERATION_ID
```

Only actions authorized by P0-W21 and operation-specific focused authority are accepted.

There is no generic “mark resolved,” “assume success,” or “retry” action.

A stale operation ID, subject digest, or Repository state is rejected.

# 7. Errors and next actions

Every error contains:

```text
code
class
message
subject_reference
current_revision | null
current_state_digest | null
details
safe_next_actions
```

Examples:

| Error | Exit | Safe next action |
| --- | --- | --- |
| `USAGE_ERROR` | 2 | show help |
| `DENIED` | 3 | inspect authority or record denial |
| `DISCLOSURE_DENIED` | 4 | change accepted policy or omit source |
| `UNSUPPORTED_HOST` | 9 | use supported host; no override |
| `STALE_REVISION` | 5 | refresh status and rebuild subject |
| `PATCH_STALE` | 5 | generate new Patch and Approval |
| `COMMAND_FAILED` | 6 | inspect output and criteria |
| `EVIDENCE_CONTRADICTED` | 4 | inspect current contradictory items |
| `OPERATION_UNKNOWN` | 7 | `kiln recover inspect` |
| `STORE_BLOCKED` | 8 | preserve files and follow diagnostic action |
| `RECEIPT_FAILED` | 10 | rebuild from immutable references |

# 8. Logging

Local logs are bounded diagnostic records under `$KILN_HOME/logs/`.

They can include:

- command name and result class;
- IDs and digests;
- timings;
- provider and Command metadata;
- warnings and unsupported controls.

They exclude by default:

- source excerpts;
- Patch content;
- credentials and secret values;
- raw stdout and stderr;
- provider hidden reasoning;
- complete Context or Tool results.

Logs do not replace journal, Evidence, Artifacts, or Receipts.

# 9. Packaging

## 9.1 Mix release

Build one release named `kiln` with:

- ERTS included;
- required OTP applications;
- Kiln application code;
- Exqlite and its target-native library;
- arm64 macOS command-host helper;
- launcher scripts for foreground CLI evaluation;
- release and build manifests.

The release is built on and for:

```text
arm64-apple-darwin
macOS 15.0 compatibility baseline
```

Mix releases require matching target architecture, operating system/vendor, and ABI for ERTS and native dependencies. The release is not portable to Linux, Windows, Intel macOS, or another incompatible target.

## 9.2 Package

Artifact set:

```text
kiln-<version>-arm64-apple-darwin.tar.gz
kiln-<version>-arm64-apple-darwin.tar.gz.sha256
kiln-<version>-arm64-apple-darwin.build.json
```

Build manifest includes:

```text
version
git_commit
dirty: false
build_time
build_host_macos_version
build_host_architecture
target_triple
erlang_otp_version
elixir_version
erts_version
exqlite_version
sqlite_version
command_helper_digest
release_digest
minimum_macos_version
```

A dirty source tree cannot produce a release artifact presented as an accepted build.

## 9.3 Installation

Initial supported installation is user-local and explicit:

1. verify SHA-256;
2. unpack under `~/Library/Application Support/Kiln/releases/<version>/`;
3. set `current` link to the selected version;
4. create or update `~/.local/bin/kiln` launcher link;
5. run `kiln doctor`;
6. do not initialize or migrate a store until the user invokes a stateful command.

No root, `/Applications`, LaunchAgent, LaunchDaemon, package installer, or Homebrew is required.

## 9.4 Upgrade

Upgrade is explicit:

- install a new version beside the old release;
- run compatibility and doctor checks;
- preserve state and Artifact directories;
- startup applies forward migrations under P0-W21;
- only after successful startup does the user select the new `current` link;
- an older binary cannot open a future migration store;
- automatic database downgrade is unsupported;
- release rollback is possible only when the existing store remains compatible.

There is no auto-update.

## 9.5 Uninstall

Removing release binaries does not delete `$KILN_HOME` state or Artifacts automatically.

Destructive data deletion requires a later explicit operator action and retention policy.

# 10. Version contract

```text
kiln --version
kiln version --format json
```

Reports:

- release version;
- build Git commit;
- target triple;
- minimum and current macOS;
- OTP, Elixir, ERTS, Exqlite, SQLite, and helper versions;
- state-store compatibility range;
- CLI schema compatibility range.

`Kiln.version/0` derives from `Application.spec(:kiln, :vsn)` or the generated release metadata. The separate hard-coded `0.1.0-dev` literal is removed when the authorized version ticket implements this contract.

# 11. First-month end-to-end workflow

```text
kiln doctor
→ kiln project init
→ register disclosure and verification Command
→ kiln session start
→ kiln context build
→ kiln context inspect
→ kiln investigate
→ kiln patch inspect
→ kiln patch approve
→ kiln patch apply
→ kiln verify run
→ kiln evidence list
→ kiln completion inspect
→ kiln completion accept
→ kiln receipt verify
```

At every point, `kiln status` displays current truth and safe next actions.

A restart between any two steps rebuilds state through P0-W21. Unknown effects route to `kiln recover inspect` rather than automatic continuation.

# 12. Upstream ownership audit

The CLI does not add or change:

- Session, Task, Run, transition, journal, projection, migration, or completion semantics;
- MiniMax, Context, Tool, Repository-read, disclosure, or secret rules;
- Patch, Approval, lease, mutation, rollback, or recovery classifications;
- Command, helper, Artifact, Evidence, criterion, acceptance, or Receipt semantics;
- OD-02 support boundaries.

It exposes those application operations and queries.

# 13. Implementation boundary

After Prompt 8-A authorization, this round can make these units safe to implement:

- CLI parser and command dispatcher;
- text and JSON result renderers;
- startup and doctor commands;
- Project, policy, and Command-registration commands;
- Session, Context, investigation, Patch, verification, Evidence, acceptance, Receipt, cancellation, and recovery command surfaces;
- stable exit and error mapping;
- local configuration paths;
- Mix release configuration, build manifest, package, checksum, and user-local installer fixture;
- version derivation and output.

It does not itself authorize implementation and does not unlock TUI or Wave B.

# 14. Candidate Prompt 6-A scaffolding

Prompt 6-A can evaluate:

- CLI request, result, error, next-action, and JSON envelope types;
- command-to-application-operation mapping fixtures;
- stable exit-code fixtures;
- no-bypass Approval and acceptance fixtures;
- doctor and host-profile fixtures;
- release/build manifest schemas;
- version derivation contract;
- help and incomplete-command placeholders that fail visibly rather than simulate product success.

It must not create a functioning product workflow, provider invocation, mutation, Command runner, or fake successful end-to-end demo.

# 15. External evidence

Official Mix documentation states that releases package application code, dependencies, and ERTS, and that host and target must match architecture, operating system/vendor, and ABI, including native dependencies. That supports an arm64 macOS release and rejects a cross-platform claim.

# 16. Completion gate

P0-W25 passes only when:

- every first-month user action and failure maps to one command or startup behavior;
- objective and criteria input are explicit;
- text and JSON output, exits, errors, and next actions are explicit;
- Approval and acceptance cannot be bypassed;
- configuration, secrets, diagnostics, restart, orphan, and recovery are explicit;
- Mix release, target, package, install, upgrade, version, and support expectations are explicit;
- the CLI does not redefine upstream semantics;
- no TUI, daemon, broad installer, implementation, or Wave B scope enters;
- the exact final planning-only head passes Repository validation.

Passing P0-W25 does not issue build authorization.
