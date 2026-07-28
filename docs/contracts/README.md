# Kiln Domain Contracts

**Status:** Foundational contract direction; not implemented  
**Contract families:** `kiln.domain/v0`, `kiln.capability/v0`, `kiln.context/v0`, `kiln.git/v0`, `kiln.delegation/v0`, `kiln.interface/v0`, `kiln.knowledge/v0`, `kiln.knowledge.security/v0`, `kiln.execution_plane/v0`

These JSON Schemas express Kiln-native domain, Capability, Context, Git change-coordination, delegated-work, public terminal-interface, local-project-intelligence, knowledge-security, and trustworthy-execution contracts.

They do not define external protocol messages. An adapter can translate ACP, MCP, LSP, SCIP, A2A, AG-UI, AHP, provider, terminal, hosting-provider, OpenTelemetry, SARIF, in-toto, SLSA, or Client messages to these contracts.

## Files

- `kiln-core.schema.json`: Workspace, Project, Repository, Environment, Session, Task, Run, Client focus, Context, Repository trust policy, and Privacy policy.
- `kiln-execution.schema.json`: Agent, Worker lease, model invocation, Capability, Capability grant, Skill, Resource, Tool call, generic Command, Terminal, Approval, Attention request, and Interruption.
- `kiln-evidence.schema.json`: Artifact, Change set, Claim, Evidence, generic Receipt, Trace reference, and Checkpoint.
- `kiln-capability.schema.json`: Capability implementation registration, selection decision, compact model-facing Tool projection, and normalized Capability result.
- `kiln-context.schema.json`: Context compile request, immutable manifest, rendered package, documentation resolution, Artifact reference, budget, cache, invalidation, and Context observability contracts.
- `kiln-git-change.schema.json`: Repository state, branch contract, worktree lease, Change set, Patch Artifact, verification binding, and integration Receipt.
- `kiln-delegation.schema.json`: delegation contract, Scout result, Verifier result, Run transition, Attention event, cancellation, timeout, and Child result delivery.
- `kiln-interface.schema.json`: public interface event, projection snapshot, Client-local state, normalized input intent, and structured CLI result.
- `kiln-knowledge.schema.json`: approved-root configuration, Repository snapshot, typed node, typed edge, search result, candidate inspection, provenance trace, and scan result.
- `kiln-knowledge-security.schema.json`: knowledge security policy, complete candidate provenance, disclosure decision, security audit event, separately authorized reference execution, and sanitized candidate projection.
- `kiln-execution-plane.schema.json`: Environment profile, Command registration, Command request and result, Patch transaction, precise completion stage, structured result, execution Receipt, telemetry record, and optional attestation export.

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
10. A model-facing Tool name describes software-development intent, not a protocol, server, vendor, CLI, executable, or persistence mechanism.
11. Availability does not grant permission.
12. Large and unbounded results use Artifact references rather than model-visible payloads.
13. A larger provider Context window does not increase the Run Context ceiling automatically.
14. Every model invocation or Context-consuming Worker step receives a new immutable Context manifest.
15. Context items preserve authority, trust, sensitivity, freshness, state binding, selection reason, transformation, and retrieval provenance.
16. Context package and Tool-schema limits are explicit contract fields, not provider defaults.
17. Context7, external documentation, model memory, and reference repositories cannot override higher-authority active Project sources.
18. Git remains authoritative for commits, refs, worktrees, and Repository content.
19. Branch contracts and worktree leases record Kiln authorization and coordination. They do not replace Git facts.
20. One writable worktree has at most one active mutation-owner Run.
21. Verification binds to an exact commit or head plus dirty-tree and Environment fingerprint.
22. A Receipt cannot make stale Evidence current, grant Capability authority, accept work, or authorize integration.
23. Every delegated Task receives a Child Run and immutable delegation contract before delegated execution.
24. A Child receives independent Context, grants, accounting, cancellation, Artifacts, Evidence, and result delivery.
25. Scout and Verifier are the only initial delegated role contracts.
26. A Verifier `PASS` requires reproduced Evidence. `BLOCKED` must not be represented as `PASS`.
27. A blocking user or permission wait requires a global Attention item and recorded resume state.
28. Unknown effects after crash, timeout, cancellation, or rollback require `orphaned` or explicit unknown-effects state rather than success.
29. Logical Parent-Child Run lineage does not define OTP supervision.
30. The delegated-work contract prohibits peer communication, shared mutable Context, and Child permission expansion in the initial version.
31. Interface events and snapshots are public projections. They do not become a second domain authority.
32. Focus, selection, navigation history, scroll, layout, and drafts are client-local.
33. Run execution, Attention, permissions, events, Artifacts, Evidence, Receipts, and Git ownership are shared durable state.
34. Public CLI output must not expose persistence schemas.
35. Duplicate, delayed, and replayed interface events must not create false state.
36. Generic activation must not approve permission, shell execution, integration, cancellation, or another destructive action.
37. Renderer or Client failure must not terminate active Runs.
38. ExRatatui types must remain outside Kiln domain contracts and modules.
39. Local project intelligence is disabled until explicit approved roots exist.
40. Reference Repository content has `instruction_authority: none` for the active Project.
41. Knowledge indexing must not mutate source or execute Repository code in the initial version.
42. Knowledge records preserve Repository snapshot, content digest, extractor, freshness, confidence, and provenance.
43. Embeddings are disabled and no graph or vector database is required by `kiln.knowledge/v0`.
44. Model-facing knowledge access uses narrow intent-level operations and does not expose SQL or arbitrary graph queries.
45. Knowledge search results are investigation candidates and cannot become current Project decisions automatically.
46. Reference instructions, prompts, roadmaps, ADRs, comments, and generated recommendations remain inert quoted data.
47. Knowledge policy denies source execution, source writes, command authority, network authority, and hosted embeddings in v0.
48. Every external disclosure is bound to policy, Run, destination, data classes, payload digest, Approval, and expiry.
49. Every displayed or reusable candidate carries complete source, state, hash, trust, licensing, sanitization, and disclosure provenance.
50. Future execution against a reference Repository requires a separate Run, grant, Environment, Approval, source snapshot, Evidence record, and audit trail.
51. The Environment broker selects the least powerful Environment that satisfies correctness, authority, isolation, and Evidence requirements. It cannot grant authority.
52. Harmless deterministic reads do not require a worktree or container.
53. Ordinary Commands use accepted versioned registrations and argument vectors rather than unrestricted shell strings.
54. An unrestricted shell requires exact explicit Approval and a dedicated Capability grant.
55. A Command owns and terminates its complete process tree or reports incomplete cleanup and unknown effects.
56. Patch transactions bind to exact base state, validate all operations before mutation, and retain rollback information.
57. Formatting and focused validation remain visible registered Commands after Patch application.
58. `Proposed`, `Implemented`, `Inspected`, `Executed`, `Verified`, `Accepted`, and `Delivered` are separate facts.
59. Exit zero, model confidence, Receipt sealing, and attestation export do not imply verification, acceptance, integration, or delivery.
60. Machine-readable results have stronger evidentiary authority than model summaries only when valid, complete, current, and subject-bound.
61. Raw structured reports remain immutable Artifacts with parser, path-mapping, completeness, and state provenance.
62. Execution Receipts contain bounded facts and references. They do not replace underlying Evidence or decisions.
63. OpenTelemetry is operational observation, not durable Evidence or audit authority.
64. Source, Patch content, secrets, sensitive prompts, raw argv, stdout, stderr, and complete result content remain outside telemetry by default.
65. Optional in-toto or SLSA-shaped export does not create a SLSA-level Claim or cryptographic authenticity.
66. WASI and WIT remain future component boundaries until a concrete accepted operation justifies them.

## Contract precedence during v0

`kiln.delegation/v0` is the detailed authority for delegated Run transitions and Attention events introduced by P0-W11.

`kiln.interface/v0` is the public projection and Client-input authority introduced by P0-W12. It does not replace domain events, delegation contracts, or durable storage.

`kiln.knowledge/v0` is the public configuration, Repository-snapshot, node, edge, result, inspection, provenance, and scan authority introduced by P0-W13.

`kiln.knowledge.security/v0` narrows `kiln.knowledge/v0` with mandatory instruction quarantine, read-only authority, complete provenance, Privacy modes, disclosure decisions, security audit events, and separate reference-execution authorization.

`kiln.execution_plane/v0` is the detailed authority for Environment selection, registered Command requests and results, transactional Patches, completion stages, structured-result ingestion, execution Receipts, telemetry records, and optional attestation exports introduced by P0-W15. It refines but does not replace the generic Command, Evidence, Receipt, Git, Capability, or Run contracts.

A more detailed contract cannot broaden an upper-layer policy or grant.

The generic Run and Attention definitions in `kiln.domain/v0` remain compatible projections. Phase 1 contract consolidation must add `waiting_for_command`, expanded Attention, and accepted interface and execution fields before runtime implementation uses those generic schemas as complete validators.

## Validation

The schemas use JSON Schema Draft 2020-12.

The three domain schemas use stable `urn:kiln:schema:*` cross-file identifiers. A validator registers them in one catalog before resolving cross-file references.

The Capability, Context, Git change, delegation, interface, knowledge, knowledge-security, and execution-plane schemas are self-contained and use provisional `https://kiln.local/schemas/*` identifiers.

A contract change requires parser validation. A foundational contract package also requires representative Draft 2020-12 validation for each top-level document type and negative cases for protected invariants.
