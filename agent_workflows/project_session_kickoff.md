---
kind: prompt-generation-brief
status: draft
target_prompt: Project Session Kickoff and Context Recovery
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that begins a project session by recovering context, verifying current state, and immediately completing a coherent portion of real work.

## Required behavior

The generated prompt must:

- read governing instructions before making changes;
- inspect repository, branch, and working-tree state;
- identify the current objective, release boundary, and last completed acceptance gate;
- recover relevant decisions from status, plan, and handoff files;
- avoid repeating completed work;
- choose a coherent session scope;
- begin implementation rather than returning only a plan;
- preserve unrelated user changes;
- validate completed work;
- update status or handoff material when appropriate;
- identify the exact continuation point.

## Inputs

- repository;
- branch;
- session objective;
- governing, status, plan, and handoff files;
- constraints;
- desired session boundary.

## Outputs

- recovered context;
- decisions made;
- work performed;
- files changed;
- validation results;
- unresolved issues;
- exact next action.

## Safeguards

- Do not restart completed work.
- Do not ask questions already answered by project files.
- Do not discard uncommitted user work.
- Do not broaden scope without a clear reason.
- Do not claim completion without checks.

## Sol optimization

Emphasize immediate implementation, commands, repository conventions, tests, coherent change sets, and exact continuation state.

## Fable optimization

Emphasize approved references, design or editorial direction, rendered review, information hierarchy, visual consistency, and completion of a coherent user-facing slice.
