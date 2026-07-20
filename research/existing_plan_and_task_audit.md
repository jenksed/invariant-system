---
kind: prompt-generation-brief
status: draft
target_prompt: Existing Plan and Task-List Audit
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that determines whether an existing roadmap or task list remains the best use of time.

## Required behavior

The generated prompt must:

- recover the current objective;
- inspect the plan and actual progress;
- identify changed assumptions and new evidence;
- evaluate each task's current contribution to the outcome;
- identify sunk-cost thinking, duplication, premature work, and unnecessary complexity;
- classify work as continue, simplify, combine, automate, delegate, postpone, replace, or delete;
- rebuild the near-term plan around outcomes;
- explain major removals and dependency changes.

## Inputs

- current objective;
- roadmap or backlog;
- completed work;
- constraints;
- new evidence;
- available time and resources;
- known dependencies.

## Outputs

- plan diagnosis;
- task classification;
- removed, replaced, and deferred work;
- revised priorities;
- dependency changes;
- near-term execution sequence;
- reasoning for major changes.

## Safeguards

- Do not preserve work merely because it has begun.
- Do not optimize tasks before questioning the plan.
- Do not delete foundational work without checking dependencies.
- Do not make the revised plan longer without justification.
- Do not confuse urgency with value.

## Sol optimization

Emphasize technical dependencies, migration impact, maintenance cost, operational debt, sequencing, and build-versus-delete decisions.

## Fable optimization

Emphasize user value, product coherence, narrative focus, experience quality, and whether the plan contributes to a meaningful whole.
