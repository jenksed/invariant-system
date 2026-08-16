# Migrate LocalStack to Floci

Status: draft

Use when an existing repository already depends on LocalStack and the goal is to move its local AWS execution surface to Floci without silently changing behavior.

## Outcome

Produce a reviewed migration in which every load-bearing LocalStack assumption is inventoried, classified, adapted or blocked, and then verified against a pinned Floci runtime.

Do not stop after changing an image tag.

## 1. Establish repository truth

Read repository instructions and inspect:

- Docker/Compose/Testcontainers configuration;
- CI jobs and wait strategies;
- `.env` and configuration files;
- init/bootstrap scripts;
- AWS SDK/client endpoint configuration;
- Terraform/OpenTofu/CloudFormation local paths;
- LocalStack-specific helper libraries and wrappers;
- persistence/data volumes;
- Lambda/container-network assumptions;
- existing integration tests and acceptance commands.

Record the currently authoritative LocalStack behavior before editing.

## 2. Run the deterministic inventory

When the FLC-03 pack is available:

```bash
engineering/development_packs/floci/aws/diagnostics/scripts/inventory-localstack . \
  --format json \
  --output .floci-artifacts/localstack-inventory.json
```

Also run `--fail-on-blocker` before runtime replacement.

Classify every finding as:

- `KEEP_COMPAT`;
- `TRANSLATE`;
- `VERIFY`;
- `REMOVE`;
- `BLOCKER`.

A known unsupported assumption such as `LAMBDA_REMOTE_DOCKER` is a blocker, not a warning to ignore.

## 3. Build the migration acceptance matrix

Copy or adapt:

`engineering/development_packs/floci/aws/diagnostics/MIGRATION_ACCEPTANCE_MATRIX.md`

Create rows only for behaviors this repository actually relies on.

Include exact pre-migration evidence where available: tests, CLI outputs, CI receipts, fixture state, or screenshots/logs if no deterministic interface exists.

If LocalStack itself can still be run safely, a differential before/after run is useful. It is not mandatory when the existing repository already has trustworthy behavioral tests or LocalStack can no longer run.

## 4. Resolve blockers before image replacement

Examples:

- `LAMBDA_REMOTE_DOCKER` → redesign the code-loading path; Floci documents it as unsupported.
- `/var/lib/localstack` persistence → move to `/app/data` and make storage mode explicit.
- standard image + init scripts calling `aws`/`boto3` → choose a pinned `-compat` image or remove that in-container tooling dependency.
- executor-specific Lambda assumptions → verify against Floci's Docker execution model.
- shared-state CI assumptions → preserve or improve job isolation.

Do not create a compatibility shim that merely hides an unresolved semantic difference.

## 5. Prefer compatibility first

For a first safe migration, preserve supported compatibility surfaces when they reduce change:

- port `4566`;
- dummy credentials;
- `/etc/localstack/init/...` paths;
- `/_localstack/init` / health wait surfaces;
- supported LocalStack environment-variable translation;
- `localhost.localstack.cloud` where the actual caller context resolves correctly.

Native Floci names can be adopted later. A migration PR should minimize simultaneous behavioral and cosmetic change.

## 6. Pin the runtime and fail closed

Use a versioned Floci image, not floating `latest`, for completion evidence.

Keep the local AWS execution boundary explicit. The migration must not permit an absent Floci runtime to fall back to public AWS.

Use synthetic local credentials only.

## 7. Verify init and fixture behavior

Prove:

- the runtime reaches the expected init phase;
- existing compatible init scripts still run, or their replacements do;
- required seeded resources exist through provider-shaped APIs;
- hooks that depend on AWS CLI/boto3 use a runtime that actually includes those tools;
- hook failures remain visible and fail startup where appropriate.

Do not infer init success from container process health alone.

## 8. Run behavioral acceptance

Run the repository's normal local integration tests plus direct state assertions for the exact services/operations that matter.

Every acceptance-matrix row must end in:

- `PASS`;
- `INTENTIONAL_CHANGE`;
- `BLOCKED`;
- `PROVIDER_ONLY`;
- `NOT_APPLICABLE`.

Blank results are unresolved work.

## 9. Audit fidelity separately

For each acceptance claim, ask whether the evidence proves:

- protocol shape;
- local behavior;
- emulator fidelity;
- target-cloud behavior.

Use `agent_workflows/audit_floci_fidelity_gap.md` for unclear cases.

Do not inherit a LocalStack assumption as an AWS guarantee merely because both emulators behave the same.

## 10. Clean reconstruction

Tear down local state, including relevant managed containers/volumes, then rebuild from source-controlled inputs and rerun the migration acceptance gate.

Completion requires a clean replay.

## Completion handoff

Report:

- source and target runtime versions;
- inventory artifact;
- blockers found and how each was resolved;
- compatibility surfaces intentionally retained;
- native Floci changes introduced;
- acceptance-matrix results;
- tests and direct assertions run;
- fidelity gaps;
- provider-only residue;
- rollback/revert path.

A valid completion statement is:

> The repository's LocalStack-specific assumptions were inventoried, the unsupported assumptions were resolved before runtime replacement, the pinned Floci configuration reproduced the required behaviors from clean state, and remaining provider-only semantics are explicit.
