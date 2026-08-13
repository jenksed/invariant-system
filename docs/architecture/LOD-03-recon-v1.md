# LOD-03 — Repository Recon v1

**Status:** Wave 3 Phase 1 (deterministic structured v1)
**Author:** loadout-writer (Wave 3)
**Scope:** Repository Recon procedure upgrade + Plan integration
**Date:** 2026-08-13

## Objective

Advance the bundled `runRepositoryRecon` procedure from a flat summary
(`{ repository, headCommit, trackedFiles, hasReadme, hasDocs, notes[] }`)
to a genuinely useful, deterministic structured v1.

The v1 result is INPUT to the fake Kiln boundary, not a Kiln record.
It is embedded in the Plan as a content-addressable block so the EXPLAIN
view can show the user what recon WOULD produce at plan time.

## Result schema (Loadout-owned)

The result schema is `loadout/repository-recon/v1`. It is NOT part of
the engineering-system v0 contracts. It is intentionally owned by
Loadout to keep the v0 contract surface stable while the recon result
shape evolves.

```text
{
  schema: "loadout/repository-recon/v1",
  repository: string,
  repository_state: {
    head_commit: string,
    head_ref: string | null,
    is_git_repository: boolean,
    tracked_files: number | null,        // null when git is unavailable
    tracked_files_source: "git" | "unavailable",
    filesystem_walk_files: number       // honestly named, not "tracked"
  },
  architecture_anchors: [
    { kind, path, observation, evidence }, ...
  ],
  constraints: [
    { kind, source, observation, evidence }, ...
  ],
  unknowns: [
    { subject, reason }, ...
  ],
  summary: string
}
```

## Architecture anchors (detected kinds)

Detection is purely deterministic and evidence-citing:

| Kind              | Examples                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------- |
| governance        | `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `CONVENTIONS.md`, `CONTRIBUTING.md`            |
| readme            | `README.md`, `README`, `README.txt`                                                      |
| manifest          | `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, ... |
| source_root       | `src/`, `lib/`, `app/`, `source/`                                                        |
| docs_architecture | `ARCHITECTURE.md`, `DESIGN.md`, `docs/architecture/`, `docs/design/`, `docs/`            |
| test_root         | `tests/`, `test/`, `spec/`, `__tests__/`                                                 |
| ci_workflow       | `.github/workflows/`, `.circleci/`, `.travis.yml`, `Jenkinsfile`, ...                    |
| build_config      | `tsconfig.json`, `webpack.config.js`, `Makefile`, `CMakeLists.txt`, ...                  |
| project_config    | `.editorconfig`, `.eslintrc.json`, `Dockerfile`, `.gitignore`, ...                       |

Every anchor carries an `evidence` field that cites a concrete
measurement (file size, sha256 digest, parsed field, directory entry
count). The procedure never infers an architecture relationship from a
directory name alone.

## Observed constraints (separately represented)

Constraints are reported separately from anchors. The v1 procedure
observes the following categories:

- `agent_rule` — repository-local governance document is present.
- `runtime` — Node runtime pinned via `engines.node`.
- `package_manager` — single lockfile present (`npm`, `yarn`, `pnpm`,
  `bun`). When multiple lockfiles are present, both the constraint and
  an unknown are surfaced.
- `test_command` — explicit `scripts.test` declared in `package.json`.
- `mutation_prohibition` — a line in a governance file explicitly
  prohibits mutation.
- `generated_boundary` — `.gitignore` lists generated/build dirs.
- `ownership` — not inferred; surfaced as an unknown instead.

Each constraint has a `source` (the path or origin) and an `evidence`
field that quotes the parsed field or line.

## Unknowns (a feature, not a bug)

Unknowns are surfaced explicitly so the result does not silently hide
its limitations. The v1 procedure produces unknowns in three categories:

1. **Missing expected anchors** — when an expected anchor (README,
   governance, manifest, test root, CI workflow) is absent.
2. **Indeterminate facts** — when a fact could not be determined (e.g.,
   no engines.node, no scripts.test, ambiguous lockfile, package.json
   not parseable).
3. **Deliberately not inferred** — ownership cannot be determined from
   the file layout alone; the procedure does not invent a claim.

## Determinism

The result is deterministic for fixed repository state:

- All outputs are sorted deterministically (paths ascending, kinds in a
  stable order).
- No timestamps in the result.
- File content digests are included in `evidence` so a content change
  yields a different anchor (LOD-RR-07).
- Removing an expected anchor adds an explicit `unknowns` entry
  (LOD-RR-08) rather than silently preserving the old conclusion.

## Truthful naming

`tracked_files` is only populated when it is derived from `git ls-files`.
When git is unavailable, the count is reported under a separate,
honestly-named field `filesystem_walk_files`, and the source is reported
as `unavailable`. The procedure never silently renames a filesystem
count to "tracked files" (LOD-RR-extra).

## Plan integration

The Plan embeds the recon result as `plan.repository_recon`. Because
the recon result is part of the content-addressable plan body, any
change to the recon result changes `plan_id`. The EXPLAIN view renders
the full recon section.

## LOD-RR acceptance mapping

| Criterion | What it asserts                                   | Test (file + name)                                   |
| --------- | ------------------------------------------------- | ---------------------------------------------------- |
| LOD-RR-01 | A real repo produces architecture anchors.        | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-01 |
| LOD-RR-02 | Every anchor cites observable evidence.           | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-02 |
| LOD-RR-03 | Observed constraints are separately represented.  | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-03 |
| LOD-RR-04 | Unknowns remain explicit.                         | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-04 |
| LOD-RR-05 | No repository mutation occurs.                    | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-05 |
| LOD-RR-06 | Output is deterministic for fixed state.          | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-06 |
| LOD-RR-07 | Changing an anchor changes the recon output.      | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-07 |
| LOD-RR-08 | Removing an expected anchor adds an unknown.      | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-08 |
| LOD-RR-09 | Result satisfies Goal better than Wave-2 summary. | `tests/unit/repository-recon-v1.spec.ts` — LOD-RR-09 |

Two extra tests cover truthful naming under git-available and
git-unavailable conditions, and the Plan integration covers the
content-addressable embedding.

## Invariants preserved

- `plan_id` is a sha256 content address over the canonicalized body.
- The recon result is part of the body; tampering with it changes the
  digest.
- The procedure binding (QMR procedure_ref, Skill procedureEntry,
  procedure interface digest) is unchanged.
- `loadout run --plan` still verifies plan integrity + freshness +
  procedure binding before submitting the embedded Work Envelope.
- All four v0 contracts are unchanged.

## Out of scope for v1

- LLM inference / remote calls.
- Network queries (CI APIs, registry queries, etc.).
- Mutation of the target repository.
- Inference of architecture relationships from directory names.
- Heuristic "primary language" or "framework" detection.
- Automatic discovery of generated files beyond `.gitignore` patterns.
