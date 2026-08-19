# ARS-001 Execution-State Validity Challenge

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Research program: `arsenal-foundation-wave-1`

## Honesty banner

This pilot uses a **deterministic scripted policy**, not a model.  The evidence
discriminates fixture/harness mechanics and the three condition mechanisms
(transcript reconstruction, generated-summary reconstruction, explicit
execution-state).  Any conclusion about whether an explicit execution-state
surface improves real agent outcomes over transcript reconstruction requires a
future protocol version with model-in-the-loop repetitions and a declared seed
policy.

## Directory layout

```
.
├── PROTOCOL.md              experiment protocol (ARS-000 field set)
├── README.md                this file
├── build_fixture.py         deterministic fixture generator
├── harness.py               deterministic experiment runner
├── metrics.py               operational metric definitions
├── fixtures/                generated synthetic task, world, oracle, manifest
│   ├── repo/
│   ├── task.json
│   ├── world.json
│   ├── oracle.json
│   └── fixture_manifest.json
└── evidence/
    └── pilot-0/
        ├── raw/             per-cell JSONL run logs
        └── results.v0.json  aggregated metrics and provenance
```

## How to run

All commands are idempotent and deterministic.

```bash
cd products/arsenal/evaluation/experiments/ars-001-execution-state

# 1. Generate fixtures
python3 build_fixture.py

# 2. Run the pilot
python3 harness.py run

# 3. Verify run-twice digest equality
python3 harness.py determinism-check
```

`harness.py determinism-check` copies the experiment source into two temporary
directories, builds fixtures and runs the pilot in each, then compares the
fixture digest and the run digest.  It prints `PASS` only if both are identical.

## Outputs

- `fixtures/fixture_manifest.json` records per-file sha256 digests and a
  `fixture_digest` computed by canonical JSON digest with a 64-zero placeholder
  for the self-digest field.
- `evidence/pilot-0/raw/*.jsonl` contains per-cell events
  (`C0`/`C1`/`C2` x `P-01`..`P-12`).
- `evidence/pilot-0/results.v0.json` aggregates primary and secondary metrics,
  provenance, limitations, and a `run_digest` computed with the same placeholder
  rule.
