---
title: Qualification Index
description: Tiered qualification plan for accepted candidates. Mix commands execute from their owning project. Required gates fail closed.
status: current
verified_at_commit: 11ba660037f33c87f8bbbf671b4b94873d7e6b3f
source_paths:
  - products/kiln/mise.toml
  - products/kiln/test/kiln/
  - products/temper-elixir/test/
  - products/temper/test/
  - integration/scenarios/
  - invariant
audience:
  - developer
  - operator
---

# Qualification Index

This index names the exact qualification groups, the commands that exercise them, the property each command proves, and how to record evidence. A claim that a candidate is fit to enter `dev` must be traceable to one or more commands below, executed at a documented candidate SHA, with the recorded result.

## Sandbox and runtime constraint

The Claude Bash sandbox cannot execute `mix compile`/`mix test` and cannot switch to a pinned Erlang/Elixir runtime via `mise exec`. **All commands below are operator-only.** No command is claimed PASS by inspection.

The candidate pins in `products/kiln/mise.toml`:

```text
[tools]
erlang = "28.4"
elixir = "1.20.2-otp-28"
vale = "3.14.2"
```

Node: `>=22.0.0` per `products/temper/package.json`. `mise` resolves Erlang/OTP 28 and Elixir 1.20.2 (compiled with Erlang/OTP 28).

Final qualification evidence MUST run under the pinned runtime:

```bash
mise --cd products/kiln exec -- mix --version
# expect: Mix 1.20.2 (compiled with Erlang/OTP 28)
```

Earlier diagnostic runs under OTP 29 remain useful diagnostic evidence but are NOT final promotion evidence.

## Pre-qualification proof of state

A fresh, detached worktree is required. The qualification must begin by proving:

```bash
# 1. exact candidate SHA
git rev-parse HEAD
# expect: 11ba660037f33c87f8bbbf671b4b94873d7e6b3f

# 2. clean git status
git status --short
# expect: empty output

# 3. Erlang 28.4, Elixir 1.20.2-otp-28
mise --cd products/kiln exec -- erl -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().' -noshell
# expect: 28
mise --cd products/kiln exec -- elixir --version
# expect: Elixir 1.20.2 (compiled with Erlang/OTP 28)

# 4. Node 22.x
node --version
# expect: v22.x.x

# 5. monorepo status
./invariant status

# 6. boundary check (deterministic, no network)
./invariant check boundaries
# expect: ok for every check; no nested .git
```

If any of these fails, stop and record the failure. Do not proceed.

## Tier 1 — deterministic / local qualification

Tier 1 is fully reproducible, requires no provider credentials, and proves the bounded deterministic properties of the candidate. Every Tier 1 command must run from the project that owns the source under test.

### Group 1.1 — M4 graph projection and truth contract

```bash
# Run from products/kiln
( cd products/kiln && mise exec -- mix test test/kiln/m4_a_graph_projection_test.exs )
( cd products/kiln && mise exec -- mix test test/kiln/m4_p0_truth_contract_test.exs )
( cd products/kiln && mise exec -- mix test test/kiln/freshness_test.exs )
( cd products/kiln && mise exec -- mix test test/kiln/why_packet_test.exs )
```

Property proven: canonical identity preservation, three-valued knowledge, three attention scopes, lifecycle scope (no cross-attempt stitching), exact canonical edge identity, hydration invalidation race, reconnect convergence, backward provenance walk, attention state correctness, "no graph node appears without a canonical source".

### Group 1.2 — M3-R1 / M3-R2 dogfood regression (deterministic)

```bash
( cd products/kiln && mise exec -- mix test test/kiln/m3_dogfood_lifecycle_test.exs )
```

Property proven: bounded identity continuity through worker → verify → review → decide → apply; bounded error propagation when identities are violated; canonical projection reconciliation after the bounded chain. **Disposable Git fixture MUST remain under `System.tmp_dir!/0`; the source checkout MUST NOT gain `products/support/` or any nested `.git`.** The integration-hygiene regression test guards this.

### Group 1.3 — Integration hygiene regression

```bash
( cd products/kiln && mise exec -- mix test test/kiln/integration_hygiene_regression_test.exs )
```

Property proven: source-checkout isolation (no `products/*/.git` after lifecycle), single source owner for `Temper.CellFrame`, `products/kiln/lib/temper/` does not contain Temper rendering sources.

### Group 1.4 — Temper-Elixir M4 surface

```bash
( cd products/temper-elixir && mise exec -- mix deps.get )
( cd products/temper-elixir && mise exec -- mix test test/cell_frame_test.exs test/m4_live_projection_test.exs test/m4_navigation_test.exs test/m4_snapshot_test.exs test/m4_why_dispatcher_test.exs test/m4_why_result_test.exs )
```

Property proven: bounded cell buffer + byte diff, navigation, snapshot stability, why dispatcher + result, live projection. Exactly one `defmodule Temper.CellFrame` source is compiled (no BEAM redefinition warning).

### Group 1.5 — Temper TypeScript M4 surface

```bash
( cd products/temper && mise exec -- npm ci )
( cd products/temper && mise exec -- npm test )
```

Property proven: deterministic TUI screen rendering, diff surface, motion/pulse projection, work-decide flow, reconnect and recovery, workbench harness, development-loop parity.

### Group 1.6 — Final scope check

```bash
./invariant check boundaries
git status --short
find . -mindepth 2 -name .git -not -path './.git/*'
```

Property proven: monorepo root is the only Git root, no nested Git, clean worktree.

If any Tier 1 group fails, stop, record the failure, and do not fix forward inside the qualification worktree.

## Tier 2 — integrated / public-boundary qualification

Tier 2 exercises the canonical cross-product public surface, against a real temporary repository. Tier 2 must execute each scenario from its `run.sh`.

### Group 2.1 — Repository Recon golden path

```bash
integration/scenarios/repository-recon/run.sh
```

Property proven: real Loadout → Kiln → Temper chain produces a canonical Run Result Envelope and Temper renders it without inventing missing state.

### Group 2.2 — WP-09 acceptance regression

```bash
integration/scenarios/wp-09-temper-rpc/run.sh
integration/scenarios/wp-09-five-tasks/run.py
integration/scenarios/wp-08-session-restart/run.sh
```

Property proven: bounded RPC envelope + error preservation; activity stream discard/resync; scope-table exact-match; reviewer independence; patch preimage (P3); approval-bypass rejection; full bounded chain `EXACT_TARGET_STATE_OBSERVED`; live reconnect across real Cowboy 2.18; daemon lifecycle; five-task E2E; session restart.

### Group 2.3 — Implement-change canonical chain

```bash
integration/scenarios/implement-change/run.sh
```

Property proven: bounded Worker → verify → review → decide → apply chain reaches `EXACT_TARGET_STATE_OBSERVED` through `Temper` via `patch-apply-governed`.

If any Tier 2 group fails, stop and record.

## Tier 3 — explicit real-provider qualification

Tier 3 requires `MINIMAX_API_KEY` exported in the calling environment. **Tier 3 commands are NEVER silently skipped.** Promotion qualification must either execute Tier 3 and record its result, or hold the promotion and record a `MORE_REPOSITORY_EVIDENCE_REQUIRED` decision.

### Group 3.1 — M3-DOGFOOD probe

```bash
# Pre-condition: MINIMAX_API_KEY exported
[[ -n "${MINIMAX_API_KEY:-}" ]] || { echo "MINIMAX_AGENT_CREDENTIAL=UNSET"; exit 2; }
products/kiln/scripts/m3_dogfood_probe.sh
```

Property proven: real MiniMax provider drives the canonical chain end-to-end; bounded reviewer preserves canonical contract; fail-closed works against a registered failing verifier; bounded apply produces a real source mutation in a disposable target.

### Group 3.2 — Real-provider lifecycle

```bash
[[ -n "${MINIMAX_API_KEY:-}" ]] || { echo "MINIMAX_AGENT_CREDENTIAL=UNSET"; exit 2; }
( cd products/kiln && mise exec -- mix test test/kiln/m3_r2_real_provider_lifecycle_test.exs --include m3_r2_real_provider_lifecycle )
( cd products/kiln && mise exec -- mix test test/kiln/m3_r2_governed_apply_test.exs --include m3_r2_governed_apply )
( cd products/kiln && mise exec -- mix test test/kiln/m3_r2_verification_failure_test.exs --include m3_r2_fail_closed )
```

Property proven: real provider drives Worker → verify → independent bounded reviewer → waiting_for_user → human ACCEPT → ready; governed apply against a disposable checkout; fail-closed on verifier FAIL.

## Recording evidence

A promotion-bound record MUST capture, per Tier 1/2/3 group:

```text
CANDIDATE_SHA         = <exact SHA from `git rev-parse HEAD`>
RUNTIME               = <Erlang/OTP version> / Elixir <version> / Node <version>
DATE                  = <ISO-8601 timestamp>
OPERATOR              = <operator identifier>
TIER_<N>.<M>          = PASS or FAIL
  command             = <exact command line>
  exit_code           = <0 = PASS, non-zero = FAIL>
  canonical_identities = <if applicable>
  log_artifact         = <path to captured stdout/stderr>
```

A `LANE-EVIDENCE-M4-Q1C.md` written from this record replaces the historical aggregate counts (`47/47`, `39/39`) which are not bit-exact to the candidate's test inventory and are NOT accepted as evidence.

## Promotion gate

Promotion of `11ba660` (or its successor repair candidate) from `experiment/m4-a-graph-projection` (or the repair branch) into `dev` requires:

1. Tier 1 PASS for every group, recorded with exit codes and runtime.
2. Tier 2 PASS for every group, recorded with scenario stdout.
3. Tier 3 PASS for every group, OR an explicit `MORE_REPOSITORY_EVIDENCE_REQUIRED` decision documented in the evidence record.
4. `./invariant check boundaries` green at the end of Tier 1.
5. `git status --short` empty at the end of Tier 1.
6. An explicit human `HUMAN_DECISION = ACCEPT` against the recorded evidence.

`MERGED_TO_DEV` follows `HUMAN_ACCEPTED` evidence. `RELEASED_TO_MAIN` follows an integrated-system qualification plus an explicit release decision.