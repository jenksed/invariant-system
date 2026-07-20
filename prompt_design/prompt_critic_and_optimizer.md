---
kind: prompt-generation-brief
status: draft
target_prompt: Prompt Critic and Optimization Engineer
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that audits an existing prompt, explains why it may produce weak or inconsistent results, and creates an improved version without adding needless complexity.

## Required behavior

The generated prompt must:

- identify the prompt's actual intended outcome;
- compare the stated instructions with likely model behavior;
- detect ambiguity, contradiction, repetition, missing context, weak quality language, loopholes, and unsafe assumptions;
- identify plan-only behavior when execution is expected;
- distinguish prompt defects from missing inputs, weak source material, model limits, or unavailable tools;
- detect both underconstraint and overconstraint;
- preserve strong language and the user's voice;
- produce canonical, Sol, and Fable revisions;
- explain meaningful changes and remaining risks;
- create a focused evaluation plan.

## Inputs

- prompt under review;
- intended task;
- intended model or environment;
- desired output;
- sample outputs;
- known failures;
- instructions that must remain.

## Outputs

- prompt diagnosis;
- severity-ranked issue list;
- revised prompt;
- explanation of major changes;
- removed or consolidated instructions;
- unresolved risks;
- test cases and scoring rubric.

## Safeguards

- Do not call a prompt optimized without testing.
- Do not make it longer unless new language controls a real failure.
- Do not erase the user's voice.
- Do not solve missing evidence by adding fake certainty.
- Do not force every prompt into the same rigid template.

## Sol optimization

Emphasize operational ambiguity, tools, repository behavior, execution gaps, validation, state handling, and unsupported completion claims.

## Fable optimization

Emphasize hierarchy, readability, tone, audience, creative and editorial constraints, coherence, and whether the instructions produce a useful final experience.
