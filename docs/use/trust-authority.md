# Trust & Authority Plane

ARS-08 provides a fail-closed admission path for imported capability packages.

The shortest mental model is:

```text
Do not install a skill and then ask whether it was safe.
Quarantine exact bytes, inspect them, bind review to the digest,
compare requested authority to the canonical capability and local policy,
then explicitly approve or reject.
```

## 1. Discover into quarantine

```bash
python3 scripts/arsenal_trust.py discover \
  --package path/to/external-skill \
  --source-kind git \
  --source https://github.com/example/skills \
  --revision 0123456789abcdef0123456789abcdef01234567 \
  --output .arsenal-trust/candidate.json
```

Discovery does not execute the package. It inventories files, rejects symlinks, computes an exact package digest, parses a small Agent Skills metadata subset when present, and records provenance assurance. The result is always `QUARANTINED`.

## 2. Review exact bytes

Create a review document matching `arsenal/trust/review.schema.json`.

The review is bound to `candidate.package.sha256` and states:

- canonical capability being considered;
- all requested authority;
- subset explicitly approved;
- unmapped tool expressions manually interpreted;
- executable paths actually reviewed;
- whether escalation was explicitly confirmed.

Do not reuse a review after candidate bytes change.

## 3. Assess policy + canonical capability

```bash
python3 scripts/arsenal_trust.py assess \
  --candidate .arsenal-trust/candidate.json \
  --review .arsenal-trust/review.json \
  --policy arsenal/trust/policy.json \
  --output .arsenal-trust/decision.json
```

The decision compares three independent boundaries:

1. imported package/review authority;
2. canonical Capability Contract required/optional/forbidden authority;
3. local trust policy baseline/escalation/prohibited authority.

Only `APPROVED` opens `route_gate.authorized`.

## 4. Verify before use

```bash
python3 scripts/arsenal_trust.py verify \
  --package path/to/external-skill \
  --decision .arsenal-trust/decision.json \
  --policy arsenal/trust/policy.json
```

Verification rechecks package digest, policy digest, canonical capability digest, effective authority, and revocation state.

Changed package bytes produce `REQUARANTINE`. Policy/capability drift produces `REVIEW_REQUIRED`.

## 5. Revoke append-only

```bash
python3 scripts/arsenal_trust.py revoke \
  --decision .arsenal-trust/decision.json \
  --reason "upstream compromise report" \
  --reference incident-2026-001 \
  --output .arsenal-trust/revoked.json
```

Revocation does not edit the original approval. It produces a new receipt that supersedes it and carries zero effective authority.

## Agent Skills caveat

`allowed-tools` is useful discovery metadata but is experimental upstream and may be interpreted differently by agent implementations.

ARS-08 treats it as a signal, not a permission boundary. Unknown expressions remain review work.

## Compiler-generated Arsenal packages

For packages containing `arsenal-manifest.json`, discovery independently verifies the compiler's package file/content digests plus canonical capability and primary-asset digests.

Use source kind `arsenal-compiled` and an exact repository SHA when available. This earns a stronger provenance label; it still does not create runtime authority.

## Default policy

`arsenal/trust/policy.json` is deliberately conservative.

Baseline review may authorize filesystem read, Git read, shell execution, and network read. Selected local mutations require explicit escalation. Secrets, remote cloud, production mutation, and network write are prohibited by this v0 policy.

This is a local v0 policy, not a universal statement that those authorities can never be legitimate.

## Later-slice seams

ARS-08 emits only the data later slices need:

- ARS-09 can index reconsideration triggers;
- ARS-10 can consume the route gate and effective grant;
- ARS-11 can satisfy or strengthen challenge requirements;
- ARS-12 must create a new quarantined candidate whenever bytes change.

Those later behaviors are intentionally not implemented here.
