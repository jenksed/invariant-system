---
title: Developing Cross-Product Contracts
description: How to change canonical boundary semantics without forking product truth.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - contracts/README.md
  - AGENTS.md
audience:
  - developer
---

# Developing Cross-Product Contracts

A root contract change is a system change even when the diff is one Markdown file.

Required discipline:

- preserve stable schema identity strings unless a deliberate compatibility change authorizes otherwise;
- identify every producer and consumer;
- update language-specific adapters without creating a second canonical spec;
- treat digest-bound fixtures as evidence-bearing artifacts, not formatting fodder;
- run all affected product gates plus integration where the contract participates.

Do not use documentation work as a back door to redesign contract semantics.
