# Wave 5 Scoreboard — Capability Evolution Loop v1

**Evaluation date:** 2026-08-13  
**Winner:** `repository-recon/staged-evidence-graph@0.2.0`  
**Capability before and after:** `repository-recon`  
**Authority before and after:** `git.read`  
**Execution boundary before and after:** real Kiln

## Product and benchmark results

| Surface | Baseline | Productized winner | False certainty |
|---|---:|---:|---:|
| Original Repository Recon target | 5/16 | 16/16 | 0 |
| Project Arsenal development | 4/15 | 15/15 | 0 |
| Loadout development | 4/15 | 15/15 | 0 |
| Kiln validation | 4/15 | 15/15 | 0 |
| Temper sealed holdout | 4/15 | 15/15 | 0 |
| Four-repository corpus total | 16/60 | 60/60 | 0 |

The productized result is not a comparison between two research functions.
Arsenal invoked the exact Loadout implementation at canonical main through an
external adapter, with no Loadout source import. The reproducible result digest
is `sha256:e1860e3bfd763c00012e06d46d84415aa2fd5c4794475eef17268c9ba4ed2dfd`.

## Candidate comparison

| Method | Development + validation | Original target | Unsupported claims |
|---|---:|---:|---:|
| Loadout runtime baseline | 12/45 | 5/16 | 0 |
| topology-inventory | 32/45 | 15/16 | 0 |
| structured-manifest | 14/45 | 2/16 | 0 |
| governance-graph | 9/45 | 4/16 | 0 |
| staged-evidence-graph | 45/45 | 16/16 | 0 |

The winner was locked before the Temper oracle was opened. On holdout it
improved from 4/15 to 15/15 with zero false certainty and one correct unknown:
Temper has no accepted root governance file, so governance authority was not
invented.

## What caused the improvement

- Complete tracked topology and bounded negative observations uniquely
  recovered 22 development/validation assertions.
- Structured JSON and runtime-manifest observation uniquely recovered 9.
- Literal governance-reference graphing uniquely recovered 4.
- Staging the three methods recovered all 45 without introducing a stronger
  relationship than the observed `references` edge.

Durable benchmark, miss taxonomy, selection, ablation, productized binding,
and result artifacts live on Project Arsenal main under `evaluation/wave5/`.

## Stable abstraction proof

```text
OLD
  Understand this repository
    → repository-recon
    → repository-recon/fixture-method@0.0.0-fixture

NEW
  Understand this repository
    → repository-recon
    → repository-recon/staged-evidence-graph@0.2.0
```

The Loadout Capability file remained byte-identical:
`sha256:32bf4718256a3cb5b4a6b24ad061c0863f582b99e8b71e5dd1a640077df901dd`.
No Arsenal runtime executes during normal Loadout use; Kiln and Temper remain
unaware of Arsenal's R&D ontology.

## Truthful public claim

We took a real Capability that supported 5 of 16 evaluated
repository-understanding assertions, used Arsenal to evaluate four competing
methods, promoted the winner beneath the same Loadout Capability, and executed
it through the same durable Kiln boundary. The productized winner supported
16/16 with zero unsupported factual claims and improved from 4/15 to 15/15 on
each frozen real-repository benchmark, including a sealed Temper holdout.

The Python, TypeScript, and Elixir generalization claim is supported by Project
Arsenal, Loadout, Temper, and Kiln evidence. It does not claim semantic
understanding beyond the evaluated assertion vocabulary.
