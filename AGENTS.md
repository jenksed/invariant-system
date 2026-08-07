# AGENTS.md

Doctrine-Version: 1.0.0

## Authority

Project Arsenal dogfoods the Engineering Doctrine it distributes.

Read and apply:

- `engineering/doctrine/CORE.md`
- `engineering/doctrine/ENGINEERING_DOCTRINE.md`

The doctrine is the default decision framework for planning, implementation, review, verification, and completion in this repository. When another project-specific requirement conflicts with it, make the tradeoff explicit rather than silently ignoring the doctrine.

## Repository Purpose

Project Arsenal is a reusable library of high-leverage prompts, skills, agent guidance, engineering doctrine, and AI workflows. Assets should be broadly reusable, explicit about their intended operating context, and easy to adopt without forcing unrelated machinery onto consuming projects.

## Project-Specific Constraints

1. Keep canonical assets single-sourced. Prefer references/imports over maintaining divergent copies.
2. Separate universal doctrine from tool-, language-, and project-specific adapters.
3. Do not turn a useful document pattern into code or infrastructure until actual adoption demonstrates the need.
4. Preserve existing useful instructions when evolving templates; do not overwrite project-specific guidance casually.
5. Make templates operational: placeholders must be obvious, and examples must not masquerade as universal commands.
6. Prefer small, independently adoptable assets over tightly coupled workflow suites.
7. Version governance artifacts when consumers may need to detect drift or upgrade deliberately.

## Required Work Loop

### Before changing an asset

1. Understand the asset's consumers and intended reuse boundary.
2. Identify whether the change belongs in the canonical doctrine, a generic template, a tool-specific adapter, a language pack, or a project-specific example.
3. Check for duplicated guidance that should instead reference a canonical source.
4. Define how the change will be inspected or verified.

### During implementation

1. Prefer the smallest coherent change.
2. Preserve useful existing behavior and wording unless change is intentional.
3. Keep canonical guidance and adapters clearly separated.
4. Avoid speculative automation that has not yet been justified by repeated use.
5. When a rule must eventually be enforced, identify the deterministic mechanism that could own it rather than pretending prompt text is enforcement.

### Before declaring completion

1. Inspect the full diff.
2. Run `git diff --check` for repository changes when working from a local checkout.
3. Confirm references and paths are valid.
4. Confirm templates do not contain accidental project-specific assumptions.
5. Report what changed, why, and any enforcement or automation intentionally deferred.

## Engineering Doctrine Check

For substantial changes, explicitly consider:

- **Invariants:** What truths must remain true?
- **Failure modes:** What credible failure modes influence the design?
- **Future architecture:** What likely future needs were considered but intentionally not implemented?
- **Blast radius:** What consumers or projects could this change affect?
- **Verification:** What evidence supports the change?

## Operating Principle

**Think broadly. Implement narrowly. Constrain deliberately. Verify with evidence.**
