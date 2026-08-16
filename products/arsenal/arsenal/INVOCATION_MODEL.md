# Arsenal Invocation Model

Schema-Version: 1.0.0

Project Arsenal separates reusable behavior from harness-specific slash-command packaging.

An asset may optionally declare an `invocation` mode in the registry.

## Modes

### `human`

The user intentionally starts the capability. Use for orchestration that changes the shape of the work, creates external tracker state, or deliberately launches a heavyweight process such as Wayfinding.

### `agent`

The agent may select the capability automatically when the task matches. Use for reusable disciplines such as bug diagnosis, TDD, research, verification, or domain-language maintenance.

### `reference`

Not an executable flow. Other assets read it for shared vocabulary, policy, or method rules.

### `composed`

Normally reached as part of a larger workflow/package. It can still be used directly, but its primary role is composition.

## Design rules

1. Invocation and implementation are separate concerns. A method can be packaged for Claude, Codex, Kiln, or another harness without changing the method itself.
2. Human-invoked orchestrators may depend on agent-invocable primitives.
3. Shared reference should live once and be pointed to, not copied into every prompt.
4. Prefer `agent` only when automatic selection is useful enough to justify its discovery/context cost.
5. Heavyweight planning processes should not auto-fire merely because a task is large; their preconditions must actually be present.
6. Harness adapters may map these modes into native metadata, slash commands, skills, policies, or tool routing.

## Future direction

Project Arsenal defines the capability contract. A future runtime such as Kiln may make invocation, permissions, context loading, and evidence capture structural rather than prompt-only.