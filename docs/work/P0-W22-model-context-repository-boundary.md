# P0-W22: Provider, Context, Tools, Repository reads, and disclosure

**Document type:** Focused planning work package  
**Status:** In progress  
**Branch:** `work/p0-w22-model-context-repository-boundary-reconciled`  
**Depends on:** P0-W21 integrated through pull request 27 and closeout pull request 28  
**Scope:** MiniMax provider boundary, sealed Context, bounded Repository reads, fixed Tools, disclosure, and secret screening only  
**Build authorization:** Not issued

## Objective

Define one reproducible MiniMax boundary, one explicit sealed Context package, four or fewer model-facing Tools, safe local Repository reads, and the only data that may leave the machine.

## Entry evidence

- Prompt 4 integrated at merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e`.
- OD-01 integrated at merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1`.
- P0-W21 integrated at merge commit `ca21d0bbc25ddf5861191f8bde374e0761d86c0a`.
- P0-W21 status closeout integrated at merge commit `6c80436b9c220a93b0ff37372deacb1f7ec0fd32`.
- P0-W21 owns Session, Task, Run, transition, journal, projection, migration, restart, orphan, and completion-transaction boundaries.
- OD-01 selects MiniMax as the only initial real provider, requires one deterministic fake, permits only sealed Context disclosure under accepted Project policy, and forbids fallback.
- Current official MiniMax documentation lists `MiniMax-M3` as the latest M-series model for coding, agentic reasoning, Tool use, and long Context.
- The Project owner uses MiniMax M3 as the workhorse and M2.7 Highspeed for bounded helper work.
- Production source contains no provider, Context, Tool, Repository-read, disclosure, or secret-screening behavior.

## Assumptions

- A direct OpenAI-compatible HTTP boundary is smaller than a provider SDK or general OpenAI client abstraction.
- Basic deterministic Repository search and reads are sufficient before LSP, Tree-sitter, or a persistent index.
- A Project disclosure policy can be accepted before source excerpts are sent.
- One provider invocation can use a transient provider-native conversation while preserving a sealed initial Context package.

## Questions resolved by this round

- Exact provider endpoint and model.
- Request, streaming, Tool, result, usage, timeout, cancellation, malformed-result, and retry behavior.
- Deterministic fake-provider behavior.
- Ordered Context fields, manifest, digest, limits, exclusions, inspection, and staleness.
- Repository root, path, ignore, symlink, file, encoding, size, search, read, and fingerprint rules.
- Four model-facing Tools and workflow-step eligibility.
- Source disclosure, secret screening, untrusted instruction handling, and provider retention claims.
- Exact W21 ownership consumption without lifecycle or persistence overlap.

## Requirements

- Consume OD-01 without widening it.
- Consume P0-W21 without redefining it.
- Select one current MiniMax model and direct API mapping.
- Define one deterministic fake provider contract.
- Define streaming, cancellation, timeout, malformed result, usage, and explicit retry behavior.
- Define an ordered sealed Context package and manifest.
- Define exact token, byte, file, item, Tool-call, turn, and elapsed limits.
- Define Repository root, eligible file set, paths, ignores, symlinks, special files, binary and encoding behavior, reads, search, and fingerprints.
- Define at most four phase-specific Tools with fixed schemas.
- Define large-result externalization and bounded continuation.
- Define disclosure, credentials, secrets, untrusted instructions, provider payload retention, and provider-side limitations.
- Keep all changes planning-only.

## Expected files

- `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`
- `docs/decisions/0023-use-minimax-m3-openai-compatible-api.md`
- `docs/decisions/README.md`
- `docs/PLANNING.md`
- `docs/work/P0-W22-model-context-repository-boundary.md`

No production source, test, Schema, dependency, configuration, CI, script, preflight, Skill, prompt, agent, or conformance scaffold changes belong in this round.

## Acceptance criteria

- One MiniMax endpoint, model, request, stream, Tool, result, usage, timeout, cancellation, malformed-result, and retry contract exists.
- One deterministic fake covers success and required failures.
- One ordered Context package, manifest, digest, state binding, and inspection contract exists.
- Exact item, source, token, byte, file, result, turn, Tool-call, and time limits exist.
- Exact Repository path, ignore, symlink, binary, encoding, special-file, search, read, and fingerprint behavior exists.
- Exactly four or fewer Tools exist and unused schemas are absent.
- Secret values, denied paths, reference repositories, runtime Skills, hidden reasoning, and unrelated files cannot enter provider Context.
- Provider payload and response retention are explicit and honest.
- No fallback, router, broker, retrieval framework, LSP, Tree-sitter, protocol, Patch application, Command, or Evidence-completion behavior enters scope.
- No P0-W21 lifecycle or persistence contract is added or changed.
- Exact final-head CI passes.

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Targeted checks must prove:

- OD-01 and P0-W21 are integrated;
- MiniMax is the only real provider;
- exactly four or fewer Tools are named;
- no fallback exists;
- every provider-bound source item carries a disclosure decision;
- no lifecycle, transition, journal, projection, migration, restart, or completion authority appears in the focused specification;
- the previous M2.7 draft did not enter the reconciled branch.

## Required completion evidence

- P0-W22-E01: Prompt 4, OD-01, W21, and W21-closeout merge Evidence.
- P0-W22-E02: current official MiniMax endpoint, model, Tool, streaming, reasoning, authentication, and privacy source review.
- P0-W22-E03: provider and deterministic-fake contracts.
- P0-W22-E04: sealed Context and disclosure contract.
- P0-W22-E05: Repository-read and Tool matrices.
- P0-W22-E06: secret, path, malformed-result, timeout, cancellation, and no-fallback examples.
- P0-W22-E07: W21 ownership audit.
- P0-W22-E08: exact planning-only compare and final-head CI.

## Explicit exclusions

P0-W22 does not:

- define or change Run, Session, or Task lifecycle;
- define journal, transaction, migration, replay, projection, or persistence semantics;
- define Patch representation, Approval, source mutation, or rollback;
- define registered Command, criterion Evidence, completion, Receipt, or CLI presentation;
- implement or scaffold any behavior;
- add provider fallback, routing, ensemble, Skills, retrieval framework, reference repositories, code intelligence, protocols, telemetry, remote execution, or attestations;
- run P0-W26 or P0-W27;
- issue build authorization.
