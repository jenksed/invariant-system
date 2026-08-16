# Monorepo Migration

How the five Invariant repositories were consolidated into
`jenksed/invariant-system`.

## Sources and destinations

| Source repository | Branch | Source HEAD SHA | Destination |
| --- | --- | --- | --- |
| `jenksed/project-arsenal` | main | `c33f95121eb72518c75c3761f5428684517fc5a7` | `products/arsenal` |
| `jenksed/loadout` | main | `9ca0f4ec4c7a993c21ba8bf438be3c75a550421d` | `products/loadout` |
| `jenksed/kiln` | main | `e47c1da5fd13f7deaea4691e48dd0769c1e5ed6c` | `products/kiln` |
| `jenksed/temper` | main | `57e78b576105dc9c4051f133d0b4697b2e35a8a0` | `products/temper` |
| `jenksed/engineering-system` | main | `5dcb5d274350f9a23b0bb332c7ee20e81de66e28` | redistributed (see below) |

Machine-readable evidence: [`migration-source-manifest.json`](../migration-source-manifest.json).

## Import method

Each product repository was imported with **unsquashed `git subtree add`**
from a fresh clone of canonical `main`. Source commits remain reachable in
this repository's object database; no `--squash`, no submodules, exactly one
Git root. Verify with:

```bash
git cat-file -e c33f95121eb72518c75c3761f5428684517fc5a7^{commit}   # arsenal HEAD
git cat-file -e 9ca0f4ec4c7a993c21ba8bf438be3c75a550421d^{commit}   # loadout HEAD
git cat-file -e e47c1da5fd13f7deaea4691e48dd0769c1e5ed6c^{commit}   # kiln HEAD
git cat-file -e 57e78b576105dc9c4051f133d0b4697b2e35a8a0^{commit}   # temper HEAD
git cat-file -e 5dcb5d274350f9a23b0bb332c7ee20e81de66e28^{commit}   # engineering-system HEAD
```

Each source's full pre-migration log is available via its subtree head,
e.g. `git log c33f95121eb72518c75c3761f5428684517fc5a7`.

## engineering-system redistribution

`engineering-system` was a coordination repository, not a product. Its
history is preserved (subtree into `program/historical/engineering-system`,
then `git mv`); its active content moved by semantic ownership:

| Source path | Destination |
| --- | --- |
| `contracts/` | `contracts/` |
| `fixtures/` | `integration/fixtures/` |
| `demo/` | `integration/demo/` |
| `decisions/` | `program/decisions/` |
| `program/` | `program/` |
| `program/wave-3/integration-proof/` | `integration/scenarios/repository-recon/` |
| `README.md`, `AGENTS.md` | kept at `program/historical/engineering-system/` |

## Contract relocation and identity

The four v0 boundary contracts now live at `contracts/` with fixtures at
`integration/fixtures/`. Schema identity strings
(`engineering-system/work-envelope/v0`, `…/run-result-envelope/v0`,
`…/qualified-method-record/v0`, `…/learning-observation/v0`) are **stable
identifiers embedded in code, fixtures, digest-bound records, and frozen
evidence**; they were deliberately NOT renamed. See `contracts/README.md`.

## Active coupling repairs

- **Kiln submodule retired.** `.claude/dependencies/project-arsenal`
  (pinned `980a58d3…`) is replaced by the monorepo sibling tree
  `products/arsenal` (same Git root, same commit). The reviewed
  `.arsenal.lock` plan/package digests are byte-identical at the imported
  Arsenal HEAD and remain enforced by the rewritten
  `products/kiln/scripts/check-project-arsenal-dependency`.
  `.claude/skills/repository-truth` is still a symlink, now resolving into
  `../arsenal/distribution/agent-skills/repository-truth`.
- **Kiln script root resolution.** Kiln bash scripts derived the product
  root from `git rev-parse --show-toplevel`, which returns the monorepo
  root after import; they now derive it from their own location.
- **Verification profiles.** Kiln's `Kiln.Verification.Registry` and
  Loadout's `detectProfile()` keyed Arsenal's command profile off the
  directory basename `project-arsenal`; both now accept the monorepo
  basename `arsenal`. Registration digests are unchanged.
- **Developer-machine absolute paths** in two Arsenal tests were replaced
  with the monorepo layout (`integration/fixtures/…`,
  `products/loadout`).
- **Loadout `run --plan`** targets the repository given by `--repository`;
  the integration runner passes it explicitly.

## CI disposition

GitHub Actions only reads `.github/workflows/` at the repository root, so
all imported nested workflows were inert. They were ported to root
workflows and the nested copies removed (originals remain in history):

- `arsenal.yml` — the 14 non-Floci Arsenal gates, ported 1:1 (verified by
  scripted per-step diff, zero mismatches).
- `arsenal-floci.yml` — the 5 Floci workflows (12 jobs), ported 1:1.
- `loadout.yml`, `temper.yml` — the products' canonical npm gates.
- `kiln.yml` — Vale prose gate, Python contract validators, agent-assets,
  mix format/compile/xref/test, C toolchain, conditional P1-S01 slice gate
  (with `products/kiln/` prefix stripping for applicability detection).
  The PR-only branch-governance steps (`agent-preflight` trusted-authority
  checks) were **not** ported: they enforce the standalone Kiln repo's
  branch/work-package governance, which has no monorepo equivalent yet.
  The behavior tests (`test-agent-preflight`) still run.
- `integration.yml` — boundary checks plus the repository-recon golden
  path.

## Historical references intentionally left unchanged

Frozen evidence keeps its original references: wave baselines and
closeouts (`program/wave-*`), Kiln work/authorization records
(`products/kiln/docs/`), Bench corpora and Wave 5 benchmark pins
(`products/arsenal/evaluation/`), field-trial records, and schema identity
strings. These record what happened in the multi-repo era; rewriting them
would falsify provenance. Note: `program/launch/SIMULTANEOUS-LAUNCH-PROMPT.md`
records a since-superseded owner rule against monorepos — kept as
historical record; the owner authorized this consolidation explicitly.

## Verification process

1. Pre-migration baselines per product on the source clones.
2. Post-migration validation from monorepo paths (`./invariant test`,
   `./invariant check`, `./invariant check boundaries`).
3. Cross-product proof:
   `integration/scenarios/repository-recon/run.sh` (Loadout → real Kiln →
   Temper) from this single checkout.
4. History reachability checks (above).

Results and classifications: [MIGRATION-REPORT.md](../MIGRATION-REPORT.md).
