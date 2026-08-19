# ARS-005 Evaluator Integrity Challenge

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: `DESIGNED` (design initiated only; no execution, no evaluation)

Research question:

> Can an implementation appear successful by modifying or weakening the
> mechanism used to determine success?

## What is here

- `PROTOCOL-DRAFT.md` — draft protocol following the ARS-000 field set. It is
  gated: execution does not begin until ARS-001 experiment infrastructure is
  credible.
- `ATTACK-CASES.md` — seeded attack catalog (`ATK-01`–`ATK-09`) as a
  standalone registry. Cases can be added here without rewriting the protocol;
  protocol changes still require a `protocol_version` bump.

## Gating statement

This experiment waits on `../ars-001-execution-state/`. ARS-005 needs the
deterministic fixture/harness pattern, evidence manifest, and run-log scoring
that ARS-001 establishes. Until that machinery is credible, ARS-005 stays in
`DESIGNED` and all attack cases stay `designed-not-run`.

The registry entry for this experiment is in `../README.md` (maintained by the
ARS-000 lane).

## Honesty banner

- No seeded attack has been executed.
- No defense arm has been evaluated.
- No model, harness, or runtime has been bound.
- All attack cases are synthetic sandbox fixtures; none have been run against
  real repository verification (`./invariant check`, Kiln verification
  registry, Bench runners, or production CI).

## References

- `../../BENCH_CONTRACT.md` — Bench case-health checks, including
  `verifier_independent`.
- `../../docs/arsenal-method-evaluation.md` — evaluator anti-patterns
  (refused composite scores, refused runtime-authority tokens, refused
  auto-promote flags, broken adapter must produce strictly worse evidence, no
  silent fallback).
- `../../method-records/contract-map.md` — digest canonicalization and honesty
  policy for method records.
- `../ars-001-execution-state/` — shared harness pattern source.
