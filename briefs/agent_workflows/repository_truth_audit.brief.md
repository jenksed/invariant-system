---
kind: prompt-generation-brief
status: source
target_prompt: Repository Truth and Current-State Audit
generator: prompt_design/master-sol-fable-super-prompt-generator.md
---

# Prompt Generation Brief

## Purpose

Create a reusable read-only audit prompt that establishes the actual state of a repository before planning or continuing work.

## Required behavior

- read governing instructions and project-status files;
- inspect branches, Git status, recent history, and uncommitted changes;
- map the repository;
- compare plans, status claims, and documentation against implementation;
- run relevant read-only validation when practical;
- classify work as complete, partial, broken, stale, missing, abandoned, duplicate, or unverified;
- identify documentation drift;
- identify the true continuation point;
- produce an evidence-backed report;
- avoid modifying files unless explicitly authorized.

## Inputs

Repository path, branch or intended branch, project objective, known status claims, optional focus area, and governing files.

## Outputs

Current-state summary, repository map, claim-versus-evidence table, validation results, documentation drift, risks/blockers, exact continuation point, and recommended next actions.

## Safeguards

Do not trust status documents without checking implementation, treat a passing build as proof of product completeness, modify a repository during a read-only audit, call untested work complete, or hide skipped checks or uncertainty.

## Sol optimization

Emphasize Git, commands, source inspection, tests, dependencies, exact files, and reproducible receipts.

## Fable optimization

Emphasize rendered state, content completeness, user experience, visual coherence, documentation clarity, and whether implementation fulfills the stated experience.
