# Development Agent Asset Notes

**Document type:** Reference

Kiln stores project-local skills, Pi prompt templates, and optional specialist-agent definitions in the repository.

These files support the coding agent that builds Kiln. They do not run inside the Kiln product.

## Asset contract

Every project-local skill and specialist-agent definition declares an invocation mode and a lifecycle status. `scripts/validate-agent-assets` enforces both fields and rejects values outside these sets.

### Invocation mode

`invocation` records who starts the asset:

| Mode | Meaning |
| --- | --- |
| `human` | The developer starts it deliberately. Use for orchestration that changes the shape of the work or makes completion claims. |
| `agent` | The coding agent may select it when the task matches. Use for reusable disciplines. |
| `reference` | Not an executable flow. Other assets read it for shared vocabulary or rules. |
| `composed` | Normally reached through a larger workflow, such as a review or closeout step. |

A heavyweight asset should not use `agent` merely because a task is large. Its preconditions must actually be present.

### Lifecycle status

`status` is an evidence claim, not a confidence claim:

| Status | Meaning |
| --- | --- |
| `draft` | No recorded evaluation evidence yet. |
| `testing` | Under evaluation against recorded cases. |
| `stable` | Recorded evaluation evidence supports the behavior. |

Every current asset is `draft`, because the repository holds no recorded evaluation evidence for any of them. Do not promote an asset because its prose reads well. Promotion requires recorded evidence for the claimed status.

These concepts are adapted from the Project Arsenal asset contract and invocation model. Kiln keeps its own reduced field set and its own enforcement, and Project Arsenal has no authority over Kiln.

## Skills

Project-local skills use this path:

```text
.agents/skills/<skill-name>/SKILL.md
```

A compatible coding agent can discover these skills from the repository.

Run this check after changing a skill:

```bash
scripts/validate-agent-assets
```

## Pi prompt templates

Pi prompt templates use this path:

```text
.pi/prompts/
```

The initial templates are:

- `/start-work`;
- `/review-work`;
- `/close-work`.

The command syntax depends on the active Pi installation. The repository stores the prompt content and does not install or change the user's global Pi configuration.

## Specialist agents

Optional specialist definitions use this path:

```text
.pi/agents/
```

The repository does not implement or install a Pi subagent extension.

Use the specialist definitions only when the current Pi environment has a reviewed extension that loads project agents.

The specialist definitions enforce these boundaries:

- the OTP reviewer has read-only tools;
- the integrity reviewer has read-only tools;
- the verifier has read and Bash tools for non-mutating checks;
- no specialist has edit or write tools;
- the main coding agent remains the implementation owner.

## Security boundary

Do not grant a third-party subagent extension access to Kiln before reviewing:

- its source repository;
- installation method;
- tool forwarding behavior;
- prompt and context forwarding;
- subprocess behavior;
- credential access;
- telemetry;
- update mechanism.

The repository agent definitions do not establish trust in the extension that executes them.
