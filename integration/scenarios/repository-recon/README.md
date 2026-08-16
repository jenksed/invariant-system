# Wave 3 Integration Proof

This directory holds the scaffolding for the Wave 3 integration proof.

The integration proof is the only place where the three products
(Arsenal, Loadout, Kiln) are exercised together against a real
target. It is the acceptance gate for Wave 3.

## Directory layout

- `proof-repo/` — deterministic mini-repository fixture with the right
  signals for Recon v1 to produce a useful result. Real `.git`, real
  commit, deliberately surfaced unknowns.
- `TEST-MATRIX.md` — the 8 negative cases + golden path + restart + dogfood
  that the verifier must run.
- `EXPECTED-RESULTS.md` — exactly what the proof must produce: the
  Recon v1 shape, the Plan shape, the Kiln Run Result Envelope shape.
- `run-logs/` — populated by the integration verifier after the
  proof runs. Not authored by anyone ahead of time.

## Authoring rules

- The spec for the proof lives in
  `engineering-system/program/wave-3/WAVE-3-FIRST-REAL-RUN.md`.
- The proof does NOT add a fifth cross-product contract.
- The proof does NOT widen capability scope beyond `repository-recon`.
- The proof MUST distinguish Simulated from Real Kiln.
- The proof MUST demonstrate restart durability.

## Running the proof

The integration verifier runs this proof from clean, built product
artifacts (no uncommitted working-tree code). The verifier:

1. Builds product CLIs from the exact merged heads.
2. Initializes the proof repository under a temp directory: `git init
   && git add -A && git commit -m "Initial deterministic proof-repo
   fixture"`. The fixture files themselves live in this engineering-system
   commit and are copied verbatim; the `.git` is verifier-local so the
   proof repo is a real-on-disk git repo without nesting inside the
   engineering-system `.git`.
3. Records the proof-repo HEAD commit for the integration proof log.
4. Runs the golden path (TEST-MATRIX §A).
5. Runs the restart durability proof (TEST-MATRIX §B).
6. Runs the 8 negative cases (TEST-MATRIX §C).
7. Runs the dogfood against one real project repo (TEST-MATRIX §D).
8. Writes the result to `run-logs/<run-id>.md` with the WAVE-3-SYSTEM-PROOF
   block populated.

## Acceptance

Wave 3 is complete only when:

- Every row in the test matrix produced the expected outcome.
- The press-worthy 30-second demo runs without caveats hiding simulation
  or ephemeral state.
- Restart reproduces the same durable facts.
- The honest QMR status (`experimental`) is reported truthfully.
