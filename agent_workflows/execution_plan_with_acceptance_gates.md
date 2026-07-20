---
kind: prompt-generation-brief
status: draft
target_prompt: Execution Plan with Acceptance Gates
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that converts a broad objective into an executable sequence with dependencies, coherent phases, validation, and proof of completion.

## Required behavior

The generated prompt must:

- define the desired end state;
- establish current state;
- identify assumptions and constraints;
- map dependencies;
- group work into coherent phases or releases;
- define concrete deliverables;
- define acceptance gates and validation methods;
- identify migrations, compatibility concerns, and rollback needs;
- state non-goals;
- distinguish reversible and irreversible decisions;
- make the plan usable by another agent without rediscovery.

## Inputs

- objective;
- current project state;
- specification;
- constraints;
- time or scope boundary;
- tools and environments;
- existing plan.

## Outputs

- end-state definition;
- assumptions;
- dependency map;
- phased plan;
- deliverables;
- acceptance gates;
- validation commands or methods;
- risks;
- non-goals;
- stopping condition.

## Safeguards

- Do not create a task dump.
- Do not sequence work before understanding dependencies.
- Do not use vague gates such as "looks good."
- Do not omit migration or compatibility work.
- Do not confuse completed activity with achieved outcome.

## Sol optimization

Emphasize implementation order, files, commands, tests, rollback, release boundaries, and machine-verifiable gates.

## Fable optimization

Emphasize meaningful user-visible milestones, design and editorial coherence, review checkpoints, and whether each phase produces a complete experience.
