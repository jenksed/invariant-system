# Proof Repository

Wave 3 deterministic integration-proof fixture.

This is a fresh, real-on-disk mini-repository with the right signals
for Loadout's Repository Recon v1 to produce a useful, deterministic
result. It must contain at least one honest unknown so the recon
output proves the unknown-surfacing invariant.

## Inventory

- `AGENTS.md` — repository-local agent rules
- `README.md` — repository overview
- `package.json` — primary Node manifest
- `tsconfig.json` — TypeScript build config
- `src/` — source root with at least `.ts` files
- `tests/` — test root with at least one test file
- `.github/workflows/ci.yml` — CI workflow
- `.gitignore` — generated boundaries
- `docs/architecture.md` — a docs architecture signal
- `package-lock.json` — package manager signal (npm)
- One deliberately ambiguous signal: no `CHANGELOG.md` and no
  explicit `OWNERS` file, so the integration proof can assert
  "architecture_ownership = unknown" rather than inferring.

## Hidden unknowns (deliberate)

The fixture intentionally lacks:

- `OWNERS` / `CODEOWNERS` — architecture ownership cannot be derived.
- `CHANGELOG.md` — release-history signal is unknown.
- Performance / benchmark budgets — not declared.

These force the recon output to surface honest unknowns.

## How the integration proof uses this

The proof repository is checked out to a known commit. The integration
verifier runs the golden path against this checkout. Restart proof:
restart Kiln, re-query the Run, confirm the durable facts reference
the same observed state.

## Mutation rules

Do not modify this directory in flight. If the integration proof
exercises a "mid-run state change" test, the proof creates a temp
sibling directory and mutates the sibling, not this one.
