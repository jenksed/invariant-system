# P0-W22: Provider, Context, Tools, Repository reads, and disclosure

**Document type:** Focused planning work package  
**Status:** Implemented, verified, accepted, and integrated  
**Integrated through:** Pull request 29, merge commit `abbded1af773981c40e0810c19ce043b9485daeb`  
**Final design head:** `d2f646cee0e8e26b86d0e0ea19f4f2226cdf163f`  
**Depends on:** P0-W21 integrated through pull request 27 and closeout pull request 28  
**Scope:** MiniMax provider boundary, sealed Context, bounded Repository reads, fixed Tools, disclosure, and secret screening only  
**Build authorization:** Not issued

## Objective

Define one reproducible MiniMax boundary, one explicit sealed Context package, four or fewer model-facing Tools, safe local Repository reads, and the only data that may leave the machine.

## Entry evidence

- Prompt 4 integrated at `45acc2ed575957c53a8c57195d99c82965e9d48e`.
- OD-01 integrated at `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1`.
- P0-W21 integrated at `ca21d0bbc25ddf5861191f8bde374e0761d86c0a`.
- P0-W21 closeout integrated at `6c80436b9c220a93b0ff37372deacb1f7ec0fd32`.
- P0-W21 owns every lifecycle, transition, journal, projection, migration, restart, orphan, and completion-transaction boundary.
- Current official MiniMax documentation identifies `MiniMax-M3` as the latest M-series model for coding, Tool use, agentic reasoning, and long Context.
- The Project owner uses M3 as the MiniMax workhorse.
- Production source contains no provider, Context, Tool, Repository-read, disclosure, or secret-screening behavior.

## Accepted decisions

P0-W22 established:

1. MiniMax is the only initial real provider.
2. Use `MiniMax-M3` through `https://api.minimax.io/v1/chat/completions`.
3. Use direct bounded HTTP and JSON mapping behind a Kiln-native provider behaviour.
4. Use one deterministic fake provider for tests.
5. Use streaming, `reasoning_split`, one standard service tier, and no fallback.
6. Keep provider-native reasoning transient inside the live Worker. It is never durable Context, transcript, Evidence, Receipt, or ordinary Artifact content.
7. Do not retry after dispatch automatically.
8. Cancellation, timeout, or connection loss after dispatch is unknown unless a terminal provider result was observed.
9. Seal one ordered Context package before dispatch.
10. Cap initial provider input at 32,000 estimated tokens and output at 8,192 tokens despite the provider's larger limit.
11. Define exactly four possible Tools: `repo.search`, `repo.read`, `artifact.read`, and `change.propose`.
12. Omit unused Tool schemas by workflow step.
13. Allow only bounded literal search and text-range reads inside one canonical selected checkout.
14. Deny path escape, symlinks, special files, binaries, invalid UTF-8, oversized files, stale digests, and mandatory secret paths.
15. Deny hosted source disclosure by default until accepted Project policy permits the exact class and destination.
16. Treat source and Tool content as untrusted data.
17. Persist normalized manifests, visible results, Tool records, usage, warnings, and digests rather than raw provider streams or complete payloads.
18. State hosted provider retention honestly and make no local-only or zero-retention claim.

## Files integrated

- `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`
- `docs/decisions/0023-use-minimax-m3-openai-compatible-api.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W22-model-context-repository-boundary.md`

The final branch contained five Markdown files, 1,424 additions, and eight deletions. It changed no production source, tests, dependencies, configuration, JSON Schemas, CI, scripts, preflight, Skills, prompts, agents, or conformance scaffolding.

## Acceptance evidence

| Criterion | Result | Evidence |
| --- | --- | --- |
| One provider endpoint and model | Pass | focused specification and ADR-0023 |
| Request, stream, Tool, result, usage, timeout, cancellation, malformed-result, and retry rules | Pass | provider contract sections |
| Deterministic fake covers success and failures | Pass | fake-provider section |
| Ordered sealed Context, manifest, digest, limits, inspection, and staleness | Pass | Context sections |
| Exact Repository path, file, search, read, and fingerprint rules | Pass | Repository sections |
| Exactly four possible Tools and unused schemas absent | Pass | Tool projection |
| Secret values and denied source cannot enter provider Context | Pass | disclosure and secret sections |
| Provider retention and hosted processing are honest | Pass | disclosure and retention sections |
| No fallback, routing, Skills, retrieval framework, code intelligence, or protocols | Pass | constraints and exclusions |
| W21 lifecycle and persistence ownership unchanged | Pass | explicit W21 ownership audit |
| Review-head Repository validation | Pass | CI `30421013613` on `32dd41ba53e4eee767b947b22c559d7ff51f20b0` |
| Exact closeout-head validation | Pass | CI `30421128818` on `d2f646cee0e8e26b86d0e0ea19f4f2226cdf163f` |

## W21 ownership audit

P0-W22 consumes operation identity, durable intent before dispatch, terminal or unknown result classification, expected revision, idempotency, restart, and orphan handling.

It does not define or modify Session, Task, or Run states; lifecycle transitions; transition authority; journal envelope; action-commit storage; projection ownership; replay; migrations; store startup; terminal alignment; or completion transaction prerequisites.

Any conflict resolves in favor of integrated P0-W21.

## External evidence

Official MiniMax sources reviewed on 2026-07-28 support the OpenAI-compatible endpoint, `MiniMax-M3`, Bearer authentication, streaming, Tool definitions, `reasoning_split`, provider-message continuity, usage fields, and hosted processing.

They do not prove provider-side deletion, non-retention, or server-side cancellation.

## Verification

Final head `d2f646cee0e8e26b86d0e0ea19f4f2226cdf163f` passed GitHub CI run `30421128818`.

The run passed Vale, current preflight behavior tests, Project agent-asset validation, dependency installation, formatting, warnings-as-errors compilation, compile-connected cycle detection, and ExUnit.

The current preflight result proves obsolete P0 mechanics only. It does not prove P1 ticket compatibility.

## Explicit exclusions

P0-W22 did not define or change lifecycle or persistence; define Patch representation, Approval, mutation, rollback, Command, Evidence, completion, Receipt, or CLI presentation; implement behavior; add fallback, routing, Skills, retrieval, reference repositories, code intelligence, protocols, telemetry, remote execution, or attestations; run Wave B; or issue build authorization.

## Gate verdict

**P0-W22 passed and is integrated.**

Build authorization remains denied.

## Exact next action

Run P0-W23 on current `main`.
