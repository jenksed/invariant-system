# Migration Report — invariant-system

# Verdict

READY_WITH_KNOWN_LIMITATIONS

The limitations are environmental (a missing local Python `jsonschema`
package) and deferred governance porting — none involve history loss,
corrupted product behavior, or ambiguous source truth.

# Sources

| repository | branch | source SHA | destination |
| --- | --- | --- | --- |
| jenksed/project-arsenal | main | c33f95121eb72518c75c3761f5428684517fc5a7 | products/arsenal |
| jenksed/loadout | main | 9ca0f4ec4c7a993c21ba8bf438be3c75a550421d | products/loadout |
| jenksed/kiln | main | e47c1da5fd13f7deaea4691e48dd0769c1e5ed6c | products/kiln |
| jenksed/temper | main | 57e78b576105dc9c4051f133d0b4697b2e35a8a0 | products/temper |
| jenksed/engineering-system | main | 5dcb5d274350f9a23b0bb332c7ee20e81de66e28 | contracts/, integration/, program/, program/historical/engineering-system/ |

Evidence: `migration-source-manifest.json`.

# History Verification

Unsquashed `git subtree add` for all five sources. Verified reachable in
this repository (`git cat-file -e <sha>^{commit}`):

- every source HEAD SHA (table above), and
- one earlier commit per source (arsenal `0acbad2f…`, loadout `c29a1df7…`,
  kiln `bd2c9bcf…`, temper `1ec41bdc…`, engineering-system `67c23a0c…`).

Full pre-migration logs are reachable via each subtree head
(e.g. `git log c33f9512…`). No squashing, no submodules, one Git root.

# Baseline Comparison

| component | before | after | classification |
| --- | --- | --- | --- |
| Arsenal gates (audit, source-model, governance, capability, method-record, Bench validate+tests, evaluate, adapter, wave5, compiler validate/verify+tests, graph, knowledge, trust, qualification) | PASS (all exit 0) | PASS (all exit 0) | PASS — preserved |
| Arsenal method-record contract-compat test | PASS (dev-machine path) | PASS (monorepo `integration/fixtures/`) | improved — no machine-specific path |
| Loadout `npm run ci` (format, lint, typecheck, 129 tests, contracts, build) | PASS | PASS | PASS — preserved |
| Kiln `mix test` | 685/689; 4 failed: `jsonschema` not installed locally | 685/689; identical 4 failures | ENVIRONMENT_BLOCKED — preserved; remedy: `pip install -r products/kiln/requirements/conformance.txt` (CI installs it) |
| Kiln mix format/compile/xref | PASS | PASS | PASS — preserved |
| Temper `npm run ci` (13 tests) | PASS | PASS | PASS — preserved |
| engineering-system | NOT_RUN — no executable content (docs/fixtures only) | n/a | NOT_RUN_WITH_REASON |

Environment: Python 3.14.6, Node v22.23.1, npm 10.9.8, Elixir 1.20.2 /
OTP 29 (source pins OTP 28.4 via mise; CI uses 28.4), git 2.50.1.

# Structural Changes

- Monorepo root initialized; products imported under `products/`.
- `engineering-system` redistributed: contracts → `contracts/`, fixtures →
  `integration/fixtures/`, demo → `integration/demo/`, decisions →
  `program/decisions/`, program → `program/`, wave-3 integration proof →
  `integration/scenarios/repository-recon/`; root README/AGENTS kept at
  `program/historical/engineering-system/`.
- New: `products/manifold/` (boundary only), root `./invariant`,
  `invariant.boundaries.json`, root `README.md`/`AGENTS.md`, root
  `.github/workflows/`.

# Active Coupling Repairs

- Kiln's pinned project-arsenal **submodule retired** → monorepo sibling
  `products/arsenal`; verifier rewritten, reviewed digests unchanged and
  still enforced; skill symlink repointed; `.gitmodules` removed.
- Kiln scripts locate the product root from their own path (were bound to
  git toplevel).
- Kiln verification registry + Loadout `detectProfile()` accept the
  monorepo basename `arsenal` for the `project-arsenal` profile.
- Two hardcoded `/Users/jenksed/...` test paths replaced with monorepo
  layout.
- Frozen evidence (wave records, SHAs, GitHub run links, schema identity
  strings) intentionally NOT rewritten.

# Contracts

Canonical v0 contracts (Work Envelope, Run Result Envelope, Qualified
Method Record, Learning Observation) live at `contracts/` with fixtures at
`integration/fixtures/`. Schema identity strings (`engineering-system/…`)
kept verbatim as stable identifiers. Products keep local adapters; no
shared package was created.

# Bench

Bench remains inside Arsenal at `products/arsenal/evaluation/` — corpora,
qualifications, method records, Wave 5 benchmark, receipts — byte-identical
to source (path relocation only). No `products/bench` created. Bench
provenance (source repo, pinned commits) is preserved in the records
themselves.

# Manifold

`products/manifold/README.md` only: purpose, inputs, output, boundary vs
Bench/Kiln, explicit non-authority list. No runtime, no speculative
architecture. `./invariant check boundaries` fails if Manifold gains
non-documentation files.

# CI

Six root workflows: `arsenal.yml` (14 gates), `arsenal-floci.yml` (12
jobs), `loadout.yml`, `temper.yml`, `kiln.yml`, `integration.yml`
(boundaries + golden path). Nested product workflows removed (inert under
GitHub Actions; preserved in history). Kiln's PR branch-governance steps
were not ported (no monorepo governance model yet); its behavior tests and
the P1-S01 conditional slice gate are retained.

# Root Developer Experience

`./invariant status | doctor | check | check boundaries | test [product]`.
Doctor checks git/gh/python3(pyyaml, jsonschema)/node/npm/mix/cc/vale/jq
and installs nothing. Product tests delegate to canonical commands.
Boundary checks: single Git root, no submodules, documentation-only
Manifold, Temper source isolation, single canonical contract copies.

# Integration Proof

`integration/scenarios/repository-recon/run.sh` — executed from this
checkout: Loadout installs repository-recon into the proof-repo fixture,
compiles a Plan bound to the real Kiln boundary, `mix kiln supervise`
grants `git.read` authority, completes the Run, records 1 Evidence + 2
Artifact references, emits `engineering-system/run-result-envelope/v0`
(verified non-simulated), and Temper renders the result as CURRENT.
Result: PASS. No sibling clones involved.

# Known Limitations

- 4 Kiln `JsonRendererTest` tests fail without the Python `jsonschema`
  package (pre-existing, environment-only; CI installs
  `requirements/conformance.txt` and is unaffected).
- Kiln's branch/work-package PR governance (`agent-preflight` trusted
  authority flow) has no monorepo equivalent yet; the script and its tests
  remain, the CI wiring does not.
- The full Wave 3 integration matrix (restart durability, 8 negative
  cases, dogfood) is specified in `integration/scenarios/repository-recon/`
  but only the golden path is automated.
- Kiln registry references `scripts/test-wave6-verify-bench.py`, which
  does not exist on Arsenal main — pre-existing source inconsistency,
  untouched.
- Local run used OTP 29 vs the pinned 28.4 (mix.exs constraint satisfied;
  CI pins 28.4).

# Next Recommended Product Work

**Invariant Development Loop v0 — the implement-change golden path**: one
AI, one repository, one real code change. Temper → Loadout → Kiln bounded
implementation → exact mutation → registered verification → evidence →
independent review → owner accept/revise → learning observation →
Arsenal/Bench. The monorepo topology, the verified Loadout→Kiln→Temper
golden path, and the verification-command registries are the foundation;
`verify-change` exists as a Loadout pack and Kiln registry family, so v0
builds on working machinery rather than new speculation.
