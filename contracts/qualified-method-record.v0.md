# Qualified Method Record v0

**Status:** Experimental fixture contract  
**Producer:** Arsenal  
**Consumer:** Loadout; Kiln only when attached as provenance to an executable obligation

## Purpose

Declare that Arsenal has evaluated a method sufficiently for a named context. Qualification is evidence about a method, not runtime authority and not automatic product promotion.

## Minimum record

```yaml
schema: engineering-system/qualified-method-record/v0
method_id: repository-recon/architecture-anchor-incremental
method_version: 0.1.0
status: qualified
qualified_for:
  outcome: understand-a-repository
  contexts: []
  exclusions: []
inputs: []
outputs: []
procedure_ref: sha256:...
evaluation:
  evidence_refs: []
  models: []
  repositories: []
  observed_strengths: []
  observed_failures: []
  confidence: bounded
provenance:
  arsenal_commit: "..."
  record_digest: sha256:...
```

## Invariants

- `status: qualified` means qualified only for the declared context.
- The record cannot grant filesystem, network, Git, or production authority.
- Loadout owns whether and how the method implements a stable Capability.
- Kiln owns whether any procedure step becomes an enforceable runtime obligation.
- A later record may supersede the method without breaking a stable Loadout Capability contract.
- Failures and exclusions are first-class; qualification must not erase negative knowledge.

## First fixture

ARS-01 produces one real Repository Recon record. Until then, LOD-01 uses a clearly marked fixture with no claim that the method is already empirically qualified.

