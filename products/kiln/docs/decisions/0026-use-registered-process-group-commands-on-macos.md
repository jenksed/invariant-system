# ADR-0026: Use registered process-group Commands on macOS

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Proposed on `work/p0-w24-command-evidence-acceptance`  
**Date:** 2026-07-28  
**Work package:** P0-W24  
**Depends on:** OD-02 and P0-W21

## Context

Kiln needs one deterministic verification Command on Apple Silicon macOS. The Command must avoid shell interpretation, own timeout and cancellation, capture output, and account for descendants. An Elixir Port can own the direct OS process and streams but does not by itself prove that grandchildren are in a controllable group or that they are gone after cancellation.

macOS provides POSIX process-group creation and signaling. A small host helper can expose those capabilities behind a narrow versioned protocol without introducing a general shell, service, NIF, or remote Worker.

## Decision drivers

- no shell strings;
- exact executable and argv;
- complete descendant ownership on the supported host;
- TERM and KILL escalation;
- explicit cleanup proof or unknown result;
- bounded output capture;
- minimal host-specific code;
- no kernel-sandbox claim;
- replaceable adapter behind platform-neutral Command contracts.

## Considered options

### Option A: Elixir Port directly to the registered executable

Advantages:

- minimal implementation;
- direct stdout, stderr, and exit handling.

Disadvantages:

- does not establish a new process group through the required API;
- closing or killing the direct Port does not prove descendants are gone;
- insufficient for the accepted cleanup contract.

### Option B: shell wrapper

Advantages:

- familiar process and signal commands.

Disadvantages:

- introduces parsing and interpolation risk;
- conflicts with the non-shell boundary;
- shell job-control behavior is not the product contract.

### Option C: small bundled macOS host helper

The helper uses `posix_spawn` with a new process group, separate pipes, `waitpid`, `killpg`, and liveness probes.

Advantages:

- narrow host boundary;
- exact process-group identity;
- no shell;
- structured errno and wait results;
- TERM/KILL/probe behavior can be tested.

Disadvantages:

- adds a small native build artifact;
- helper protocol and binary integrity require conformance;
- behavior is macOS-specific.

### Option D: NIF for process management

Advantages:

- direct libc calls from BEAM.

Disadvantages:

- native code in the VM can threaten VM stability;
- broader and riskier boundary than a supervised external helper;
- unnecessary for one host operation.

## Decision

Select Option C.

1. Commands use versioned registrations with absolute executable identity and argv schema.
2. Kiln starts one transient external helper per Command through an Elixir Port.
3. The helper creates the child with `POSIX_SPAWN_SETPGROUP` and pgroup `0`.
4. The helper emits structured child PID, process-group ID, spawn, wait, and errno records.
5. A signal mode uses `killpg` for the exact group.
6. A probe mode uses signal `0` or an equivalent group observation.
7. Timeout and cancellation use SIGTERM, five-second grace, SIGKILL, five-second grace, and final probe.
8. A known timed-out or canceled result requires the group is proved absent.
9. Missing cleanup proof is an unknown effect under P0-W21.
10. The helper accepts no shell command, PATH search, environment inheritance request, arbitrary signal number, or unvalidated path.
11. The helper is fingerprinted and must match the supported host profile.
12. Prompt 6-A can scaffold the helper protocol and fake fixtures. The real helper is implementation and requires Prompt 8-A authorization.

## Consequences

### Positive

- Command cleanup has one testable owner.
- Elixir domain and Evidence code remain platform-neutral.
- The helper can be adversarially tested without placing native code inside the BEAM.
- Unsupported or failed process controls remain explicit.

### Negative

- The first implementation includes a small C or equivalent native helper.
- Packaging must include and fingerprint an arm64 macOS binary.
- Cross-platform support requires separate host adapters.

### Neutral or operational

- The helper is not a product Capability or model Tool.
- The helper does not enforce filesystem or network isolation.
- Command registration remains the authority for executable, argv, cwd, environment, and limits.

## Evidence

Apple's macOS manual pages document `posix_spawnattr_setpgroup`, `killpg`, negative process identifiers for group signaling, and signal `0` for existence checks. These primitives support the design but do not prove Kiln behavior.

## Verification

The authorized implementation must prove:

- helper binary identity;
- new process group creation;
- no shell;
- stdout and stderr separation;
- leader and descendant handling;
- TERM and KILL escalation;
- group absence proof;
- unknown result when cleanup cannot be proved;
- bounded output and structured error mapping;
- clean helper and Port shutdown on the OD-02 host.
