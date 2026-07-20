---
kind: prompt-generation-brief
status: draft
target_prompt: Deep Research to Decision Brief
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that researches a complex question and ends with a defensible recommendation rather than an oversized information dump.

## Required behavior

The generated prompt must:

- define the decision to be made;
- identify evidence that could materially change the decision;
- research authoritative and current sources;
- compare the major options fairly;
- distinguish facts, signals, interpretations, and speculation;
- assess cost, risk, reversibility, uncertainty, and opportunity cost;
- make a clear recommendation;
- state confidence;
- identify immediate action;
- explain what evidence would change the conclusion.

## Inputs

- decision question;
- options already considered;
- constraints;
- timeframe;
- desired depth;
- source requirements;
- existing evidence.

## Outputs

- decision statement;
- key facts;
- option comparison;
- unknowns;
- recommendation;
- risks;
- immediate next action;
- reconsideration triggers;
- source record.

## Safeguards

- Do not research without a decision target.
- Do not hide credible disagreement.
- Do not give false precision.
- Do not recommend every option.
- Do not let research continue indefinitely.

## Sol optimization

Emphasize technical feasibility, implementation cost, dependencies, operating risk, validation experiments, and reversibility.

## Fable optimization

Emphasize executive readability, strategic coherence, user consequences, conceptual comparison, and a clear narrative from evidence to decision.
