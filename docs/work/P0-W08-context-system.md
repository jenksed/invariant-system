# P0-W08: Context System

**Document type:** Reference  
**Status:** In progress  
**Branch:** `work/p0-w08-context-system`  
**Depends on:** P0-W07 through draft pull request 8

## Objective

Define Kiln's Context compiler, bounded Context package, token-budget policy, progressive-disclosure rules, Artifact-reference policy, documentation resolver, Capability-exposure policy, Child-Run and Verifier-Run Context boundaries, and Context observability requirements.

The system must optimize for the smallest sufficient Context for the next decision or action. A larger model window must not become a reason to load more content.

## Observed current state

| Observation | Evidence | Date or commit |
| --- | --- | --- |
| Context is a provenance-bearing selection for one Run. | `docs/INTERNAL-DOMAIN-MODEL.md` | 2026-07-28 |
| A Context manifest is an immutable ordered set for one invocation or Worker step. | `docs/INTERNAL-DOMAIN-MODEL.md` | 2026-07-28 |
| Artifact content does not enter model Context without explicit inclusion. | `KILN-INV-031` and internal domain model | 2026-07-28 |
| Child Runs receive explicit Context and do not inherit it by default. | Run model and internal domain model | 2026-07-28 |
| The Capability broker keeps the full catalog outside model Context. | ADR 0009 and `docs/CAPABILITY-INTEGRATION.md` | 2026-07-28 |
| Model-facing Tools are capped at twelve and are phase-specific. | ADR 0009 | 2026-07-28 |
| Large Capability results become Artifacts. | Capability Integration and `kiln-capability/v0` | 2026-07-28 |
| Privacy policy gates Context egress. | Security model and `KILN-INV-033` | 2026-07-28 |
| No Context compiler, documentation resolver, package schema, token policy, or observability implementation exists. | P0-W07 source and planning baseline | 2026-07-28 |

## Assumptions and unknowns

### Assumptions

- **P0-W08-A01:** A bounded deterministic compiler can produce a useful package without retaining the complete transcript.
- **P0-W08-A02:** Repository and semantic retrieval can operate at symbol, line, hunk, and section granularity.
- **P0-W08-A03:** Large results can remain accessible through Artifact references and stable cursors.
- **P0-W08-A04:** Phase-specific Tool exposure reduces selection noise and schema cost.
- **P0-W08-A05:** Stable prompt segments can improve provider cache behavior without defining correctness.
- **P0-W08-A06:** Local, version-matched documentation can answer most initial Elixir questions before Context7 or web research.
- **P0-W08-A07:** Child and Verifier Runs can receive independent retrieval and permission scopes.
- **P0-W08-A08:** Model and Tool token usage can be attributed to Runs and, when explicit, accepted Change sets.

### Unknowns

- **P0-W08-U01:** Unknown. Final phase token targets require dogfooding.
- **P0-W08-U02:** Unknown. Provider-specific tokenizer estimation error requires adapter implementation.
- **P0-W08-U03:** Unknown. The final relevance-scoring and candidate-ranking algorithm requires fixtures.
- **P0-W08-U04:** Unknown. Embeddings are not justified until exact and semantic retrieval fail accepted cases.
- **P0-W08-U05:** Unknown. Local ExDoc indexing and runtime documentation adapter boundaries require implementation evidence.
- **P0-W08-U06:** Unknown. Context7 adapter details and authentication remain deferred.
- **P0-W08-U07:** Unknown. Provider prompt-cache controls require direct adapter experiments.
- **P0-W08-U08:** Unknown. Cross-Run and accepted-change token attribution for shared work requires explicit event design.
- **P0-W08-U09:** Unknown. Automatic contradiction detection requires evaluation against real Project documents.
- **P0-W08-U10:** Unknown. Model-assisted summary policy requires proof that provenance and omissions remain inspectable.

## Applicable invariants and decisions

This work preserves:

- ADR 0001 through ADR 0009;
- `KILN-INV-001` through `KILN-INV-044`;
- Run-owned Context boundaries;
- immutable Context manifests;
- explicit Artifact-to-Context inclusion;
- Child Run non-inheritance;
- independent Evidence and Receipt semantics;
- phase-specific compact Tool projection;
- MCP and LSP behind Kiln-native contracts;
- Privacy policy before model egress;
- no process for every noun.

This work adds ADR 0010 and ADR 0011 and extends the invariant register.

## Requirements

- **P0-W08-R01:** Kiln shall compile the smallest sufficient Context for the next decision or action.
- **P0-W08-R02:** A larger model context window shall not automatically increase the active Context ceiling.
- **P0-W08-R03:** Every model invocation or Context-consuming Worker step shall receive a new immutable Context manifest.
- **P0-W08-R04:** A replacement package shall remove stale, superseded, duplicate, resolved, and low-relevance material rather than append indefinitely.
- **P0-W08-R05:** Every Context item shall record provenance, authority, trust, sensitivity, freshness, state binding, selection reason, token estimate, and transformations.
- **P0-W08-R06:** Retrieval shall be just in time and shall prefer symbol, line, hunk, section, page, and Artifact-segment units over whole-source loading.
- **P0-W08-R07:** Raw LSP protocol objects shall remain outside model Context.
- **P0-W08-R08:** Complete MCP catalogs and all MCP Tools shall remain outside model Context.
- **P0-W08-R09:** Active model-facing Tools shall normally number six to eight and shall never exceed twelve.
- **P0-W08-R10:** Tool schemas shall use a default 2,500-token budget and an absolute 4,000-token ceiling.
- **P0-W08-R11:** Tool exposure shall depend on phase, Task intent, Run state, availability, effective authority, and schema budget.
- **P0-W08-R12:** Tool discovery and Skill loading shall be lazy.
- **P0-W08-R13:** Tool results shall use bounded summaries, explicit truncation, stable pagination, and snapshot-bound cursors.
- **P0-W08-R14:** Complete logs, test output, documentation pages, DOM snapshots, database results, large diffs, and binary output shall become Artifacts when a digest and reference are sufficient.
- **P0-W08-R15:** Artifact references shall preserve digest, size, media type, source, summary, trust, sensitivity, freshness, state binding, continuation, and retrieval provenance.
- **P0-W08-R16:** Prompt segments shall use stable ordering and canonical serialization for cache awareness.
- **P0-W08-R17:** Cache hits shall not change semantics, authority, privacy, freshness, or manifest generation.
- **P0-W08-R18:** The initial Run Context ceiling shall default to 16,000 input tokens with lower phase targets.
- **P0-W08-R19:** Unused budget shall remain unused rather than be filled with lower-value material.
- **P0-W08-R20:** Context omissions and invalidations shall be recorded with reasons and estimated token savings.
- **P0-W08-R21:** The Elixir documentation resolver shall use the accepted authority and version order.
- **P0-W08-R22:** Context7 shall remain supported but shall not override Repository-local, accepted, dependency-authored, local ExDoc, or running-Project documentation.
- **P0-W08-R23:** Model memory shall be the final documentation source and shall remain an explicitly unverified hypothesis or query aid.
- **P0-W08-R24:** Child Runs shall receive independent Context manifests and explicit delegation envelopes rather than Parent transcripts or ambient authority.
- **P0-W08-R25:** Verifier Runs shall receive independently retrieved, criteria-centered, bias-reduced first-pass Context.
- **P0-W08-R26:** Verifier first-pass Context shall not treat the implementer's conclusion as fact and shall exclude write Tools by default.
- **P0-W08-R27:** Context observability shall measure all required model, Tool, result, cache, repetition, compaction, retrieval, Artifact, Run-cost, and accepted-change-cost fields.
- **P0-W08-R28:** Observability shall avoid retaining sensitive raw Context content by default.
- **P0-W08-R29:** The compiler shall fail explicitly when mandatory Context cannot fit or no authorized retrieval path exists.
- **P0-W08-R30:** This work package shall define architecture and contracts only and shall not implement production runtime behavior.

## Proposed changes

1. Add `docs/CONTEXT-SYSTEM.md`.
2. Add ADR 0010 for smallest-sufficient Context compilation.
3. Add ADR 0011 for documentation authority and version resolution.
4. Add `docs/contracts/kiln-context.schema.json`.
5. Update the contract and ADR indexes.
6. Extend Project invariants.
7. Reconcile architecture, security, Capability integration, roadmap, README, and AGENTS.
8. Add this P0-W08 work-package plan.
9. Do not implement production code.

## Expected files or components

| Path | Expected change |
| --- | --- |
| `docs/CONTEXT-SYSTEM.md` | Add compiler architecture, schema, budgets, disclosure, Artifacts, resolver, Run policies, metrics, and acceptance criteria. |
| `docs/decisions/0010-compile-smallest-sufficient-context.md` | Accept the compiler, package replacement, budgets, and independent Run contexts. |
| `docs/decisions/0011-resolve-documentation-by-authority-and-version.md` | Accept Elixir documentation source order and Context7 limits. |
| `docs/contracts/kiln-context.schema.json` | Define compile request, manifest, package, documentation resolution, and observability contracts. |
| `docs/contracts/README.md` | Index the Context contract. |
| `docs/decisions/README.md` | Index ADR 0010 and ADR 0011. |
| `docs/PROJECT-INVARIANTS.md` | Add stable Context constraints. |
| `docs/ARCHITECTURE.md` | Add the Context compiler and documentation resolver boundaries. |
| `docs/SECURITY-MODEL.md` | Add Context trust, privacy, Child, and Verifier rules. |
| `docs/CAPABILITY-INTEGRATION.md` | Reconcile Tool exposure, lazy discovery, and protocol-output limits. |
| `docs/ROADMAP.md` | Add P0-W08 and Context proof requirements. |
| `README.md` | Link the Context system and summarize the position. |
| `AGENTS.md` | Require smallest-sufficient Context and authoritative documentation resolution. |
| `docs/work/P0-W08-context-system.md` | Record this work package. |

## Acceptance criteria

- **P0-W08-AC01**
  - **Given** a model with a large context window
  - **When** the Context policy is inspected
  - **Then** it defines an independent Run ceiling, lower phase targets, and no automatic window filling
  - **Evidence:** token-budget policy and ADR 0010

- **P0-W08-AC02**
  - **Given** the complete compiler input set
  - **When** architecture is inspected
  - **Then** it defines freeze, candidate planning, retrieval, classification, transformation, deduplication, invalidation, budgeting, ordering, sealing, rendering, and observation stages
  - **Evidence:** Context compiler architecture

- **P0-W08-AC03**
  - **Given** one Context package
  - **When** the schema is inspected
  - **Then** it contains identifiers, purpose, phase, source state, items, Tools, Artifacts, budgets, cache segments, exclusions, invalidations, provenance, and integrity digests
  - **Evidence:** Context package schema and `kiln-context/v0`

- **P0-W08-AC04**
  - **Given** Repository and documentation sources
  - **When** retrieval occurs
  - **Then** Kiln prefers the narrowest sufficient symbol, line, hunk, section, page, or Artifact segment and records retrieval provenance
  - **Evidence:** progressive disclosure and retrieval rules

- **P0-W08-AC05**
  - **Given** stale or duplicate Context
  - **When** a new package is compiled
  - **Then** stale material is replaced, duplicates are collapsed, and token savings and reasons are recorded
  - **Evidence:** deduplication, invalidation, and observability rules

- **P0-W08-AC06**
  - **Given** more than twelve available Tools
  - **When** a phase package is compiled
  - **Then** no more than twelve phase-relevant intent Tools are exposed and schemas remain within budget
  - **Evidence:** Capability-exposure and Tool-schema rules

- **P0-W08-AC07**
  - **Given** MCP and LSP implementations
  - **When** the model-facing Context is inspected
  - **Then** it contains neither full MCP catalogs nor raw LSP protocol objects
  - **Evidence:** Capability and protocol policies

- **P0-W08-AC08**
  - **Given** a large Tool or documentation result
  - **When** it exceeds inline limits
  - **Then** it becomes an Artifact with an explicit digest, bounded summary, excerpt, provenance, and continuation
  - **Evidence:** Artifact-reference policy and schema

- **P0-W08-AC09**
  - **Given** a paginated result
  - **When** the source changes
  - **Then** the snapshot-bound cursor fails explicitly as stale
  - **Evidence:** pagination and cursor rules

- **P0-W08-AC10**
  - **Given** several available Skills
  - **When** one phase needs one procedure
  - **Then** only the selected Skill sections enter Context and the full catalog remains outside
  - **Evidence:** lazy Skill rules

- **P0-W08-AC11**
  - **Given** several Elixir documentation sources
  - **When** the resolver answers a question
  - **Then** it applies the accepted authority order, binds versions, records conflicts, and keeps Context7 below local version-matched sources
  - **Evidence:** documentation resolver and ADR 0011

- **P0-W08-AC12**
  - **Given** a Child Run
  - **When** its Context is compiled
  - **Then** it receives an independent manifest, explicit bounded brief, selected references, requested output, and explicit grants
  - **Evidence:** Child-Run Context policy

- **P0-W08-AC13**
  - **Given** an implementation Claim requiring verification
  - **When** a Verifier starts
  - **Then** it receives independently retrieved, criteria-centered, bias-reduced Context and no write Tools by default
  - **Evidence:** Verifier-context policy

- **P0-W08-AC14**
  - **Given** provider prompt caching
  - **When** a cache hit occurs
  - **Then** Kiln still generates a new manifest and cannot restore stale Context or bypass authority and privacy rules
  - **Evidence:** cache policy and ADR 0010

- **P0-W08-AC15**
  - **Given** a completed model invocation
  - **When** Context observability is inspected
  - **Then** it reports all required token, Tool, result, cache, repetition, compaction, retrieval, Artifact, Run-cost, and accepted-change-cost fields
  - **Evidence:** observability requirements and schema

- **P0-W08-AC16**
  - **Given** low-confidence or low-relevance candidates
  - **When** they are not required to disclose a material unknown
  - **Then** the compiler omits them and records the reason
  - **Evidence:** selection and omission rules

- **P0-W08-AC17**
  - **Given** Privacy policy restrictions
  - **When** a remote model package is compiled
  - **Then** blocked data is omitted or transformed before egress and the decision is recorded
  - **Evidence:** Security model and Context item contract

- **P0-W08-AC18**
  - **Given** the JSON contract
  - **When** a parser and schema validator load it
  - **Then** it is valid Draft 2020-12 JSON Schema and exposes compile request, manifest, package, documentation resolution, and observation definitions
  - **Evidence:** parser and validator output

- **P0-W08-AC19**
  - **Given** architecture, security, Capability integration, invariants, roadmap, README, and AGENTS
  - **When** terminology is inspected
  - **Then** they agree on smallest-sufficient Context, replacement, bounded Tool exposure, Artifacts, resolver order, and independent Run contexts
  - **Evidence:** cross-document inspection

- **P0-W08-AC20**
  - **Given** this planning-only work package
  - **When** the final diff is reviewed
  - **Then** no production source, tests, dependencies, workflows, scripts, prompts, Skills, or runtime configuration changed
  - **Evidence:** changed-file inventory

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
python -m json.tool docs/contracts/kiln-context.schema.json
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

A Draft 2020-12 JSON Schema validator must also load `docs/contracts/kiln-context.schema.json` before this work package is complete.

## Required completion evidence

| Evidence ID | Acceptance criterion | Required evidence |
| --- | --- | --- |
| P0-W08-E01 | P0-W08-AC01 | Token ceilings, phase targets, category budgets, and ADR 0010. |
| P0-W08-E02 | P0-W08-AC02 | Compiler architecture and pipeline. |
| P0-W08-E03 | P0-W08-AC03 | Package schema and contract. |
| P0-W08-E04 | P0-W08-AC04 | Retrieval and progressive-disclosure rules. |
| P0-W08-E05 | P0-W08-AC05 | Deduplication, invalidation, and metrics. |
| P0-W08-E06 | P0-W08-AC06 | Tool maximum, schema budgets, and phase table. |
| P0-W08-E07 | P0-W08-AC07 | MCP and LSP model-facing boundaries. |
| P0-W08-E08 | P0-W08-AC08 | Artifact-reference and externalization rules. |
| P0-W08-E09 | P0-W08-AC09 | Cursor binding and stale-cursor behavior. |
| P0-W08-E10 | P0-W08-AC10 | Lazy Skill policy. |
| P0-W08-E11 | P0-W08-AC11 | Resolver order, version rules, Context7 position, and ADR 0011. |
| P0-W08-E12 | P0-W08-AC12 | Child delegation package. |
| P0-W08-E13 | P0-W08-AC13 | Verifier first-pass package and independence rules. |
| P0-W08-E14 | P0-W08-AC14 | Stable prefix and cache policy. |
| P0-W08-E15 | P0-W08-AC15 | Observability fields and schema. |
| P0-W08-E16 | P0-W08-AC16 | Omission and exclusion records. |
| P0-W08-E17 | P0-W08-AC17 | Privacy and egress reconciliation. |
| P0-W08-E18 | P0-W08-AC18 | JSON parser and schema-validator output. |
| P0-W08-E19 | P0-W08-AC19 | Cross-document terminology review. |
| P0-W08-E20 | P0-W08-AC20 | Final changed-file list. |
| P0-W08-E21 | All | Passing complete CI against the final head. |

## Explicit exclusions

- production Elixir implementation;
- SQLite migrations;
- tokenizer implementation;
- provider adapter changes;
- model invocation implementation;
- Context compiler process design;
- embedding or vector database adoption;
- local ExDoc index implementation;
- runtime documentation adapter implementation;
- Context7 integration;
- web research integration;
- MCP client or server changes;
- LSP client or server changes;
- Artifact store changes;
- prompt-cache provider integration;
- DOM or database summarizers;
- Tool, Skill, prompt, workflow, or CI changes;
- automatic accepted-change token allocation.

## Completion statement

Implemented but unverified.