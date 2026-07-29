# ADR-0025: Support Apple Silicon macOS first

**Document type:** Owner decision  
**Status:** Accepted  
**Integration status:** Proposed on `docs/od-02-apple-silicon-macos`  
**Date:** 2026-07-28  
**Owner decision:** OD-02  
**Required by:** P0-W24 and P0-W25

## Context

Kiln's first-month workflow needs concrete process-tree, filesystem, SQLite, packaging, installation, and support assumptions. Claiming macOS and Linux together would force planning to specify and test two different process, filesystem, isolation, and delivery surfaces before one complete workflow works.

The Project owner develops on an Apple Silicon MacBook Pro with an M1 Pro. Apple currently supports that hardware on macOS Sequoia 15 and newer macOS Tahoe 26 releases. Current Apple security releases continue to include macOS 15 updates.

## Decision drivers

- Validate the first complete workflow on the owner's real machine.
- Make process and filesystem behavior testable.
- Avoid pretending portable domain contracts imply portable effective controls.
- Keep domain data and application boundaries portable where practical.
- Report unsupported or degraded controls honestly.
- Avoid a second packaging and support path before Single-Run Alpha works.

## Decision

OD-02 is:

```text
supported_os_family: macOS
supported_architecture: arm64 / Apple Silicon
minimum_macos_version: 15.0
primary_validation_machine: owner's Apple Silicon MacBook Pro with M1 Pro
state_and_checkout_filesystem: local APFS volume
user_model: one interactive local user
shell_requirement: none for registered Commands
other_hosts: unsupported until complete workflow Evidence exists
```

Additional rules:

1. macOS 15.0 or later on Apple Silicon is the only first-month supported host claim.
2. The current patched release of the installed major macOS version is required for release validation.
3. The owner's M1 Pro Mac is the primary acceptance machine.
4. `$KILN_HOME`, SQLite state, mutation recovery data, Artifacts, and the selected checkout must reside on a local APFS volume for the first supported contract.
5. Network filesystems, cloud-synchronized filesystem semantics, removable filesystems, and remote mounts are unsupported for authoritative state and mutation recovery.
6. Kiln runs as one interactive local user. It does not require root and does not install a system daemon.
7. Domain records, Schemas, provider interfaces, Patch manifests, Evidence, and Receipts remain platform-neutral where semantics permit.
8. Process-tree, signal, cancellation, filesystem replacement, fsync, path case behavior, executable discovery, keychain, and packaging controls must have explicit macOS implementations or report `unsupported`, `degraded`, `blocked`, or `unknown`.
9. Missing effective control never silently falls back to a weaker claim.
10. Linux, Intel macOS, Windows, containers, virtual machines, and remote hosts are not supported until the complete authorized workflow passes their own host conformance and adversarial review.
11. A later host expansion requires measured need, a focused host profile, conformance Evidence, and an accepted decision.

## Minimum runtime assumptions

The first release validation must pin and report:

- macOS product version and build;
- `arm64` architecture;
- filesystem type and local mount status;
- Erlang/OTP version from the Project toolchain;
- Elixir version from the Project toolchain;
- Git version;
- SQLite library and embedded SQLite version;
- terminal encoding and locale;
- executable paths for registered Commands;
- effective process-group and cancellation support;
- effective file replacement, sync, permission, and case-sensitivity behavior.

Exact Erlang, Elixir, Git, and library versions are owned by authorized implementation and release tickets, not by this owner decision.

## Supported-host guarantees

On the supported profile, Kiln must prove:

- state-store startup, migration, WAL, restart, and corruption behavior;
- canonical path and no-symlink controls;
- same-directory regular-file replacement behavior used by P0-W23;
- rollback bundle durability and restart observation;
- registered Command executable resolution without a shell;
- process-group creation, timeout, cancellation escalation, and descendant cleanup;
- bounded stdout and stderr capture;
- local credential reference resolution without credential persistence;
- CLI installation, invocation, upgrade, and version reporting;
- honest reporting of unsupported isolation, Resource, and network controls.

## Unsupported claims

The first-month product does not claim:

- kernel sandboxing;
- container isolation;
- denial of all network access at the operating-system level;
- cgroup-like Resource enforcement;
- Linux namespaces;
- cross-user or team isolation;
- system-wide service management;
- process cleanup on untested hosts;
- reliable mutation on network or synchronized filesystems;
- support for Intel macOS, Linux, Windows, or remote execution.

## Consequences

### Positive

- P0-W24 can define one real process-tree and Command contract.
- P0-W23 filesystem assumptions receive one concrete validation target.
- P0-W25 can define one installation and support path.
- Unsupported controls become visible instead of implicit.
- The first implementation can focus on the owner's actual development environment.

### Negative

- The first release is not cross-platform.
- Some Elixir abstractions will need macOS-specific adapters or probes.
- Users on other platforms cannot rely on the first support claim.
- Host expansion will require later conformance work.

### Neutral or operational

- Portable pure domain modules remain preferred.
- Host-specific behavior belongs behind small explicit adapters.
- macOS Tahoe 26 is allowed but not required; macOS 15.0 is the minimum family baseline.
- Release validation records the exact patched version used.

## Evidence and assumptions

### Observed evidence

- The owner uses an M1 Pro MacBook Pro for Kiln development.
- Apple lists 2021 Apple-silicon MacBook Pro models as compatible with macOS Sequoia 15 and Tahoe 26.
- Apple continues to publish security updates for macOS Sequoia 15.
- macOS exposes POSIX process-group signaling, but exact descendant ownership and cleanup must be proved by Kiln's implementation.

### Inferences

- macOS 15.0 is a practical minimum because it is supported on the owner's hardware and remains in Apple's current security-release set.
- Local APFS is the narrowest filesystem profile for testing SQLite WAL and mutation recovery without remote-filesystem ambiguity.

### Unknowns

- The exact macOS version currently installed on the validation machine must be captured by the implementation ticket.
- The exact Elixir/OTP mechanism or helper needed to create and terminate a complete process group remains a P0-W24 decision.
- APFS case sensitivity can vary by volume and must be reported rather than assumed.

## Verification

P0-W24 and P0-W25 must consume this decision. They must not widen the support claim.

The authorized implementation must prove the effective host profile through machine-readable diagnostics and acceptance fixtures before release.
