---
kind: prompt-generation-brief
status: draft
target_prompt: Session Handoff and Continuation Pack
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that captures enough verified context for another model or later session to continue without repeating discovery work.

## Required behavior

The generated prompt must:

- state the session objective;
- describe verified completed work;
- identify files changed;
- record validation and failed checks;
- preserve important decisions and rationale;
- identify unresolved issues;
- record repository, branch, and working-tree state;
- separate required next work from optional ideas;
- state the exact continuation point;
- produce a ready-to-use continuation prompt.

## Inputs

- session transcript or notes;
- repository;
- Git state;
- completed work;
- validation results;
- unresolved decisions;
- relevant project files.

## Outputs

- current status;
- completed work;
- files changed;
- validation;
- decisions;
- known issues;
- immediate next action;
- continuation instructions;
- exact files and commands to inspect first.

## Safeguards

- Do not describe planned work as completed.
- Do not omit failed tests.
- Do not write "continue where we left off."
- Do not bury the immediate next step.
- Do not overload the handoff with obsolete history.

## Sol optimization

Emphasize branch, commit, working tree, exact files, commands, tests, implementation state, and next code change.

## Fable optimization

Emphasize current creative or editorial direction, references, approved choices, unresolved experience problems, and the next coherent visible deliverable.
