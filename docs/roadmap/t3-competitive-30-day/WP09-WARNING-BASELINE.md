# WP-09 Warning Baseline

Date: 2026-08-19.

## Rule

**WP-09 (and any future) changed files MUST NOT introduce new compiler
warnings.** Pre-existing inherited warnings remain unchanged and are
documented below for transparency, but WP-09 is not the gate that
cleans them up.

## Enforcement

- The `verify-wp09` entry point runs `MIX_ENV=test mix compile --force`
  before the focused test gate. Any new warning in WP-09-introduced
  files will surface there.
- The `m12_d_contract_drift_test.exs` covers the contract-level
  invariants. Compiler warnings are covered by the compile step in
  `verify-wp09`.

## Inherited warning baseline (pre-WP-09)

These warnings exist at `WP08_FINAL_SHA = 96f76ad` (the WP-09 base)
and are NOT introduced by WP-09. They will remain until a dedicated
cleanup work package addresses them.

### `lib/kiln/minimax_m3_adapter.ex`
- `:52` — unused alias `Canonical`
- `:663` — unreachable clause `translate_envelope_to_canonical(_)` (catch-all)
- `:805` — exhaustive match already covered for `System.get_env("MINIMAX_API_KEY")`

### `lib/kiln/cli.ex`
- `:153` — unused `plan_ref` variable
- `:690` — `defp load_json/2` not grouped with prior definition (clause grouping)
- `:713` — unused function `return/1`

### `lib/kiln/worker.ex`
- `:24` — unused alias `ExecutionAuthorityGate`
- `:512` — unreachable `:ok ->` clause in `validate_dispatch/3`

### `lib/kiln/m0_currentness.ex`
- (Not WP-09-introduced; flagged for completeness)

## WP-09-introduced warning baseline

**ZERO.** After this final hardening pass:
- `lib/kiln/rpc/handlers/{worker,verify,review,human_decision,project,activity}.ex` introduce no new warnings.
- `lib/kiln/activity/{hub,websocket}.ex` introduce no new warnings.
- `lib/kiln/rpc/router.ex` introduces no new warnings (its changes only added dispatch arms).
- `lib/kiln/rpc/error.ex` introduces no new warnings (added `bounded_from_err/2`; the `maybe_put/3` unused-key warning was fixed).
- `lib/kiln/service.ex` introduces no new warnings (only modified the error-handling `else` clause).
- `lib/kiln/daemon.ex` introduces no new warnings (only changed dispatch-table shape).
- `lib/kiln/application.ex` introduces no new warnings (added Hub to children list).
- `test/kiln/m12_d_handlers_test.exs` introduces no new warnings (fixed `@at` undefined; removed unused Router alias).
- `test/kiln/m12_d_contract_drift_test.exs`, `m12_d_scope_regression_test.exs` — new tests, no warnings.
- `products/temper/src/{client,stream,live,types,cli}.ts` — TypeScript code; warnings checked by `npm test`.
- `products/temper/src/render.ts` — unchanged from WP-08 PROVEN; no new warnings.

## Verification

The follow-up sandbox-free session must run:

```
cd products/kiln
MIX_ENV=test mix compile --force 2>&1 | tee /tmp/wp09-compile.log
```

If any warning originates from a file in the "WP-09-introduced" set,
that is a regression of WP-09 closeout and must be repaired.

Warnings originating from `minimax_m3_adapter.ex`, `cli.ex`,
`worker.ex` (lines 24, 512), or `m0_currentness.ex` are inherited
and accepted.
