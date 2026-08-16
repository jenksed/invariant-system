# Capability Gap Preflight

Status: ARS-04 v0

Capability Gap Preflight checks a declared Arsenal route before execution. It verifies that every required capability is present in the selected inventory, resolves to a registered implementation, meets the route's minimum version and qualification, and has the required permission profile.

## Validate and inspect

```bash
python3 scripts/arsenal_graph.py validate
python3 scripts/arsenal_graph.py explain --route route.feature-delivery
```

Current v0 routes are `route.repository-audit`, `route.feature-delivery`, `route.bug-repair`, and `route.local-cloud-feature-delivery`.

## Normal feature preflight

```bash
python3 scripts/arsenal_graph.py preflight \
  --route route.feature-delivery \
  --inventory canonical \
  --authority-profile workspace-safe
```

Expected verdict: `READY`.

## Check pinned competence

ARS-03 introduced `.arsenal.lock`. Use it as the inventory with:

```bash
python3 scripts/arsenal_graph.py preflight \
  --route route.feature-delivery \
  --inventory lock \
  --authority-profile workspace-safe
```

ARS-03 v0 pins Repository Truth only, so the multi-step feature route returns `CAPABILITY_GAP`. Source capabilities are not silently treated as downstream installed competence.

## Simulate missing TDD

```bash
python3 scripts/arsenal_graph.py preflight \
  --route route.feature-delivery \
  --inventory canonical \
  --authority-profile workspace-safe \
  --omit capability.tdd
```

Expected verdict: `CAPABILITY_GAP`.

## Require stronger qualification

```bash
python3 scripts/arsenal_graph.py preflight \
  --route route.feature-delivery \
  --inventory canonical \
  --authority-profile workspace-safe \
  --minimum-lifecycle testing \
  --minimum-evaluation candidate
```

Expected verdict: `QUALIFICATION_GAP`, because current Core capabilities are still `draft / unassessed`.

## Consume real Bench evidence

The Local Cloud capability earned `testing / candidate` in ARS-02. Its route requires that exact minimum:

```bash
python3 scripts/arsenal_graph.py preflight \
  --route route.local-cloud-feature-delivery \
  --inventory canonical \
  --authority-profile local-cloud-safe
```

Expected verdict: `READY`.

Running the same route with `workspace-safe` returns `AUTHORITY_GAP` because `cloud.local` is not granted. The preflight does not respond by requesting remote-cloud credentials.

## Machine-readable output

Add `--json` to any preflight command for a structured report. Each step includes capability identity, dependency predecessors, implementation resolution, required/granted permissions, actual/minimum qualification, preconditions, outputs, final status, and reasons.

Exit codes:

- `0` — `READY`
- `3` — `CAPABILITY_GAP`
- `4` — `AUTHORITY_GAP`
- `5` — `QUALIFICATION_GAP`
- `6` — `UNKNOWN`

## v0 boundary

ARS-04 v0 does not infer routes from vague intent, install missing capability packages, broaden permissions automatically, select models, execute routes, or infer consequential dependencies from similar free-text names. Those remain later capability-system concerns.
