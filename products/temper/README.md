# Temper

Temper is a read-only terminal workbench for inspecting a real Loadout Plan
and its canonical Kiln Run Result. It gives operators one truthful place to
answer: what was planned, what ran, what authority was granted, what Evidence
and Artifacts exist, and whether the repository has moved since the Run.

Temper never grants authority, executes work, mutates product state, or
invents facts absent from the accepted v0 contracts.

## Real Run Workbench v0

The Wave 4 vertical slice provides these focuses:

- Overview
- Plan
- Run
- Authority
- Evidence
- Artifacts
- Raw Result
- Help

Missing or incompatible inputs render as `n/a` with a reason. Evidence
freshness and contradiction also render as `n/a` because those projections
are not present in `engineering-system/run-result-envelope/v0`.

## Requirements

- Node.js 20.10 or newer
- Git
- A repository containing a real Loadout Run record under
  `.loadout/runs/*.json`

## Run

```sh
npm ci
npm run build
./dist/src/cli.js /path/to/repository
```

Temper discovers the newest Run record and follows its referenced Plan. Use
explicit paths when replaying or diagnosing a specific record:

```sh
./dist/src/cli.js /path/to/repository \
  --run /path/to/run.json \
  --plan /path/to/plan.json
```

For deterministic, non-interactive output:

```sh
./dist/src/cli.js /path/to/repository --snapshot --width 100
./dist/src/cli.js /path/to/repository --snapshot --focus raw --width 120
```

Keyboard controls:

| Key | Focus or action |
|---|---|
| `p` | Plan |
| `u` | Run |
| `a` | Authority |
| `e` | Evidence |
| `t` | Artifacts |
| `r` | Raw Result |
| `?` | Help |
| `Tab` / arrows | Next or previous focus |
| `Escape` | Overview |
| `q` / `Ctrl-C` | Quit |

## Verify

```sh
npm run ci
```

The suite type-checks, builds, and tests real-input projection, exact raw JSON,
truthful missing-state behavior, repository staleness, source traceability,
and rendering at 60-, 80-, 100-, and 128-column widths.

## Ownership boundaries

- Arsenal owns Capability and method truth.
- Loadout owns planning and the Run history record.
- Kiln owns execution, authority decisions, Evidence, Artifacts, and acceptance
  readiness.
- Temper only reads and projects those records.

See [docs/SOURCES.md](docs/SOURCES.md) for the field-level source map and the
commands that produce each visible fact.
