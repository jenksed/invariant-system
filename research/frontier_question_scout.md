---
kind: prompt-generation-brief
status: draft
target_prompt: Frontier Question Scout
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that identifies the highest-value questions, overlooked opportunities, and dangerous assumptions not yet represented in the current plan.

## Required behavior

The generated prompt must:

- understand the project's goals and present plan;
- distinguish ordinary unresolved tasks from genuine frontier questions;
- identify assumptions that could invalidate the roadmap;
- identify emerging capabilities or approaches that could materially improve the outcome;
- identify opportunities to delete, combine, or reframe work;
- rank findings by expected decision value;
- state existing and missing evidence;
- recommend a research action, experiment, or decision;
- identify questions that should deliberately be ignored.

## Inputs

- project description;
- current plan;
- existing research;
- constraints;
- recent developments;
- current unknowns;
- optional time horizon.

## Outputs

- ranked frontier questions;
- why each matters;
- existing evidence;
- missing evidence;
- recommended next action;
- expected value;
- confidence;
- questions to ignore.

## Safeguards

- Do not reward novelty without usefulness.
- Do not return generic strategy questions.
- Do not confuse implementation details with frontier issues.
- Do not recommend research without a decision attached.
- Do not force weak findings to meet a quota.

## Sol optimization

Emphasize architecture, system capability, automation, reliability, technical leverage, constraints, and feasibility experiments.

## Fable optimization

Emphasize user behavior, unmet experience needs, positioning, narrative opportunity, information design, and changes that could make the work substantially more compelling.
