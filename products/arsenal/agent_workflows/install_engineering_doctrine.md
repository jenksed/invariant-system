# Install or Audit the Engineering Doctrine

Use this workflow from the root of a software repository when you want an AI coding agent to install, update, or audit the project's engineering-governance instructions.

---

You are working in an existing software repository.

Your task is to make the repository conform to the Engineering Doctrine maintained in `project-arsenal`, while preserving and respecting any valid repository-specific instructions already present.

## Source material

Use these canonical assets from `project-arsenal`:

- `engineering/doctrine/CORE.md`
- `engineering/doctrine/ENGINEERING_DOCTRINE.md`
- `engineering/templates/AGENTS.md`
- `engineering/templates/CLAUDE.md`

## Required process

1. Inspect the repository before editing:
   - existing `AGENTS.md`, `CLAUDE.md`, nested agent instruction files, and equivalent governance files;
   - README and contributor documentation;
   - language/toolchain configuration;
   - existing test, lint, type-check, build, security, and verification commands;
   - CI workflows and relevant scripts.

2. Identify conflicts and repository-specific constraints. Do not overwrite valuable existing instructions merely to match a template.

3. Install or update a root `AGENTS.md` so that:
   - the Engineering Doctrine is the default decision framework;
   - the compact constitutional core is present or authoritatively referenced;
   - project-specific invariants and constraints remain explicit;
   - the work loop requires understanding, bounded implementation, deterministic feedback, and evidence-backed completion;
   - real repository verification commands replace template placeholders;
   - meaningful deviations from the doctrine are explicit.

4. Install or update root `CLAUDE.md` so that it imports or delegates to `AGENTS.md` rather than duplicating the full doctrine, unless the repository's Claude tooling requires a different mechanism.

5. Preserve useful existing agent-specific instructions by placing them in the appropriate project-specific section or agent adapter.

6. For substantial engineering work, ensure the repository guidance asks these questions where appropriate:
   - What invariants must remain true?
   - What credible failure modes influence the design?
   - What future needs were considered but intentionally not implemented?
   - What is the blast radius and reversibility of the change?
   - What deterministic evidence will prove completion?

7. Prefer deterministic enforcement over prompt-only rules where the repository already has an appropriate mechanism. Do not build new policy infrastructure merely to satisfy this workflow unless requested. Instead, identify follow-up opportunities such as CI checks, hooks, verification scripts, type/schema constraints, or permissions.

8. Validate the result:
   - inspect the final diff;
   - ensure existing instructions were not accidentally lost;
   - ensure verification commands are real and repository-appropriate;
   - ensure `AGENTS.md` and `CLAUDE.md` do not contain conflicting copies of the doctrine;
   - record the adopted `Doctrine-Version`.

## Completion report

Report:

- files created or changed;
- existing guidance preserved or relocated;
- repository-specific doctrine adaptations;
- verification commands established;
- unresolved conflicts or uncertainty;
- deterministic-enforcement opportunities intentionally deferred.

Do not claim the governance installation is complete if important repository instructions remain unresolved or the resulting files conflict.
