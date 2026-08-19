# Repository Recon Integration Scenario

This directory contains the current cross-product Repository Recon proof and the broader historical Wave 3 acceptance material around it.

## What runs today

`run.sh` executes the automated golden path from one `invariant-system` checkout:

1. build Loadout and Temper when needed;
2. compile Kiln when needed;
3. create a real temporary Git repository from `proof-repo/`;
4. install Loadout's `repository-recon` capability;
5. compile a Plan with `--execution kiln`;
6. run through the real Kiln supervision boundary;
7. assert the canonical `engineering-system/run-result-envelope/v0` result is not simulated;
8. render the recorded result through Temper.

Run it with:

```bash
./integration/scenarios/repository-recon/run.sh
# or
./invariant test integration
```

Temporary state is removed on exit unless `KEEP_WORKDIR=1`.

## What does not run automatically here

`TEST-MATRIX.md` and `EXPECTED-RESULTS.md` preserve the broader Wave 3 acceptance design, including restart durability, negative cases, and dogfood. The current monorepo runner automates the golden path only.

Do not cite the existence of the matrix as evidence that every row was executed by this script.

## Directory layout

- `proof-repo/` — deterministic source fixture copied into a verifier-local real Git repository.
- `run.sh` — current monorepo golden-path runner.
- `TEST-MATRIX.md` — broader acceptance matrix and negative/restart cases.
- `EXPECTED-RESULTS.md` — expected contract/output shapes.

## Contract boundaries

This scenario does not create a new cross-product contract. It exercises the canonical contracts under `contracts/` and verifies the real-vs-simulated distinction explicitly.

Historical Wave 3 references to the former `engineering-system` repository are provenance, not instructions to restore the old repository topology.
