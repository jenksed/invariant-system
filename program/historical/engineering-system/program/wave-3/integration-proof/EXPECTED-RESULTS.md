# Wave 3 Integration Proof — Expected Results

This document describes what the integration proof MUST produce when run
against the deterministic proof repository.

## A. Repository Recon v1 output

```
{
  "schema": "loadout/repository-recon/v1",
  "repository": "<abs path to proof-repo>",
  "repository_state": {
    "head_commit": "<recorded commit>",
    "head_ref": "refs/heads/<branch>",
    "is_git_repository": true,
    "tracked_files": <count>,
    "tracked_files_source": "git",
    "filesystem_walk_files": <count>
  },
  "architecture_anchors": [
    { "kind": "governance",        "path": "AGENTS.md",         "evidence": "..." },
    { "kind": "readme",            "path": "README.md",         "evidence": "..." },
    { "kind": "manifest",          "path": "package.json",      "evidence": "..." },
    { "kind": "source_root",       "path": "src/",              "evidence": "..." },
    { "kind": "docs_architecture", "path": "docs/",             "evidence": "..." },
    { "kind": "test_root",         "path": "tests/",            "evidence": "..." },
    { "kind": "ci_workflow",       "path": ".github/workflows/","evidence": "..." },
    { "kind": "build_config",      "path": "tsconfig.json",     "evidence": "..." },
    { "kind": "project_config",    "path": ".gitignore",        "evidence": "..." }
  ],
  "constraints": [
    { "kind": "agent_rule",         "source": "AGENTS.md",     "observation": "...", "evidence": "..." },
    { "kind": "runtime",            "source": "package.json",  "observation": "Node >=20.10.0", "evidence": "..." },
    { "kind": "package_manager",    "source": "npm lockfile",  "observation": "npm", "evidence": "..." },
    { "kind": "test_command",       "source": "package.json",  "observation": "node --test", "evidence": "..." },
    { "kind": "generated_boundary", "source": ".gitignore",    "observation": "...", "evidence": "..." }
  ],
  "unknowns": [
    { "subject": "architecture_ownership", "reason": "no OWNERS/CODEOWNERS file" }
  ],
  "summary": "Recon v1 of <repo>: 9 architecture anchors, 5 constraints, 1 unknowns. HEAD=<sha> tracked_files=<n> source=git."
}
```

The exact count of architecture anchors may grow if the proof-repo
gains more files during the proof run. The minimum invariants are:

- AGENTS.md, README.md, package.json, src/, tests/, .github/workflows/,
  tsconfig.json, .gitignore must all be present and cited
- At least one unknown: `architecture_ownership`
- `tracked_files` count must come from `git ls-files` (not a recursive
  filesystem walk)

## B. Plan artifact

The plan must contain:

```
{
  "schema": "loadout/plan/v0",
  "plan_id": "<sha256 of canonicalized body>",
  "plan_repository_recon": {<ReconResultV1 above>},
  "method": {
    "method_id": "repository-recon/architecture-anchor-incremental",
    "method_version": "...",
    "status": "experimental",
    "confidence": "...",
    "record_digest": "sha256:...",
    "procedure_ref": "sha256:..."
  },
  "procedure_binding": {
    "qmr_procedure_ref": "sha256:...",
    "skill_procedure_entry": "./run.ts",
    "procedure_interface_digest": "sha256:..."
  },
  "compatibility": {<status, outcome, context, intersection>},
  "execution_boundary": "kiln",
  "work_envelope": {<verified-shape work envelope>},
  "explanation": "..."
}
```

## C. Real Kiln run

Calling `mix kiln supervise --work-envelope <tempfile> --format json`
must produce a JSON envelope with:

```
{
  "schema": "engineering-system/run-result-envelope/v0",
  "work_id": "<sha>",
  "run_id": "<sha>",
  "status": "completed",
  "input_state": {<observed>},
  "final_state": {<observed>},
  "authority": {
    "requested": ["git.read"],
    "granted": ["git.read"],
    "denied": []
  },
  "effects": ["<observation artifact id>"],
  "evidence": ["<repo-state-observed evidence id>"],
  "proof_obligations": {
    "satisfied": ["repo-state-observed"],
    "unsatisfied": [],
    "invalidated": []
  },
  "unknowns": [],
  "recovery": null,
  "acceptance_readiness": {
    "ready": false,
    "reasons": []
  }
}
```

`acceptance_readiness.ready` is `false` until and unless the user
explicitly accepts the run. The proof MUST report this truthfully.

## D. Restart durability

After `kiln stop && kiln start`, the same `inspect_run/2` call must
return the same `work_id`, `run_id`, Artifact references, Evidence
references, and Run Result Envelope facts.

## E. Honest QMR status

The canonical QMR for `repository-recon/architecture-anchor-incremental`
remains `experimental`. Arsenal reports `experimental → experimental`.
Qualification gap is documented at `project-arsenal/docs/arsenal-method-evaluation.md`.

No auto-promotion. No fabricated `qualified`. The proof must show
`experimental` and refuse to claim otherwise.
