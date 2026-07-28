# Kiln Domain Contracts

**Status:** Foundational contract direction; not implemented  
**Contract families:** `kiln.domain/v0`, `kiln.capability/v0`, `kiln.context/v0`, `kiln.git/v0`, `kiln.delegation/v0`

These JSON Schemas express Kiln-native domain, Capability, Context, Git change-coordination, and delegated-work contracts.

They do not define external protocol messages. An adapter can translate ACP, MCP, LSP, A2A, AG-UI, AHP, provider, terminal, hosting-provider, or client messages to these contracts.

## Files

- `kiln-core.schema.json`: Workspace, Project, Repository, Environment, Session, Task, Run, Client focus, Context, Repository trust policy, and Privacy policy.
- `kiln-execution.schema.json`: Agent, Worker lease, model invocation, Capability, Capability grant, Skill, Resource, Tool call, Command, Terminal, Approval, Attention request, and Interruption.
- `kiln-evidence.schema.json`: Artifact, Change set, Claim, Evidence, Receipt, Trace reference, and Checkpoint.
- `kiln-capability.schema.json`: Capability implementation registration, selection decision, compact model-facing Tool projection, and normalized Capability result.
- `kiln-context.schema.json`: Context compile request, immutable manifest, rendered package, documentation resolution, Artifact reference, budget, cache, invalidation, and Context observability contracts.
- `kiln-git-change.schema.json`: Repository state, branch contract, worktree lease, Change set, Patch Artifact, verification binding, and integration Receipt.
- `kiln-delegation.schema.json`: delegation contract, Scout result, Verifier result, Run transition, Attention event, cancellation, timeout, and Child result delivery.

## Rules

1. Kiln generates all core identifiers.
2. External identifiers belong in adapter-owned mapping records.
3. Unknown external fields do not enter a core entity.
4. A schema definition does not require a database table or OTP process.
5. State transitions are durable events. Entity documents can be immutable records or rebuildable projections.
6. Contract version `v0` can change before implementation. A later incompatible contract requires a new version.
7. Capability availability, effective authority, Evidence freshness, Trace, completion readiness, integration readiness, and most Client state are derived projections.
8. Process identifiers and runtime handles must not appear in durable contracts.
9. The complete Capability catalog remains outside model Context.
10. A model-facing Tool name describes software-development intent, not a protocol, server, CLI, or vendor.
11. Availability does not grant permission.
12. Large and unbounded results use Artifact references rather than model-visible payloads.
13. A larger provider Context window does not increase the Run Context ceiling automatically.
14. Every model invocation or Context-consuming Worker step receives a new immutable Context manifest.
15. Context items preserve authority, trust, sensitivity, freshness, state binding, selection reason, transformation, and retrieval provenance.
16. Context package and Tool-schema limits are explicit contract fields, not provider defaults.
17. Context7, external documentation, and model memory cannot override higher-authority version-matched Project sources.
18. Git remains authoritative for commits, refs, worktrees, and Repository content.
19. Branch contracts and worktree leases record Kiln authorization and coordination. They do not replace Git facts.
20. One writable worktree has at most one active mutation-owner Run.
21. Verification binds to an exact commit or head plus dirty-tree fingerprint.
22. A Receipt cannot make stale Evidence current or grant merge authority.
23. Every delegated Task receives a Child Run and immutable delegation contract before delegated execution.
24. A Child receives independent Context, grants, accounting, cancellation, Artifacts, Evidence, and result delivery.
25. Scout and Verifier are the only initial delegated role contracts.
26. A Verifier `PASS` requires reproduced Evidence. `BLOCKED` must not be represented as `PASS`.
27. A blocking user or permission wait requires a global Attention item and recorded resume state.
28. Unknown effects after crash, timeout, or cancellation require `orphaned` state rather than success.
29. Logical Parent-Child Run lineage does not define OTP supervision.
30. The delegated-work contract prohibits peer communication, shared mutable Context, and Child permission expansion in the initial version.

## Contract precedence during v0

`kiln.delegation/v0` is the detailed authority for delegated Run transitions and Attention events introduced by P0-W11.

The generic Run and Attention definitions in `kiln.domain/v0` remain compatible projections. Phase 1 contract consolidation must add `waiting_for_command` and the expanded Attention taxonomy to those generic schemas before runtime implementation uses them as complete validators.

## Validation

The schemas use JSON Schema Draft 2020-12.

The three domain schemas use stable `urn:kiln:schema:*` cross-file identifiers. A validator registers them in one catalog before resolving cross-file references.

The Capability, Context, Git change, and delegation schemas are self-contained and use provisional `https://kiln.local/schemas/*` identifiers.

A contract change requires parser validation. A foundational contract package also requires representative Draft 2020-12 validation for each top-level document type and negative cases for protected invariants.
