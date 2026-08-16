# Arsenal Asset Contract

Schema-Version: 1.0.0

Project Arsenal's machine-readable metadata is composed from:

- `arsenal/registry.json` — canonical base registry;
- `arsenal/registry.d/*.json` — deterministic extension fragments loaded in filename order.

The merged registry is the canonical metadata view for reusable Project Arsenal assets. Fragmentation exists to let independent capability packs/foundations add assets without turning one large JSON file into a merge-conflict hotspot.

Every registry file must use the same schema version.

## Asset vs capability

The Asset Contract and Capability Contract have deliberately different responsibilities.

```text
Asset
  = a registered repository artifact or package

Capability
  = a versioned behavioral contract for achieving a useful outcome
```

This document remains authoritative for artifact identity, repository path, kind, asset lifecycle, invocation metadata, and asset-to-asset relationships.

Behavioral capability definitions live under `arsenal/capabilities/*.json` and are governed by `arsenal/CAPABILITY_CONTRACT.md`.

Rules across the boundary:

1. Not every registered asset is a capability. Templates, references, doctrines, source briefs, schemas, and distribution artifacts may exist only as assets.
2. A capability references registered asset IDs for implementation and provenance rather than replacing the Asset Registry.
3. One capability may compose several assets; one asset may support more than one capability.
4. Capability `display_name` and compatibility aliases may evolve without rewriting stable asset IDs.
5. Asset lifecycle and capability lifecycle are separate evidence claims. Neither automatically promotes the other.
6. Harness/distribution packages remain assets or derived artifacts; they do not become the canonical behavioral definition merely because a harness can discover them.

This separation lets Project Arsenal evolve behavioral contracts without destabilizing repository identity and lets future compilers generate multiple harness packages from one canonical capability definition.

## Required fields

Every registered asset must define:

- `id` — stable dotted identifier.
- `path` — repository-relative path.
- `category` — primary library category.
- `kind` — artifact type.
- `status` — lifecycle state.
- `purpose` — one-sentence observable purpose.

Optional relationship fields:

- `upstream` — asset IDs that commonly feed this asset.
- `downstream` — asset IDs that commonly consume this asset.
- `source_brief` — preserved generation source for a compiled prompt.
- `source_for` — canonical asset produced from a source brief.
- `invocation` — harness-neutral invocation mode from `arsenal/INVOCATION_MODEL.md`.

## Kinds

- `prompt` — directly reusable canonical prompt.
- `prompt-package` — prompt plus variants, evaluation material, or packaging metadata.
- `generator` — produces another prompt or prompt package.
- `brief` — preserved source-generation artifact; not a directly runnable canonical capability.
- `workflow` — composition or operating sequence across assets.
- `template` — reusable file or repository template.
- `doctrine` — governing engineering principles.
- `method` — reusable reasoning/operating method independent of a particular prompt or harness.
- `reference` — shared vocabulary, policy, or mechanics consumed by other assets.
- `router` — chooses among capabilities without owning their implementation.

## Invocation modes

When present, `invocation` must be one of:

- `human`
- `agent`
- `reference`
- `composed`

See `arsenal/INVOCATION_MODEL.md` for semantics.

## Lifecycle states

- `source` — preserved source material used to generate another asset.
- `draft` — canonical asset exists but has not yet earned a testing or stable claim.
- `unverified` — pre-registry asset that appears usable but has not yet been evaluated under the lifecycle contract.
- `testing` — evaluation cases are being run and tracked.
- `stable` — evaluation evidence supports repeated use for the intended scope.
- `deprecated` — retained for compatibility or history but should not be selected for new work.

Status is an evidence claim. Do not promote an asset because its prose looks good.

## Integrity rules

1. Every registry path must exist.
2. IDs and paths must be unique across the merged registry.
3. All registry files must use the supported schema version.
4. Directly runnable `prompt` assets must not contain a `prompt-generation-brief` payload or the Master Sol/Fable generator wrapper.
5. A `source_brief` path must exist and be registered as `kind: brief`.
6. `upstream`, `downstream`, and `source_for` references must resolve to registered asset IDs.
7. Optional `invocation` values must be valid.
8. `CATALOG.md` must match the catalog rendered from the merged registry.
9. Source briefs remain separate from compiled prompts so the library never presents generation source as a finished capability.

## Change rule

When adding or materially changing an asset:

1. update the base registry or the appropriate `registry.d` fragment;
2. run `python3 scripts/arsenal_audit.py --write-catalog`;
3. run `python3 scripts/arsenal_audit.py`;
4. inspect the resulting diff;
5. do not promote lifecycle status without the evidence required for that state.
