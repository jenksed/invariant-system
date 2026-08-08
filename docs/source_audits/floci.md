# Source Audit — Floci

Audit date: 2026-08-08

Primary project: `floci-io/floci`

Source commit observed on `main`: `ff8d6efdf33a0118b2490b9a52ee6db6a8fdbca8`

Latest published AWS emulator release observed: `1.5.34` (2026-07-29).

License observed in the Floci project family and public documentation: MIT.

This audit records the Floci capabilities and constraints that Project Arsenal may depend on. It is intentionally more conservative than product marketing: Arsenal should treat operation-specific documentation, executable compatibility evidence, and known limitations as stronger evidence than aggregate service counts or parity slogans.

## Sources reviewed

- Project overview: https://floci.io/
- AWS service matrix: https://floci.io/floci/services/
- AWS setup: https://floci.io/floci/getting-started/aws-setup/
- Storage modes: https://floci.io/floci/configuration/storage/
- Initialization hooks: https://floci.io/floci/configuration/initialization-hooks/
- LocalStack migration: https://floci.io/floci/getting-started/migrate-from-localstack/
- STS behavior/limitations: https://floci.io/floci/services/sts/
- AWS quick start: https://floci.io/floci/getting-started/quick-start/
- AWS product page: https://floci.io/aws/
- Azure overview: https://floci.io/floci-az/services/
- GCP overview: https://floci.io/gcp/
- Source repository: https://github.com/floci-io/floci
- Releases: https://github.com/floci-io/floci/releases

## Adopt as the first Local Cloud Development Pack

Floci is a strong first implementation for Arsenal's emulator-neutral Local Cloud Engineering foundation because it provides:

- provider-shaped local endpoints intended for existing SDK/CLI/IaC clients;
- credential-free/dummy-credential development for the AWS emulator;
- a unified CLI surface for starting, stopping, inspecting, diagnosing, and snapshotting local cloud environments;
- explicit storage modes for ephemeral CI and durable local development;
- ordered initialization hooks with a machine-readable readiness surface;
- LocalStack-compatible port/path/environment behavior for migration use cases;
- current AWS, Azure, GCP, and OCI emulator families;
- operation-specific service documentation that can feed a fidelity ledger;
- real container-backed engines for selected complex services while retaining provider-shaped control planes.

Arsenal should use these capabilities to make local execution deterministic and evidence-producing, not to turn Floci into a universal truth oracle for cloud behavior.

## Volatility discovered during audit

Public Floci surfaces currently disagree on aggregate service counts.

On 2026-08-08:

- the main overview advertised 69 AWS services;
- the AWS canonical service matrix stated 68 AWS services and explicitly described itself as the canonical operation-count reference;
- overview counts for Azure/GCP also differed from some service-specific pages retrieved during research.

Project Arsenal therefore must **not** encode aggregate service counts as durable capability truth.

The durable rule is:

> Resolve fidelity at provider + service + exact operation/protocol + required behavior, using the most specific current evidence available.

## AWS execution facts adopted

The AWS emulator uses port `4566` and accepts non-empty dummy credentials. The documented basic local environment uses:

- `AWS_ENDPOINT_URL=http://localhost:4566`
- `AWS_DEFAULT_REGION=us-east-1`
- `AWS_ACCESS_KEY_ID=test`
- `AWS_SECRET_ACCESS_KEY=test`

The documented default local account ID is `000000000000`, with multi-account behavior available through access-key-derived account IDs.

Arsenal should treat these as Floci pack defaults, not universal AWS-emulator assumptions.

## Storage model adopted

Floci documents four AWS storage modes:

- `memory` — ephemeral; recommended for unit/integration tests and CI;
- `persistent` — synchronous durable writes;
- `hybrid` — in-memory reads with asynchronous persistence;
- `wal` — append-only log with compaction.

The published Docker image documents `memory` as its shipped default even though an internal code default differs. Arsenal guidance should therefore always make intended storage semantics explicit rather than relying on an implementation default.

Container-backed services can have separate Docker volume lifecycles. Reset/cleanup evidence must include those managed volumes when relevant.

## Initialization lifecycle adopted

Floci exposes ordered init phases:

`boot → start → ready → stop`

The AWS APIs are available from `start` onward. Hooks run sequentially and fail fast; failures in boot/start/ready can cause startup to fail. Both native `/_floci/init` and LocalStack-compatible `/_localstack/init` status surfaces can report initialization progress.

This is suitable for deterministic fixture seeding and readiness gates.

Scripts that require AWS CLI or boto3 should use the documented compat image (`latest-compat` or a pinned versioned compat tag) rather than assuming those tools exist in the standard image.

## LocalStack migration behavior adopted carefully

Floci intentionally preserves significant LocalStack Community compatibility:

- port `4566`;
- AWS SDK/CLI endpoint shape;
- dummy credentials;
- `/etc/localstack/init/` compatibility paths;
- `/_localstack/init` and health compatibility endpoints;
- translation of several LocalStack environment variables.

But migration is not semantically guaranteed by an image-name swap. Documented differences include Lambda execution behavior, unsupported `LAMBDA_REMOTE_DOCKER`, data-directory differences, logging variables, and service-selection behavior.

Arsenal should therefore implement LocalStack migration as an audit + replacement + verification workflow, not as blind text substitution.

## Fidelity gaps are first-class evidence

Floci's STS documentation gives a concrete example of why Arsenal needs a fidelity ledger.

With IAM enforcement enabled, Floci evaluates several trust-policy forms for `AssumeRole`, but documented limitations include:

- trust-policy `Condition` blocks are not evaluated;
- `sts:ExternalId` is therefore not enforced;
- the caller's own cross-account identity policy is not evaluated as real AWS would require.

A local passing test cannot prove those AWS authorization semantics. The correct response is to mark the claim outside the local fidelity boundary and escalate only that remaining verification if the feature depends on it.

Other service pages similarly document stubbed, mock-only, stored-but-inert, or out-of-scope behavior. The same rule applies.

## IaC treatment

Floci advertises and tests Terraform/OpenTofu compatibility, and the observed current source includes OpenTofu compatibility coverage. Arsenal should use Floci for local IaC feedback where the involved resources/actions are supported.

A successful local apply proves the supported local path, not universal provider acceptance. Provider-specific policy, quota, region, billing, and control-plane behavior may still require remote verification.

## Snapshot treatment

The Floci CLI documents snapshot save/restore for local state. Arsenal may use snapshots to accelerate expensive fixture construction, but snapshots are caches unless they have provenance, version compatibility, regeneration inputs, and post-restore checks.

## Multi-cloud direction

Floci currently presents separate AWS, Azure, GCP, and OCI emulators behind a broader Floci toolchain. Arsenal should preserve a provider-neutral foundation and add provider overlays incrementally.

AWS is the recommended tracer implementation because its current Floci surface is deepest and exposes the fidelity problems the general contract needs to solve. Azure/GCP/OCI should validate the abstraction after the AWS pack stabilizes rather than forcing premature lowest-common-denominator design.

## Do not import as Arsenal doctrine

Do not canonize these claims without operation-specific evidence:

- exact aggregate service counts;
- "100% protocol fidelity" as a general guarantee;
- "drop-in replacement" as proof that every LocalStack workload is behaviorally equivalent;
- a successful emulator response as proof of provider authorization, quota, timing, billing, regional, or production semantics;
- floating `latest` image tags as completion-quality provenance.

## Arsenal adaptation boundary

Project Arsenal owns:

- the local-cloud method;
- cloud execution boundary;
- fidelity ledger;
- reproducible fixture discipline;
- Development Pack verification contract;
- evidence and escalation semantics.

Floci owns its implementation, supported operations, configuration, release behavior, and compatibility surface.

Arsenal should point to Floci's current primary documentation rather than duplicate volatile service matrices.

## Architectural takeaway

Floci is most valuable to Project Arsenal not because it can claim to be "the cloud locally," but because it gives agents and engineers a low-blast-radius provider-shaped execution surface.

The durable Arsenal differentiator is the evidence model around it:

**local-first by default, fidelity-scoped by operation, deterministic from fixtures, explicit about remaining provider-only proof, and incapable of silently escalating into a real account.**