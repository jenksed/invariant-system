# Wave 3 Integration Proof — Test Matrix

This matrix defines exactly what the integration verifier must run
against the deterministic proof repository and the published product
artifacts.

## A. Golden path

Input: the deterministic proof repository (`proof-repo/`) at HEAD
recorded at the start of the integration proof.

Expected sequence (observed through the built products):

1. `loadout install repository-recon --repository <proof-repo>`
2. `loadout plan --goal "Understand this repository" --repository <proof-repo> --execution kiln`
   - Real Plan artifact
   - Architecture-relevant Capability
   - Method with QMR provenance
   - Work Envelope with `read` authority requested
   - Execution boundary = `kiln`
3. `loadout run --plan <plan>`
   - Plan integrity verified
   - Plan freshness verified
   - Procedure binding verified
   - Real Kiln CLI invoked with the Work Envelope
   - Kiln observation recorded
   - Kiln authority decision durably stored
   - IF GRANTED: procedure executed exactly once
   - Artifact persisted
   - Evidence persisted
   - Run Result Envelope produced from durable facts
   - Loadout Result View rendered without `simulated: true`

## B. Restart durability

After one successful run:

1. Stop Kiln normally
2. Restart Kiln
3. Inspect the Run via `kiln <application> inspect <run-id>` or
   architecture-equivalent projection
4. Same durable IDs reference the same observed state

## C. Negative matrix

| ID | Scenario | Expected | Procedure invocation count |
|---|---|---|---|
| C-1 | **Stale Plan** — submit a Plan whose `project_state` no longer matches the current snapshot | Loadout refuses before submission to Kiln | 0 |
| C-2 | **Tampered Plan** — file edits to `plan_id` or `procedure_binding` | Integrity failure before submission to Kiln | 0 |
| C-3 | **Kiln unavailable** — `mix` not on PATH, or `--kiln-binary` missing | Loadout fails closed with a clear error. No fallback to fake Kiln | 0 |
| C-4 | **Authority denied** — request unsupported authority (filesystem.write, git.write, network, scope outside target) | Kiln returns `:denied` with a typed reason. Loadout surfaces the denial truthfully. Procedure NOT invoked | 0 |
| C-5 | **Procedure failure** — grant valid read authority. Procedure throws / fails. | Kiln receives the failure observation. Run Result does NOT claim success. Acceptance readiness reports the failure truthfully | 1 (failed) |
| C-6 | **Mid-run state change** — grant read. Change repo. Submit old observation. | Evidence cannot remain falsely current / ready. The currentness evaluator reports stale or unknown where the canonical semantics require it | 1 (with stale evidence) |
| C-7 | **Retry** — submit identical work again | No duplicate unrelated Run. Same `work_id` returns the same durable Run identity | 0 (after first run) |
| C-8 | **Conflicting retry** — reuse `work_id` with changed semantic payload | Idempotency conflict / rejection. Run is not silently overwritten | 0 (no successful run) |

## D. Dogfood (run after negative matrix passes)

Run the same flow against ONE real repository owned by the project.
Preferred: project-arsenal, loadout, or kiln.

Do not modify the chosen repository.

Record in the proof:
- Anchors found
- Constraints found
- Unknowns surfaced
- Run id
- Artifact ids
- Evidence ids
- Authority result
- Readiness result

## E. Acceptance truthfulness

The proof MUST demonstrate — without caveats hiding simulation or
ephemeral state — that:

```
$ loadout plan --goal "Understand this repository"
... produces a real Plan with execution_boundary = kiln ...

$ loadout run --plan ...
... invokes the Kiln CLI, real authority decision, real artifact, real Run Result Envelope ...

$ kiln <application> inspect <run-id>
... same durable facts after restart ...
```

If any of these cannot be shown, the corresponding acceptance
criterion is NOT met.
