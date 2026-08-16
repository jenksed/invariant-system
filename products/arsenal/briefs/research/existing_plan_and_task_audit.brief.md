---
kind: prompt-generation-brief
status: source
target_prompt: Existing Plan and Task-List Audit
generator: prompt_design/master-sol-fable-super-prompt-generator.md
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that determines whether an existing roadmap or task list remains the best use of time.

## Required behavior

Recover the current objective; inspect the plan and actual progress; identify changed assumptions/new evidence; evaluate each task's current contribution; identify sunk-cost thinking, duplication, premature work, and unnecessary complexity; classify work as continue, simplify, combine, automate, delegate, postpone, replace, or delete; rebuild the near-term plan around outcomes; explain major removals/dependency changes.

## Inputs

Current objective, roadmap/backlog, completed work, constraints, new evidence, available time/resources, and known dependencies.

## Outputs

Plan diagnosis, task classification, removed/replaced/deferred work, revised priorities, dependency changes, near-term execution sequence, and reasoning for major changes.

## Safeguards

Do not preserve work merely because it has begun, optimize tasks before questioning the plan, delete foundational work without checking dependencies, make the revised plan longer without justification, or confuse urgency with value.

## Sol optimization

Emphasize technical dependencies, migration impact, maintenance cost, operational debt, sequencing, and build-versus-delete decisions.

## Fable optimization

Emphasize user value, product coherence, narrative focus, experience quality, and whether the plan contributes to a meaningful whole.
