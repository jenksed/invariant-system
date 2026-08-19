---
title: Recovery
description: Effect recovery, Session reconstruction, operator reconnect, and why uncertainty must survive interruption.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/README.md
  - products/kiln/lib/
  - products/kiln/test/
  - docs/_meta/post-wp09-product-direction.md
audience:
  - developer
  - operator
---

# Recovery

A process crash is not permission to pretend the last effect never happened.

Kiln's recovery model exists to distinguish durable facts from uncertain effects. If execution was interrupted after a consequential action may have crossed the boundary, the safe state can be `unknown` or `requires reconciliation`, not automatic replay.

The current documented repository state contains journal/recovery foundations; the full interruption matrix remains evidence-gated and must be classified slice by slice as executable proof lands.

## Three recovery problems

### 1. Effect/runtime recovery

Kiln must preserve what is known, what may have happened, and what can safely be retried. Retry policy requires effect semantics, idempotency knowledge, and state binding.

### 2. Operator/UI recovery

The post-WP-09 Workbench target is stronger than persisting a terminal or browser session. A fresh Temper process should be able to query Kiln and reconstruct the current governed Session, including required human attention, activity, verification/review state, and known uncertainty.

Temper-local persistence may improve UX, but it cannot be required to recover canonical workflow truth.

### 3. Distributed disconnect/reconnect

Remote Temper → Kiln operation adds topology failure without changing authority. Disconnecting the operator must not terminate or orphan canonical Session truth merely because the UI disappeared. Reconnect must re-establish identity/freshness and show stale/unknown state explicitly rather than pretending continuity.

## Identity that must not collapse

Remote/recovery design should keep these distinguishable:

```text
filesystem path
project identity
repository identity
Session identity
Kiln instance / service identity
execution host
operator host
```

A path equality check is not a project identity protocol. `localhost` is a deployment detail, not an architectural identity.

## Acceptance direction

For Workbench recovery, the decisive property is: terminate Temper, start a new Temper process, reconnect to the authoritative Kiln/Session, and reconstruct actionable current state without relying on prior Temper memory.

For remote recovery, repeat the property across distinct operator/execution hosts and include disconnect, stale-state, and identity-mismatch cases.
