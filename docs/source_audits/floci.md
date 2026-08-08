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
- Environment variables: https://floci.io/floci/configuration/environment-variables/
- Advanced application configuration/logging: https://floci.io/floci/configuration/advanced/application-yml/
- LocalStack migration: https://floci.io/floci/getting-started/migrate-from-localstack/
- Lambda behavior/migration notes: https://floci.io/floci/services/lambda/
- STS behavior/limitations: https://floci.io/floci/services/sts/
- AWS quick start: https://floci.io/floci/getting-started/quick-start/
- AWS product page: https://floci.io/aws/
- Azure overview: https://floci.io/floci-az/services/
- GCP overview: https://floci.io/gcp/
- Source repository: https://github.com/floci-io/floci
- Releases: https://github.com/floci-io/floci/releases
- Floci CLI source/documentation: https://github.com/floci-io/floci-cli
- Floci `awslocal` wrapper source at the audited source commit: `bin/awslocal`

## Adopt as the first Local Cloud Development Pack

Floci is a strong first implementation for Arsenal's emulator-neutral Local Cloud Engineering foundation because it provides:

- provider-shaped local endpoints intended for existing SDK/CLI/IaC clients;
- credential-free/dummy-credential development for the AWS emulator;
- a unified CLI surface for starting, stopping, inspecting, and diagnosing local cloud environments;
- explicit storage modes for ephemeral CI and durable local development;
- ordered initialization hooks with a machine-readable readiness surface;
- LocalStack-compatible port/path/environment behavior for migration use cases;
- current AWS, Azure, GCP, and OCI emulator families;
- operation-specific service documentation that can feed a fidelity ledger;
- real container-backed engines for selected complex services while retaining provider-shaped control planes.

The Floci CLI also documents snapshot commands. Those commands must be capability-checked against the running server before Arsenal depends on them; the latest released AWS server observed during FLC-02 does not implement the documented snapshot endpoint.

Arsenal should use these capabilities to make local execution deterministic and evidence-producing, not to turn Floci into a universal truth oracle for cloud behavior.

## Volatility discovered during audit

Public Floci surfaces currently disagree on aggregate service counts.

On 2026-08-08:

- the main overview advertised 69 AWS services;
- the AWS canonical service matrix stated 68 AWS services and explicitly described itself as the canonical operation-count reference;
- the LocalStack migration page still contained an aggregate count of 58 in explanatory text;
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

FLC-03 runtime validation exposed an additional deployment-level constraint: persistent `/app/data` must be writable by Floci's non-root container user. A host bind created from a GitHub Actions checkout inherited ownership that prevented the released `1.5.34-compat` container from opening its persistent state. Replacing that bind with a Docker named volume allowed the same `persistent` storage mode to initialize normally. The reference migration fixture therefore uses a named volume rather than weakening container isolation by running Floci as root.

This is environment evidence rather than a universal ban on host binds. A repository may use a host path when its ownership/permissions are deliberately compatible and verified.

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
- translation of several LocalStack environment variables;
- a LocalStack-style `Ready.` startup log line while compatibility translation is enabled;
- LocalStack wildcard S3 DNS compatibility for `*.s3.localhost.localstack.cloud`;
- selected `_aws/*` inspection surfaces including SES mailbox inspection and non-destructive SQS message peeking.

The migration documentation states that compatibility translation is enabled by default. Explicit Floci variables win when both native and LocalStack variables are set. `LOCALSTACK_PARITY=false` disables the translation layer.

Documented translation examples include:

- `PERSISTENCE=1` / `PERSIST_STATE=1` → `FLOCI_STORAGE_MODE=persistent`;
- `LOCALSTACK_HOST` / `LOCALSTACK_HOSTNAME` → `FLOCI_HOSTNAME`;
- `EDGE_PORT` → `FLOCI_PORT`;
- `GATEWAY_LISTEN` → `QUARKUS_HTTP_HOST`;
- `LS_LOG` / `DEBUG=1` → `QUARKUS_LOG_LEVEL`;
- `DOCKER_HOST` → `FLOCI_DOCKER_DOCKER_HOST`;
- `LAMBDA_DOCKER_NETWORK` → `FLOCI_SERVICES_LAMBDA_DOCKER_NETWORK`;
- `DOCKER_NETWORK` → `FLOCI_SERVICES_DOCKER_NETWORK`;
- `LAMBDA_REMOVE_CONTAINERS=1` → `FLOCI_SERVICES_LAMBDA_EPHEMERAL=true`;
- `USE_SSL=1` → `FLOCI_TLS_ENABLED=true`.

But migration is not semantically guaranteed by an image-name swap. Documented differences include:

- `LAMBDA_REMOTE_DOCKER` is not supported;
- Floci always uses Docker containers for Lambda rather than LocalStack's executor selection model;
- LocalStack data path `/var/lib/localstack` differs from Floci `/app/data`;
- service-selection variables do not map to the same runtime model;
- certificate/configuration details can require explicit verification even when a translation exists.

Arsenal should therefore implement LocalStack migration as an inventory + blocker resolution + replacement + behavioral verification workflow, not as blind text substitution.

Compatibility paths are valid migration tools. FLC-03 intentionally keeps `/etc/localstack/init/ready.d`, `PERSISTENCE=1`, and `/_localstack/init` in its migrated reference fixture so the acceptance gate proves that supported compatibility can reduce simultaneous change. Native Floci renaming is optional cleanup, not migration authority.

## FLC-03 runtime migration findings

The FLC-03 compatibility tracer produced two evidence-backed findings that are easy to miss from configuration documentation alone.

### Preserve `awslocal` when a LocalStack init script already uses it

The released Floci `-compat` image ships an `awslocal` wrapper. Its source explicitly passes `--endpoint-url` on every AWS CLI invocation because some service-specific endpoint resolvers in older botocore versions — notably SQS — can silently bypass `AWS_ENDPOINT_URL`.

FLC-03 proved this failure mode directly:

1. a migrated ready hook used bare `aws` while `AWS_ENDPOINT_URL=http://localhost:4566` and synthetic `test/test` credentials were present;
2. `aws s3 mb` succeeded locally;
3. `aws sqs create-queue` escaped to public AWS and returned `InvalidClientTokenId` for the synthetic credentials;
4. no SQS acceptance assertion was weakened;
5. restoring the legacy `awslocal` commands made both S3 and SQS seed operations pass through the pinned Floci runtime;
6. the final migration gate asserts that the LocalStack and Floci-compatible init scripts are byte-for-byte identical.

The durable migration rule is therefore:

> If a legacy LocalStack init script already uses `awslocal`, preserve it through the first Floci migration unless there is a reason to replace it. If using bare `aws`, pass the local endpoint explicitly rather than assuming `AWS_ENDPOINT_URL` will govern every client/service version.

This is a client-routing compatibility concern, not evidence that Floci SQS itself rejects `test/test`; FLC-01/FLC-02 and the FLC-03 external reproduction path successfully exercise SQS locally with synthetic credentials.

### Prefer a writable named volume for the reference persistent migration fixture

The first FLC-03 migrated Compose fixture mapped a checkout directory directly to `/app/data`. On the hosted runner, that directory was not writable by Floci's non-root runtime user and startup failed before ready hooks could complete.

The final reference fixture uses a Docker named volume at `/app/data`, preserves `PERSISTENCE=1`, and proves persistent-mode startup plus LocalStack-compatible init behavior. This keeps the runtime non-root and makes the ownership boundary deterministic in CI.

These findings reinforce the pack's core migration rule: retain supported compatibility surfaces first, then let executable behavioral gates reveal which assumptions genuinely need adaptation.

## Diagnostic and logging behavior adopted

Floci uses Quarkus logging. Current configuration documentation states:

- effective default logging is `INFO`;
- service operation events are available at `DEBUG`;
- full request/response payload detail is available at `TRACE` for service categories;
- the shipped minimum logging level permits raising an individual service category to TRACE without globally changing the minimum.

Project Arsenal therefore adopts scoped logging escalation:

`INFO → affected service DEBUG → affected service TRACE`

Global TRACE is not the default diagnostic action because it increases noise and can capture unnecessary payload detail.

The CLI documents `floci status`, `floci logs --follow`, and `floci doctor`. FLC-03 treats these as useful supplemental diagnostics, not mandatory pack dependencies. Direct init endpoints, Docker evidence, and provider-shaped read-only operations remain the portable diagnostic substrate.

For container-backed services, diagnosis must distinguish the Floci control plane from managed/spawned service containers and their network/DNS/runtime state.

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

The Floci CLI currently documents AWS commands to save and load named snapshots. During FLC-02 validation, however, the latest published AWS server release (`1.5.34`) did not expose the documented `/_floci/snapshots/<name>` control-plane route.

A real POST against the pinned runtime fell through to S3 routing and returned:

`InvalidArgument: POST requires either ?uploads, ?uploadId, ?restore or ?select parameter.`

Source inspection of the released/current AWS server likewise found no snapshot controller for that path at the audit point.

Project Arsenal therefore must not treat CLI/documentation presence as proof of server capability. Snapshot acceleration is optional and capability-gated:

- if the running server supports save/load, apply provenance-keyed cache invalidation and post-restore assertions;
- if the exact known released-server endpoint-unavailable signature is observed, record `UNSUPPORTED`/`SKIP` and continue through the authoritative zero-state provision/assert/destroy gate;
- any other snapshot failure remains a gate failure until explained.

Snapshots are caches, never completion authority.

## Multi-cloud direction

Floci currently presents separate AWS, Azure, GCP, and OCI emulators behind a broader Floci toolchain. Arsenal should preserve a provider-neutral foundation and add provider overlays incrementally.

AWS is the recommended tracer implementation because its current Floci surface is deepest and exposes the fidelity problems the general contract needs to solve. Azure/GCP/OCI should validate the abstraction after the AWS pack stabilizes rather than forcing premature lowest-common-denominator design.

## Do not import as Arsenal doctrine

Do not canonize these claims without operation-specific evidence:

- exact aggregate service counts;
- "100% protocol fidelity" as a general guarantee;
- "drop-in replacement" as proof that every LocalStack workload is behaviorally equivalent;
- CLI command presence as proof that the corresponding server endpoint exists in the pinned runtime;
- a successful emulator response as proof of provider authorization, quota, timing, billing, regional, or production semantics;
- floating `latest` image tags as completion-quality provenance.

## Arsenal adaptation boundary

Project Arsenal owns:

- the local-cloud method;
- cloud execution boundary;
- fidelity ledger;
- reproducible fixture discipline;
- Development Pack verification contract;
- evidence and escalation semantics;
- migration inventory classification;
- reproduction minimization and red/green evidence;
- diagnostic classification.

Floci owns its implementation, supported operations, configuration, release behavior, and compatibility surface.

Arsenal should point to Floci's current primary documentation rather than duplicate volatile service matrices.

## Architectural takeaway

Floci is most valuable to Project Arsenal not because it can claim to be "the cloud locally," but because it gives agents and engineers a low-blast-radius provider-shaped execution surface.

The durable Arsenal differentiator is the evidence model around it:

**local-first by default, fidelity-scoped by operation, deterministic from fixtures, migration-safe through explicit assumption inventory, diagnostic through red/green reproductions, explicit about remaining provider-only proof, and incapable of silently escalating into a real account.**
