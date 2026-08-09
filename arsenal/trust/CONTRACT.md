# Trust & Authority Plane Contract

Status: ARS-08 v0

Project Arsenal already knows what authority a canonical capability requires (ARS-01), whether a declared route has a sufficient authority profile (ARS-04), what proof surface is justified (ARS-05/06), and what authority a completed evidence-producing run actually observed (ARS-07). ARS-08 adds the missing admission-control layer for imported competence.

## Headline invariant

> **Competence is not authority.**

A package can contain useful instructions and still be untrusted, stale, over-privileged, or inappropriate for the capability it claims to implement. Familiar packaging, popularity, provenance metadata, or a cryptographic digest is evidence to inspect; none is itself authorization.

Additional invariants:

- provenance is evidence, not trust;
- every external import starts quarantined;
- approval is bound to exact bytes, policy, review, and canonical capability state;
- digest drift resets trust;
- approval cannot increase canonical capability authority;
- policy cannot widen the canonical capability contract;
- the canonical capability contract cannot bypass local trust policy;
- revocation preserves prior evidence rather than rewriting history.

## Responsibility boundary

```text
Capability Contract
  = what authority behavior requires / allows / forbids

Compiler + .arsenal.lock
  = exact first-party capability/package provenance

Trust Candidate
  = exact imported bytes + source metadata + authority signals

Trust Review
  = explicit interpretation + requested/approved authority

Trust Policy
  = local baseline / escalation / prohibited ceiling

Trust Decision
  = admission result bound to candidate + policy + capability digests

Capability Graph / future Intent Compiler
  = may consume approval; may not create trust

Flight Recorder
  = records authority actually observed during execution
```

ARS-08 does not replace any of those layers.

## Ingress state machine

```text
discover
  ↓
QUARANTINED
  ↓
inspect exact bytes + provenance + authority signals
  ↓
explicit review
  ↓
canonical capability + local policy comparison
  ├── APPROVED
  ├── REVIEW_REQUIRED
  ├── ESCALATION_REQUIRED
  └── REJECTED
```

Approval is an admission result. It does **not** automatically install, compile, register, or execute a package.

## Candidate identity

Discovery inventories every regular file beneath the candidate root and records:

- traversal-free relative path;
- SHA-256 digest;
- executable bit;
- deterministic package digest over sorted path/digest pairs.

Symlink indirection is rejected in v0.

Candidate IDs are derived from the exact package digest. Any content change therefore creates materially different candidate state.

## Provenance assurance

ARS-08 v0 deliberately uses narrow assurance labels:

- `incomplete` — required source/revision facts are missing;
- `digest-only` — exact reviewed local bytes are pinned, but publisher/source identity is not independently verified;
- `source-revision-pinned` — an exact commit-like source revision is declared;
- `compiler-manifest-verified` — an Arsenal compiler package manifest and canonical source digests verify against the current repository.

These labels do not claim that the package is safe.

A digest proves which bytes were reviewed. It does not prove those bytes are benign.

A pinned source revision identifies expected source state. It is not a verified publisher identity.

Cryptographic publisher/build attestations require signature, identity, trust-root, and policy verification. ARS-08 v0 leaves Sigstore/GitHub/SLSA-style verification as an adapter seam rather than emitting a fake `verified` result.

## Agent Skills authority signals

The upstream Agent Skills `allowed-tools` field is treated as an **advisory discovery signal**, never as an Arsenal grant or enforcement boundary.

The v0 adapter conservatively maps a small understood subset:

- `Read`, `Grep`, `Glob` → `filesystem.read`;
- `Write`, `Edit` → `filesystem.write`;
- `WebFetch`, `WebSearch` → `network.read`;
- recognized read-only `Bash(git ...)` forms → `shell.execute` + `git.read`;
- generic Git Bash wildcard → `shell.execute` + `git.read` + `git.write`.

Unknown expressions remain `unmapped_tools` and require explicit acknowledgement during review.

The adapter does not assume a harness enforces `allowed-tools`.

## Explicit review

A Trust Review is bound to the exact candidate digest and records:

- target canonical capability ID;
- approve/reject disposition;
- review evidence reference;
- requested authority;
- approved authority;
- acknowledged unmapped tools;
- reviewed executable paths;
- evidence references;
- explicit escalation confirmation/reference when needed.

The review reference is an evidence locator, not a cryptographic reviewer-identity claim.

ARS-08 v0 has no automatic third-party approval path.

## Authority arithmetic

For target capability `C`:

```text
canonical_allowed(C)
  = C.authority.required ∪ C.authority.optional
```

A candidate cannot be approved when reviewed requested authority:

- intersects `C.authority.forbidden`; or
- contains authority outside `canonical_allowed(C)`.

Approval must also satisfy:

```text
approved ⊆ requested
C.authority.required ⊆ approved
```

This means imported material cannot silently acquire authority merely because a reviewer or local policy profile is broader.

## Default local policy

`arsenal/trust/policy.json` is a deliberately conservative v0 policy, not a universal Arsenal prohibition.

Baseline authority:

- `filesystem.read`
- `git.read`
- `shell.execute`
- `network.read`

Escalation authority:

- `filesystem.write`
- `git.write`
- `tracker.read`
- `tracker.write`
- `cloud.local`
- `human.confirmation`

Prohibited under this policy:

- `network.write`
- `secrets.read`
- `cloud.remote`
- `production.mutate`

No policy may automatically approve third-party competence in v0.

## Escalation

Escalation is explicit widening within the intersection of canonical capability authority and local policy.

If requested authority intersects `policy.escalation_authority`, an approval requires:

- `escalation.confirmed: true`;
- non-empty `confirmation_reference`.

Otherwise the verdict is `ESCALATION_REQUIRED`.

Authority in `policy.prohibited_authority` cannot be approved under that policy.

## Verdicts

ARS-08 v0 uses:

- `APPROVED` — exact candidate is authorized under the bound policy/review/capability state;
- `QUARANTINED` — candidate has not yet been admitted;
- `REVIEW_REQUIRED` — provenance or interpretation is insufficient, or bound policy/canonical state changed;
- `ESCALATION_REQUIRED` — canonical authority is possible but above the baseline policy ceiling and lacks explicit confirmation;
- `REJECTED` — review/package authority conflicts with canonical capability or policy boundaries;
- `REVOKED` — a prior approval was explicitly superseded.

Only `APPROVED` produces:

```json
{"route_gate": {"authorized": true}}
```

## Revocation

Revocation is append-only evidence.

A revoked decision:

- receives a new deterministic decision ID;
- records `supersedes_decision_id`;
- empties effective authority;
- closes the route gate;
- leaves the prior approved decision unchanged.

## Drift and reconsideration

Every approval binds exact:

- candidate package digest;
- trust-policy digest;
- canonical capability digest.

Verification returns:

- `REQUARANTINE` when candidate bytes change;
- `REVIEW_REQUIRED` when policy or canonical capability state changes;
- `REVOKED` when explicit revocation supersedes approval.

Trust Decisions also expose data-level reconsideration triggers:

- `candidate-digest-change`;
- `policy-digest-change`;
- `canonical-capability-change`;
- `authority-increase`;
- `evaluation-regression`;
- `explicit-revocation`.

## First-party compiler bridge

A compiler-generated Arsenal package is still inspected rather than implicitly trusted.

For `arsenal-manifest.json`, ARS-08 verifies:

1. each manifest-listed package file digest;
2. the compiler's canonical sorted file/digest `content_sha256` algorithm;
3. canonical capability-file digest;
4. canonical primary-asset digest.

This is distinct from the Trust Candidate's independent package identity digest. Both are preserved because they answer different questions:

- compiler manifest digest → did the derived package still match compiler provenance?
- candidate digest → are these the exact bytes this trust decision reviewed?

## Future-slice seams — scaffold only

ARS-08 intentionally leaves four typed seams without implementing their owning systems.

### ARS-09 — Knowledge Plane

`reconsideration_triggers` can later become typed knowledge invalidation/reconsideration edges. ARS-08 does not create a knowledge store or infer durable project facts.

### ARS-10 — Intent Compiler

`route_gate.authorized`, `required_decision_id`, target digest, and effective authority can later be consumed by route planning. ARS-08 does not compile objectives or choose routes/models.

### ARS-11 — Adversarial Verification

`challenge.required/status/reasons` records when policy says a later independent challenge should exist. ARS-08 does not launch a skeptic/verifier agent and does not fake a passed challenge.

### ARS-12 — Controlled Capability Evolution

`content_change_action: REQUARANTINE` establishes that changed capability/package bytes never inherit prior approval. ARS-08 does not autonomously mutate or promote capabilities.

These are interfaces, not pre-claimed future features.

## Reference CLI

ARS-08 provides a narrow reference utility:

```bash
python3 scripts/arsenal_trust.py validate
python3 scripts/arsenal_trust.py discover ...
python3 scripts/arsenal_trust.py assess ...
python3 scripts/arsenal_trust.py verify ...
python3 scripts/arsenal_trust.py revoke ...
```

This is not a claim that a general top-level `arsenal` CLI already exists.

## Non-goals

ARS-08 v0 does not:

- execute imported instructions during inspection;
- automatically install or register approved candidates;
- claim OS/container-level sandbox enforcement;
- treat Agent Skills metadata as a security boundary;
- claim publisher identity from a URL or commit string;
- implement Sigstore/GitHub/SLSA attestation verification yet;
- grant secrets, remote-cloud, production, or network-write authority under the default policy;
- implement ARS-09 through ARS-12 behavior;
- let a model create its own authority.

## Exit criteria

ARS-08 v0 is complete when CI proves at least:

1. discovery is deterministic and always begins in quarantine;
2. exact reviewed third-party bytes can earn bounded approval;
3. overbroad authority conflicts with canonical capability authority and is rejected;
4. mutation authority requires explicit escalation confirmation;
5. incomplete source provenance cannot silently earn approval;
6. package drift re-quarantines an approved candidate;
7. policy/canonical drift requires review;
8. explicit revocation closes the route gate without rewriting prior evidence;
9. the compiler-generated Repository Truth package can be re-verified through its existing manifest provenance;
10. future ARS-09/10/11/12 seams remain data-only;
11. final CI is read-only and the delivered Arsenal regression spine remains green.
