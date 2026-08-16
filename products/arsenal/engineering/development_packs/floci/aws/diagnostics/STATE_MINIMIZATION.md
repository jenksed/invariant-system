# State Capture and Minimization for Cloud Reproduction

Status: draft

The purpose of state capture is to preserve causal structure without importing production state into a local emulator.

## Capture only what the symptom needs

Start with a claim-oriented manifest:

- symptom;
- service;
- operation/protocol;
- resource type;
- relevant configuration fields;
- event/request shape;
- ordering/timing condition if load-bearing;
- expected result;
- observed result.

Do not begin by exporting whole accounts, databases, buckets, queues, logs, or Terraform state.

## Sanitize at the boundary

Replace or remove:

- credentials and tokens;
- customer/user identifiers;
- real account IDs;
- private hostnames and IPs;
- proprietary payload contents;
- secrets and secret names when sensitive;
- object bodies not causally relevant;
- production ARNs when a synthetic ARN preserves structure.

Record the transformation so a reviewer can tell which fields were preserved and why.

## Convert captured evidence into source-controlled construction

Preferred reconstruction order:

1. declarative fixture or IaC;
2. idempotent seed script;
3. provider-shaped API calls;
4. small captured request/event payload;
5. snapshot only as a cache after a source-controlled reconstruction exists.

The repository should be able to recreate the local case from zero.

## Minimize while the signal stays red

Remove one dimension at a time:

- unrelated resources;
- unused configuration;
- extra payload fields;
- unrelated permissions;
- callers;
- retries;
- timing delays;
- auxiliary services.

After every removal, rerun the red-capable signal.

Stop when removing any remaining element makes the symptom disappear or changes the question being investigated.

## Preserve a control

A strong local reproduction has a nearby control:

- corrected configuration;
- alternate operation;
- single-field change;
- known-good fixture;
- prior revision.

The control should turn the same signal green. This prevents a permanently failing test from being mistaken for a diagnosis loop.

## Fidelity checkpoint

Before treating the local reproduction as causal evidence, record:

- exact operations exercised;
- current Floci support evidence;
- documented deviations;
- whether the suspicious semantic is implemented, stubbed, inert, approximate, or provider-only.

If the suspected cause sits outside the emulator fidelity boundary, keep the local case as application/configuration evidence but do not infer provider causality.

## Completion

A minimized reproduction is complete when another engineer or agent can:

1. reconstruct from zero;
2. run one command;
3. observe the same red signal;
4. apply the documented control;
5. observe green;
6. understand exactly what the local result does and does not prove.
