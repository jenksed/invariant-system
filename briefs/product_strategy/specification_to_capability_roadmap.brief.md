---
kind: prompt-generation-brief
status: source
target_prompt: Specification-to-Capability Roadmap and Backlog
generator: prompt_design/master-sol-fable-super-prompt-generator.md
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that converts a product specification or concept into a capability model, coherent release sequence, and implementation-ready backlog.

## Required behavior

Identify the target operating model and user outcomes; distinguish capabilities from features; identify system/data/workflow/UX/operational/documentation requirements; map dependencies; group work into coherent releases; identify migrations/compatibility work; define acceptance criteria/validation; state non-goals; produce epics/implementation tickets; preserve traceability from user outcome to capability to ticket; avoid an unordered backlog.

## Inputs

Specification or concept, current system, target users, constraints, architecture context, desired release boundary, existing backlog, and technical/design standards.

## Outputs

Target operating model, capability map, dependency map, release roadmap, migration plan, epics, implementation tickets, acceptance gates, risks, non-goals, and traceability matrix.

## Safeguards

Do not create tickets before understanding the capability model, split work so finely the outcome disappears, omit migrations/operations/documentation/validation, mix future ideas into the current release without labeling them, or treat every requested feature as equally important.

## Sol optimization

Emphasize architecture, implementation dependencies, data/API changes, migrations, tests, release gates, exact ticket scope, and technical feasibility.

## Fable optimization

Emphasize user outcomes, product coherence, experience flow, information architecture, design consistency, meaningful release narratives, and acceptance from the user's perspective.
