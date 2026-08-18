---
title: Execution Model
description: Current execution ownership and the boundary between planning and durable runtime truth.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/loadout/src/core/kiln-driver.ts
  - products/kiln/README.md
  - integration/scenarios/repository-recon/run.sh
audience:
  - developer
---

# Execution Model

Loadout prepares. Kiln executes and records.

In the current Repository Recon path, Loadout serializes a Work Envelope to a temporary file and spawns the Kiln CLI with exact argv rather than a shell string. Kiln binds durable Run identity, observes repository state, evaluates authority, and returns the canonical Run Result Envelope. Loadout validates that response and fails closed on transport or semantic failures.

That path is intentionally narrow and read-oriented. It should not be generalized into a claim that every planned governed-mutation or provider-execution slice exists.

Kiln's larger product model is a durable Run hierarchy over repository truth, with SQLite recording work facts and recovery state while Git/filesystem remain source truth. Future execution slices must preserve that distinction.
