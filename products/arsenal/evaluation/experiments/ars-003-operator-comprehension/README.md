# ARS-003 Graph Operator Comprehension

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


**FORMATIVE RESEARCH — NOT GENERALIZABLE EVIDENCE.**

This directory contains a single-operator comprehension prototype for ARS-003.
It is a research instrument, not a product runtime. Results from one operator do
not generalize to all graph engineers.

## Purpose

Investigate the research question:

> "What representation allows a graph engineer to understand and operate durable
> agentic work with the least cognitive reconstruction?"

The prototype emits three static HTML representations of the same synthetic
graph fixture and provides a nine-task operator worksheet with correct answers
derived from that fixture.

## What this is NOT

- Not Temper. No Temper runtime code lives here.
- Not an execution surface, authority, or mutation path. The HTML files are
  static renderings of a synthetic graph.
- Not generalizable evidence. A single-operator formative study can bound the
  design space; it cannot prove behavior for all graph engineers.

## Regeneration

From the `prototype/` directory:

```bash
python3 build_prototype.py
```

This deterministically emits:

- `graph-fixture.json`
- `a-conversation-tabs.html`
- `b-graph-first.html`
- `c-hybrid.html`

Expected digest for `graph-fixture.json` (verified run-twice):

```
sha256:dd6af90337dfce836157303413c1581313ed563f339d81f6231d652ddde12835
```

All renderings carry the banner:

> ARS-003 formative prototype — non-authoritative representation; not an
> execution surface.

## Files

- `PROTOCOL.md` — formative research protocol (State: DESIGNED).
- `prototype/build_prototype.py` — deterministic fixture and rendering
  generator.
- `prototype/graph-fixture.json` — synthetic graph, event log, evidence index,
  and absence interval.
- `prototype/tasks.md` — operator task battery worksheet with correct answers
  and scoring rubrics.
- `prototype/a-conversation-tabs.html` — Representation A.
- `prototype/b-graph-first.html` — Representation B.
- `prototype/c-hybrid.html` — Representation C.

## Promotion

Any production UX change would be a possible downstream target for Temper, but
must follow `../../promotion/PACKET-TEMPLATE.md` and normal product
authorization. This experiment does not authorize implementation.
