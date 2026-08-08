# FLC-01 AWS Golden-Path Fidelity Ledger

Status: draft  
Evidence review date: 2026-08-08  
Reference runtime: `floci/floci:1.5.34-compat`

This ledger scopes the claims made by the FLC-01 tracer. The durable unit is the exact operation plus the semantic the acceptance path needs.

| Service | Material operation | FLC-01 use | Local evidence claim | Important boundary |
|---|---|---|---|---|
| S3 | `CreateBucket` / `HeadBucket` | Seed fixture | Protocol + required existence behavior | No quota/region/policy proof |
| S3 | `PutObject` | Upload tracer input and Lambda result | Protocol + object-write behavior | No AWS durability/SSE/replication claim |
| S3 | `GetObject` | Lambda reads input; gate downloads result | Protocol + object-read behavior | No AWS consistency/performance claim |
| S3 | `HeadObject` | Poll for result | Protocol + required existence behavior | Timing is local-emulator timing |
| SQS | `CreateQueue` / `GetQueueUrl` | Seed fixture | Protocol + queue identity behavior | No AWS quota/policy proof |
| SQS | `GetQueueAttributes` | Resolve QueueArn | Protocol + required attribute behavior | Only attributes used by tracer are claimed |
| SQS | `SendMessage` | Enqueue work item | Protocol + message acceptance behavior | No throughput/ordering claim |
| Lambda | `CreateFunction` | Seed Docker-backed consumer | Protocol + local function creation | AWS control-plane validation may differ |
| Lambda | `GetFunction` | Inner gate | Protocol + function visibility | No provider deployment-state timing claim |
| Lambda | `CreateEventSourceMapping` / `ListEventSourceMappings` | Connect SQS to function | Protocol + local SQS dispatch behavior | Floci documents serialized polling; scaling parity is not claimed |
| IAM | `CreateRole` / `GetRole` | Supply Lambda role ARN | Protocol + stored role behavior | FLC-01 runs with IAM enforcement disabled; authorization is **not** verified |

## Runtime semantics exercised

The Lambda handler executes inside a Docker container and calls S3 through the endpoint Floci injects into spawned Lambda containers when `FLOCI_HOSTNAME=floci`.

This is stronger than an in-process function stub, but it is still not proof of AWS Lambda's Firecracker isolation, cold-start timing, network policy, IAM enforcement, or service quotas.

## Known relevant Floci behavior

Current Floci documentation states:

- S3 implements the object operations used here.
- SQS implements the queue/message operations used here.
- Lambda implements function creation/invocation and SQS event-source mappings.
- Lambda event-source mappings currently serialize SQS invocations per mapping; `ScalingConfig.MaximumConcurrency` may round-trip without enforcing real parallel dispatch.
- Lambda containers receive the local AWS endpoint when Compose uses `FLOCI_HOSTNAME=floci`.
- the native init endpoint exposes `completed.ready`.
- `POST /_floci/state/reset` clears registered state-holding services and storage state.

FLC-01 does not use `ScalingConfig`, but the limitation is recorded because it is an example of why operation support cannot be treated as full semantic parity.

## Evidence labels

For this tracer, a green completion gate supports:

- **Protocol verified** for the listed operations.
- **Behavior verified** for the narrow read/write/queue/dispatch behaviors asserted by the tracer.
- **Fidelity scoped** by this ledger.

It does **not** support the label `Cloud verified`.

## Re-check triggers

Re-review this ledger when:

- changing the pinned Floci release;
- adding an AWS operation;
- enabling IAM enforcement;
- changing SQS batching/concurrency behavior;
- changing Lambda networking/runtime configuration;
- adopting persistent storage or snapshots;
- making a provider-parity acceptance claim.

## Provider-only proof remaining

None is required to prove the local FLC-01 tracer itself.

A production feature using these operations may still require scoped AWS verification for its own acceptance contract, especially authorization, quotas, region/account behavior, networking, and timing.
