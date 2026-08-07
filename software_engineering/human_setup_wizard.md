# Build a Human Setup / Cutover Wizard

Use when progress is blocked by steps a human genuinely must perform: credential creation, third-party dashboard actions, privileged approvals, physical/manual tasks, or an irreversible cutover.

Do not use this to offload work the agent can perform safely itself.

## Goal

Turn a vague manual procedure into an explicit, gated, repeatable walkthrough with deterministic checks around the human steps.

## Scope

Inspect repository/config/CI/docs first and determine:

- ordered stages;
- inputs/values each stage produces;
- where each value belongs;
- secret vs non-secret handling;
- irreversible actions requiring confirmation;
- verification possible after each stage.

Show the stage plan before authoring automation.

## Authoring principles

When a script is appropriate:

- make the current stage and remaining stages visible;
- open/provide the authoritative destination before asking for a value;
- capture secrets without echoing them;
- persist values idempotently to the intended target;
- confirm before destructive/irreversible steps;
- verify syntax/static correctness before handoff;
- do not fake an end-to-end run that requires human/browser interaction.

When scripting is not appropriate, produce the same structure as a checklist with explicit completion criteria and evidence capture.

## Completion

The procedure is ready when a competent person unfamiliar with the task can complete it without inventing steps, and the resulting system state can be verified.