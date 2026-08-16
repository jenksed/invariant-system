---
kind: prompt-generation-brief
status: source
target_prompt: Independent Verification and Receipt Builder
generator: prompt_design/master-sol-fable-super-prompt-generator.md
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that independently verifies completion claims and produces evidence another person can inspect.

## Required behavior

- begin from explicit claims and acceptance criteria;
- identify evidence that would prove or disprove each claim;
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

Repository or artifact, completion claims, acceptance criteria, validation environment, prior test results, and optional expected screenshots or outputs.

## Outputs

Claim-to-evidence matrix, checks performed, pass/fail results, rendered findings, unverified items, defects, completion verdict, and receipt bundle.

## Safeguards

Do not trust self-reported completion, treat file existence as functional completion, alter evidence without disclosure, conceal skipped checks, or overstate confidence.

## Sol optimization

Emphasize tests, builds, linting, CLI receipts, Git diff, source inspection, reproducibility, and exact failures.

## Fable optimization

Emphasize rendered pages/documents, interaction quality, visual defects, content flow, audience usability, and whether the result feels finished.
