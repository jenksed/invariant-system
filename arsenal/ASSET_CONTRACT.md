# Arsenal Asset Contract

Schema-Version: 1.0.0

`arsenal/registry.json` is the canonical metadata registry for reusable Project Arsenal assets.

The registry exists so filenames, lifecycle state, dependencies, source briefs, and intended composition can be inspected deterministically instead of inferred from prose or directory names.

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

## Kinds

- `prompt` — directly reusable canonical prompt.
- `prompt-package` — prompt plus variants, evaluation material, or packaging metadata.
- `generator` — produces another prompt or prompt package.
- `brief` — preserved source-generation artifact; not a directly runnable canonical capability.
- `workflow` — composition or operating sequence across assets.
- `template` — reusable file or repository template.
- `doctrine` — governing engineering principles.

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
2. IDs and paths must be unique.
3. Directly runnable `prompt` assets must not contain a `prompt-generation-brief` payload or the Master Sol/Fable generator wrapper.
4. A `source_brief` path must exist and be registered as `kind: brief`.
5. `upstream`, `downstream`, and `source_for` references must resolve to registered asset IDs.
6. `CATALOG.md` must match the catalog rendered from the registry.
7. Source briefs remain separate from compiled prompts so the library never again presents generation source as a finished capability.

## Change rule

When adding or materially changing an asset:

1. update `arsenal/registry.json`;
2. run `python3 scripts/arsenal_audit.py --write-catalog`;
3. run `python3 scripts/arsenal_audit.py`;
4. inspect the resulting diff;
5. do not promote lifecycle status without the evidence required for that state.
