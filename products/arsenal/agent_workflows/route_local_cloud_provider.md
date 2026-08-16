# Route Local Cloud Provider

Use this workflow when a cloud-dependent engineering task needs the correct Floci provider overlay selected before implementation or diagnosis.

This router owns **provider selection only**. When the caller still needs to decide what kind of engineering capability should run after the provider is known, hand the result to `agent_workflows/local_cloud_router.md`; provider resolution does not imply that every higher-level Arsenal specialization exists for that provider.

## Outcome

Select exactly one local-cloud provider from explicit task intent and repository evidence, or stop as ambiguous/unknown. Do not default to AWS merely because the generic Floci pack originated there.

## Procedure

1. Read repository instructions and cloud configuration before changing anything.
2. Run the deterministic provider resolver when available:

   `engineering/development_packs/floci/providers/scripts/resolve-provider . --format json`

3. Corroborate the result with task intent and the concrete client/IaC surface being changed.
4. Route to the provider-owned pack:
   - AWS → `engineering/development_packs/floci/aws/`
   - Azure → `engineering/development_packs/floci/azure/`
   - GCP → `engineering/development_packs/floci/gcp/`
   - OCI → `engineering/development_packs/floci/oci/`
5. Resolve the exact services/operations and fidelity requirements inside that provider overlay.
6. If the request still needs work-kind/capability selection, continue through `agent_workflows/local_cloud_router.md` so provider support for that specialization is checked explicitly.
7. Use the provider's endpoint guard before any provider-shaped client is invoked.
8. If evidence is mixed, return `AMBIGUOUS` with the conflicting paths. Require an explicit provider choice; do not guess.
9. If no provider evidence exists, return `UNKNOWN`; do not introduce cloud tooling speculatively.
10. Never request real credentials merely to make a local Floci path work.
11. Never fall back to a public provider because the emulator is missing, unhealthy, unsupported, or because a higher-level Arsenal capability is not implemented for the resolved provider. Escalation is a separate evidence-backed decision under the Cloud Execution Boundary.

## Required handoff

Report:

- selected provider;
- evidence paths/signals;
- selected overlay path;
- exact services/operations needed;
- known local fidelity boundaries;
- whether higher-level capability routing remains;
- whether any provider-only proof remains.

## Stop conditions

Stop before implementation when:

- provider evidence is ambiguous;
- the required operation is not supported by the selected overlay and no bounded redesign is authorized;
- a command would route to a public provider;
- the task requires provider semantics not represented by the local fixture and those semantics are acceptance-critical.

If the provider is known but a requested higher-level specialization is unavailable for it, return to `agent_workflows/local_cloud_router.md` and preserve that result as a capability gap rather than treating it as proof that real-cloud execution is required.
