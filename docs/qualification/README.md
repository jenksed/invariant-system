---
title: Qualification Index
description: Executable scenarios, evidence commands, and reproduction paths for the current accepted candidate and pending promotions.
status: current
verified_at_commit: 1dcb5466debe6d443d6a0fb648ae8eea73d2b128
source_paths:
  - integration/scenarios/
  - products/kiln/scripts/
  - products/kiln/test/kiln/
  - products/temper-elixir/test/
  - products/temper/test/
  - invariant
audience:
  - developer
  - operator
---

# Qualification Index

This index points to executable scenarios and evidence commands. A claim that an integration is qualified must be traceable to one or more commands listed here, executed at a documented candidate SHA.

## Sandbox constraint

This Claude environment cannot execute Elixir/Mix commands in the Bash sandbox. All commands below must be run by an operator from a non-sandboxed shell. The qualified result is the operator's recorded output, not PASS-by-inspection.

## Repository status and boundary check

These run on every commit and are the cheapest sanity gate.

```bash
./invariant status
./invariant check boundaries
```

`./invariant check boundaries` enforces: single Git root, no submodules, `manifold_selection_only` (selector surface only), `temper_no_sibling_source_coupling`, and `single_canonical_contracts`.

Property proven: the repository state satisfies the documented boundary policy. It does NOT prove that any specific integration is fit to enter `dev` or `main`.

## Whole-system scenarios

These exercise the public cross-product boundary. They are the strongest "is the integrated system fit" tests.

### Repository Recon — golden path

```bash
./integration/scenarios/repository-recon/run.sh
```

Property proven: a real Loadout → Kiln → Temper chain produces a canonical Run Result Envelope and Temper renders it without inventing missing state.

### WP-09 — Temper RPC daemon

```bash
./integration/scenarios/wp-09-temper-rpc/run.sh
```

Property proven: `mix invariant serve` subprocess accepts the canonical RPC envelope, performs bounded lifecycle, and survives disconnect/reconnect.

### WP-09 — five-task E2E

```bash
./integration/scenarios/wp-09-five-tasks/run.py
```

Property proven: the five-task acceptance suite runs against a live daemon without bypassing authority.

### WP-08 — session restart

```bash
./integration/scenarios/wp-08-session-restart/run.sh
```

Property proven: a session survives restart and a new client reconstructs actionable state.

### Implement change (M11 E2 canonical chain)

```bash
./integration/scenarios/implement-change/run.sh
```

Property proven: the bounded Worker → verify → review → decide → apply chain reaches `EXACT_TARGET_STATE_OBSERVED` end-to-end through `Temper` via `patch-apply-governed`.

## M4-Q1C qualification plan

The following plan answers: is `11ba660` still fit to become the next `dev` baseline on top of `1dcb546`?

A prerequisite is checking out candidate `11ba660` in a clean worktree. None of these commands run inside the Claude Bash sandbox.

### 1. M4 targeted property tests

```bash
# M4-A truthful graph
MIX_ENV=test mix test products/kiln/test/kiln/m4_a_graph_projection_test.exs

# M4-P0 truth contract
MIX_ENV=test mix test products/kiln/test/kiln/m4_p0_truth_contract_test.exs

# Freshness
MIX_ENV=test mix test products/kiln/test/kiln/freshness_test.exs

# Why packet
MIX_ENV=test mix test products/kiln/test/kiln/why_packet_test.exs
```

Property proven: canonical identity preservation, three-valued knowledge, attention scopes, lifecycle scope, hydration invalidation race, reconnect convergence, backward provenance walk, attention state, "no nodes appear without a canonical source".

### 2. M3-R1 / M3-R2 dogfood regression

```bash
# M3-R1 deterministic dogfood lifecycle (matches historical M3_R1_FOCUSED 4/4 and M3_DOGFOOD 4/4)
MIX_ENV=test mix test products/kiln/test/kiln/m3_dogfood_lifecycle_test.exs

# M3-R2 governed apply
MIX_ENV=test mix test products/kiln/test/kiln/m3_r2_governed_apply_test.exs --include m3_r2_governed_apply

# M3-R2 real provider lifecycle (requires MINIMAX_API_KEY)
if [[ -n "${MINIMAX_API_KEY:-}" ]]; then
  MIX_ENV=test mix test products/kiln/test/kiln/m3_r2_real_provider_lifecycle_test.exs --include m3_r2_real_provider_lifecycle
fi

# M3-R2 fail-closed
MIX_ENV=test mix test products/kiln/test/kiln/m3_r2_verification_failure_test.exs --include m3_r2_fail_closed
```

Property proven: bounded identity continuity; bounded error propagation; canonical projection reconciliation after worker/verify/review/decide/apply; fail-closed on verifier FAIL; bounded review artifact; bounded patch-apply against a disposable worktree.

### 3. M3-DOGFOOD probe (real MiniMax required)

```bash
if [[ -n "${MINIMAX_API_KEY:-}" ]]; then
  products/kiln/scripts/m3_dogfood_probe.sh
fi
```

Property proven: real provider drives the canonical chain end-to-end; bounded reviewer preserves canonical contract; fail-closed works against a registered failing verifier; bounded apply produces a real source mutation in a disposable target.

This command is NOT runnable inside the Claude Bash sandbox. Operator must run from a shell with `MINIMAX_API_KEY` exported.

### 4. Temper / operator runtime (M4 elixir + M4 TS)

```bash
# Temper-elixir M4 surface
MIX_ENV=test mix test products/temper-elixir/test/cell_frame_test.exs \
                              products/temper-elixir/test/m4_live_projection_test.exs \
                              products/temper-elixir/test/m4_navigation_test.exs \
                              products/temper-elixir/test/m4_snapshot_test.exs \
                              products/temper-elixir/test/m4_why_dispatcher_test.exs \
                              products/temper-elixir/test/m4_why_result_test.exs

# Temper TS M4 surface
(cd products/temper && npm test -- tui.test.ts diff.test.ts home.test.ts motion-pulse.test.ts \
                                   work-decide.test.ts work-disconnect.test.ts live.test.ts \
                                   workbench.test.ts development-loop.test.ts)
```

Property proven: bounded operator surface; truthful projection; bounded diff; reconnect/recovery; work decision flow; motion and pulse projection; live stream; workbench harness; development-loop parity.

### 5. Accepted WP-09 regression coverage

```bash
# WP-09 owner gates (Kiln RPC lifecycle, activity hub, daemon)
MIX_ENV=test mix test products/kiln/test/kiln/m12_d_handlers_test.exs \
                  products/kiln/test/kiln/activity_hub_test.exs \
                  products/kiln/test/kiln/m12_d_kiln_daemon_test.exs \
                  products/kiln/test/kiln/m12_d_session_rpc_test.exs \
                  products/kiln/test/kiln/m12_d_scope_regression_test.exs \
                  products/kiln/test/kiln/m12_d_contract_drift_test.exs

# WP-09 acceptance scenarios
./integration/scenarios/wp-09-temper-rpc/run.sh
./integration/scenarios/wp-09-five-tasks/run.py
./integration/scenarios/wp-08-session-restart/run.sh
```

Property proven: WP-09 bounded RPC envelope + error preservation; activity stream discard/resync; scope-table exact-match; reviewer independence; patch preimage; approval-bypass rejection; full bounded chain `EXACT_TARGET_STATE_OBSERVED`; live reconnect; daemon lifecycle; five-task E2E; session restart.

### 6. Boundary / scope-integrity checks

```bash
./invariant check boundaries
```

Property proven: no nested Git root, no submodules, Manifold selection-only surface is the only permitted runtime surface, no Temper/Kiln source coupling outside their boundaries, no contract duplication.

### 7. Granularity check

The aggregate counts reported historically (`M4_KILN_TRUTH_PROJECTION = 47/47`, `M4_TEMPER_RUNTIME_OPERATOR = 39/39`) do NOT match the bit-exact test count at `11ba660` (49 kiln-related tests, 57 temper-elixir tests). The aggregate historical counts are NOT used as evidence. Property coverage comes from the named test files above.

## Promotion gate

Promotion of `11ba660` from `experiment/m4-a-graph-projection` into `dev` requires:

1. The seven commands above executed at candidate SHA with results recorded.
2. A fresh `LANE-EVIDENCE-M4-Q1C.md` capturing pass/fail per file plus canonical identities.
4. An explicit human `HUMAN_DECISION = ACCEPT` against the fresh evidence.
5. Boundary check green.

`MERGED_TO_DEV` follows `HUMAN_ACCEPTED` evidence. `RELEASED_TO_MAIN` follows an integrated-system qualification plus an explicit release decision.