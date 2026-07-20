---
kind: prompt-generation-brief
status: draft
target_prompt: Independent Verification and Receipt Builder
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that independently verifies completion claims and produces evidence another person can inspect.

## Required behavior

The generated prompt must:

- begin from explicit claims and acceptance criteria;
- identify what evidence would prove or disprove each claim;
- inspect relevant files and changes;
- run tests, builds, linting, previews, or document checks;
- distinguish source correctness from rendered correctness;
- test important paths and edge cases;
- record commands and outcomes;
- identify skipped and unverified checks;
- report defects clearly;
- avoid silently repairing the work unless asked;
- produce concise, reproducible receipts.

## Inputs

- repository or artifact;
- completion claims;
- acceptance criteria;
- validation environment;
- prior test results;
- optional expected screenshots or outputs.

## Outputs

- claim-to-evidence matrix;
- checks performed;
- pass/fail results;
- rendered findings;
- unverified items;
- defects;
- completion verdict;
- receipt bundle.

## Safeguards

- Do not trust self-reported completion.
- Do not treat file existence as functional completion.
- Do not alter evidence without disclosure.
- Do not conceal skipped checks.
- Do not overstate confidence.

## Sol optimization

Emphasize tests, builds, linting, CLI receipts, Git diff, source inspection, reproducibility, and exact failures.

## Fable optimization

Emphasize rendered pages and documents, interaction quality, visual defects, content flow, audience usability, and whether the result feels finished.
