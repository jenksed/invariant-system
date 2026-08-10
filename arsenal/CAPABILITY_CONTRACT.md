# Arsenal Capability Contract v2

Schema-Version: 2.2.0

Project Arsenal distinguishes **assets** from **capabilities**.

```text
Asset
  = a registered repository artifact or package

Capability
  = a versioned behavioral contract for achieving a useful outcome
```

The Asset Contract remains authoritative for repository identity, path, artifact kind, asset lifecycle, and asset-to-asset relationships. The Capability Contract adds the behavioral information needed to reason about useful work without binding that behavior to any one harness or distribution format.

Canonical capability data is composed from:

- `arsenal/capabilities/*.json` — one capability fragment per file, loaded in filename order;
- `arsenal/capability.schema.json` — structural schema for one capability fragment;
- `scripts/capability_audit.py` — executable cross-contract validation against the merged Asset Registry.

Fragmentation is deliberate. Capabilities should be independently evolvable and pack-friendly rather than recreating a single large merge-conflict hotspot.

Every fragment uses the same capability schema version.

## Identity

Every capability defines:

- `id` — stable dotted machine identity prefixed `capability.`;
- `version` — semantic version of the behavioral contract;
- `display_name` — current human-facing name;
- `aliases` — compatibility/discovery names that are not machine identity;
- `purpose` — one observable outcome;
- `lifecycle` — evidence-backed capability maturity;
- `invocation` — harness-neutral invocation semantics.

A display-name change does not require an ID change.

Aliases are compatibility and discovery metadata only. They must never be used as canonical machine keys. Public names may therefore evolve from **Grill** to **Pressure Test** and from **Wayfind/Wayfinding** to **Recon** without rewriting existing asset IDs or losing historical provenance.

Display names and aliases are case-insensitively unique across the merged capability set.

## Discovery

Every capability defines:

- `discovery.use_when` — non-empty array of positive applicability statements;
- `discovery.do_not_use_when` — optional array of meaningful exclusions and collisions.

Discovery statements must be behavioral and harness-neutral. They must not encode target-specific marketing copy, harness identifiers, or prompt-style imperative language. The `purpose` field remains the concise observable outcome; discovery expands *when* the outcome applies without restating *what* the outcome is.

Discovery belongs to canonical capability truth. Compiler adapters may derive target-specific frontmatter (such as Agent Skills `description` fields) from canonical discovery plus target-specific packaging metadata, but must not duplicate the discovery statements in adapter-only fields.

## Invocation semantics

Capabilities declare one of three harness-neutral invocation semantics:

- `human` — the capability expects explicit human initiation and confirmation;
- `agent` — the capability is appropriate for autonomous agent invocation;
- `composed` — the capability is meaningful only as part of a composed sequence.

Target adapters must preserve the declared invocation boundary. Adapters that cannot preserve a required boundary must either:

- refuse to export the capability for that target;
- emit an explicit unsupported/incompatible state;
- require a target adapter policy that demonstrably preserves the boundary.

Adapters must not silently flatten invocation semantics.

## Resources and loading

Capabilities declare an optional `implementation.resources` array describing each bundled asset's role and load policy. Resources let a capability express progressive disclosure instead of dumping every implementation asset into model context.

Resource roles:

- `instructions` — small activation content that belongs in the always-loaded entrypoint;
- `reference` — bundled canonical workflow that the model reads on demand;
- `script` — executable code that the runtime should invoke rather than read;
- `template` — reusable file or content template that the model fills in;
- `fixture` — bounded state used to test or demonstrate the capability;
- `asset` — any other bundled artifact.

Loading policies:

- `always` — bundled into the always-loaded entrypoint (subject to documented size policy);
- `on-demand` — bundled separately; the model reads the reference when it needs the content;
- `execute-not-read` — bundled as a callable artifact; the runtime executes rather than the model reading the content.

Role × load compatibility:

- `instructions`, `reference`, `template` may use `always` or `on-demand` (never `execute-not-read`);
- `script`, `fixture`, `asset` may use `on-demand` or `execute-not-read`.

The `primary_asset` remains the canonical behavioral reference. When `resources` is absent the compiler derives a single `reference` / `on-demand` resource from the primary asset for backward compatibility; when present the declared resources are authoritative.

Resource paths are not specified inline. The compiler derives safe repository-relative paths from the registered asset paths and rejects path traversal at compile time.

## Behavioral interface

Each capability declares:

- `inputs` — named information the capability can consume;
- `outputs` — named useful results the capability produces;
- `preconditions` — conditions that must be true before the behavior is appropriate;
- `context` — required and preferred evidence/context classes.

Inputs and outputs describe behavioral meaning, not CLI arguments or prompt variables. Harness adapters may translate them into native UI, skill metadata, commands, or tool calls later.

ARS-04 may use these declarations to construct a Capability Graph. ARS-01 does not build that router yet.

## Implementation boundary

A capability references implementations through registered **asset IDs**, never direct harness package paths.

```json
{
  "implementation": {
    "primary_asset": "agent.repository-truth-audit",
    "asset_ids": ["agent.repository-truth-audit"]
  }
}
```

Rules:

1. Every implementation asset resolves in the merged Asset Registry.
2. `primary_asset` appears in `asset_ids`.
3. Asset status and capability lifecycle are separate evidence claims.
4. A capability may compose multiple assets without making those assets identical to the capability.
5. Distribution artifacts such as the ARS-00B Repository Truth Agent Skill are derived packaging, not canonical capability behavior.

## Authority

Capabilities declare authority in three disjoint sets:

- `required` — completion is impossible without it;
- `optional` — may be used when separately available and authorized;
- `forbidden` — outside the capability's default authority boundary.

Initial authority vocabulary:

- `filesystem.read`
- `filesystem.write`
- `shell.execute`
- `network.read`
- `network.write`
- `git.read`
- `git.write`
- `tracker.read`
- `tracker.write`
- `secrets.read`
- `cloud.local`
- `cloud.remote`
- `production.mutate`
- `human.confirmation`

ARS-01 records authority; it does not yet enforce operating-system permissions. ARS-08 owns the Trust & Authority Plane that will turn these declarations into enforceable policy.

No token may occur in more than one authority set. A `read-only` capability may not require known write/mutation authority.

## Mutation class

Every capability declares one mutation class:

- `read-only` — no intentional state mutation;
- `workspace-write` — may change local/repository working state;
- `external-write` — may intentionally mutate an external system;
- `high-consequence` — may mutate staging, production, or another consequential surface.

`reversible` describes the expected normal rollback/removal property of the declared mutation class. It is not proof that every individual action is reversible.

## Execution surfaces

Capabilities describe execution intent using:

- `preferred` — lowest/normal execution surface;
- `allowed` — surfaces the current contract may use;
- `prohibited` — surfaces requiring another capability, escalation, or contract revision.

Initial substrate vocabulary:

- `reasoning-only`
- `repository-read`
- `local-process`
- `local-container`
- `local-emulator`
- `local-cluster`
- `remote-sandbox`
- `shared-nonproduction`
- `staging`
- `production`
- `user-mediated`

`preferred` is a subset of `allowed`. `allowed` and `prohibited` do not overlap.

ARS-05 owns generalized substrate selection and fidelity semantics. ARS-01 records enough behavioral intent for that future work without pretending the selector already exists.

## Verification and evidence

Each capability declares:

- `verification.requirements` — consequential proof obligations;
- `verification.receipt_required` — whether a durable receipt is mandatory;
- `evidence_outputs` — inspectable outputs a caller may rely on within the declared scope.

Initial evidence kinds:

- `report`
- `artifact`
- `command`
- `test`
- `diff`
- `receipt`
- `decision-record`
- `runtime-observation`
- `verdict`

These are evidence labels, not claims that an artifact has already been independently validated.

## Evaluation and lifecycle

Capability lifecycle values:

- `draft`
- `testing`
- `stable`
- `deprecated`

Evaluation status values:

- `unassessed`
- `planned`
- `candidate`
- `qualified`

Rules:

1. `testing` requires an evaluation-suite asset and evaluation status `candidate` or `qualified`.
2. `stable` requires at least one evaluation-suite asset and status `qualified`.
3. ARS-01 does not promote any Core Arsenal capability merely because it now has a schema.
4. ARS-02 Arsenal Bench owns the first executable evidence capable of moving capability lifecycle beyond `draft`.

This keeps **stable is an evidence claim** true across assets and capabilities.

## Provenance and compatibility

`provenance.asset_ids` records registered assets that materially define or justify the capability contract.

`compatibility.supersedes` may name prior capability IDs only when a real capability migration exists. It is not used to rewrite asset history.

`compatibility.notes` records durable compatibility decisions such as the Pressure Test/Grill and Recon/Wayfinding public-name transitions.

## Harness-neutrality rule

Canonical capability fragments must not encode harness packaging.

The executable audit rejects product/package-specific markers such as:

- Codex;
- Claude;
- `.agents/skills`;
- Agent Skills;
- slash-command packaging;
- plugin packaging.

Those belong in distribution adapters and compiler targets.

The ARS-00B Repository Truth Agent Skill is therefore a **compiler regression target**, not a field in the canonical capability definition.

## First migration set

ARS-01 represents, without harness-specific semantics:

1. Repository Truth;
2. Pressure Test — current Grill/grilling lineage;
3. Recon — current Wayfind/Wayfinding lineage;
4. Diagnose;
5. TDD;
6. Review;
7. Verify;
8. Resume;
9. Local Cloud Feature Delivery — execution-backed Floci composition.

The first eight exercise reusable reasoning and engineering behavior. The ninth prevents the contract from accidentally assuming every capability is prompt-only or read-only.

## Validation

Run:

```bash
python3 scripts/capability_audit.py
python3 scripts/test-capability-contract.py
python3 scripts/arsenal_audit.py
```

The capability audit validates the merged capability set and every reference into the merged Asset Registry.

The negative-contract suite proves rejection of at least:

- duplicate public names/aliases;
- missing implementation assets;
- overlapping authority sets;
- read-only capabilities requiring write authority;
- invalid execution-substrate relationships;
- harness-specific leakage into canonical capability data;
- unsupported `stable` lifecycle claims.

## Change rule

When adding or materially changing a capability:

1. add or update its file under `arsenal/capabilities/`;
2. keep referenced implementation/provenance assets registered under the Asset Contract;
3. run the capability audit and negative-contract suite;
4. update distribution artifacts only when their adapter/compiler contract requires it;
5. do not promote lifecycle without ARS-02-compatible evaluation evidence;
6. inspect capability and asset diffs independently.

## What this contract deliberately does not do

ARS-01 does **not** yet provide:

- automatic capability routing or graph execution — ARS-04;
- generalized execution-substrate selection/fidelity enforcement — ARS-05;
- telemetry/observability — ARS-07;
- enforceable permission mediation — ARS-08;
- typed project knowledge — ARS-09;
- intent compilation — ARS-10;
- autonomous capability evolution — ARS-12.

The contract creates a stable behavioral representation those later systems can consume without making them prerequisites for useful capability definitions today.
