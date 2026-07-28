# ADR 0018: Use tiered deterministic execution and evidence

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W15
- **Date:** 2026-07-28

## Context

Kiln already defines Runs, Capability grants, supervised Commands, Git worktrees, Patch Artifacts, Claims, Evidence, Receipts, and exact-state verification.

Those contracts do not yet define how Kiln chooses among host, Project, worktree, container, disposable Resource, and future Wasm execution. They also do not provide a complete Command registry, transactional Patch lifecycle, structured-result ingestion model, precise completion stages, execution Receipt, telemetry boundary, or future attestation mapping.

Without a coherent execution plane, Kiln could over-isolate harmless reads, under-isolate risky execution, rely on shell text, lose process descendants, apply stale patches, confuse exit zero with verification, or treat model confidence as proof.

## Decision

Kiln uses a tiered deterministic execution plane.

The Environment broker selects the least powerful Environment that satisfies correctness, authority, isolation, dependency, reproducibility, and Evidence requirements:

```text
no execution
→ trusted host read
→ active Project Environment
→ isolated Git worktree
→ accepted Project Dev Container
→ disposable OCI worker
→ future Wasm component
```

Containers and worktrees are not required for harmless operations.

Ordinary Commands use accepted versioned registrations with:

- fixed executable resolution;
- argument-vector schemas;
- working-directory and path policy;
- minimal environment construction;
- explicit network and secret policy;
- time, output, and Resource limits;
- owned process-tree lifecycle;
- structured result adapters;
- Artifact, Evidence, and Receipt references.

An unrestricted shell is exceptional. It requires explicit Approval for the exact command digest and a dedicated Capability grant.

Patch changes use immutable proposals bound to exact Repository state. Kiln validates all paths and preconditions, produces an inspectable deterministic preview, retains rollback information, stages all operations, applies the transaction, observes the result, and then runs visible registered formatter and validation Commands.

Kiln records these stages separately:

```text
Proposed
Implemented
Inspected
Executed
Verified
Accepted
Delivered
```

No stage implies the next stage. Every material completion Claim links to current Evidence.

Machine-readable results normally receive more evidentiary weight than model summaries only when they are valid, complete, current, and bound to the evaluated subject. Raw reports remain immutable Artifacts.

Kiln generates deterministic execution Receipts and can later export eligible Receipts as in-toto Statements or SLSA provenance. Formal attestations remain optional and do not apply to every local action.

OpenTelemetry records bounded operation and measurement data. Source, patches, secrets, sensitive prompts, raw argv, and complete output remain excluded by default. Telemetry does not replace durable events, Evidence, audit records, or Receipts.

The authoritative design is in `docs/TRUSTWORTHY-EXECUTION-PLANE.md`, its three focused companion specifications, and `docs/contracts/kiln-execution-plane.schema.json`.

## Consequences

- Harmless local work avoids unnecessary container and worktree overhead.
- Risky execution can escalate to stronger disposable isolation without changing Run identity.
- Project containers remain useful but cannot grant themselves authority.
- Command behavior becomes inspectable, bounded, replayable at the request level, and easier to verify.
- Process-tree cleanup and unknown effects become explicit correctness concerns.
- Patch application becomes a deterministic transaction rather than an unstructured write sequence.
- Formatting and tests remain visible Commands with their own Evidence.
- Completion language becomes precise and resistant to optimistic model summaries.
- Structured tool output becomes reusable Evidence without discarding raw reports.
- Artifact storage, Receipt sealing, and telemetry require explicit implementation work.
- Future attestation compatibility is preserved without imposing supply-chain ceremony on ordinary development.

## Rejected positions

- Requiring a container for every read or Command.
- Requiring a worktree for every read-only Run.
- Running every Project Command directly on the trusted host.
- Treating Dev Container configuration as implicit authority to build, mount, forward ports, inject secrets, or run lifecycle Commands.
- Allowing arbitrary command strings through the ordinary runner.
- Relying on killing only the direct child process.
- Treating exit zero, model confidence, or a Receipt as verification.
- Treating `Proposed`, `Implemented`, `Executed`, `Verified`, `Accepted`, and `Delivered` as synonyms.
- Applying fuzzy or state-mismatched patches automatically.
- Hiding formatter or generator mutations inside Patch application.
- Discarding raw reports after normalization.
- Putting source, secrets, prompts, or complete output in telemetry by default.
- Requiring in-toto or SLSA output for every local Command or edit.
- Claiming a SLSA level because an exporter emits a compatible document shape.
- Selecting WASI or WIT before a concrete plugin operation justifies the boundary.

## Review triggers

Review this decision when:

- a harmless operation cannot run safely without broader isolation;
- a Project toolchain requires a new Environment class;
- a supported platform cannot own and terminate process trees reliably;
- Dev Container or OCI behavior cannot be reduced to the accepted Environment contract;
- remote execution is proposed;
- a Patch operation cannot preserve deterministic preconditions and rollback evidence;
- a structured-result format requires new authority or sensitive-data rules;
- OpenTelemetry semantic conventions materially change;
- a Wasm component provides a concrete portability or containment advantage;
- an attestation consumer requires signing, DSSE, SLSA level claims, or publication policy.
