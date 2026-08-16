# Proof Repository AGENTS.md

This repository is a deterministic fixture used by the Wave 3
integration proof. It is NOT a real product. It exists so that:

- Loadout's Repository Recon v1 produces deterministic output
- Arsenal's evaluation corpus can be run against a stable surface
- The integration test matrix can be replayed after restart

Proof repository content rules:

- The fixture is read-only. No instrumentation writes back.
- Real commit. Real .git. Real HEAD.
- Real AGENTS.md, README, package.json, tests, CI workflow.
- Source roots and docs architecture are real on-disk directories.
- At least one deliberately ambiguous/unresolved point so the recon
  output surfaces an honest unknown.

The integrator MUST NOT modify this directory in flight.
