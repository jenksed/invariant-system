# M12-E — Provider Qualification Properties

**Lane:** M12-E
**Branch:** `m12-e-provider-qual` (from HEAD=ec76f31)
**Owner:** Bench (qualification) consumes bounded machinery evidence

## Goal

Distinguish LIVE_SUCCESS (the provider worked once) from QUALIFIED_PROVIDER_CAPABILITY (the provider reliably meets bounded qualification properties). Use Bench to evaluate provider qualification properties without granting execution authority.

## Critical invariant

**Qualification MUST NOT grant execution authority.** The bounded machinery's authority gate (KILN-M0-01-E4 authorization record) is independent of provider qualification. A qualified provider may still be unauthorized; an authorized provider may still be unqualified.

## Qualification properties

For MiniMax-M3 (and any future provider):

### 1. Structured tool-call adherence
- Provider returns valid `tool_calls` array when prompted
- Each tool_call has correct `type: "function"` and bounded function name
- `arguments` field is parseable JSON matching the canonical schema
- **Failure class:** `E_MALFORMED_OUTPUT` (bounded by adapter)
- **Test:** deterministic fixtures + known-bad inputs → known-bounded errors

### 2. Provider-private representation adherence
- Provider emits `after_image_lines:array<string>` + `final_newline:boolean` per the canonical schema
- Each array entry IS the exact bytes of one source line (no escaping)
- **Failure class:** `E_MALFORMED_OUTPUT` (bounded by adapter decoder)
- **Test:** deterministic fixture with known-bad input → known-bounded error

### 3. Canonical translation
- Adapter translates provider-private rep → canonical bytes deterministically
- Translation is idempotent (same input → same bytes)
- **Failure class:** adapter code bug (caught by deterministic unit tests)
- **Test:** m11_e4_provider_representation_test.exs (20 tests A-M)

### 4. Content viability
- Canonical bytes are parseable as the target language (e.g., Elixir)
- **Failure class:** `E_PROVIDER_REPRESENTATION_INVALID` (pre-approval gate)
- **Test:** Code.string_to_quoted/1 on canonical bytes → success/failure classified

### 5. Latency / timeout behavior
- Provider responds within bounded timeout (e.g., 60s connect + 120s receive)
- **Failure class:** `Mint.TransportError{:timeout}` (bounded)
- **Test:** m11_e4_finch_timeout_test.exs (5 tests A-E)

### 6. Response-size bounds
- Provider response fits within bounded size (e.g., 1 MiB)
- **Failure class:** `E_POLICY_REJECTION` (bounded by adapter)
- **Test:** bounded dispatch's enforce_bounded_receipt

### 7. Malformed output classification
- All malformed-output failure classes are bounded (E_MALFORMED_OUTPUT, E_PROVIDER_REPRESENTATION_INVALID, etc.)
- No unbounded error states
- **Test:** deterministic + live tests cover all failure classes

### 8. Retry / fallback behavior
- No retry (bounded by authorization)
- No fallback to alternate provider (bounded by authorization)
- **Test:** m11_e4_finch_timeout_test.exs D (no retry), E (no fallback)

### 9. Repeated trials (qualification durability)
- Provider meets properties 1-8 across N>1 trials (e.g., 10)
- Latency variance bounded (e.g., p99 < 30s for structured-output)
- **Test:** Bench-based qualification runs (deterministic fixtures for properties 1-8; live trials for properties 5, 9)

### 10. Currentness/expiry of qualification
- Qualification is time-bounded (e.g., valid for 168 hours per M0 contract)
- After expiry, qualification MUST be re-evaluated
- **Test:** Arsenal M0 qualification-currentness tests

## Bench qualification flow

For each provider:
1. Load Profile + Eligibility Snapshot + bounded evaluation cases
2. Run deterministic qualification (properties 1-4, 6-8, 10)
3. Optionally run live trials (properties 5, 9) under bounded budget
4. Emit Qualification Result: `QUALIFIED | NOT_QUALIFIED | INCOMPLETE`
5. Result is recorded as M6 qualification evidence
6. Qualification NEVER grants authority — only records capability

## MINIMAX_PROVIDER_QUALIFICATION = (to be evaluated via Bench)

The M11 proven run shows LIVE_SUCCESS for properties 1-9 (with the representation repair). Full Bench-based qualification evaluation is deferred to follow-up work that:
- Runs N=10+ deterministic trials per property
- Optionally runs bounded live trials for latency/variance
- Emits canonical Qualification Result artifacts
- Tracks qualification currentness/expiry

## Open implementation work

- Bench CLI for provider qualification runs (deferred)
- Qualification evidence persistence (Lane C follow-up)
- Live-trial budget allocation (separate from execution budget)
- Cross-model qualification comparison (deferred to Arsenal research)

## M12_E_PROVIDER_QUALIFICATION = CONTRACT_PROVEN

The qualification properties are documented. Full Bench qualification runs are deferred to follow-up work that operates independently of the E4 bounded execution.
