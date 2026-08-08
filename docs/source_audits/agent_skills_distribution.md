# Agent Skills Distribution Source Audit

Audit date: 2026-08-08

Scope: ARS-00B Repository Truth distribution pilot

This audit records the external format and harness assumptions adopted by Project Arsenal for the first portable capability package. It does not make Agent Skills part of Arsenal's canonical architecture.

## Sources consulted

- Agent Skills specification: https://agentskills.io/specification
- Agent Skills reference repository: https://github.com/agentskills/agentskills
- OpenAI/Codex skill catalog and migration notes: https://github.com/openai/skills
- OpenAI Codex project-local skill discovery behavior and maintainer discussion: https://github.com/openai/codex/issues/11314
- Anthropic Agent Skills authoring guidance: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

## Confirmed portable format assumptions

The open Agent Skills specification defines a skill as a directory containing at minimum `SKILL.md`.

`SKILL.md` uses YAML frontmatter followed by Markdown instructions.

Required fields include:

- `name`;
- `description`.

The format permits optional supporting resources such as scripts, references, and assets.

The `name` field is constrained to a short lowercase/hyphenated identifier. The description is discovery metadata and should explain both what the skill does and when it applies.

These assumptions are suitable for an Arsenal export because they are packaging/discovery concerns rather than the full behavioral capability contract.

## Progressive disclosure adoption

Anthropic's current Agent Skills guidance emphasizes that skill metadata is used for discovery and the full body is loaded when relevant, with additional reference files loaded only as needed.

ARS-00B adopts that pattern narrowly:

- `SKILL.md` stays compact;
- the canonical Repository Truth workflow is bundled as a one-hop reference;
- deterministic package verification checks that the reference is still the canonical source snapshot.

Arsenal does not copy every supporting document into the skill preemptively.

## Codex target decision

Codex currently recognizes the shared Agent Skills convention under `.agents/skills`.

The first ARS-00B acceptance path uses a project-local installation:

`<project-root>/.agents/skills/repository-truth`

A Codex maintainer has explicitly described both project-local `.agents/skills` and user-level `~/.agents/skills` as supported discovery roots.

Project-local is the primary pilot target because:

- it binds the skill to the repository under audit;
- it is easy to inspect and remove;
- it avoids depending on user-global indexing state;
- it exercises the shared cross-agent directory rather than a Codex-private legacy directory.

User-global installation remains a convenience path, not the primary acceptance claim.

## Known current ecosystem caveat

Codex desktop/app users have reported intermittent skill-picker/indexing issues for personal `~/.agents/skills` installations even when the documented/discovery path is correct.

ARS-00B therefore does not make a strong claim about a specific desktop picker UI. The package/install contract is filesystem-based and the primary acceptance path is project-local.

This is exactly why Arsenal should own canonical behavior while treating harness discovery as an adapter surface.

## OpenAI ecosystem transition

The historical `openai/skills` catalog now points users toward OpenAI's newer plugin distribution model for current Codex/ChatGPT packaging examples.

ARS-00B does not attempt to build an OpenAI plugin. Doing so would broaden the pilot before Project Arsenal has a Capability Contract or compiler.

The useful durable signal is that OpenAI continues to support skills based on the open Agent Skills standard while higher-level distribution surfaces evolve.

## Arsenal architectural decision

Agent Skills is a **distribution format**, not Project Arsenal's source-of-truth model.

Canonical behavior remains in Arsenal assets today and moves toward Capability Contract v2 under ARS-01.

The ARS-00B package therefore has this shape:

```text
canonical Arsenal asset
        ↓
portable reference snapshot
        ↓
thin SKILL.md discovery adapter
        ↓
harness-specific installation location
```

ARS-03 should later compile this package from canonical capability data and verify the output rather than maintaining parallel behavioral prose.

## Explicit non-adoptions

ARS-00B does not adopt:

- one universal skills installation path for every harness;
- Codex-specific behavior as Arsenal's canonical behavior;
- Claude-specific metadata as Arsenal's capability schema;
- `allowed-tools` as an Arsenal authority model;
- a plugin architecture before ARS-03;
- external skill lifecycle status as Arsenal lifecycle evidence.

## Revalidation triggers

Revisit this audit when:

- the Agent Skills specification changes required frontmatter or package structure;
- Codex changes `.agents/skills` discovery semantics materially;
- ARS-01 introduces Capability Contract v2;
- ARS-03 begins compiler/export work;
- a second harness becomes an explicitly supported distribution target.
