# Reproducible Cloud Fixtures

Status: draft

A **cloud fixture** is the minimum controlled resource/state graph required to exercise a cloud-dependent behavior.

Fixtures turn local cloud environments from long-lived developer snowflakes into reproducible evidence surfaces.

## Fixture properties

A completion-quality fixture should be:

- **minimal** — contains only resources and data required by the behavior under test;
- **versioned** — lives with the code or another durable source of truth;
- **idempotent or resettable** — repeated runs do not accumulate hidden assumptions;
- **observable** — tests can inspect the resulting state without relying only on exit status;
- **portable** — works in a clean developer/CI environment with documented prerequisites;
- **safe** — defaults to local endpoints and cannot accidentally target a real provider because an environment variable was omitted.

## Fixture forms

Prefer the simplest form that preserves determinism:

1. **Initialization scripts** — best when resources can be recreated quickly and declaratively.
2. **IaC fixture** — best when infrastructure definitions themselves are part of the behavior under test.
3. **Programmatic seed** — appropriate when setup must use SDK behavior or generate complex data.
4. **Snapshot** — useful for expensive state graphs, but only when the snapshot has provenance, version compatibility, and a deterministic restore check.
5. **Persistent development state** — useful for human inner loops, but weaker as completion evidence unless reconstructed or independently audited.

## Clean-room replay

For slice or completion gates, prefer a clean-room replay:

1. start from an empty or intentionally restored emulator state;
2. wait on an explicit readiness signal;
3. apply the fixture;
4. assert fixture prerequisites;
5. run the behavior under test;
6. assert externally observable outcomes;
7. collect logs/state/evidence;
8. destroy or reset the environment;
9. repeat when the acceptance risk warrants proving replayability.

## Endpoint safety

Fixture code must make the local target explicit.

Avoid patterns where removing one environment variable causes an SDK or CLI to fall back to its normal public cloud endpoint. Prefer wrapper commands, dedicated profiles, explicit endpoint variables, or assertions that fail closed when the expected local endpoint is absent.

## Secret rule

Fixtures use synthetic secrets unless the behavior explicitly tests secret-management semantics.

Do not copy production secrets, customer data, access tokens, certificates, or account identifiers into a local emulator merely to make the fixture realistic.

## Time and identity

Record assumptions that commonly create false confidence:

- fixed regions/accounts/projects;
- local account identifiers;
- timestamps and TTL behavior;
- generated ARNs/resource names;
- eventual-consistency expectations;
- IAM identities and policy evaluation;
- container/network addresses assigned dynamically.

Tests should consume resource identifiers returned by the local control plane where practical rather than hard-code implementation details.

## Snapshot rule

A snapshot is not a substitute for source-controlled setup.

When snapshots are used, record:

- emulator implementation and version/tag;
- fixture/schema version;
- creation procedure;
- digest or immutable identifier when available;
- restore procedure;
- post-restore verification;
- invalidation conditions.

If the snapshot cannot be regenerated from durable inputs, treat it as a cache rather than canonical state.

## Completion criterion

A cloud fixture is trustworthy when a clean environment can recreate or restore the required state, verify that state before execution, exercise the target behavior, and produce the same acceptance evidence without undocumented manual setup.