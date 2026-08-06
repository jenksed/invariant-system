# Draft Schemas

These JSON Schemas are review scaffolding for the proposed domain. They are not integrated with current Kiln contracts and do not authorize runtime implementation.

Schemas:

- `development-pack-manifest.schema.json`
- `quality-subject.schema.json`
- `verification-obligation.schema.json`
- `quality-observation.schema.json`
- `finding.schema.json`
- `evidence-contribution.schema.json`
- `assurance-plan.schema.json`

## Validation policy

- JSON Schema draft 2020-12;
- closed objects by default;
- explicit version fields;
- SHA-256 digest syntax;
- no source payloads, secrets, PIDs, shell strings, or authority grants;
- future changes require compatibility review before `v1`.
