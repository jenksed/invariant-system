# Work Envelope v0

**Status:** Experimental semantic contract  
**Producer:** Loadout  
**Consumer:** Kiln

## Purpose

Translate a user Goal and selected Capability into a bounded request for a Kiln Task/Run without granting runtime authority or importing Loadout's internal object model.

## Minimum envelope

```yaml
schema: engineering-system/work-envelope/v0
work_id: "..."
created_at: "..."
producer:
  product: loadout
  version: "..."
goal:
  title: "..."
  success_conditions: []
capability:
  id: repository-recon
  contract_version: 0.1.0
  method_provenance: []
project_state:
  repository: "..."
  base_commit: "..."
  workspace_state_digest: "..."
scope:
  included: []
  excluded: []
constraints:
  must: []
  must_not: []
context_refs: []
proof_obligations: []
authority_requests: []
```

## Invariants

- The envelope requests work; it does not create a Run or grant authority.
- `project_state` binds the request to observable repository state.
- Context crosses by content-addressed reference when possible, not copied mutable truth.
- A Proof Obligation describes required evidence or a predicate; it does not claim satisfaction.
- Kiln may narrow or deny requested authority. Loadout must present denials truthfully.
- Kiln does not need Loadout's Workspace, Pack, Catalog, or Skill ontology to consume the envelope.
- Arsenal is optional provenance in normal execution, not a required runtime dependency.

## v0 exclusions

- nested/child Run graphs;
- organization ontology;
- remote execution topology;
- general policy language;
- product acceptance decisions;
- automatic learning ingestion.

