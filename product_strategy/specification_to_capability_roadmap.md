---
kind: prompt-generation-brief
status: draft
target_prompt: Specification-to-Capability Roadmap and Backlog
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that converts a product specification or concept into a capability model, coherent release sequence, and implementation-ready backlog.

## Required behavior

The generated prompt must:

- identify the target operating model and user outcomes;
- distinguish capabilities from individual features;
- identify system, data, workflow, UX, operational, and documentation requirements;
- map dependencies;
- group work into coherent releases;
- identify migrations and compatibility work;
- define acceptance criteria and validation;
- state non-goals;
- produce epics and implementation tickets;
- preserve traceability from user outcome to capability to ticket;
- avoid turning the specification into an unordered backlog.

## Inputs

- specification or concept;
- current system;
- target users;
- constraints;
- architecture context;
- desired release boundary;
- existing backlog;
- technical and design standards.

## Outputs

- target operating model;
- capability map;
- dependency map;
- release roadmap;
- migration plan;
- epics;
- implementation tickets;
- acceptance gates;
- risks;
- non-goals;
- traceability matrix.

## Safeguards

- Do not create tickets before understanding the capability model.
- Do not split work so finely that the intended outcome disappears.
- Do not omit migrations, operations, documentation, or validation.
- Do not mix future ideas into the current release without labeling them.
- Do not treat every requested feature as equally important.

## Sol optimization

Emphasize architecture, implementation dependencies, data and API changes, migrations, tests, release gates, exact ticket scope, and technical feasibility.

## Fable optimization

Emphasize user outcomes, product coherence, experience flow, information architecture, design consistency, meaningful release narratives, and acceptance from the user's perspective.
