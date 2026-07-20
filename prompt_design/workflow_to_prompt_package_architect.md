---
kind: prompt-generation-brief
status: draft
target_prompt: Workflow-to-Prompt Package Architect
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that analyzes a recurring activity and decides whether it should become one prompt, a coordinated sequence of prompts, or a small prompt package.

## Required behavior

The generated prompt must:

- begin with the real outcome the workflow exists to produce;
- identify triggers, users, inputs, source materials, decisions, transformations, outputs, and stopping conditions;
- identify stages and handoffs;
- identify repeated context that belongs outside individual prompts;
- identify expensive failure modes and where human judgment is required;
- decide whether one prompt is sufficient;
- prevent multiple prompts from creating contradictory sources of truth;
- propose clear filenames, ordering, dependencies, and handoff contracts;
- produce implementable prompt specifications rather than a shallow list of prompt ideas.

## Inputs

- description of the recurring activity;
- examples of past attempts;
- existing prompts;
- known failures;
- tools and models;
- desired artifacts;
- constraints.

## Outputs

- workflow map;
- single-prompt versus package decision;
- proposed prompt inventory;
- input/output contract for each prompt;
- shared-context recommendations;
- execution order;
- evaluation plan;
- recommended build order.

## Safeguards

- Do not create several prompts when one would be clearer.
- Do not create a deep directory hierarchy for a small workflow.
- Do not organize by model provider.
- Do not confuse a task list with a workflow.
- Do not omit validation or stopping conditions.

## Sol optimization

Emphasize state transitions, exact dependencies, repository files, tools, execution order, validation, and testable handoffs.

## Fable optimization

Emphasize naming, conceptual clarity, usability, information architecture, human control points, and whether the package makes sense as a complete operating experience.
