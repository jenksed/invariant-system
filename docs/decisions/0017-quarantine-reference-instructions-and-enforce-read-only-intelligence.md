# ADR 0017: Quarantine reference instructions and technically enforce read-only intelligence

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W14
- **Date:** 2026-07-28

## Context

Kiln can search explicitly approved local repositories for engineering patterns. Those repositories can contain useful code and documentation, but they can also contain malicious or accidental instructions, secrets, executable configuration, unsafe parsers, hostile Git settings, and source with unclear licensing.

The active Project already distinguishes authoritative instructions from reference content. P0-W14 must make that distinction a technical security boundary rather than a prompt convention.

Indirect prompt injection is especially relevant because a model can receive untrusted text from code repositories and may propose actions based on it. Preventing the model from seeing the text would also prevent legitimate investigation. Kiln therefore needs instruction quarantine, provenance, denied Capabilities, read-only source access, external-disclosure controls, and adversarial verification.

## Decision

Reference Repository content always has:

```text
instruction_authority: none
active_instruction: false
permission_effect: none
tool_directives: ignored
```

Instruction-like content remains inert quoted Evidence. It cannot change active Project intent, Tasks, requirements, policy, grants, Tool availability, model selection, write scope, verification, completion, or integration authority.

The knowledge indexer receives a dedicated read-only Capability profile. It receives no source-write, Git-mutation, command-execution, dependency-installation, service, secret-read, model, publication, or network authority.

Kiln enforces the boundary through:

- canonical approved-root checks before every read;
- normalized root-relative paths;
- symlink and special-file policy;
- read-only file handles;
- a fixed, sanitized Git observation adapter;
- separate processes or stronger isolation for risky extractors;
- read-only mounts and no-network profiles where available;
- a Kiln-owned writable data directory outside indexed repositories;
- schema constants that prohibit instruction and permission effects;
- instruction quarantine and renderer-safe candidate projections;
- secret scanning before indexing, display, Context inclusion, or disclosure;
- per-root Privacy modes;
- explicit external-disclosure decisions;
- licensing and source provenance;
- append-oriented security audit events;
- malicious fixture repositories and before-and-after integrity checks.

No source content leaves the machine by default. Remote models, MCP servers, APIs, and hosted embeddings receive only data classes approved by a current policy or explicit disclosure decision.

Future execution against a reference Repository is outside the indexing grant. It requires a separate Task, Run, Capability grant, isolated Environment, explicit Approval, exact source snapshot, new Evidence record, and audit trail.

The detailed contract is in `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md` and `docs/contracts/kiln-knowledge-security.schema.json`.

## Consequences

- Reference repositories remain useful without becoming authority sources.
- Prompt injection can influence a model's proposal, but it cannot directly change authority or execute an action.
- Some extractors are unavailable when the required isolation profile cannot be verified.
- Indexing may be partial when secrets, unsupported file types, path boundaries, licensing uncertainty, or resource limits block content.
- The default user experience is local-only and may require explicit disclosure Approval before a remote model can inspect source.
- Derived data requires dedicated storage, retention, and audit policy.
- Reuse requires compatibility, licensing, provenance, and active-project verification.
- Containers and process boundaries are described honestly; neither is assumed to provide stronger containment than verified.

## Rejected positions

- Trusting `AGENTS.md`, `CLAUDE.md`, prompt files, ADRs, roadmaps, TODOs, or comments from a reference Repository as active instructions.
- Relying only on a system prompt that tells the model to ignore retrieved instructions.
- Giving the knowledge indexer general command or network access.
- Allowing parsers, language servers, package managers, or semantic indexers to start from Repository configuration automatically.
- Storing caches, indexes, temporary files, or audit records inside indexed repositories.
- Following symlinks after only a discovery-time root check.
- Treating local MCP as a sandbox or implicit disclosure authority.
- Sending source to a remote model or hosted embedding service because the service is configured.
- Presenting copied or adapted code without source and license provenance.
- Reusing the indexer's grant for future Repository execution.
- Silently running a risky extractor with weaker isolation when the preferred sandbox is unavailable.

## Review triggers

Review this decision when:

- an accepted query requires execution against a reference Repository;
- a parser or semantic indexer cannot operate under the accepted read-only profile;
- hosted embeddings have a concrete accepted retrieval benefit;
- remote or team knowledge sharing is proposed;
- per-root Privacy modes create unacceptable usability cost;
- a supported platform cannot provide required path or process controls;
- adversarial tests reveal a new instruction, path, execution, disclosure, or provenance bypass;
- legal or licensing review requires stronger reuse controls;
- the knowledge subsystem becomes multi-user or remotely operated.
