# Set Up Project Arsenal in a Repository

Configure an existing repository so Arsenal workflows can discover project conventions instead of hardcoding them.

Do not overwrite useful existing instructions. Explore first, then propose the smallest configuration needed.

## Discover

Inspect:

- `AGENTS.md`, `CLAUDE.md`, and other agent instructions;
- Engineering Doctrine installation/version if present;
- issue tracker/remote conventions;
- status/plan/handoff conventions;
- domain glossary/context documents;
- ADR/decision-record location;
- verification commands from package/task/build config and CI;
- security/permission boundaries relevant to agents;
- monorepo or multi-context boundaries.

## Configure only what is missing

Prefer a small `docs/agents/` configuration surface with pointers rather than duplicating repository truth:

```text
docs/agents/
├── arsenal.md
├── issue-tracker.md        # only if tracker behavior needs explanation
├── domain.md               # only if domain docs need a pointer/layout rule
└── verification.md         # only when canonical verification is not obvious from tooling
```

`docs/agents/arsenal.md` should state:

- which Arsenal workflows this repo expects to use;
- where work/decision tracking lives;
- where domain language and durable decisions live;
- how to find/run authoritative verification;
- project-specific exclusions or adaptations.

## Instruction-file integration

Add or update one concise Arsenal section in the repository's existing agent instruction surface. Point to `docs/agents/arsenal.md`; do not paste the whole Arsenal library into always-loaded context.

If the Engineering Doctrine is not installed, use `agent_workflows/install_engineering_doctrine.md` rather than reimplementing it here.

## Completion

Setup is complete when a fresh agent can answer, without guessing:

1. What governs engineering decisions here?
2. Where is work/decision state tracked?
3. Where is project vocabulary/decision history?
4. What deterministic verification proves completion?
5. Which Arsenal workflows are expected/relevant?

Do not create configuration files whose answers are already obvious and durable in the repository itself.