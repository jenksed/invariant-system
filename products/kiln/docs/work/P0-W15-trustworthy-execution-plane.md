# P0-W15: Trustworthy execution plane

- **Status:** Implemented and verified
- **Branch:** `work/p0-w15-trustworthy-execution-plane`
- **Depends on:** P0-W06 through P0-W14
- **Scope:** Planning and contracts only

## Objective

Define Kiln's trustworthy execution plane so deterministic execution, transactional mutation, machine-readable Evidence, Receipts, and observability outrank model confidence.

## Observed current state

- Run is the accepted execution identity.
- Capability availability, grants, and effective authority are separate.
- The generic Command contract records executable, argv, working directory, environment, timeout, lifecycle status, and output Artifacts.
- Git change isolation defines protected trunk, exclusive writable worktrees, Patch Artifacts, exact-state verification, integration Approval, and recovery.
- Evidence contracts distinguish Claims, Evidence, Artifacts, Change sets, Receipts, and freshness.
- The terminal interface uses precise proposed, applied, executed, verified, accepted, integrated, and delivered language.
- The knowledge-security boundary denies reference-index execution and requires separate authorization for future reference execution.
- No accepted Environment hierarchy, Command registry, transactional Patch engine, structured-result ingestion model, expanded execution Receipt, OpenTelemetry model, or attestation mapping exists.
- No production execution-plane implementation exists.

## Protected invariants

This work preserves:

- Run as the primary execution unit;
- explicit Capability grants and least privilege;
- Git and filesystem source truth;
- one mutation owner per writable worktree;
- authoring and integration authority separation;
- Claims, Evidence, and Receipts as distinct concepts;
- exact-state Evidence freshness;
- reference repositories as Evidence rather than instruction sources;
- no ambient Child authority;
- deterministic bookkeeping;
- bounded Context and Artifact disclosure;
- honest distinction between process, container, worktree, and sandbox boundaries.

ADR 0018 records the additional execution-plane decision.

## Requirements

- **P0-W15-R01:** Define the least-powerful sufficient execution hierarchy.
- **P0-W15-R02:** Define trusted-host, active-Project, worktree, Dev Container, OCI, disposable Resource, and future Wasm use.
- **P0-W15-R03:** Do not require containers or worktrees for harmless operations.
- **P0-W15-R04:** Define Environment selection and effective-isolation reporting.
- **P0-W15-R05:** Define restricted network, secret injection, Resource limits, and process-tree termination.
- **P0-W15-R06:** Define a versioned deterministic Command registry.
- **P0-W15-R07:** Define executable, argv, cwd, environment, timeout, output, side-effect, and result policies.
- **P0-W15-R08:** Retain an unrestricted shell only behind exact explicit Approval and a dedicated grant.
- **P0-W15-R09:** Define transactional Patch proposal, validation, preview, application, rollback, and observation.
- **P0-W15-R10:** Support exact patches, create, delete, move, rename preview, conflicts, changed regions, AST adapters, framework operations, and Child Patch Artifacts.
- **P0-W15-R11:** Keep formatting and focused validation as visible registered Commands.
- **P0-W15-R12:** Define Proposed, Implemented, Inspected, Executed, Verified, Accepted, and Delivered separately.
- **P0-W15-R13:** Require current Evidence for material completion Claims.
- **P0-W15-R14:** Define machine-readable Evidence authority and limitations.
- **P0-W15-R15:** Define ingestion for SARIF, tests, compiler, linter, security, browser, build, and coverage results.
- **P0-W15-R16:** Integrate immutable content-addressed Artifacts with execution and Evidence.
- **P0-W15-R17:** Define detailed deterministic execution Receipts.
- **P0-W15-R18:** Instrument Task, Run, model, Context, Capability, Tool, Command, Patch, verification, Attention, Approval, Artifact, completion, and delivery.
- **P0-W15-R19:** Define token, cost, cache, overhead, repetition, failure, denial, verification, and unsupported-completion metrics.
- **P0-W15-R20:** Exclude sensitive source, prompts, secrets, argv, and output from telemetry by default.
- **P0-W15-R21:** Define optional in-toto and SLSA mappings without mandatory attestation or unsupported level Claims.
- **P0-W15-R22:** Add and validate `kiln.execution_plane/v0`.
- **P0-W15-R23:** Reconcile later planning without moving production models, remote execution, Wasm, or attestation services earlier.
- **P0-W15-R24:** Do not add production runtime code or dependencies.

## Changes

- Add `docs/TRUSTWORTHY-EXECUTION-PLANE.md`.
- Add focused Command/Patch, Evidence/Receipt, and observability/attestation specifications.
- Add `docs/contracts/kiln-execution-plane.schema.json`.
- Add ADR 0018.
- Add P0-W15 to the roadmap.
- Update README, ADR index, and contract index.
- Record PR #18 and ADR 0017 as integrated.
- Reconcile Phase 1 Command, Patch, Evidence, Receipt, telemetry, and phase-proof boundaries.

## Acceptance criteria

The normative criteria are `P0-W15-AC01` through `P0-W15-AC46` in `docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md`.

Additional work-package criteria:

- **P0-W15-AC47:** The execution-plane schema parses as JSON.
- **P0-W15-AC48:** Draft 2020-12 meta-schema validation passes.
- **P0-W15-AC49:** Representative Environment, registration, request, result, Patch, stage, structured-result, Receipt, telemetry, and attestation documents validate.
- **P0-W15-AC50:** Negative cases reject shell and unrestricted network use without Approval, path traversal, missing Patch rollback, invalid verification, acceptance, and delivery stages, sensitive telemetry keys, ineligible attestation subjects, and delivery Receipts without acceptance and delivery Evidence.
- **P0-W15-AC51:** The diff contains documentation and JSON contracts only.
- **P0-W15-AC52:** Repository CI passes on the final branch head.
- **P0-W15-AC53:** Existing domain, Capability, Context, Git, Evidence, delegation, interface, knowledge, and knowledge-security decisions remain intact.

## Verification

Verification result:

- the committed schema blob matches the locally validated file digest;
- JSON parsing and Draft 2020-12 meta-schema validation passed;
- ten representative positive documents passed;
- ten protected negative documents were rejected;
- the final design diff contains documentation and JSON contracts only;
- GitHub CI run `30403068021` passed on the design head.

Repository checks:

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Contract checks:

```bash
python -m json.tool docs/contracts/kiln-execution-plane.schema.json
```

A Draft 2020-12 validator must validate:

- Environment profile;
- Command registration;
- Command request;
- Command result;
- Patch transaction;
- completion-stage record;
- structured result;
- execution Receipt;
- telemetry record;
- attestation export.

Protected negative cases must reject:

- explicit shell without exact Approval and sufficient grant references;
- unrestricted network without Approval;
- a Patch path containing traversal;
- a Patch transaction without rollback information;
- `Verified` without current `PASS` Evidence;
- `Accepted` without an acceptance decision;
- `Delivered` without destination Evidence;
- telemetry attribute names that request source, Patch, prompt, secret, argv, stdout, stderr, or content capture;
- eligible attestation export without an immutable subject;
- a delivery Receipt without acceptance and delivery Evidence.

## Evidence

- **P0-W15-E01:** The specification covers every required output.
- **P0-W15-E02:** ADR 0018 records the tiered deterministic execution decision.
- **P0-W15-E03:** The execution-plane schema parses and validates.
- **P0-W15-E04:** Ten representative positive and ten protected negative documents pass.
- **P0-W15-E05:** README, roadmap, ADR index, and contract index link to the execution plane.
- **P0-W15-E06:** Primary specifications support OCI, Dev Container, OpenTelemetry, SARIF, WASI/WIT, in-toto, and SLSA compatibility positions.
- **P0-W15-E07:** The diff contains planning and contracts only.
- **P0-W15-E08:** Repository CI passes on the final branch head.

## Exclusions

This work does not implement:

- Command processes or terminals;
- Environment provisioning;
- Dev Container or OCI adapters;
- worktree or Patch mutation code;
- disposable databases;
- network namespaces or secret providers;
- Resource enforcement;
- process-group, cgroup, container, or Job Object cleanup;
- result format parsers;
- Artifact storage;
- OpenTelemetry dependencies or exporters;
- WASI or WIT plugins;
- in-toto, SLSA, DSSE, signing, or publication;
- remote execution;
- production model invocation.
