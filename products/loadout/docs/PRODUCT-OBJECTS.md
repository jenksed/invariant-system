# Loadout Product Objects

## User-facing hierarchy

| Object         | Meaning                                                            | Visibility           |
| -------------- | ------------------------------------------------------------------ | -------------------- |
| Workspace      | The project/job/context the user is working in                     | Everyone             |
| Goal           | What the user wants to accomplish                                  | Everyone             |
| Capability     | Stable contract for an outcome                                     | Everyone             |
| Skill          | Reusable method used within a Capability                           | Power users          |
| Pack           | Curated collection of Capabilities, Skills, and configuration      | Everyone             |
| Catalog        | Discovery source for Packs and Capabilities                        | Everyone             |
| Connector      | Configured connection exposed to Capabilities                      | Everyone/power users |
| Run projection | Loadout's view of a Kiln Task/Run                                  | As needed            |
| Result view    | Truthful presentation of output, evidence, blockers, and readiness | Everyone             |

## Progressive disclosure

- Basic user: “Understand this repository.”
- Engineer: select or configure the Repository Recon Capability.
- Power user: inspect or replace a Skill while preserving the Capability contract.
- Researcher: follow method provenance into Arsenal when direct research access is appropriate.

## Capability contract minimum

Every Capability declares:

- stable identifier and contract version;
- user Goal/outcome;
- inputs and outputs;
- optional effects;
- evidence expectations;
- compatibility and provenance;
- failure and unresolved-result shape.

Underlying methods may change without a Capability breaking its user-level contract. Incompatible input/output or semantic changes require an explicit contract-version transition.
