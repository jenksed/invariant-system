# LANE-EVIDENCE — M11 E4 (MiniMax provider network dogfood)

**Lane:** `M11-E4`
**Branch lineage:** `m0/kiln-02` → ... → `m0/sys-03` (M11 E2/P2/P3) → M11 E4 acceptance
**Final SHA:** `ec76f31ffea9bf1dc2be5f9eea964a01919f8611` (E4_REPRESENTATION_REPAIR_SHA)
**Authorization basis:** `products/kiln/docs/authorizations/KILN-M0-01-E4.provider-network.authorization`
**Closed by:** Joshua Jenks, ACCEPT (2026-08-18, live execution)

## What M11 E4 proved

The M11 E4 lane ran the **first complete canonical MiniMax M3 provider.dogfood loop** under
Kiln's bounded M0 contract envelope. The chain executed end-to-end at HEAD=ec76f31:

```
real MiniMax-M3
  → Kiln.MinimaxM3Adapter
  → Finch.stream_while/5 (bounded, HTTP/1, receive_timeout bounded)
  → Mint 1.9.3 (conn_opts: [transport_opts: [timeout: 60_000]])
  → api.minimax.io/v1/chat/completions
  → bounded dispatch (status:ok, body 4734 bytes)
  → bounded Worker completion (canonical bytes, Elixir-parseable)
  → PatchProposal (semantic_digest 905f0bc9..., patch_digest sha256:3ad80b17...)
  → owner APPROVE_EXACT_BYTES
  → patch-apply-governed (PatchService.apply/3, EXACT_TARGET_STATE_OBSERVED)
  → VerificationResult PASS (ver_8895597f9aa10aa5, registered verifier
                              = canonical E4 authority suite)
  → Manifold-selected reviewer (prf_833961bc..., digest sha256:0eb495a8...,
                              distinct from implementer sha256:d44d6371...)
  → Review (rev_92561084bb8d80ba, verdict=APPROVE,
            implementer_transcript_received=false, independence_by_digest=true,
            6 findings)
  → explicit owner HumanDecision ACCEPT (hd_0f9a847d1a3f2df9)
  → RunResultProjection (rj_440db422c7b3f237,
                         semantic_digest sha256:2d8c61750104d6fd...)
  → Temper snapshot
```

## What defects dogfood exposed

M11 E4 surfaced four concrete defects during dogfood. Each was repaired, deterministically
tested, and re-proven via fresh-SHA. The chain of defects (and their repairs) is the primary
value of the lane — it forced every bounded invariant to be exercised.

| Defect | Discovery | Repair commit | Deterministic proof |
|--------|-----------|---------------|---------------------|
| **CONNECT_TIMEOUT** — Mint's default connect_timeout fired before Finch.stream_while/5's receive_timeout during the canonical-Finch live dispatch | Call 3 timed out at ~30s; prior curl-based Calls 1+2 succeeded at 12s | `09cd4f9d` — `conn_opts: [transport_opts: [timeout: 60_000]]` on the bounded `Kiln.MinimaxFinch` pool | `m11_e4_finch_timeout_test.exs` 5/5 PASS (A–E: completes-below, stalls-beyond, oversize, no-retry, no-fallback) |
| **STRUCTURED_OUTPUT** — model double-escaped `\n` in JSON-encoded `after_image_bytes`; content decoded as 1-line file with literal `\n` (invalid Elixir) | Call 4 succeeded (status:ok, 2567 bytes) but post-state was one line with literal `\n` characters; bounded dispatch accepted structurally valid JSON whose content was semantically invalid | `ec76f31` — replace provider-private `after_image_bytes:string` with provider-private `after_image_lines:array<string> + final_newline:boolean`; adapter deterministic translation; pre-approval Elixir-parseability content-validity gate via `Code.string_to_quoted/1` (non-bang); bounded `:E_PROVIDER_REPRESENTATION_INVALID` failure class | `m11_e4_provider_representation_test.exs` 20/20 PASS (A–M + content-validity + canonical pass-through) |

Plus two defects that were correctly rejected automatically without consuming a human gate:

| Defect | Discovery | Rejection mechanism |
|--------|-----------|--------------------|
| **Placeholder digest + destructive skeleton** | Call 1 (prior curl run) returned `expected_before_digest="UNKNOWN_ORIGINAL_DIGEST_PLACEHOLDER"` and proposed replacing the 2114-byte module with a 40-byte skeleton | Bounded dispatch's preimage check + the bounded apply's digest verification fail-closed; no apply attempted; no owner gate consumed |
| **Connection-timeout race in test loopback server** | During repair determinism verification, Test A in `m11_e4_finch_timeout_test.exs` flaked at ~40% rate due to TCP-level send/close race | Loopback server updated to send headers+body atomically in a single `:gen_tcp.send` call; explicit `System.put_env("MINIMAX_API_KEY", ...)` in test setup eliminates env-propagation flakiness |

## What was repaired

The two commits in the M11 E4 chain that are durable source-code repairs (not test-only):

- `09cd4f9d` — **timeout-repair**: explicit bounded Mint connect_timeout
- `ec76f31` — **representation-repair**: provider-private line-array + pre-approval Elixir gate

The associated deterministic test coverage (in repo):
- `products/kiln/test/kiln/m11_e4_finch_timeout_test.exs`
- `products/kiln/test/kiln/m11_e4_finch_loopback_test.exs`
- `products/kiln/test/kiln/m11_e4_provider_authority_test.exs`
- `products/kiln/test/kiln/m11_e4_provider_canonical_chain_test.exs`
- `products/kiln/test/kiln/m11_e4_provider_representation_test.exs`
- `products/kiln/test/kiln/minimax_m3_adapter_deterministic_test.exs`

97 tests across these files, all PASS at HEAD=ec76f31 (verified across multiple
consecutive runs after the loopback-server atomic-write fix).

The accepted M11 dogfood mutation:

```
target:    products/kiln/lib/kiln/operation_lifecycle.ex
pre:       sha256:355155f98ea5883d868441c7bc796c5370a2c7b378dfec8554039dea075f662b (2114 bytes)
post:      sha256:ffc399d7a8141a4edced0577927ca11d2c1a8510fb56b6bf5a7e8c99fff54f7a (2143 bytes)
diff:      +1 line ("# E4 bounded dogfood change." inserted as line 2)
```

The mutation is a minimal bounded dogfood change: a single comment line marking the
executed dogfood target. No functional change.

## Lessons retained

The M11 E4 lane proved several architectural properties that are durable lessons:

1. **Component-green does not prove composed-green.** Each individual bounded invariant
   (authority gate, canonical envelope, bounded apply, verification, review) was proven
   individually before M11. M11 E4 proved that the COMPOSITION through the entire chain
   produces a single coherent mutation. Individual tests did not catch the ConnectTimeout
   or the StructuredOutput defects — only the composed execution did.

2. **Exact result correctness does not prove correct provenance.** The post-state sha256
   on disk was correct. The patch_digest was correctly bound. But the upstream provider
   representation (literal `\n` characters) was wrong. Result correctness is necessary
   but not sufficient; the PROVENANCE chain (provider → canonical → bounded apply →
   result) must also be correct.

3. **Provider protocol validity != canonical artifact validity.** A model that emits
   structurally valid JSON for the provider's tool-call protocol can still produce a
   semantically invalid canonical artifact. The provider cannot know about the canonical
   contract; only the bounded dispatch can.

4. **Structural validity != semantic candidate viability.** Pre-M11, the bounded dispatch
   validated `tool_calls` count, message structure, function name, argument JSON parse.
   That structural validation is necessary but not sufficient. The new content-validity
   gate (`Code.string_to_quoted/1` on `after_image_bytes`) is the semantic gate.

5. **Qualification != authorization.** The provider's qualification (it's a working API
   endpoint) and the bounded machinery's authorization to dispatch to it (KILN-M0-01-E4
   authorization record) are independent. Both are required.

6. **Selection != execution authority.** Manifold's REVIEWER Assignment is selected by
   `FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST`; that selection does NOT grant execution
   authority. The Reviewer emits a verdict; the owner emits HumanDecision. Two separate
   authority gates.

7. **Human approval binds exact bytes/base state.** APPROVE_EXACT_BYTES is not a
   generic approval. The owner explicitly named base_state_sha256, proposal_semantic_digest,
   proposal_patch_digest, approved_post_state_sha256. The bounded apply's identity check
   (`assert_rebuild_matches_approved`) verifies all four.

8. **Provider adapters compile provider-native representation into deterministic canonical
   contracts.** MiniMax emits `after_image_lines:array + final_newline:bool` (provider-
   private, ambiguous for the model). The adapter deterministically compiles this into
   `after_image_bytes:string` (canonical, exact bytes). The provider-private representation
   dies inside the adapter; downstream consumers see only the canonical contract.

9. **Recovery must reconcile observable state rather than replay blindly.** The bounded
   apply's fail-closed preimage check exists precisely so that a "request returned error"
   never causes a blind replay. Where effect is uncertain, recovery must inspect
   authoritative observable state (post-state sha256, evidence record) before continuing.

## Reconciliation notes (M11-B)

The M11 closeout reconciliation surfaced two report-accuracy issues that were
deterministically investigated and resolved:

- **Endpoint**: actual canonical-Finch dispatch used `/v1/chat/completions` (matches
  authorization record `KILN-M0-01-E4.provider-network.authorization`). The owner's
  repeated `/v1/text/chatcompletion_v2` references were an instruction TO the model in
  the bounded context, not the actual endpoint. No defect.

- **Commit lineage**: the actual chain is
  `8fa7b4d (E4_REPAIR_SHA) → 09cd4f9d (timeout repair) → 3315f66 (timeout test) →
  ec76f31 (representation repair = E4_REPRESENTATION_REPAIR_SHA)`.
  The earlier evidence wording "carries forward from HEAD=3315f66" was imprecise: 3315f66
  is an ANCESTOR of ec76f31, not a predecessor. The chain is correct; only the phrasing
  was imprecise.

- **RunResultProjection identity**: the canonical-Finch run and the prior curl-run produced
  different `rj_*` ids and different `sha256:*` semantic_digests once the verify.exs bug was
  fixed (verify.exs looked for nested `assignment` key but Manifold emits top-level keys,
  causing `nil` reviewer_assign to propagate and accidentally converge with the prior
  digest). With correct refs, the canonical-Finch projection is
  `rj_440db422c7b3f237` / `sha256:2d8c61750104d6fd...` (distinct from prior curl-run).
  The projection identity is correctly bound to inputs; no defect.

- **Live call accounting**: across all M11 E4 attempts, 5 bounded live calls were
  consumed (1 prior curl rejected, 1 prior curl accepted, 2 canonical Finch attempts in
  the prior session with the 2-call timeout-repair budget, 1 canonical Finch accepted
  in this session with the 2-call representation-repair budget). 1 call remains in the
  current 2-call budget. No call was wasted on speculative wording changes.

## Arsenal research packet

A bounded observational Arsenal research packet captures the M11 E4 evidence, defect
classes, deterministic repairs, and open research questions for the provider-native
exact-byte generation problem:

```
products/arsenal/research/m11_e4_provider_native_exact_byte_generation.md
```

The packet is OBSERVATIONAL and does not block M11 closure. Open research questions
include: cross-model variance on the same ambiguity class, per-token validation
alternatives, provider-native alternative representations (diff hunks, base64), and
post-apply semantic checks beyond Elixir parseability.

## Deferred to M12

Per the M12 lanes:

- **CI Golden Path** (Lane A) — turn M11 from "we ran it" into "fresh checkout proves it"
- **Recovery / Restart** (Lane B) — `E_MUTATION_UNKNOWN_EFFECT`, blind-replay prohibition
- **Artifact + Run/Session Canonicalization** (Lane C) — durable ID/semantic/store for every bounded artifact; ownerships the RunResultProjection identity defect (already addressed, but the broader artifact model is M12 work)
- **Temper Operator Surface** (Lane D) — bounded Session-derived state, real operator UX
- **Provider Qualification** (Lane E) — distinguish LIVE_SUCCESS from QUALIFIED_PROVIDER_CAPABILITY; qualification MUST NOT grant execution authority

## Final acceptance

```
E4_REPRESENTATION_REPAIR_SHA   = ec76f31ffea9bf1dc2be5f9eea964a01919f8611
LIVE_CANONICAL_FINCH_INVOCATION = PROVEN  (at HEAD=ec76f31, directly, not inherited)
LIVE_STRUCTURED_OUTPUT          = PROVEN
REAL_WORKER_COMPLETION          = PROVEN
E4_PATCH_PROPOSAL               = PROVEN
E4_APPROVAL                     = PROVEN  (owner explicit APPROVE_EXACT_BYTES)
E4_APPLY_EFFECT                 = PROVEN  (EXACT_TARGET_STATE_OBSERVED)
SAME_COMPLETION_REMATERIALIZATION = PROVEN
E4_VERIFICATION                 = PROVEN  (VerificationResult PASS)
MANIFOLD_REVIEWER_ASSIGNMENT    = PROVEN  (intelligence-assignment/m0-v1)
REVIEWER_INDEPENDENCE           = PROVEN  (digest-distinct + implementer_transcript_received=false)
E4_REVIEW                       = PROVEN  (verdict=APPROVE)
E4_HUMAN_DECISION               = PROVEN  (ACCEPT)
E4_PROJECTION                   = PROVEN  (RunResultProjection built)
E4_TEMPER                       = PROVEN  (snapshot produced)

E4_ACCEPTANCE_STATUS            = PROVEN
M11_COMPLETE                    = YES
```

The canonical-Finch live-dispatch evidence is at HEAD=ec76f31 directly:
- bounded dispatch returned `status: :ok` from `/v1/chat/completions`
- body = 4734 bytes, sha256 = `d307ff83f1ca07d39f261f64ef1e908763bed5fbf947e262f5867dfcd3d12efe`
- envelope decoded via `decode_provider_response_wrapper/1`
- content-validity gate passed (`Code.string_to_quoted/1` succeeded on canonical bytes)
- semantic_digest = `905f0bc93ccfad068a6e07579b162e920255d6430a78101fe900460e3288f587`
- patch_digest = `sha256:3ad80b17cd8e162d92ade7670f5a679fc26e365c0081e504cd18a09854e864be`

**M11 E4 lane closed.**
