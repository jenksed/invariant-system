# Knowledge Plane operator guide

Use the Knowledge Plane when repository truth depends on relationships among authority, lifecycle state, exact Git state, plan digests, Evidence, unknowns, and negative knowledge.

## Validate a snapshot

```bash
python3 scripts/arsenal_knowledge.py validate \
  --snapshot arsenal/knowledge/fixtures/kft-0-kiln.json
```

This validates typed structure and reports contradictions and lifecycle findings without treating those findings as malformed input. Use `--strict-findings` when a clean result is required by a gate.

## Evaluate implementation authority

```bash
python3 scripts/arsenal_knowledge.py adjudicate \
  --snapshot arsenal/knowledge/fixtures/kft-0-kiln.json \
  --query query.kft-0.p1-s02-t01-authority
```

The KFT-0 fixture intentionally exits `3` with `NOT_AUTHORIZED`. That is the correct result: Kiln's stronger repository authority says P1-S02 is not authorized, while PR #48's conflicting claim remains visible as a challenge.

Only `AUTHORIZED` exits `0`. `NOT_AUTHORIZED`, `BLOCKED`, `STALE`, and `UNKNOWN` never grant implementation authority.

## Compile task-relevant context

```bash
python3 scripts/arsenal_knowledge.py compile \
  --snapshot arsenal/knowledge/fixtures/kft-0-kiln.json \
  --query query.kft-0.p1-s02-t01-authority
```

The result includes the query seeds, relevant relationship closure, required sources, excluded entity count, and authority result. It is designed as future Intent Compiler input, not as an executable route.

## Create another snapshot

Start from `arsenal/knowledge/snapshot.schema.json` and preserve these rules:

1. Freeze the repository and any branch/PR artifact SHAs.
2. Record source digests when exact bytes are available.
3. Derive authority rank from the repository's declared authority order; never infer it from confidence or document detail.
4. Keep conflicting claims rather than choosing one during extraction.
5. Separate planning, permission, authorization, implementation, verification, and acceptance claims.
6. Use an `owner-authorization` source with an exact digest for any authorization record.
7. Record unavailable Evidence and the retrieval limitation.
8. Add explicit query seeds so context compilation has a bounded starting point.

The snapshot producer is responsible for truthful observation. The deterministic evaluator validates and resolves the typed input; it does not certify that an extractor read the repository correctly.
