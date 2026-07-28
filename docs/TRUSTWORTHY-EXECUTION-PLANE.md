# Trustworthy Execution Plane

**Document type:** Specification  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W15  
**Implementation status:** Not implemented  
**Contract version:** `kiln.execution_plane/v0`

## Purpose

This specification defines Kiln's trustworthy execution plane.

The execution plane turns accepted Tasks, Capability grants, Repository state, and Environment policy into deterministic Commands, transactional changes, machine-readable Evidence, Artifacts, Receipts, and telemetry.

Kiln prefers deterministic execution and machine-readable observations over model confidence.

A model can propose an operation, explain a result, or state a Claim. It cannot make an operation safe, make stale Evidence current, convert a failed check into a pass, accept its own work, or prove delivery.

This specification is the primary authority. Focused companion specifications are:

- `docs/COMMAND-AND-PATCH-EXECUTION.md`;
- `docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md`;
- `docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md`.

The execution plane extends and must remain compatible with:

- `docs/INTERNAL-DOMAIN-MODEL.md`;
- `docs/CAPABILITY-INTEGRATION.md`;
- `docs/SECURITY-MODEL.md`;
- `docs/GIT-CHANGE-ISOLATION.md`;
- `docs/DELEGATED-WORK.md`;
- `docs/CLI-TUI.md`;
- `kiln.domain/v0`;
- `kiln.capability/v0`;
- `kiln.git/v0`;
- `kiln.evidence/v0`.

## Accepted positions

Kiln accepts these positions:

1. Kiln selects the least powerful Environment that can produce the required Evidence.
2. A harmless low-risk read does not require a container or worktree.
3. Project-defined Commands run in an accepted Project Environment when that Environment is required for correct behavior.
4. An independently mutating Run uses an exclusive writable worktree and mutation lease.
5. Untrusted, destructive, disposable, or dependency-installing work escalates to a disposable isolated worker when the platform supports the required containment.
6. A Dev Container is an accepted Project Environment description. It does not grant authority and is not assumed to be safe merely because it uses containers.
7. OCI containers are an isolation implementation. They do not replace Capability policy, path policy, secret policy, Evidence binding, or process cleanup.
8. Disposable databases are bounded Resources attached to an Environment. They do not define the Run or Environment identity.
9. Network and secrets are denied unless one Command registration and active grant require them.
10. Commands use a versioned registry and argument vectors by default. They do not use an unrestricted shell string.
11. An unrestricted shell remains an exceptional escape hatch behind explicit Approval and a dedicated grant.
12. Patch application is a deterministic transaction with preconditions, an immutable proposal, rollback information, exact changed-region records, and post-application state observation.
13. `Proposed`, `Implemented`, `Inspected`, `Executed`, `Verified`, `Accepted`, and `Delivered` are separate stages.
14. Every material completion Claim links to current Evidence.
15. A structured machine result normally has higher evidentiary weight than a model summary when the result is valid, complete, current, and bound to the evaluated state.
16. Complete raw results remain available as Artifacts when normalized summaries are used.
17. Receipts seal facts and references. A Receipt does not make Evidence current, approve work, or grant integration authority.
18. OpenTelemetry records operation shape and measurements. Telemetry is not automatically Evidence.
19. Source code, patches, secrets, sensitive prompts, and complete Command output do not enter telemetry by default.
20. Kiln Receipts can later map to in-toto Statements and SLSA provenance when the action produces an appropriate immutable subject.
21. Formal supply-chain attestations are optional exports. They are not required for every local edit or Command.
22. WASI and WIT remain a future constrained component boundary. They do not replace ordinary host or Project Commands before a concrete plugin contract proves value.

## Critical distinctions

| Distinction | Kiln rule |
| --- | --- |
| Environment and Run | An Environment supplies execution Resources. A Run remains the durable work identity. |
| Container and sandbox | A container is one isolation mechanism. Kiln reports the effective controls instead of claiming complete sandboxing. |
| Worktree and Environment | A worktree isolates Repository mutation. An Environment controls processes, dependencies, network, secrets, and Resources. They can be combined. |
| Dev Container and OCI worker | A Dev Container expresses a Project development environment. A disposable OCI worker is selected for bounded isolated execution. |
| Disposable database and Project database | A disposable database is an ephemeral test Resource. It cannot be represented as the active Project database. |
| Registered Command and shell | A registered Command has a fixed executable, argument policy, and Environment policy. A shell can interpret arbitrary syntax and requires exceptional authority. |
| Exit zero and verification | Exit zero is one machine observation. Verification evaluates an acceptance criterion against current state. |
| Patch and implemented state | A Patch Artifact is proposed content. Implementation begins only after accepted application to the target state. |
| Formatting and correctness | Formatting proves only that an accepted formatter ran and reported its result. |
| Structured result and truth | A valid structured result is a strong observation. It remains scoped to its producer, parser, state, and completeness. |
| Model summary and Evidence | A model summary is a Claim-bearing transformation. It does not outrank the source result. |
| Receipt and attestation | A Receipt is Kiln's local sealed manifest. An attestation is an optional interoperable export. |
| Telemetry and audit | Telemetry measures system behavior. Durable audit and Evidence records establish accepted facts and decisions. |

## Execution hierarchy

Kiln evaluates Environment classes in this order and selects the first class that satisfies correctness, authority, isolation, dependency, reproducibility, and Evidence requirements.

```text
0. no execution
1. trusted host read
2. active Project Environment
3. isolated Git worktree
4. Project Dev Container
5. disposable OCI worker
6. future Wasm component
```

This is a decision hierarchy, not a rule that every operation must traverse each level.

### Level 0: no execution

Use when the required result can be produced from accepted records and bounded file reads.

Examples:

- parse an existing JSON report;
- inspect a source file;
- hash a file;
- compare two immutable Artifacts;
- render a stored Receipt;
- query the local knowledge index.

No Command, shell, container, worktree, network, or secret grant is created.

### Level 1: trusted host read

Use for low-risk deterministic host operations that:

- read only approved local Resources;
- do not execute Repository-controlled code;
- do not install dependencies;
- do not require Project environment variables or services;
- do not mutate the active Repository;
- have bounded input and output;
- use a Kiln-owned implementation or accepted fixed executable.

Examples include controlled Git observation, filesystem metadata, hashing, and parsing an already produced report.

The trusted host is not an ambient authority source. Each operation still requires a matching Capability grant and Resource scope.

### Level 2: active Project Environment

Use when correct execution depends on the Project's accepted toolchain, runtime, dependency set, configuration, or service contract.

Examples:

- `mix test` in an Elixir Project;
- a compiler using Project lockfiles;
- an accepted linter or formatter;
- a read-only framework introspection Command;
- a focused test that requires the existing Project service topology.

The Environment can be host-based, managed by a runtime manager, or described by Project configuration.

Kiln records the effective Environment fingerprint. Project-local configuration can describe execution but cannot grant itself Capabilities, network, secrets, or unrestricted host access.

### Level 3: isolated Git worktree

Use when a Run needs independently owned Repository mutation or stable exact-state verification.

The worktree provides:

- one recorded base state;
- one path boundary;
- one branch or detached state;
- one mutation-owner lease when writable;
- dirty-tree observation;
- exact verification binding;
- recovery without overwriting another Run's work.

A worktree does not isolate processes, network, secrets, or host Resources. It is combined with another Environment class when those controls matter.

### Level 4: Project Dev Container

Use when the Project has an accepted Dev Container definition and the definition is required for reproducible development behavior.

Before use, Kiln evaluates the resolved configuration, including:

- image or build inputs;
- mounts and workspace mount behavior;
- lifecycle Commands;
- Features;
- user and privilege settings;
- environment variables;
- forwarded ports;
- host sockets;
- requested capabilities;
- network behavior;
- secret references;
- write locations.

Lifecycle Commands, Features, Dockerfiles, and Compose configuration are executable inputs. They require explicit policy and cannot run merely because a `devcontainer.json` file exists.

Kiln records the resolved image digest or build-input digest when available. Mutable tags alone do not establish a reproducible Environment.

### Level 5: disposable OCI worker

Use for work that benefits from stronger disposable isolation, including:

- dependency installation;
- untrusted Project code;
- migrations against a disposable database;
- browser automation;
- security scanners with broad source reads;
- destructive tests;
- native tools with uncertain behavior;
- Commands that must have network denied technically;
- Commands that must not see the host home directory or credentials.

The preferred profile includes:

- an immutable or digest-pinned OCI image;
- a read-only root filesystem where practical;
- an explicit writable work directory;
- only required mounts;
- a non-root user;
- dropped capabilities;
- no host sockets;
- no ambient home directory;
- no inherited credentials;
- network denied or explicitly allowlisted;
- CPU, memory, process, file-size, and time limits;
- process-tree ownership and termination;
- Artifact export through one controlled output channel;
- cleanup and post-run state inspection.

Kiln records actual effective controls. It does not claim a container is isolated when the runtime exposes broad mounts, privileged mode, host networking, or powerful sockets.

### Level 6: future Wasm component

A future Wasm component can be selected when:

- the operation has a stable narrow interface;
- WIT can describe all required imports and exports;
- the component needs no unsupported host behavior;
- filesystem, network, clock, random, and environment access can be granted explicitly;
- output is bounded and machine-readable;
- the runtime and component digest are recorded;
- the component provides a real portability or isolation advantage.

WIT defines the interface contract. It does not prove component behavior or safety.

WASI and component-model versions must be pinned. A future component receives only the imports in its accepted world and the Resources authorized for the Run.

## Environment selection

The Environment broker evaluates:

```text
operation intent
+ accepted Command registration
+ Repository role and state
+ mutation requirement
+ toolchain requirement
+ dependency requirement
+ service and database requirement
+ trust and risk class
+ requested network and secrets
+ platform containment availability
+ required Evidence and reproducibility
= selected Environment profile
```

The broker cannot grant authority. It filters Environment registrations against policy and active Capability grants.

### Selection rules

Kiln uses the trusted host when:

- the operation is a fixed low-risk read;
- Repository code is not executed;
- no Project dependency or service is required;
- no mutation occurs;
- output and duration are bounded.

Kiln uses the active Project Environment when:

- the Project toolchain is required;
- the active checkout can safely serve the operation;
- the operation does not need independent mutation ownership;
- accepted policy permits Project-defined execution.

Kiln adds a Git worktree when:

- a Run mutates independently;
- stable exact-state verification requires a separate checkout;
- the active checkout can move during execution;
- a Patch Artifact must be applied outside the user's checkout.

Kiln uses a Project container when:

- the accepted Project environment is container-defined;
- the resolved container configuration passes policy review;
- its lifecycle behavior is required and authorized;
- the container does not silently broaden mounts, network, secrets, or privilege.

Kiln uses a disposable isolated worker when:

- execution is untrusted or destructive;
- dependency installation is needed;
- a disposable service or database is needed;
- network denial or Resource control must be enforced technically;
- host contamination or persistent caches are unacceptable;
- a browser or native scanner requires stronger containment.

Kiln uses a future Wasm component only when an accepted WIT contract and runtime profile can replace a broader process safely.

## Isolation policy

### Isolation dimensions

Kiln evaluates isolation as independent dimensions:

```text
Repository path
Repository mutation ownership
filesystem writes
process identity and tree
runtime and dependency state
network
secrets
service and database state
CPU and memory
output and Artifact path
lifecycle and cleanup
```

One mechanism rarely covers every dimension.

### Host execution policy

Host execution is allowed only through accepted deterministic implementations and registered Commands.

The runner does not inherit the user's complete shell environment. It builds an environment from:

- required system values;
- accepted Project values;
- explicit literal non-secret values;
- secret references resolved just in time;
- Kiln-owned temporary and cache paths;
- policy-required denials and overrides.

Host execution must not use the user shell startup files.

### Project-local execution policy

Project-local execution requires:

- an active Project Repository;
- an accepted Environment registration;
- an exact working-directory scope;
- a registered Command;
- required grants;
- pre-execution Repository and Environment observation;
- post-execution Repository observation when side effects are possible.

A Project configuration file can select an accepted registration. It cannot define arbitrary executable authority.

### Worktree policy

A writable worktree requires the accepted branch contract and exclusive mutation lease.

A read-only or detached worktree can be used without a mutation lease when no write Capability exists.

The runner rejects a writable Command when:

- the worktree lease is absent, expired, stale, or owned by another Run;
- the working directory escapes the leased worktree;
- the Command's path scope exceeds the lease;
- the base or head state no longer matches the execution request.

### Container policy

A container registration records:

- runtime and version;
- OCI image digest or build-input digest;
- effective user;
- root filesystem mode;
- mounts and write modes;
- namespaces and network mode;
- Linux capabilities or equivalent controls;
- Resource limits;
- environment and secret bindings;
- host sockets and devices;
- entrypoint and argument behavior;
- cleanup policy.

Unknown or degraded controls narrow availability.

### Disposable database policy

A disposable database is provisioned for one bounded Run or verification scope.

It records:

- engine and version;
- image or executable digest when available;
- schema input and migration set;
- seed-data digest;
- connection mode;
- network scope;
- credentials as secret references;
- storage persistence mode;
- startup and readiness Evidence;
- cleanup result;
- retained dump or log Artifacts when policy permits.

The default storage mode is ephemeral. A failed cleanup creates Attention and an orphaned Resource record.

### Restricted networking

Network modes are:

```text
denied
loopback_only
service_set
host_allowlist
unrestricted_approved
```

`unrestricted_approved` requires explicit Approval and a dedicated network grant.

The runner records requested and effective network modes. DNS, proxy, registry, package-host, and callback needs are part of the allowlist.

A network denial that cannot be enforced technically must be reported as degraded isolation. Policy decides whether the Command is unavailable or can proceed with additional Approval.

### Secret injection

Secrets enter execution only as references resolved after authorization.

Kiln must:

- bind each secret to one Command and Environment;
- avoid putting secret values in Command documents, Receipts, telemetry, logs, or argv;
- prefer file descriptors, mounted files, or process-specific environment injection over command-line arguments;
- redact exact and derived secret forms from bounded output;
- destroy temporary secret material after execution;
- record the secret identifier and injection method, not the value;
- revoke or expire secret grants independently from the Run.

### Resource limits

An Environment profile can set:

- wall-clock timeout;
- graceful termination window;
- CPU time or quota;
- memory limit;
- process count;
- open-file limit;
- output byte limit;
- Artifact byte limit;
- temporary disk limit;
- file-size limit;
- database storage limit;
- network byte or request limit when enforceable.

An unsupported Resource limit remains visible. It must not be represented as enforced.

### Process-tree termination

Every Command has one owned process tree or isolation-unit identity.

Termination follows:

```text
request cancellation or timeout
→ stop accepting new input
→ send graceful termination to the owned tree
→ wait for the registered grace period
→ force termination of remaining owned processes
→ close pipes and terminals
→ stop attached disposable Resources
→ inspect Repository and Environment state
→ record descendants, exit observations, cleanup, and unknown effects
```

On Unix-like systems, the implementation can use a dedicated process group, session, container, or cgroup. On Windows, it can use a Job Object or another accepted tree-owning primitive.

Killing only the direct child process is insufficient.

If Kiln cannot prove that descendants stopped or side effects are known, the Command becomes `orphaned` or records `effects_unknown`. It cannot be reported as a clean cancellation.
