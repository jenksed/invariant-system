# Arsenal Research Packet — Provider-Native Exact-Byte Generation

**Lane:** M11 E4 (provider.representation.exact_byte.generation)
**Research question:** What provider-native representation and validation
method most reliably compiles probabilistic model output into exact source
bytes while preserving provider independence, deterministic
canonicalization, fail-closed behavior, and exact-byte human authority?

**Scope:** bounded research/evidence capture. No Kiln contract changes.
Arsenal observes and evaluates independently of E4 execution.

---

## 1. Observed evidence

### 1.1 Live evidence packet (sanitized — credential value excluded)

All live request/response pairs captured in:

```
/tmp/m11_e4_live/request_1.json
/tmp/m11_e4_live/response_1.json
/tmp/m11_e4_live/request_2.json
/tmp/m11_e4_live/response_2.json
/tmp/m11_e4_live/canonical_envelope_bytes.json
/tmp/m11_e4_live/canonical_dispatch_evidence.json
/tmp/m11_e4_live/canonical_proposal.json
/tmp/m11_e4_live/simulated_post_state.ex
/tmp/m11_e4_live_run1/                                  (full prior curl-based run, preserved)
/tmp/m11_e4_live_clean/                                (prior canonical timed-out attempt, preserved)
/tmp/m11_e4_live_repaired/                             (timeout-repair canonical, preserved)
/tmp/m11_e4_live_representation/                        (this research packet + representation-repair tree)
```

### 1.2 Live calls summary

| Call | Transport | Result | Defect class |
|------|-----------|--------|--------------|
| 1 (prior curl-based) | curl substitution | REJECTED | placeholder digest + destructive skeleton (model semantics) |
| 2 (prior curl-based) | curl substitution | ACCEPTED | none — bounded completion valid |
| 3 (canonical Finch #1, repair tree) | Finch.stream_while/5 + Mint default conn_timeout | TIMEOUT | CONNECT_TIMEOUT (Mint default 5_000–30_000ms; observed provider latency ~12s; first chunk ~30s; fired before Finch.stream_while/5's receive_timeout of 120_000ms) |
| 4 (canonical Finch #2, repair tree, FINAL new-budget call) | Finch.stream_while/5 + Mint conn_timeout=60_000ms + receive_timeout=120_000ms | SUCCEEDED (status:ok, body=2567 bytes) | STRUCTURED_OUTPUT — model's `after_image_bytes` contained literal `\n` (backslash + n, 2 chars) instead of actual newline (1 char). Double-escaping in the JSON-encoded model output. Simulated post-state file confirmed: 1 line, contains literal `\n`, NOT parseable as Elixir. |

### 1.3 Model / provider

- **Provider:** api.minimax.io
- **Endpoint:** https://api.minimax.io/v1/chat/completions
- **Model:** MiniMax-M3 (per recorded authorization + adapter config)
- **Transport:** `Finch.stream_while/5` over HTTP/1 (HTTP/1 explicit because bounded-receive depends on connection-level back-pressure)
- **Structured output:** native function/tool calling — bounded dispatch invokes `kiln_emit_candidate_envelope` with `engineering-system/implementer-patch-proposal-input/v1` schema

### 1.4 Representation failures observed

| Class | Description | Frequency | Effect |
|-------|-------------|-----------|--------|
| Placeholder digest | Model echoed "UNKNOWN_ORIGINAL_DIGEST_PLACEHOLDER" instead of the authoritative pre-state sha256 | 1/4 calls (Call 1) | Bounded dispatch rejects; pre-state mismatch is fail-closed |
| Destructive replace | Model proposed replacing 2114-byte module with 40-byte skeleton | 1/4 calls (Call 1) | Bounded dispatch cannot enforce semantic non-destructiveness for arbitrary targets |
| Connect timeout | Mint default connect_timeout fired at ~30s before Finch.stream_while/5's receive_timeout of 120s | 1/4 calls (Call 3) | Bounded apply never attempted; transport configuration defect |
| Receive timeout (correctly bounded) | Finch.stream_while/5's receive_timeout fires after 120s if no chunk arrives | 0/4 calls | Test B in m11_e4_finch_timeout_test.exs proves bounded behavior |
| Literal-newline escape | Model double-escaped `\n` in JSON-encoded `after_image_bytes`; content decoded as 1-line file with literal `\n` characters | 1/4 calls (Call 4) | Bounded apply would write invalid Elixir to disk; not fail-closed at bounded dispatch; **caught post-hoc** only by simulated post-state inspection |
| Provider failure (non-timeout) | HTTP 4xx/5xx response | 0/4 calls | bounded dispatch normalizes to canonical failure classes |

### 1.5 Canonicalization rules currently in force

```
content     = Enum.join(after_image_lines, "\n")
bytes       = if final_newline, do: content <> "\n", else: content
```

This is the **M11 E4 representation-repair** canonicalization (committed at
`E4_REPRESENTATION_REPAIR_SHA = ec76f31ffea9bf1dc2be5f9eea964a01919f8611`,
per owner authorization §4). Provider-private representation
(`after_image_lines` + `final_newline`) lives only inside the MiniMax
tool schema; the downstream canonical envelope contract
(`engineering-system/implementer-patch-proposal-input/v1`) continues to
carry `after_image_bytes` only.

---

## 2. Ambiguity classes identified

### 2.1 Whole-file string field with embedded escape sequences

**Class:** the provider's structured output carries a single string field
(`after_image_bytes`) that is supposed to be the exact bytes of the
post-image. The model's representation of this field must encode newlines,
quotes, and backslashes via JSON escaping. **The model's escaping is
probabilistic.**

**Failure mode:** the model produces JSON where `\n` (newline) is encoded
as `\\n` (literal backslash + n). On JSON decoding, the result is a
string with literal `\n` characters, not actual newlines. The bounded
dispatch's structural validation accepts the structurally-valid JSON.
The bounded apply writes the bytes verbatim. The post-state file is
invalid Elixir (one line with literal `\n`).

**Mitigation (M11 E4 representation-repair):** replace the whole-file
string field with a provider-private line-array
(`after_image_lines` + `final_newline`). Each array entry IS the exact
bytes of one source line — literal characters, no escaping. The adapter
joins with `\n` and optionally appends a trailing newline.

**Residual risk:** the line-array representation still depends on the
model correctly producing an array of strings. Models can still produce
malformed arrays (e.g., empty arrays, non-string entries, arrays with
the wrong count). The bounded dispatch rejects malformed arrays with
`:E_MALFORMED_OUTPUT` (proven by tests M1–M3).

### 2.2 Pre-approval content validity

**Class:** a structurally-valid canonical envelope is not necessarily a
viable candidate for an Elixir target. The bounded machinery writes
whatever the model proposed; it does not validate language semantics.

**Failure mode:** a model can produce a structurally-valid envelope whose
`after_image_bytes` does not parse as Elixir. The bounded apply succeeds
technically; the post-state file is invalid.

**Mitigation (M11 E4 representation-repair §6):** a pre-approval
Elixir-parseability content-validity gate runs after provider-private
translation. Uses `Code.string_to_quoted/1` (non-bang) so exception
handling stays outside the bounded dispatch's expected control flow.
On parse failure, the adapter returns
`{:error, %{code: :E_PROVIDER_REPRESENTATION_INVALID, ...}}` and the
bounded dispatch never emits a candidate.

**Residual risk:** parseability is necessary but not sufficient for
semantic correctness. A syntactically valid Elixir file may still
introduce runtime errors or behavioral regressions. Post-apply
verification (existing deterministic + registered verifier surface)
covers this.

### 2.3 Provider-native contract divergence

**Class:** the MiniMax native function/tool calling reliably produces
structural schema (proven: 4/4 calls produced valid `tool_calls` with
correct function name and argument JSON parse). But the model's content
of the arguments is probabilistic.

**Evidence:** the `tool_call` machinery has been 100% reliable across
the bounded evidence. The content within `arguments` is the
unreliability surface.

---

## 3. Deterministic repairs applied (M11 E4)

### 3.1 Timeout-configuration repair (commit `09cd4f9d`)

- **Defect:** Mint default connect_timeout fired before Finch.stream_while/5's receive_timeout
- **Repair:** explicit `conn_opts: [transport_opts: [timeout: 60_000]]` on the bounded Kiln.MinimaxFinch pool
- **Deterministic tests:** `m11_e4_finch_timeout_test.exs` — 5 tests (A–E) on loopback, all PASS at HEAD=3315f66 and HEAD=ec76f31
- **Verified:** `LIVE_CANONICAL_FINCH_INVOCATION = PROVEN` (Call 4 succeeded end-to-end at HEAD=3315f66)

### 3.2 Representation repair (commit `ec76f31`)

- **Defect:** model's `after_image_bytes` carried literal `\n` not actual newlines
- **Repair:** provider-private line-array (`after_image_lines` + `final_newline`); deterministic translation; pre-approval Elixir-parseability gate
- **Deterministic tests:** `m11_e4_provider_representation_test.exs` — 20 tests (A–M + content-validity + canonical pass-through), all PASS at HEAD=ec76f31
- **Verified:** `PROVIDER_REPRESENTATION_TRANSLATION = PROVEN`, `CONTENT_VALIDITY_GATE = PROVEN`

---

## 4. Open research questions for Arsenal

1. **Provider-native alternative representations.** Are there provider-native formats (e.g., dedicated patch/diff formats, file-id + diff hunks, base64-encoded structured payloads) that eliminate the line-array ambiguity class entirely? Survey across providers.

2. **Per-token validation.** Can the bounded dispatch apply a per-token or per-line semantic check during streaming, not just at the post-hoc parseability gate? E.g., reject any line containing literal `\n` after first-line boundary.

3. **Cross-model variance.** Do other models (Claude, GPT, etc.) exhibit the same double-escape class, or is this MiniMax-specific? Quantitative comparison.

4. **Determinism guarantees from providers.** What is the maximum byte-level determinism a provider can guarantee? Provider-side temperature / seed controls. Per-call reproducibility tests.

5. **Hybrid representation.** Could a hybrid representation (line-array for most cases + explicit byte-level fallback for edge cases like binary files) close the gap without changing canonical contracts?

6. **Post-apply semantic checks.** Beyond Elixir parseability, what other semantic checks should the bounded dispatch apply? (e.g., behavioral regression detection, dependency impact analysis.)

---

## 5. Constraints Arsenal must respect

- **No Kiln contract changes during this execution.** Arsenal is observational only.
- **No Arsenal architecture changes.** Research packet only.
- **Provider independence preserved.** The repair must work across providers, not just MiniMax.
- **Exact-byte authority preserved.** No post-approval normalization that mutates bytes outside the bounded apply's authority.
- **Deterministic canonicalization.** Same envelope bytes must always produce same canonical bytes.

---

## 6. Packet status

- **Created:** 2026-08-18 (M11 E4 session)
- **Lane:** M11 E4
- **Owner:** Joshua Jenks
- **Status:** OBSERVATIONAL — does not block E4 execution
- **Related SHAs:**
  - `E4_REPAIR_SHA = 8fa7b4de20041b1d08dd6f7fe8548200e1140bca` (authority-gate ancestry)
  - `E4_TIMEOUT_REPAIR_SHA = 09cd4f9d30dd16ad93ff11c1a026d6b6eeefd85a` (Mint connect_timeout)
  - `E4_REPRESENTATION_REPAIR_SHA = ec76f31ffea9bf1dc2be5f9eea964a01919f8611` (provider-private line-array + content-validity gate)
