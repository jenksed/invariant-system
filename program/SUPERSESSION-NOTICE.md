# Supersession Notice — Monorepo Consolidation

**Issued:** 2026-08-16 (Pass-04 design / SYS-M0-01 ratification)
**Status:** Active authority. Supersedes-as-active-authority the
documents listed below.

## Active authority

For Month-One planning and execution, active authority is:

- root `README.md` and `AGENTS.md`
- `invariant.boundaries.json` and `./invariant` boundary check
- current monorepo work packages under `program/recursive-planning/`
- root `invariant` command surface (`status`, `doctor`, `check`,
  `check boundaries`, `test [product]`)

There are **no per-product launch SHAs** and **no multi-repo launch
ceremony** for Month One. The merge train is one trunk (`main`), with
short-lived `m0/<lane-slug>` feature branches merged in M1–M11 order.

## Superseded-as-active-authority (preserved as provenance)

The following documents are **preserved verbatim** but are no longer
active authority for monorepo work:

| Document | Reason |
|---|---|
| `program/LAUNCH-READINESS.md` | Multi-repo simultaneous launch checklist; the monorepo has no equivalent step |
| `program/DEPENDENCIES.md` | Per-repo launch ordering; monorepo has merge-gate ordering instead |
| `program/COORDINATION-OVERVIEW.md` | Four-repo coordination model; the monorepo absorbs the coordination role |
| `program/PROJECT-STATE.md` | Per-repo SHAs and launch pins; the monorepo has one trunk |
| `program/launch/` | Multi-repo launch orchestration; superseded by `./invariant test` + `integration/scenarios/implement-change/` |
| `program/work-packages/{ARSENAL-01,LOADOUT-01,KILN-01}.md` | First-wave per-repo packages; superseded by the M0 work packages in `program/recursive-planning/pass-{03,04}/planning/30-day/work-packages/` |

Each of the four `program/*.md` files listed above carries a
3-line banner at the top pointing back to this notice. The banner is
the only edit; the rest of each file is preserved unchanged as
historical provenance.

## What this notice does NOT do

- It does **not** rewrite or relocate historical evidence. Wave
  records, qualification receipts, and frozen evaluation evidence
  under `program/historical/`, `products/arsenal/evaluation/{cases,
  qualifications}/`, and the kilned `products/kiln/docs/decisions/`
  are preserved with their original references intact, per
  `docs/MONOREPO-MIGRATION.md` ("Historical references intentionally
  left unchanged").
- It does **not** rename or weaken any contract identity string
  (the `engineering-system/...` prefixes). The four canonical v0
  contracts (`work-envelope.v0.md`, `run-result-envelope.v0.md`,
  `qualified-method-record.v0.md`, `learning-observation.v0.md`)
  retain their identities; the new M0 packet under `contracts/m0/`
  is an additional, byte-exact-ratified set, not a replacement.
- It does **not** grant any product new authority. Each product's
  `AGENTS.md` and the boundary check remain the boundary of record.

## Owner sign-off

This notice is issued by the Pass-04 design process on behalf of the
program/system owner. It takes effect at the M2 merge (SYS-M0-01
ratification). Revisions require a new owner-authorized notice with
the same supersession discipline.