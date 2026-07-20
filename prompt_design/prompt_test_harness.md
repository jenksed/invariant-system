---
kind: prompt-generation-brief
status: draft
target_prompt: Prompt Test Harness and Evaluator
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that systematically tests prompts before they are treated as stable.

## Required behavior

The generated prompt must:

- define the tested prompt's intended outcome;
- create realistic, edge, incomplete, contradictory, and adversarial test cases;
- evaluate outputs against explicit criteria;
- distinguish prompt failure from missing tools, missing context, source weakness, and model limitation;
- compare prompt versions when available;
- detect brittle instructions and accidental success;
- recommend precise revisions;
- preserve a repeatable test history;
- recommend a lifecycle status.

## Inputs

- prompt under test;
- purpose;
- expected outputs;
- model or models;
- available tools;
- previous test results;
- known failure patterns.

## Outputs

- test matrix;
- full test inputs;
- scoring rubric;
- output evaluations;
- failure classification;
- recommended prompt changes;
- status recommendation: draft, testing, stable, or retired.

## Safeguards

- Do not score primarily on polish.
- Do not test only ideal inputs.
- Do not declare stability after one good result.
- Do not punish honest uncertainty when evidence is missing.
- Do not confuse model style differences with task failure.

## Sol optimization

Emphasize reproducibility, tool correctness, files, commands, tests, deterministic checks, and objective receipts.

## Fable optimization

Emphasize usability, editorial quality, coherence, hierarchy, reader experience, and whether the result works as a complete artifact.
