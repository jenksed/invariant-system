# Route Local Cloud Provider

Use this workflow when a cloud-dependent engineering task needs the correct Floci provider overlay selected before implementation or diagnosis.

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
6. Use the provider's endpoint guard before any provider-shaped client is invoked.
7. If evidence is mixed, return `AMBIGUOUS` with the conflicting paths. Require an explicit provider choice; do not guess.
8. If no provider evidence exists, return `UNKNOWN`; do not introduce cloud tooling speculatively.
9. Never request real credentials merely to make a local Floci path work.
10. Never fall back to a public provider because the emulator is missing, unhealthy, or unsupported. Escalation is a separate evidence-backed decision under the Cloud Execution Boundary.

## Required handoff

Report:

- selected provider;
- evidence paths/signals;
- selected overlay path;
- exact services/operations needed;
- known local fidelity boundaries;
- whether any provider-only proof remains.

## Stop conditions

Stop before implementation when:

- provider evidence is ambiguous;
- the required operation is not supported by the selected overlay and no bounded redesign is authorized;
- a command would route to a public provider;
- the task requires provider semantics not represented by the local fixture and those semantics are acceptance-critical.
