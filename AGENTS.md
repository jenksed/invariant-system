# AGENTS.md — Invariant monorepo

Guidance for AI coding agents working in this repository. Product-local
`AGENTS.md` files inside `products/*/` still apply when you work inside
those trees; this file governs the whole.

## What this is

Invariant is one product system with five product areas. The monorepo
removes repository boundaries, **not** architectural boundaries. Doctrine:
determinism over discretion; capability is not authority; intelligence
proposes, infrastructure enforces; context is compiled, not accumulated;
completion requires evidence; test the property, not the proxy.

## Product map and ownership

- `products/arsenal` — intelligence, methods, evaluation, learning,
  qualification. Python tooling, no package manager; scripts self-locate.
- `products/arsenal/evaluation` — **Bench**. Evaluation/qualification
  evidence lives here. Bench is not a peer product; do not create
  `products/bench`.
- `products/loadout` — goals → capabilities → plans/work envelopes.
  TypeScript/npm.
- `products/kiln` — authority, execution, evidence, verification. Elixir.
  Kiln is the only execution truth.
- `products/temper` — operator experience. Read-only projection; never an
  authority or mutation surface.
- `products/manifold` — intelligence selection. **Boundary documentation
  only.** Do not add a runtime here without an explicit milestone.
- `contracts/` — canonical cross-product contract specs. Schema identity
  strings like `engineering-system/work-envelope/v0` are stable
  identifiers — do not rename them.
- `integration/` — cross-product fixtures and scenarios.
- `program/` — decisions, roadmap, wave records.
  `program/historical/engineering-system/` preserves the old coordination
  repo's root documents.

## Establishing repository truth

Do not trust prose (including this file) over the tree. Verify with:

```bash
./invariant status
./invariant check            # structure
./invariant check boundaries # architecture policy
git log --oneline -10
```

## Running tests

```bash
./invariant test arsenal     # Python gates from products/arsenal
./invariant test loadout     # npm run ci in products/loadout
./invariant test kiln        # mix format/compile/xref/test in products/kiln
./invariant test temper      # npm run ci in products/temper
./invariant test integration # real Loadout→Kiln→Temper golden path
./invariant test             # everything
```

You may also `cd` into a product and use its own canonical commands.
Missing toolchains are diagnosed by `./invariant doctor` — install nothing
globally without the owner's instruction.

## Cross-product change rules

1. A change to `contracts/`, `integration/`, or boundary policy requires
   running every consuming product's tests, not just one.
2. Do not introduce source-level imports between products. Products
   exchange facts through the contracts and files (`.loadout/` state,
   envelopes), not through each other's code.
3. Path assumptions across products must be monorepo-relative
   (`products/<name>`), never absolute, never `../<old-repo-name>` clones.
4. Fixture files under `integration/fixtures/` and some product fixtures
   are digest-bound. Reformatting them breaks proofs. Change them only as
   a deliberate, recorded contract change.
5. Kiln's verification registry keys command profiles off the target
   repository's directory basename (`products/arsenal` → profile
   `project-arsenal` alias). Do not rename product directories.

## Evidence expectations

"Done" means verified: run the relevant tests and cite what you ran and
its result. Do not claim behavior you did not execute. If a check is
environment-blocked (e.g. missing `jsonschema`), say so explicitly instead
of skipping silently.

## Frozen and historical artifacts

Evaluation receipts, qualification records, authorization records, wave
closeouts, and pinned SHAs under `docs/`, `program/`, and
`products/*/evaluation/` are **provenance**. They refer to the historical
multi-repo layout on purpose. Do not rewrite them to reference
`invariant-system` paths. If relocation is technically required, record
both `original_source_repository` and the new location.

## Stop conditions

Stop and ask the owner before:

- rewriting or deleting historical evidence;
- changing a contract's semantics or identity string;
- weakening a test, gate, or boundary check to make it pass;
- installing global tooling;
- performing git mutations beyond ordinary local commits (no force-push,
  no history rewrite, no remote changes to the legacy repositories);
- building Manifold, Fleet, or any new product capability not in the
  current work package.

## Root command

`./invariant` is the only root entry point: `status`, `doctor`, `check`,
`check boundaries`, `test [product]`. Extend it rather than adding
parallel scripts — and keep it delegating to canonical product commands.
