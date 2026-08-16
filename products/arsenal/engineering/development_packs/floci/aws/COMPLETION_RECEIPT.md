# FLC-01 Completion Receipt Schema

A completion run writes `.floci-artifacts/completion-receipt.md`.

Required fields:

- provider;
- pinned image tag;
- Floci reported version;
- container image ID;
- pulled repo digest when available;
- endpoint;
- storage/reset mode;
- fixture paths;
- readiness evidence;
- golden-path result;
- state/effect assertions;
- fidelity ledger pointer;
- real-cloud evidence;
- provider-only verification remaining;
- cleanup/reconstruction evidence.

A receipt is evidence about one run. It is not a substitute for the checked-in fidelity policy or the reproducible scripts that generated it.

The gate must not write `Cloud verified` unless a separate authorized real-provider check actually ran and its evidence is attached.
