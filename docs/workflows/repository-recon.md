---
title: Repository Recon
description: The current real Loadout → Kiln → Temper golden path.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - integration/scenarios/repository-recon/run.sh
  - products/loadout/src/core/kiln-driver.ts
  - products/temper/src/
audience:
  - developer
  - operator
---

# Repository Recon

Repository Recon is the best current answer to “Can these components actually cross their public boundaries in one real workflow?”

## Run it

```bash
./invariant test integration
```

or directly:

```bash
./integration/scenarios/repository-recon/run.sh
```

## What happens

```mermaid
sequenceDiagram
    participant O as Operator / scenario
    participant L as Loadout
    participant K as Kiln
    participant T as Temper

    O->>L: install repository-recon
    O->>L: plan goal with execution=kiln
    L-->>O: Plan + Work Envelope
    O->>L: run Plan with real Kiln boundary
    L->>K: exact argv + Work Envelope tempfile
    K-->>L: canonical Run Result Envelope
    L-->>O: durable Run record
    O->>T: render repository snapshot
    T-->>O: plan/run/authority/evidence/artifacts
```

The runner creates a temporary real Git repository from the deterministic fixture so repository identity and currentness are not faked.

## What it proves

- one-checkout product interoperability;
- Work Envelope transport into real Kiln supervision;
- canonical Run Result parsing;
- explicit rejection of simulated labeling on the real path;
- Temper can project the recorded result.

## What it does not prove

The runner's own header is explicit: restart durability, eight negative cases, and dogfood remain specified in `TEST-MATRIX.md` rather than automated here. It also does not prove the future governed code-mutation Development Loop.
