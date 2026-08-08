# Audit a Floci Fidelity Gap

Status: draft

Use when a local Floci result is ambiguous: the application may be wrong, Floci may differ from the target provider, documentation may be incomplete, or the remaining acceptance claim may be provider-only.

## Outcome

Produce an operation-level claim/evidence record that decides whether the local result is usable, blocked, emulator-specific, or requires narrowly scoped provider verification.

## 1. State one exact claim

Write the claim at this granularity:

`provider → service → operation/protocol → required semantic`

Examples:

- AWS → STS → AssumeRole → trust-policy `Condition` must reject missing ExternalId;
- AWS → SQS → GetQueueAttributes → RedrivePolicy must report the configured maxReceiveCount;
- AWS → CloudFormation → CreateStack → the required resource type/property must be provisioned with the asserted state.

Do not audit “SQS support” or “IAM parity” as a single claim.

## 2. Gather evidence in authority order

Prefer:

1. authorized target-provider observation when necessary and already available;
2. target-provider official documentation/specification;
3. current Floci operation/service documentation;
4. current Floci source/tests;
5. local execution observation on a pinned Floci runtime;
6. marketing/overview statements;
7. assumption.

Record dates and emulator provenance for mutable evidence.

## 3. Compare required semantic to Floci's implemented semantic

Classify Floci evidence as:

- `DOCUMENTED_MATCH` — the required semantic is explicitly documented and locally observed;
- `LOCAL_MATCH_ONLY` — local behavior matches, but emulator fidelity is not independently established;
- `DOCUMENTED_DEVIATION` — Floci explicitly differs from the provider semantic;
- `STUBBED_OR_INERT` — operation exists but the relevant behavior is mock/stored/inert;
- `UNSUPPORTED` — operation/semantic is not implemented;
- `UNCLEAR` — current source/docs do not resolve the question.

A successful API response is never sufficient by itself to claim provider fidelity.

## 4. Run a discriminating local probe when useful

Construct the smallest request that would distinguish competing interpretations.

Preserve:

- request;
- response;
- runtime version/image digest;
- fixture state;
- relevant logs;
- expected provider semantic.

If the probe only confirms what the emulator does, label it local evidence rather than provider evidence.

## 5. Decide the engineering consequence

End in one of:

- `PROCEED_LOCAL` — the acceptance claim can be established sufficiently through current local evidence;
- `PROCEED_WITH_LIMIT` — local work is useful but the known deviation must remain visible;
- `BLOCK_EMULATOR_PATH` — the required semantic is unsupported or misleading locally;
- `EMULATOR_DEFECT_CANDIDATE` — current Floci behavior appears inconsistent with its docs/source or required wire behavior;
- `PROVIDER_VERIFICATION_REQUIRED` — only the target provider can establish the remaining claim;
- `REDESIGN` — the implementation should avoid relying on a semantic that cannot be tested safely enough.

## 6. For LocalStack migration, compare both emulators without promoting either to authority

If LocalStack and Floci differ:

- preserve the old LocalStack observation as migration evidence;
- determine which behavior the application actually depends on;
- consult provider authority for the intended semantic;
- decide whether the migration reveals an application bug, a Floci gap, or an old LocalStack-specific dependency.

“LocalStack did it” is not proof that AWS does it.

## 7. Escalate narrowly

When provider verification is required, state:

- the exact unresolved semantic;
- smallest provider action required;
- required permissions;
- expected cost/blast radius;
- cleanup;
- evidence that will close the gap.

Never convert a fidelity question into blanket cloud credentials or production mutation.

## Output

Record:

- claim;
- provider/service/operation;
- required semantic;
- Floci provenance;
- target-provider evidence;
- Floci docs/source evidence;
- local observation;
- known deviation;
- classification;
- engineering consequence;
- residual provider-only proof;
- revalidation trigger.

Feed durable findings back into the relevant fidelity ledger rather than leaving them only in an incident transcript.
