# ARS-09 Knowledge Plane v0 Contract

ARS-09 turns durable engineering knowledge into typed, provenance-bearing, queryable data. Its first executable tracer is KFT-0 against Kiln because KFT-0 exposed a class of failure that document shape, green CI, and ordinary repository inspection did not settle:

> An implementation can exist and verify successfully while authority to create or merge it remains absent.

The Knowledge Plane must preserve that distinction. It may represent and adjudicate observed authority claims, but it may not manufacture authority.

## Product boundary

The v0 unit is an **exact-state Knowledge Snapshot**:

```text
repository identity + exact SHA
  + retrieved sources and authority order
  + typed knowledge entities
  + source-bound state claims
  + relationships
  + exact authorization records, when any
  + explicit queries
  + field-trial observations
```

The snapshot is content-addressed with canonical JSON. It is safe to inspect in read-only mode and deterministic to validate, adjudicate, and compile.

The v0 implementation deliberately consumes typed observations. It does not use a model or a generic Markdown parser to infer authority. Extraction is a separate capability boundary because false certainty at that boundary would be more dangerous than an explicit `UNKNOWN` result.

## Typed knowledge

The initial entity vocabulary is:

- `Decision`;
- `Requirement`;
- `Invariant`;
- `Assumption`;
- `Unknown`;
- `NegativeKnowledge`;
- `Evidence`;
- `Experiment`;
- `Observation`;
- `Incident`;
- `Capability`;
- `Artifact`;
- `ReconsiderationTrigger`;
- `Exception`;
- `FrictionEvent`;
- `CompetenceExpectation`;
- `Authorization`.

Entities retain source references, status, supporting/challenging entities, and reconsideration triggers. Relationships are explicit rather than reconstructed from conversational proximity.

## State is a vector, not one overloaded status

KFT-0 showed that `planned`, `implemented`, `verified`, and `accepted` may coexist across different documents without being equivalent. ARS-09 therefore records independent predicates:

| Dimension | Values |
|---|---|
| Planning | `unplanned`, `proposed`, `accepted` |
| Permission | `unspecified`, `permitted`, `forbidden` |
| Implementation authorization | `not-authorized`, `authorized`, `revoked` |
| Implementation | `not-started`, `in-progress`, `implemented` |
| Verification | `unverified`, `verified`, `failed` |
| Acceptance | `unaccepted`, `accepted`, `rejected` |

The evaluator surfaces impossible or dangerous combinations, including:

- a Proposed plan associated with in-progress or implemented work;
- implementation without resolved authorization;
- verified work without implemented state;
- accepted work without verified state.

These findings do not erase the underlying claims. The contradiction remains inspectable.

## Source authority and contradiction rules

Each source records:

- kind and locator;
- observed repository SHA;
- optional artifact SHA for branch/PR material;
- exact content digest when captured;
- retrieval status and durability;
- authority rank derived from the repository's own declared authority order.

Lower numeric rank is stronger. Arsenal does not invent this order. A snapshot producer must observe it from repository authority; if the order cannot be established, the appropriate result is `UNKNOWN` or `BLOCKED` rather than a guessed rank.

Claims are resolved per `(subject, predicate)`:

1. ignore unavailable or state-inapplicable sources for current resolution while retaining them as stale/unavailable evidence;
2. select the strongest current authority rank;
3. fail `BLOCKED` if equally authoritative current sources disagree;
4. resolve the strongest value while retaining lower-rank challenges;
5. preserve all cross-source contradictions in the result.

A PR body can therefore challenge repository authority without overriding it.

## Exact authorization records

An `authorized` prose claim is necessary context but insufficient authority. An `AUTHORIZED` result additionally requires one active record bound to:

- exact subject/work package;
- owner;
- scope;
- base repository SHA;
- plan path;
- plan SHA-256;
- issue time;
- status;
- a retrieved, content-digested `owner-authorization` source bound to the same repository state.

An implementation-authority query must carry the expected owner and exact scope in its target alongside the repository SHA, plan path, and plan digest. Record fields are applicability constraints, not presence-only metadata: any owner or scope mismatch fails closed just like SHA or plan drift.

Applicability outcomes are:

| Verdict | Meaning | May implement? |
|---|---|---|
| `AUTHORIZED` | Strongest claim is authorized and an exact active record applies. | Yes |
| `NOT_AUTHORIZED` | Strongest applicable repository authority explicitly denies authorization. | No |
| `BLOCKED` | Top authority contradicts itself or an authorized claim lacks a valid record. | No |
| `STALE` | Only stale claims apply, or the record does not match exact target state. | No |
| `UNKNOWN` | No applicable authority evidence exists. | No |

No result other than `AUTHORIZED` sets `may_implement: true`.

## Evidence retrieval and applicability

KFT-0 found that ignored/local Evidence could be referenced without one durable retrieval path. ARS-09 v0 makes this loss representable:

- `retrieved`, `not-retrieved`, and `unavailable` are explicit;
- durability distinguishes repository, PR, CI artifact, owner-machine, transient, and unknown sources;
- state binding prevents evidence for one SHA from silently proving another;
- unavailable Evidence stays in the snapshot with its limitation instead of disappearing.

This slice does not implement an Evidence storage backend or owner-machine synchronization. That belongs to the Evidence Observatory/storage boundary and must be implemented only after a concrete retention and access contract exists.

## Relevant-subgraph context compilation

Context compilation starts from query seed entities and follows explicit relationships. It returns:

- selected typed knowledge;
- relevant relationships;
- only the sources required by those entities;
- selection metadata, including excluded entity count;
- the authority result for an authority query.

It does not dump the complete snapshot or conversation history into every task.

## KFT-0 acceptance fixture

`arsenal/knowledge/fixtures/kft-0-kiln.json` freezes the first real external tracer:

- Kiln main `ad319d7c748a6b723b9cff4187fa06c60bc3cf06`;
- PR #48 head `60367874bfc3c0e6d8cbd736f58e1ae17938943b`;
- the T01 plan digest;
- stronger repository sources stating P1-S02 is not authorized;
- the conflicting PR claim of explicit authorization;
- Proposed, implemented, verified, and unaccepted lifecycle observations;
- no exact owner authorization record;
- the durable Evidence retrieval gap;
- Arsenal's Field Trial wins, losses, friction, and capability gaps.

The required authority result is `NOT_AUTHORIZED`. The fixture must also retain the conflicting PR claim and surface lifecycle findings. Removing the contradiction to make the record look clean would fail the purpose of the trial.

## Invariants

1. Knowledge is not authority.
2. Competence, capability availability, permission, authorization, implementation, verification, and acceptance remain distinct.
3. A source cannot outrank the repository authority order merely because its claim is newer or more detailed.
4. An authorization claim cannot replace an exact authorization record.
5. Exact-state or plan-digest drift fails closed.
6. Missing or unavailable Evidence remains visible.
7. Contradictions are preserved, not averaged away.
8. Context compilation selects a relevant subgraph rather than a history dump.
9. The Knowledge Plane cannot mutate the target repository or create its own authorization.

## Intentionally deferred

The v0 slice does not yet:

- extract typed claims automatically from arbitrary repository prose;
- decide a repository authority hierarchy when the repository does not declare one;
- store or synchronize ignored/local Evidence;
- scan branch age or select among stale branches;
- discover/install missing capabilities;
- compile objectives into executable routes;
- alter ARS-08 trust decisions;
- authorize, implement, merge, or accept Kiln work;
- promote Knowledge entities or capabilities without human-reviewed evidence.

Automatic source extraction, Capability Gap Preflight integration, branch-age filtering, and route generation remain ARS-10 or demand-driven follow-on work. Durable Evidence retrieval requires its own storage/access design rather than being hidden inside this validator.

## Verification

```bash
python3 scripts/arsenal_knowledge.py validate \
  --snapshot arsenal/knowledge/fixtures/kft-0-kiln.json

python3 scripts/arsenal_knowledge.py adjudicate \
  --snapshot arsenal/knowledge/fixtures/kft-0-kiln.json \
  --query query.kft-0.p1-s02-t01-authority

python3 scripts/arsenal_knowledge.py compile \
  --snapshot arsenal/knowledge/fixtures/kft-0-kiln.json \
  --query query.kft-0.p1-s02-t01-authority

python3 scripts/test-arsenal-knowledge.py
```

`adjudicate` exits `0` only for `AUTHORIZED`; all non-authorizing verdicts exit `3`. Structural/input failures exit `2`.
