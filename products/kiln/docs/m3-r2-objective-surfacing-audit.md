# M3-R2 Objective-Surfacing Contract Audit

**Date**: 2026-08-20
**Auditor**: M3-R2 lane
**Status**: PROVISIONAL — pending schema-level repair

## What changed

`products/kiln/lib/kiln/worker.ex:merge_dispatch_attrs/3` (+26/-5 lines)
encodes `request_attrs["engineering_objective"]` into
`context_manifest_ref.id` when the request carries one, otherwise
falls back to `profile["system_config"]`. The digest is the SHA-256
of the objective bytes.

## Why it was needed

Live M3-R2 run #1 returned
`{:error, :E_PROVIDER_REPRESENTATION_INVALID}` because the MiniMax
provider produced no usable output — its response body was a textual
refusal that did not parse as a bounded envelope.

The refusal text (verbatim from the captured raw body):

> "I can't produce this envelope. The dispatch context you've
> provided contains no actual patch content — only metadata
> placeholders. To emit a valid
> `engineering-system/implementer-patch-proposal-input/v1` envelope,
> I need the real content..."

The model refused because `bounded_context_text/1` showed it only:
- `output_contract`
- `envelope_schema`
- `invocation_id`
- `context_manifest_ref: %{id: <system_config_id>, digest: <sha256>}`

There was no engineering objective visible to the model. The bounded
context was honest metadata, not a task statement. The model refused to
fabricate, which is the correct behavior of a constrained provider.

## Audit questions and findings

### 1. What is `context_manifest_ref`?

Defined in `contracts/m0/schemas/candidate-invocation.m0-v1.schema.json`
and `contracts/m0/schemas/review.m0-v1.schema.json`. Both reference
`artifactRef` from the `$defs`:

```json
"artifactRef": {
  "additionalProperties": false,
  "properties": {
    "digest": { "pattern": "^sha256:[0-9a-f]{64}$", "type": "string" },
    "id":     { "minLength": 1, "type": "string" }
  },
  "required": ["id", "digest"],
  "type": "object"
}
```

The field is also referenced in
`contracts/m0/schemas/intelligence-requirement.m0-v1.schema.json`
under `must_use_separate_context_manifest`.

### 2. What is `context_manifest_ref.id` semantically supposed to represent?

Per the schema's name and the
`must_use_separate_context_manifest` rule in
`intelligence-requirement.m0-v1.schema.json`, `.id` is an opaque
identifier for a *context manifest artifact* — separate from the
engineering task itself. The corresponding `.digest` is the SHA-256 of
that manifest's bytes. The downstream Kiln code currently builds it
from `profile["system_config"]["id"]` / `["digest"]` (a UUID-shaped
identifier and its hash).

### 3. Is `.id` an opaque identity/reference only?

Schema-wise it is any non-empty string (no format constraint, no
length limit). In current practice it carries a short UUID-shaped
string. The field is rendered to the model via
`bounded_context_text/1` (`Kiln.MinimaxM3Adapter` and
`Kiln.KimiAdapter` both):

```elixir
"context_manifest_ref: #{inspect(request.context_manifest_ref)}"
```

So the model sees `id` verbatim. The field is *technically* allowed
to carry any text; *semantically* it has been an opaque identifier.

### 4. Is it legitimately allowed to carry objective-bearing information?

- Schema: YES (no constraint on content beyond non-empty string).
- Semantics: QUESTIONABLE — the field name and the
  `must_use_separate_context_manifest` rule suggest it points to a
  context-manifest artifact, not to the task statement.
- Live behavior: the model in MiniMax reads `id` as ordinary text and
  uses it as the engineering task when `id` contains the objective.
- Risk: another consumer (a verifier, a downstream reducer, the
  Kimi adapter, the bounded-context renderer) might treat `id` as an
  identifier and try to dereference it. We have not surveyed all
  consumers exhaustively; the current change passes `Kiln.Review.build/9`
  unchanged because the field flows from the request through
  `Worker.propose/5` only.

### 5. Exactly what bytes/text does MiniMax receive after `merge_dispatch_attrs/3`?

Verified against the captured raw body of run #2 (after the fix).
The model-facing `user` message contains:

```
Bounded dispatch context.

You are operating inside a bounded Kiln dispatch. Produce a single
canonical envelope by calling the function kiln_emit_candidate_envelope.
Do not include any other text, reasoning, or function calls.

output_contract: IMPLEMENTER_PATCH_PROPOSAL
envelope_schema: engineering-system/implementer-patch-proposal-input/v1
invocation_id: inv_e2_<hex>
context_manifest_ref: %{id: "Add a small bounded module attribute @m3r2_smoke_marker \"true\" to the end of the file products/kiln/lib/kiln/m0_types.ex. Do not modify anything else.", digest: "sha256:<64-hex>"}
```

The objective is the value of `id` in `context_manifest_ref`.

### 6. Where does the human-readable engineering objective become visible to the model?

Only inside `context_manifest_ref.id`, via the `inspect(...)` call in
`bounded_context_text/1`. There is no other field that carries the
objective.

### 7. Does any consumer now depend on a new undocumented encoding convention?

Yes — the new convention is "if `request_attrs` carries
`engineering_objective`, encode it into `context_manifest_ref.id` and
make the digest the SHA-256 of the objective text." No other code in
the kiln product knows this convention. The encoded form still parses
as `artifactRef`; the convention is invisible outside the bounded
context.

### 8. Is the SHA-256 digest being used only as identity/provenance, or is it being treated as semantic content?

Treated only as identity/provenance. The digest satisfies the schema
regex (`^sha256:[0-9a-f]{64}$`) and is verifiable as SHA-256 of the
objective bytes; nothing in the runtime tries to reconstruct objective
text from the digest. The model cannot decode objective from a digest
(it has the id right next to it).

## Classification

The current change is **PROVISIONAL** per the user's instruction.

The principled fix is **MISSING IMPLEMENTATION** in the schema layer:
`engineering-system/candidate-invocation/m0-v1` does not currently
carry an `engineering_objective` field. The bounded
`engineering-system/intelligence-assignment/m0-v1` carries the
assignment but the assignment's `requirement_ref` is a generic
artifact reference; the requirement text itself does not surface to
the provider.

The proper repair:

1. Add an `engineering_objective` field to
   `contracts/m0/schemas/candidate-invocation.m0-v1.schema.json`
   (string, non-empty).
2. Add it to `Kiln.CandidateInvocation` struct, identity payload, and
   `merge_dispatch_attrs/3` mapping (string-keyed in
   `request_attrs`).
3. Render it in `bounded_context_text/1` as its own line, e.g.
   `engineering_objective: <text>` — not stuffed into `context_manifest_ref.id`.
4. Update `bounded_context_text/1` in BOTH `Kiln.MinimaxM3Adapter`
   and `Kiln.KimiAdapter` to keep their model-facing text consistent.

This requires a schema bump and an identity-payload digest change.
That is dependency-sensitive work that does not belong in the M3
close-out.

## Status carried into M3 freeze

OBJECTIVE_SURFACING_CONTRACT: REPAIRED (provisional)

The current `merge_dispatch_attrs/3` change keeps M3-R2 functional but
loads the contract. The full repair (add `engineering_objective` as a
first-class field) is queued for the next lane that owns schema
contracts.

## Non-secret evidence captured

```
wko_id:              wko_13dba3170ba4f31c
semantic_digest:     sha256:01931d8d0f047ac1113ab77ede4f6b181ae1b4469213f0c093fab672d02d051c
base_commit:         82b2d54fc64e8a55a404269926ef5a3816e3c040
adapter_digest:      sha256:cd8bd03f67dd21b2c96e0cebf46d775ecd573ded98bc3d64a47dc3ea424d7ab3
operation:           add test/support/m3r2_marker.ex (78 bytes)
proposal_id:         pp_2488ae6d1e35f1e7
proposal_patch_digest: sha256:cb8f8fa2cf7dd2e49167b2a3b240ef54f65a125a18883de340e75f329ba01eda
verification_id:     ver_6d711ed3d015992a
verification_digest: sha256:dcc715748bfd5d8811f00be5af056ad2e32d4bbd5a5b8fa93667b8b42f953156
review_id:           rev_8ac70712c962586f
review_digest:       sha256:0112f3843e1fe616b2c8713e7c394c39ac9aa65d584efeaf7a00041a926f3ad6
decision_id:         dec_f63309c06553644e88794c016197a594
final_run_state:     ready
```