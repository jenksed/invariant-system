# Invariant

Invariant is a local-first system for AI-assisted software engineering where
**completion requires evidence**: intelligence may propose, but
infrastructure enforces, executes, and proves.

This repository is the canonical monorepo for the Invariant product system.
It consolidates what were five separate repositories (`project-arsenal`,
`loadout`, `kiln`, `temper`, and the `engineering-system` coordination repo)
into one development surface with preserved Git history. See
[docs/MONOREPO-MIGRATION.md](docs/MONOREPO-MIGRATION.md) and
[MIGRATION-REPORT.md](MIGRATION-REPORT.md) for provenance.

## Products

| Product | Path | Role |
| --- | --- | --- |
| **Arsenal** | `products/arsenal` | Engineering intelligence: methods, reusable judgment, research, learning, qualification. Includes **Bench** (`products/arsenal/evaluation/`), the evaluation/qualification harness. |
| **Loadout** | `products/loadout` | Human-facing capability environment: Goal → Capability → Skills/configuration → Plan / Work Envelope preparation. |
| **Kiln** | `products/kiln` | Durable execution truth: authority, Runs, effects, artifacts, evidence, registered verification, restart/recovery. Elixir/OTP. |
| **Temper** | `products/temper` | Operator experience: a read-only terminal workbench over Loadout Plans and Kiln Run Results. |
| **Manifold** | `products/manifold` | Intelligence selection/allocation. **Boundary only — no runtime yet.** |

The former `engineering-system` coordination repository is not a product;
its contracts, fixtures, decisions, and program records now live at
`contracts/`, `integration/`, and `program/` (history under
`program/historical/engineering-system/`).

The operating loop:

    Arsenal learns.   Bench evaluates.   Manifold selects.
    Loadout prepares. Kiln authorizes, executes, records, and proves.
    Temper presents and operates.

## What works today

- **Arsenal**: machine-checked asset library (registry, capability
  contracts, compiler → distributable Agent Skills), Bench evaluation
  harness with a 19-case corpus, method evaluation (repository-recon)
  including a real-repo benchmark, trust/knowledge/observability gates.
- **Loadout**: CLI + minimal web UI; bundled `repository-recon` and
  `verify-change` packs; compiles Work Envelope v0; runs against a
  deterministic simulated boundary or the real Kiln.
- **Kiln**: durable single-Run foundation (SQLite journal), artifact/evidence
  substrate, work-envelope supervision (`mix kiln supervise`), registered
  per-product verification commands, restart recovery.
- **Temper**: renders a real Loadout Plan + Kiln Run Result: authority,
  evidence, artifacts, and repository currentness — `n/a` with a reason
  when facts are missing.
- **Cross-product flow**: `integration/scenarios/repository-recon/run.sh`
  executes the Wave 3 golden path from this one checkout — Loadout plans,
  real Kiln supervises and records, Temper reads the result.

## What is not done

- Manifold has no implementation (by design, yet).
- `implement-change` (the Development Loop v0 golden path: one AI, one
  repository, one real code change) is the next milestone, not present.
- The full Wave 3 integration matrix (restart durability, negative cases)
  is specified in `integration/scenarios/repository-recon/` but only the
  golden path is automated here.
- Kiln's P1-S02+ runtime slices remain unauthorized/unimplemented, as in
  the source repository.

## Setup

Per-toolchain requirements are checked by:

```bash
./invariant doctor
```

Broadly: Git, Python 3.12+ (`pyyaml`, and `jsonschema` for Kiln's contract
validators), Node 20.10+ and npm, Elixir 1.20 / Erlang OTP (see
`products/kiln/mise.toml`), a C compiler, and Vale for Kiln's prose gate.

## Verify

```bash
./invariant check             # structural checks
./invariant check boundaries  # architecture-boundary policy
./invariant test arsenal      # per-product validation
./invariant test loadout
./invariant test kiln
./invariant test temper
./invariant test integration  # real cross-product golden path
./invariant test              # all of the above
```

Each product remains independently testable from its own directory with its
own canonical commands (see its README/AGENTS.md).

## What comes next

**Invariant Development Loop v0** — one AI, one repository, one real code
change: Temper → Loadout → Manifold (selection, once needed) → Kiln
bounded implementation → exact mutation → registered verification →
evidence → independent review → operator accept/revise → learning
observation back to Arsenal/Bench. The migration is the rebaseline that
makes this loop buildable in one place.

## Repository rules

- One Git root. No submodules. No nested checkouts.
- Architectural boundaries are encoded in `invariant.boundaries.json` and
  enforced by `./invariant check boundaries`.
- Historical evidence (evaluation records, authorization records, wave
  closeouts) is frozen provenance: do not rewrite it to look like it was
  produced inside the monorepo.
