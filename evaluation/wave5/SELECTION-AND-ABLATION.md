# Wave 5 Repository Recon Selection and Ablation

**Selection set:** Project Arsenal + Loadout development, Kiln validation  
**Holdout:** Temper, first evaluated after `winner-lock.v1.json` existed  
**Winner:** `repository-recon/staged-evidence-graph`  
**Winner implementation digest:**
`sha256:7992da31c1394ed9cb872764178d329bb1784605c529fc993aa668736267a99f`

## Blind selection result

| Method | Development + validation | False certainty | Deterministic | Observed cost |
|---|---:|---:|---|---:|
| Loadout runtime baseline | 12/45 | 0 | yes | 450–500 ms |
| topology-inventory | 32/45 | 0 | yes | 50–70 ms |
| structured-manifest | 14/45 | 0 | yes | 120–140 ms |
| governance-graph | 9/45 | 0 | yes | 2–5 ms |
| staged-evidence-graph | **45/45** | **0** | **yes** | 200–230 ms |

The first staged evaluation emitted one invalid filesystem-presence claim for
an unmaterialized Kiln gitlink. That result was rejected. The narrow repair
stopped strengthening Git index presence into filesystem presence. A second
validation miss came from retaining Elixir punctuation in raw manifest lines;
the manifest stage now emits bounded declaration tokens for `app:` and
`elixir:`. All candidates were rerun after that repair.

## Original 16-assertion gate

| Method | Supported | Unsupported factual claims |
|---|---:|---:|
| Frozen productized baseline | 5/16 | 0 |
| topology-inventory | 15/16 | 0 |
| structured-manifest | 2/16 | 0 |
| governance-graph | 4/16 | 0 |
| staged-evidence-graph | **16/16** | **0** |

Topology recovered every original miss except the structured
`capability.recon` identity relationship. Structured parsing recovered that
last relationship. The winner therefore exceeds the 12/16 gold target without
regressing any of the five baseline-supported assertions.

## Holdout gate

Temper was not evaluated until the winner lock bound the method and its exact
implementation digest.

```text
HOLDOUT_BASELINE_SUPPORTED=4/15
HOLDOUT_WINNER_SUPPORTED=15/15
HOLDOUT_BASELINE_FALSE_CLAIMS=0
HOLDOUT_WINNER_FALSE_CLAIMS=0
HOLDOUT_UNKNOWN_QUALITY=PASS — missing root governance remains an explicit unknown
```

The holdout improved by 11 supported assertions and did not regress or add a
false claim.

## What actually made it better

### Change: complete topology inventory with bounded negative knowledge

Recovered 22 real-corpus assertions that neither other isolated stage could
support, including source/test/CI organization, exact architecture paths,
lockfiles, and root-manifest absences. On the original corpus this change
recovered ten of the eleven misses.

The key mechanism is not a larger hard-coded positive catalogue. It is a
sorted tracked-file inventory, explicit directory parents, and a bounded set
of standard negative observations. Gitlinks are not represented as
filesystem-present unless materialized.

### Change: structured manifest parsing

Recovered nine real-corpus assertions unique among isolated stages:

- Arsenal project and capability identities;
- Loadout package name, Node version, Capability/method binding, and CI command;
- Kiln application and Elixir version declarations.

On the original corpus it recovered `capability_id_recon`, the only assertion
topology alone could not support.

### Change: literal governance relationship graph

Recovered four real-corpus relationships unique among isolated stages:

- Arsenal `AGENTS.md` → doctrine core;
- Arsenal `AGENTS.md` → full doctrine;
- Kiln `CLAUDE.md` → `AGENTS.md`;
- Kiln `AGENTS.md` → engineering doctrine.

The relation is deliberately named `references`. The method does not infer
authority from a filename or silently strengthen a reference into governance.

### Change: staged composition

The winner is the canonical union of the three evidence-bound stages. It adds
no narrative synthesis, model call, network access, or hidden expectation
lookup. Every factual output is independently revalidated by the evaluator.

## Evidence artifacts

- `results/selection/*.json`: baseline and four candidates on development + validation.
- `results/original-16/*.json`: each candidate on the frozen original target.
- `results/holdout/*.json`: baseline and locked winner on Temper.
- `winner-lock.v1.json`: selection boundary and exact implementation binding.
