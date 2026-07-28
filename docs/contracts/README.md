# Kiln Domain Contracts

**Status:** Foundational contract direction; not implemented  
**Contract families:** `kiln.domain/v0`, `kiln.capability/v0`, `kiln.context/v0`

These JSON Schemas express Kiln-native domain, capability, and Context contracts.

They do not define external protocol messages. An adapter can translate ACP, MCP, LSP, A2A, AG-UI, AHP, provider, terminal, or client messages to these contracts.

## Files

- `kiln-core.schema.json`: Workspace, Project, Repository, Environment, Session, Task, Run, Client focus, Context, Repository trust policy, and Privacy policy.
- `kiln-execution.schema.json`: Agent, Worker lease, model invocation, Capability, Capability grant, Skill, Resource, Tool call, Command, Terminal, Approval, Attention request, and Interruption.
- `kiln-evidence.schema.json`: Artifact, Change set, Claim, Evidence, Receipt, Trace reference, and Checkpoint.
- `kiln-capability.schema.json`: Capability implementation registration, selection decision, compact model-facing Tool projection, and normalized capability result.
- `kiln-context.schema.json`: Context compile request, immutable manifest, rendered package, documentation resolution, Artifact reference, budget, cache, invalidation, and Context observability contracts.

## Rules

1. Kiln generates all core identifiers.
2. External identifiers belong in adapter-owned mapping records.
3. Unknown external fields do not enter a core entity.
4. A schema definition does not require a database table or OTP process.
5. State transitions are durable events. Entity documents can be immutable records or rebuildable projections.
6. Contract version `v0` is allowed to change before implementation. A later incompatible contract requires a new version.
7. Capability availability, effective authority, Evidence freshness, Trace, completion readiness, and most Client state are derived projections.
8. Process identifiers and runtime handles must never appear in these schemas.
9. The complete Capability catalog remains outside model Context.
10. A model-facing Tool name describes software-development intent, not a protocol, server, CLI, or vendor.
11. An available registration does not grant permission.
12. Large and unbounded results must use Artifact references rather than model-visible payloads.
13. A larger provider Context window does not increase the Run Context ceiling automatically.
14. Every model invocation or Context-consuming Worker step receives a new immutable Context manifest.
15. Context items must preserve authority, trust, sensitivity, freshness, state binding, selection reason, transformation, and retrieval provenance.
16. Context package and Tool-schema limits are explicit contract fields, not provider defaults.
17. Context7, external documentation, and model memory cannot override higher-authority version-matched Project sources.

## Validation

The schemas use JSON Schema Draft 2020-12.

The three domain schemas use stable `urn:kiln:schema:*` cross-file identifiers. A validator must register them in one catalog before resolving cross-file references.

The Capability schema is self-contained and uses `https://kiln.local/schemas/kiln-capability.schema.json` as its provisional identifier.

The Context schema is self-contained and uses `https://kiln.local/schemas/kiln-context.schema.json` as its provisional identifier.
