# Trust & Authority

ARS-08 is Project Arsenal's admission-control boundary for imported competence.

Start with:

- [`CONTRACT.md`](CONTRACT.md) — canonical trust, authority, quarantine, approval, escalation, drift, and revocation semantics;
- [`policy.json`](policy.json) — conservative v0 local trust policy;
- [`candidate.schema.json`](candidate.schema.json) — exact quarantined package identity and provenance;
- [`review.schema.json`](review.schema.json) — review bound to exact candidate bytes;
- [`decision.schema.json`](decision.schema.json) — machine-readable admission verdict and route gate;
- [`../../docs/use/trust-authority.md`](../../docs/use/trust-authority.md) — operator workflow;
- [`../../docs/source_audits/trust-and-provenance.md`](../../docs/source_audits/trust-and-provenance.md) — upstream standards audit.

Reference implementation:

```bash
python3 scripts/arsenal_trust.py validate
python3 scripts/arsenal_trust.py discover --help
python3 scripts/arsenal_trust.py assess --help
python3 scripts/arsenal_trust.py verify --help
python3 scripts/arsenal_trust.py revoke --help
```

The fixtures in `fixtures/` are test inputs only. They are not approved third-party packages and are not catalog products.

The ARS-09 through ARS-12 fields emitted by Trust Decisions are forward-compatible data seams only; their owning systems are not implemented by ARS-08.
