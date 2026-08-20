---
title: Two-Track Candidate Qualification
description: Executed evidence and verdicts for the pre-Graph A0 and Graph-enabled B0 candidates.
status: partial
verified_at_commit: 5e7b0134d5e901603904ca5b1f4f3f16d4a472ec
source_paths:
  - invariant
  - invariant.boundaries.json
  - products/kiln/
  - products/temper/
  - products/temper-elixir/
  - integration/scenarios/
  - docs/m4-graph-ownership-audit.md
  - scripts/two-track
audience:
  - developer
  - operator
---

# Two-Track Candidate Qualification

## Verdict

```text
MAIN_CANDIDATE_A0=0c6ed3ad39c6a9a8808a37c8728c56f3dcd254af
MAIN_VERDICT=NOT_QUALIFIED

DEV_CANDIDATE_B0=5e7b0134d5e901603904ca5b1f4f3f16d4a472ec
DEV_VERDICT=NOT_QUALIFIED
```

The history supports “A0 is pre-Graph; B0 is its Graph descendant.” The
acceptance statement that both are qualified Lab tracks is not yet proven.
This qualification run did not justify a release claim. A later owner-authorized
publication of documentation/tooling successors on the two branch lines does
not change these historical verdicts.

The repeatable entry point is:

```bash
./invariant track create main /path/to/invariant-main-a0
./invariant track create dev /path/to/invariant-dev-b0
./invariant track test main /path/to/invariant-main-a0 qualification --output /path/to/evidence/main
./invariant track test dev /path/to/invariant-dev-b0 qualification --output /path/to/evidence/dev
```

The helper verifies the exact candidate and clean tree, removes
`MINIMAX_API_KEY`, records every gate independently, and returns nonzero when
any gate fails. Its final gate also detects test-created source contamination.
Canonical dependency setup is logged as part of the relevant product/Graph
gate and may require package-network access on a fresh machine. The helper does
not claim that a host runtime matches the repository pin.

Tests ran on 2026-08-20 in clean detached worktrees on Darwin arm64. The host
was Node 26.3.0, npm 11.16.0, Elixir 1.20.2 compiled with Erlang/OTP 29, and Mix
1.20.2/OTP 29. The repository requires OTP 28 for final qualification, so even
passing Elixir evidence is diagnostic until repeated under the pin. Provider
credentials were removed from direct Mix test commands; no live provider call
was made and no secret value was printed.

The first sandboxed root runs encountered a `tsx` IPC `EPERM`. The identical
commands were rerun with the required local process permissions; the table
records those reruns, which progressed through TypeScript and exposed the
genuine Kiln formatting failure. The sandbox incident is not counted as a
candidate defect.

## Executed evidence

| Candidate | Command | Exit | Result |
| --- | --- | ---: | --- |
| A0 | `./invariant status` | 0 | Exact detached candidate, clean before tests |
| A0 | `./invariant doctor` | 1 | Printed prerequisites as present but returned 1 due to the later-fixed root parser defect |
| A0 | `./invariant check` | 0 | Structure passed before tests |
| A0 | `./invariant check boundaries` | 0 | Declared boundary rules passed |
| A0 | `./invariant test` | 1 | Arsenal and Loadout passed; stopped at Kiln `mix format --check-formatted` failure |
| B0 | `./invariant status` | 0 | Exact detached candidate, clean before tests |
| B0 | `./invariant doctor` | 0 | Passed; safely reported credential presence by length and reported OTP pin mismatch |
| B0 | `./invariant check` | 0 | Structure passed before tests |
| B0 | `./invariant check boundaries` | 0 | Declared rules passed, but missed the unregistered Elixir Temper cross-product dependency |
| B0 | `./invariant test` | 1 | Arsenal and Loadout passed; stopped at Kiln `mix format --check-formatted` failure |
| A0, B0 | `./invariant test loadout` | 0 | 26 test files, 140 tests passed on each; contract validation/build passed |
| A0, B0 | `./invariant test temper` | 0 | 110/110 TypeScript Temper tests passed on each |
| A0, B0 | `./invariant test manifold` | 0 | 17/17 selection-only tests passed on each |
| A0, B0 | `./invariant test contracts` | 0 | M0 conformance passed: 26 positive, 14 mandatory negative, manifest 40 |
| A0, B0 | `./invariant test integration` | 0 | Real Loadout→Kiln→Temper repository-recon path passed; `simulated=False` |
| A0 | `(cd products/kiln && env -u MINIMAX_API_KEY mix test)` | 2 | 1,064 tests, 8 failures; 1,056 passed |
| B0 | `(cd products/kiln && env -u MINIMAX_API_KEY mix test)` | 2 | 1,115 tests, 6 failures; 1,109 passed |
| B0 | focused Graph/Kiln test command below | 0 | 50/50 passed |
| B0 | `(cd products/temper-elixir && mix test)` | 0 | 68/68 passed after `mix deps.get` |

The focused Graph command was:

```bash
cd products/kiln
env -u MINIMAX_API_KEY mix test \
  test/kiln/m4_a_graph_projection_test.exs \
  test/kiln/m4_p0_truth_contract_test.exs \
  test/kiln/freshness_test.exs \
  test/kiln/header_priority_test.exs \
  test/kiln/why_packet_test.exs \
  test/kiln/integration_hygiene_regression_test.exs
```

This group covers Graph identity/edge truth, projection determinism,
freshness/currentness, header priority, WhyPacket determinism, and the repaired
integration-hygiene regression. Temper Elixir's isolated suite covers work-map,
proof/inspector, live projection, navigation, Why dispatch/result, CellFrame,
and committed snapshots. Passing those groups does not cure the source-boundary
violation or shared-core failures.

## Reconciliation helper verification

The new operator surface was exercised rather than documented by inspection:

| Command | Result |
| --- | --- |
| `./invariant track doctor LAB_ROOT` | PASS against the locally available Lab: both objects, ancestry, pre-Graph/Graph topology, required launcher surfaces, and Lab `lab-switch` found |
| `./invariant track create main …` / `create dev …` | PASS: clean detached worktrees at the exact A0/B0 SHAs |
| `./invariant track test main … smoke` | Expected FAIL: A0 doctor exit 1; status/structure/boundaries/final-clean all passed and all logs were retained |
| `./invariant track test dev … smoke` | PASS: all five gates, including final clean-tree check |
| `./invariant run --help` | PASS: delegates to the bounded `temper-live` launcher |
| `./invariant test graph` | FAIL: focused Kiln Graph group passed 50/50, then the newly registered Temper-Elixir format gate identified unformatted source |
| `./invariant test runtime` | FAIL: session start/query and digest identity passed, but WP-08 restart failed because the killed daemon's port did not release within the bounded window |
| `./integration/scenarios/wp-09-temper-rpc/run.sh` | PASS independently: auth/scope, project/session/activity RPC, bounded error, daemon restart, and reconstructed session identity |

`bash -n`, ShellCheck, and `git diff --check` pass for the new/modified shell
surface. The reconciliation boundary gate now intentionally returns 1 and
names the exact `products/temper-elixir/mix.exs` path dependency. These failures
are actionable candidate evidence, not helper malfunctions.

## Failures and limitations

A0's eight Kiln failures were:

- missing exported M0 currentness function;
- stale date-bound M3 dogfood eligibility expectations;
- a provider fallback expectation;
- `human.decide` invalid-input behavior returning missing-fields detail;
- deferred-subsystem boundary detection of `DogfoodAdapter` repository-source
  access; and
- three provider-labelled tests attempting localhost and receiving connection
  refusal despite the credential being unset.

B0 repairs the currentness and dogfood-date failures but retains the other six.
The three localhost attempts reveal test isolation/configuration defects; they
are not live-provider evidence. Both candidates also fail formatting before the
root runner reaches canonical warnings-as-errors compilation. Direct Mix tests
compiled with warnings, including M4 code, so compilation qualification remains
open.

Dependency resolution reported three known `cowlib 2.19.0` advisories (one low,
two medium). B0 documents the issue in
`docs/security/ADVISORY-COWLIB-2.19.0.md` but does not remove the vulnerable
dependency. This is a general remediation gate, not Graph behavior.

Tests created local artifacts. A0 produced Python cache and a nested
`products/support/.git`, after which structure checks fail; B0 produced
`erl_crash.dump` and Python cache. The B0 integration-hygiene repair detects the
former class. The reconciliation `.gitignore` change suppresses safe caches and
crash/local config, but intentionally does not hide `products/support` or all
project tooling directories.

## Acceptance checklist

### A0 successor required before `main`

- backport the general root/integration hygiene repairs from B0;
- resolve all Kiln failures and formatting/warnings-as-errors under OTP 28;
- repair or explicitly isolate provider-labelled tests so credential absence
  cannot trigger network/localhost behavior;
- address the `cowlib` advisories and rerun dependency/security gates;
- rerun full root, product, recovery/restart, daemon/RPC, and integration gates
  from a clean worktree; and
- perform a clean Invariant Lab install/start/restart exercise with recorded
  source identity, state path, and token/config handling.

No Graph dependency is required by A0; that acceptance property is satisfied
by tree inspection, subject to rechecking the successor.

### B0 successor required before `dev`

- satisfy every shared-core A0-successor gate;
- remove the direct `temper-elixir`→Kiln source dependency in favor of an
  accepted contract/public interface, or explicitly keep the directory as an
  excluded experiment;
- register whichever Graph operator surface is promoted in root structure,
  boundary, format, compile, and test gates;
- resolve acknowledged Kiln/Temper placement smells for operator-only
  freshness/labels/attention or formally accept a narrow contract owner;
- repeat the focused Graph and snapshot/navigation suites under OTP 28; and
- wire the promoted Graph surface into a separate Lab target and prove public
  RPC, restart convergence, source identity, and provider-independent behavior.

## Lab-readiness assessment

Lab was inspected but not modified or executed.

**A0 — READY_WITH_CHANGES.** Lab can snapshot a local source worktree, records
path/branch/HEAD/dirty/tree digest, builds a Docker image, starts real Kiln and
TypeScript Temper across HTTP/WebSocket, uses an explicit SQLite state volume,
and externalizes tokens/config. The real integration supports the public-boundary
hypothesis and no Graph code is required. A0 is not a qualified reference until
its common gates are fixed and the actual clean Lab install/start/restart run is
captured.

**B0 — NOT_READY for Graph comparison.** Its shared TypeScript system can use
the same snapshot path, but Lab would not exercise `products/temper-elixir` or
its Graph views. Adding B0 today would label a non-Graph runtime as the Graph
track and carry the source-boundary defect. A small later Lab change should add
an explicit Graph target only after the operator implementation and public
interface are decided and qualified.

## Recommendation

Create successor candidates rather than blessing the historical tips:

```text
A0 0c6ed3a -> A1: common repairs + qualification fixes + docs/hygiene
B0 5e7b013 -> B1: same common guarantees + Graph boundary/promotion repair
```

Do not describe either published branch as runtime-qualified until successor
candidates have exact committed SHAs, clean pinned-runtime evidence, and human
acceptance. Documentation/tooling publication is deliberately separate from
that qualification decision.

The reconciliation successor now registers `temper-elixir` in root status and
test dispatch, provides `./invariant test graph` and `./invariant test runtime`,
and makes a direct Temper-Elixir→Kiln source reference fail
`./invariant check boundaries`. That closes the gate-discovery defect; it does
not repair or authorize the underlying product coupling.
