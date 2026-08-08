# Arsenal Compiler & Distribution Contract

Status: ARS-03 v0

Project Arsenal capabilities are canonical behavioral contracts. Distribution packages are derived artifacts for specific harness ecosystems.

## Responsibility boundary

```text
Capability Contract
  = what competence means

Asset Registry
  = where canonical implementation/provenance lives

Export Plan
  = target-specific packaging metadata

Compiler
  = deterministic translation

.arsenal.lock
  = pinned competence + provenance + generated-export evidence

Distribution package
  = derived harness-facing artifact
```

A downstream package must not become a second behavioral authority.

## v0 target

ARS-03 v0 deliberately proves one exporter deeply before multiplying formats:

- `capability.repository-truth`
- target: `agent-skills`
- output: `distribution/agent-skills/repository-truth/`

The exporter must reproduce the manually proven ARS-00B package shape from canonical Capability Contract data, the registered primary implementation asset, and the small target-specific export plan.

Claude, Codex-specific, MiniMax/generic, and Kiln-native packages remain later export adapters unless repository evidence proves a distinct format is required. Codex can already consume the Agent Skills pilot.

## Canonical inputs

The compiler reads:

1. `arsenal/capabilities/*.json`
2. merged Asset Registry (`arsenal/registry.json` + `arsenal/registry.d/*.json`)
3. `arsenal/compiler/export-plan.json`
4. canonical implementation assets referenced by the capability

Target-specific export metadata may describe discovery/package concerns such as package name, description, compatibility text, and destination. It must not duplicate the canonical behavior body.

## Generated Agent Skills package

The v0 Agent Skills adapter generates:

- `SKILL.md` — discovery adapter generated from capability metadata and authority boundaries;
- `references/<canonical-source>` — byte-for-byte snapshot of the registered primary implementation asset;
- `arsenal-manifest.json` — proof-carrying package manifest with capability identity, qualification, authority, provenance, and content digests.

Generated files are not hand-maintained behavioral sources.

## Competence lockfile

`.arsenal.lock` is deterministic JSON despite its extension.

It pins the competence this repository has chosen to distribute:

- capability ID and version;
- exact capability-file digest;
- lifecycle and evaluation qualification at compile time;
- registered primary implementation asset and exact digest;
- export target and adapter version;
- generated package path and digest;
- export-plan digest.

The lockfile intentionally does **not** pin a model or harness runtime. Model choice may later be informed by evaluation evidence, but the competence contract is separable from the model executing it.

The lockfile contains no timestamps so an unchanged source graph produces byte-identical output.

## Qualification semantics

A lockfile records qualification; it does not create qualification.

For example:

- `draft / unassessed` remains draft/unassessed in the lock;
- `testing / candidate` remains testing/candidate;
- the compiler may not silently promote lifecycle state;
- stale or superseded evaluation evidence must be handled by the evaluation/trust layers, not hidden by compilation.

## Determinism

Given identical canonical inputs, the compiler must produce byte-identical:

- `SKILL.md`;
- reference snapshot;
- package manifest;
- `.arsenal.lock`.

Package digests are computed from sorted relative paths and SHA-256 file digests.

## Safety

The compiler:

- writes only declared distribution paths and `.arsenal.lock`;
- rejects absolute paths and `..` traversal;
- rejects unknown capabilities and unknown targets;
- rejects export plans whose package names are invalid;
- resolves implementation paths only through the Asset Registry;
- never executes capability instructions while compiling them;
- never adds authority not present in the capability;
- never requires secrets or remote-provider credentials.

## Verification

`python3 scripts/arsenal_compile.py verify` must dry-build every declared export into a temporary directory and byte-compare it with the checked-in distribution plus `.arsenal.lock`.

A manually edited generated package therefore fails closed.

## ARS-00B regression

The Repository Truth package must continue to satisfy the ARS-00B distribution and installer contract. Compilation does not weaken the existing byte-for-byte canonical reference requirement.

## Exit criteria

ARS-03 v0 is complete when:

1. the Repository Truth Agent Skills package is compiler-generated;
2. the generated reference remains byte-identical to the canonical workflow;
3. `.arsenal.lock` is deterministic and records capability/provenance/qualification/export digests;
4. negative tests reject invalid plans and package drift;
5. the old ARS-00B distribution verifier and installer remain green;
6. final ARS-03 CI is read-only;
7. generated artifacts are verified rather than hand-edited.
