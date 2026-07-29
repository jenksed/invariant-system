# Model, Context, and Repository Boundary

**Document type:** Focused model and disclosure authority  
**Decision status:** Proposed by P0-W22; owner acceptance required  
**Integration status:** Proposed on `work/p0-w22-model-context-repository-boundary-reconciled`  
**Implementation status:** Not implemented  
**Owner decision:** OD-01 integrated through ADR-0021  
**Upstream authority:** P0-W21 integrated through pull request 27  
**Build authorization:** Not issued

## Authority

This specification owns first-month decisions for:

- the only real provider and deterministic fake;
- provider request, stream, result, timeout, cancellation, malformed-result, usage, and retry behavior;
- the sealed Context package and manifest;
- model-visible Tool projection;
- bounded active-Repository observation, search, and read;
- bounded Kiln Artifact reads during one invocation;
- source disclosure and provider egress;
- secret and sensitive-content screening;
- provider request and response retention.

It does not own:

- Session, Task, or Run lifecycle;
- transition authority;
- journal envelope, projections, migrations, transactions, restart, orphan, or completion transaction semantics;
- Patch Approval or source mutation;
- registered Command execution;
- criterion Evidence, completion, Receipt, or acceptance;
- CLI syntax or presentation.

P0-W21 controls every lifecycle and persistence detail. This document consumes its operation identity, intent-before-dispatch, terminal-or-unknown result, expected-revision, idempotency, and conservative orphan rules without modifying them.

## Accepted constraints

P0-W22 preserves:

- MiniMax as the only initial real provider;
- one deterministic fake provider for tests;
- no fallback, router, ensemble, or silent provider substitution;
- only the sealed Context package and required provider metadata may leave the machine;
- source excerpts require an accepted Project disclosure policy;
- Context and Tool availability do not grant authority;
- four or fewer Tool schemas per invocation;
- Repository content and Tool results are untrusted data;
- reference repositories, runtime Skills, LSP, Tree-sitter, persistent indexes, protocols, hosted retrieval, and remote execution are disabled;
- large or unbounded results remain Artifacts;
- a model can propose work but cannot approve, apply, verify, accept, or complete it.

# 1. Decision summary

P0-W22 accepts these focused decisions:

1. Use MiniMax through its OpenAI-compatible Chat Completions endpoint.
2. Use `MiniMax-M3` as the first configured real model.
3. Use direct bounded HTTP and JSON mapping behind a Kiln-native provider behaviour.
4. Use streaming for the real provider and deterministic scripted events for the fake.
5. Enable `reasoning_split` so thinking content is structurally separate from visible output.
6. Keep provider-native reasoning only in the live Worker for provider-message continuity. Never store it as Context, transcript, Evidence, Receipt, or ordinary Artifact content.
7. Do not retry a dispatched provider request automatically.
8. Classify cancellation, timeout, or connection loss after dispatch as an unknown provider effect unless a terminal provider result was observed.
9. Seal one ordered Context package before dispatch. Tool results can extend only the transient invocation conversation.
10. Define exactly four possible Tools: `repo.search`, `repo.read`, `artifact.read`, and `change.propose`.
11. Select a workflow-specific subset. An unused Tool schema is absent.
12. Apply deterministic path, size, encoding, special-file, symlink, ignore, disclosure, and secret controls before content becomes model-visible.
13. Default remote source disclosure to denied until accepted Project policy permits the exact class and destination.
14. Persist normalized manifests, requests, visible results, Tool records, usage, warnings, and digests. Do not persist raw stream frames or complete provider payloads by default.
15. State provider-side retention honestly: hosted MiniMax processing is not local-only, and Kiln cannot prove provider deletion or non-retention.

# 2. Provider profile

## 2.1 Identity

```text
provider_id: minimax
provider_profile: minimax-m3-openai/v1
api_family: openai-compatible-chat-completions
endpoint: https://api.minimax.io/v1/chat/completions
model: MiniMax-M3
service_tier: standard
fallback: none
```

A different provider, endpoint family, model, or service tier requires an accepted profile revision. Historical invocation manifests retain their exact profile.

## 2.2 Why M3

Current official MiniMax documentation identifies `MiniMax-M3` as the latest M-series model for agentic reasoning, Tool use, coding, and long-Context tasks. The Project owner already uses M3 as the MiniMax workhorse.

Kiln still limits initial input to a small bounded package. The provider's maximum Context window is not a Context budget.

## 2.3 Authentication

The provider adapter resolves an opaque credential reference only at dispatch.

Initial reference:

```text
MINIMAX_API_KEY
```

Rules:

- the value never enters journal entries, Context, Tool results, transcript, Artifact metadata, Receipt, CLI output, or detailed errors;
- logs record only reference name and resolution status;
- missing or empty credentials block dispatch;
- the value is sent only in the authorization header;
- Kiln does not create or edit `.env` files;
- Project source cannot select a credential reference.

## 2.4 Normalized invocation request

```text
invocation_id
session_id
run_id
operation_id
provider_profile_id
model_id
context_package_id
context_package_digest
tool_projection_id
tool_projection_digest
max_output_tokens
timeout_profile_id
stream
authority_reference
disclosure_decision_references
request_created_at
```

The provider adapter derives provider-native fields from this request and the sealed package. Provider-native message objects do not become domain state.

## 2.5 Request mapping

Initial provider fields:

```text
model: MiniMax-M3
stream: true
stream_options.include_usage: true
max_completion_tokens: 8192
temperature: 1.0
top_p: 0.95
service_tier: standard
reasoning_split: true
tools: selected fixed Tool schemas
n: 1
```

Rules:

- only text input is allowed;
- image, video, audio, file, and multimodal inputs are absent;
- deprecated function-call fields are absent;
- unsupported or ignored compatibility fields are absent;
- the initial Context becomes ordered system and user text plus fixed Tool schemas;
- Tool results are appended only inside the live invocation;
- Tool results cannot add Tools, permissions, source roots, provider settings, or instructions.

## 2.6 Streaming events

The adapter normalizes the stream into transient events:

```text
response_started
reasoning_state_observed
visible_text_delta
tool_call_started
tool_arguments_delta
tool_call_completed
usage_observed
response_completed
provider_error
stream_ended
```

`reasoning_state_observed` can record only bounded metadata needed for continuity, such as presence and provider message identity. Reasoning text is not emitted to domain consumers or durable stores.

A visible result is terminal only after a valid provider completion event and final normalized mapping.

## 2.7 Provider-message continuity

MiniMax requires complete assistant responses, including Tool calls and separated reasoning fields, to remain in multi-turn function-call history.

Kiln therefore permits one transient provider-native conversation owned by the live model Worker.

Rules:

- the sealed initial package remains immutable;
- the full provider assistant object can remain only in Worker memory during that invocation;
- normalized Tool results are appended to that transient conversation;
- hidden reasoning is not copied into Kiln Context, transcript, Artifacts, Evidence, or Receipts;
- the transient conversation is destroyed after terminal normalization;
- Worker loss does not trigger reconstruction from hidden reasoning;
- Worker loss after dispatch without terminal result follows P0-W21 unknown-effect and orphan rules.

## 2.8 Normalized result

```text
invocation_id
provider_id
model_id
provider_request_id | null
status
visible_message_artifact_id | null
normalized_tool_calls
finish_reason
usage
input_sensitive | unknown
output_sensitive | unknown
warnings
provider_metadata
started_at
completed_at
result_digest
```

`status` is:

```text
succeeded
failed
canceled_before_dispatch
unknown
```

There is no success-like canceled-after-dispatch state.

## 2.9 Timeout profile

```text
connect_timeout_ms: 10_000
first_byte_timeout_ms: 60_000
idle_stream_timeout_ms: 60_000
total_invocation_timeout_ms: 600_000
```

- timeout before dispatch is a known local failure;
- timeout after dispatch without terminal result is an unknown provider effect;
- Kiln closes its local connection but does not claim hosted processing or billing stopped;
- no automatic retry follows an unknown effect.

## 2.10 Cancellation

| Boundary | Classification |
| --- | --- |
| before credential resolution | `canceled_before_dispatch` |
| after credential resolution but before request bytes | `canceled_before_dispatch` |
| after dispatch with terminal result observed | use observed result |
| after dispatch without terminal result | `unknown` |

P0-W26 can deepen cancellation only after runtime Evidence exists. It cannot replace this conservative Wave A rule without an accepted authority change.

## 2.11 Retry

There is no automatic provider retry.

- validation failure does not dispatch;
- DNS, connect, TLS, HTTP, rate-limit, provider, stream, timeout, malformed-result, and connection-loss outcomes return one explicit result;
- a user can request a new invocation through a new workflow action;
- an uncertain prior dispatch remains subject to P0-W21 reconciliation;
- a new invocation has new invocation and operation identities;
- Kiln never switches model or provider silently.

## 2.12 Malformed data

Return known failure when the terminal response proves:

- required fields are absent;
- Tool arguments are invalid JSON;
- a Tool is outside the selected projection;
- Tool-call, turn, byte, or time limits are exceeded;
- a finish reason is unsupported;
- usage has invalid types;
- visible output exceeds limits;
- a known provider error terminates the stream.

Return `unknown` when the connection ends and Kiln cannot prove whether a valid terminal result existed.

## 2.13 Usage

Retain provider-reported normalized accounting when present:

```text
input_tokens | null
output_tokens | null
total_tokens | null
reasoning_tokens | null
cache_read_tokens | null
cache_creation_tokens | null
```

Usage is accounting metadata, not proof of correct work.

# 3. Deterministic fake provider

## 3.1 Purpose

The fake proves provider-boundary behavior without network, credentials, cost, provider availability, or model nondeterminism.

It is a test implementation of the same Kiln behaviour, not a second selectable real provider.

## 3.2 Script

```text
scenario_id
expected_request_digest
expected_context_digest
expected_tool_projection_digest
events
expected_terminal_status
expected_result_digest
```

Supported events:

- visible text chunks;
- complete Tool calls;
- malformed Tool arguments;
- known provider error before visible output;
- known provider error after partial visible output;
- timeout before first byte;
- idle timeout;
- connection loss;
- usage observation;
- terminal success;
- cancellation before dispatch;
- cancellation after dispatch with unknown effect.

## 3.3 Determinism

The fake:

- performs no network access;
- reads no credentials;
- uses a supplied deterministic clock;
- emits only scripted events;
- verifies request, Context, and Tool-projection digests;
- fails on an unexpected Tool, extra turn, or extra event;
- produces byte-stable normalized results.

# 4. Sealed Context package

## 4.1 Identity

```text
context_package_id
context_schema
session_id
run_id
workflow_step
objective_revision
criteria_revision
repository_observation_id
repository_state_digest
policy_snapshot_id
provider_profile_id
ordered_items
tool_projection_id
limits
exclusions
created_at
package_digest
```

The digest covers schema, ordered item manifests, Tool projection digest, limits, exclusions, provider destination, and disclosure decisions.

Credential values are never package content.

## 4.2 Ordered item classes

The package can contain these classes, in this order:

1. `system_contract`;
2. `objective`;
3. `criteria`;
4. `constraints_and_exclusions`;
5. `workflow_state`;
6. `repository_observation`;
7. `project_instructions`;
8. `source_excerpt`;
9. `current_failure_or_warning`;
10. `current_claim_or_proposal_summary`;
11. `artifact_excerpt`;
12. `output_contract`;
13. `tool_projection`.

An unneeded class is absent.

## 4.3 Item manifest

```text
item_id
item_class
source_kind
source_reference
authority
trust
sensitivity
repository_state_binding | null
freshness
selection_reason
transformation
original_digest | null
included_digest
byte_count
token_estimate
disclosure_mode
disclosure_decision_id | null
```

Source content, comments, documentation, prompt files, and generated text use `authority: untrusted_data` unless selected through the accepted active Project instruction path.

## 4.4 Limits

```text
maximum_context_items: 64
maximum_source_files: 24
maximum_source_excerpts: 48
maximum_single_source_excerpt_bytes: 16_384
maximum_total_source_excerpt_bytes: 262_144
maximum_artifact_excerpt_bytes: 16_384
maximum_serialized_provider_payload_bytes: 524_288
maximum_estimated_input_tokens: 32_000
maximum_output_tokens: 8_192
maximum_tool_schemas: 4
maximum_tool_calls: 12
maximum_provider_turns: 8
maximum_invocation_elapsed_ms: 600_000
```

The provider's larger Context window does not widen these limits.

If required items exceed a limit, package construction blocks. It does not silently drop criteria, accepted instructions, warnings, state bindings, or output contracts.

Optional source items are removed by a deterministic lowest-priority rule. Every exclusion is recorded.

## 4.5 Inspection

Before dispatch, Kiln can expose:

- provider and model;
- package digest;
- item classes and sources;
- files and ranges;
- bytes and token estimate;
- Tool names;
- disclosure decisions;
- exclusions and blocked items;
- warnings and unknowns.

P0-W25 owns CLI presentation. This round requires inspectable data.

## 4.6 Staleness

A package is stale when any bound fact changes, including:

- objective or criteria revision;
- Project instructions or disclosure policy;
- Repository commit, dirty fingerprint, file digest, or selected range;
- Tool schema or limit;
- provider profile or destination;
- current proposal, failure, warning, or required proof reference.

A stale package cannot dispatch. It receives a new identity and digest after rebuild.

# 5. Disclosure policy

## 5.1 Default

Hosted source disclosure is denied by default.

One accepted Project policy is required before source excerpts enter a MiniMax package.

## 5.2 Modes

```text
deny
metadata_only
approved_excerpt
explicit_each_time
local_only
```

- `deny`: neither metadata nor content leaves the machine;
- `metadata_only`: bounded permitted metadata only;
- `approved_excerpt`: policy permits bounded matching excerpts;
- `explicit_each_time`: one user decision binds the exact package digest;
- `local_only`: local inspection allowed, hosted disclosure forbidden.

## 5.3 Decision record

```text
decision_id
project_id
provider_id
destination
source_class
path_rule
allowed_transformations
maximum_bytes
accepted_by
accepted_at
expires_at | null
policy_revision
context_package_digest | null
```

`explicit_each_time` requires `context_package_digest`.

## 5.4 Non-overridable denials

Project policy cannot disclose:

- credential values;
- private keys;
- authentication cookies or tokens;
- mandatory secret paths;
- Kiln state database content;
- provider credentials;
- hidden model reasoning;
- reference-Repository source in version 0.1;
- files outside the canonical active Repository root.

## 5.5 Hosted retention and location

Kiln records that the package is sent to a hosted MiniMax API. MiniMax's current API privacy policy permits retention as necessary or legally permitted and describes processing or storage in United States data centers.

Kiln therefore does not claim:

- local-only processing;
- zero retention;
- immediate deletion;
- no provider logging;
- no safety or abuse review.

The Project policy must present the hosted destination and package digest before acceptance.

# 6. Repository boundary

## 6.1 Observation

```text
repository_id
canonical_root
worktree_root
vcs_kind: git
head_commit | null
branch | null
detached
dirty_fingerprint
ignore_policy_digest
observation_time
repository_state_digest
```

Every path is interpreted relative to the canonical selected checkout.

## 6.2 Path rules

Accept only paths that:

- are relative UTF-8 paths;
- normalize without escape;
- remain inside the canonical root after parent resolution;
- identify a regular file or permitted directory traversal;
- do not traverse a symlink;
- are not under `.git/` or `$KILN_HOME`;
- are not denied by Project or mandatory policy.

Deny:

- absolute paths;
- `..` escape;
- symlinks and junction-like escapes;
- sockets, devices, FIFOs, and special files;
- submodule content by default;
- nested Repository content unless explicitly included in the active boundary;
- files outside the selected checkout.

## 6.3 Ignore order

1. mandatory Kiln exclusions;
2. mandatory secret-path exclusions;
3. Project deny rules;
4. accepted Repository ignore files;
5. Project include rules, which cannot override mandatory exclusions.

Generated, vendor, dependency-cache, and build-output content is excluded by default when identified by Repository or Project rules.

## 6.4 File eligibility

Initial eligible content is regular UTF-8 text.

```text
maximum_file_size_for_read: 1_048_576 bytes
maximum_single_read_result: 131_072 bytes
maximum_single_search_result: 65_536 bytes
maximum_search_matches: 100
maximum_line_length_in_result: 4_096 bytes
```

Block:

- NUL bytes;
- invalid UTF-8;
- binary detection;
- oversize files or lines;
- permission or I/O failure;
- content changed after observed digest.

A blocked path can appear in local status without content disclosure.

## 6.5 State fingerprint

The state digest covers:

- canonical root identity;
- Git HEAD or no-commit state;
- branch or detached state;
- relevant tracked dirty paths and digests;
- accepted relevant untracked paths;
- ignore-policy digest;
- selected file digests.

It binds Kiln observations and provider Context to exact local state. It does not replace Git.

## 6.6 Literal search

`repo.search` performs bounded deterministic literal search.

Input:

```text
query
path_prefixes | []
include_globs | []
case_sensitive
maximum_matches <= 100
```

Rules:

- no shell;
- no user-supplied regular expression;
- only eligible files;
- deterministic path, line, and column order;
- each result includes path, range, bounded excerpt, file digest, and completeness;
- truncated results return a continuation token bound to query, root, state digest, and previous boundary;
- Repository change invalidates continuation.

## 6.7 Bounded read

`repo.read` input:

```text
path
start_line
end_line
expected_file_digest | null
```

Rules:

- maximum returned bytes is 131,072;
- output includes normalized path, exact range, file digest, Repository state digest, byte count, and completeness;
- digest mismatch returns `STALE_SOURCE` and no content;
- no automatic whole-file retry;
- original text bytes are preserved except safe display framing;
- provider disclosure occurs only after policy and secret screening.

# 7. Secret and sensitive-content controls

## 7.1 Mandatory denied paths

The versioned mandatory list includes:

- `.env` and `.env.*`, except explicitly classified non-secret examples;
- `.ssh/`;
- cloud credential directories;
- `.npmrc`, `.pypirc`, `.netrc`, and credential-helper files;
- `.pem`, `.key`, `.p12`, `.pfx`, and known private-key files;
- provider credential files;
- `$KILN_HOME` state and secret configuration;
- Artifacts marked secret;
- database files.

Project policy can add denials but cannot remove mandatory denials.

## 7.2 Content screening

Before model visibility, deterministically check for:

- private-key headers;
- high-confidence provider, cloud, Git-hosting, package-registry, and authentication token formats;
- high-confidence password or secret assignments in structured configuration;
- authorization headers, cookies, and credentialed connection strings;
- control characters and bidirectional controls;
- NUL bytes or invalid encoding.

A high-confidence match blocks the entire excerpt by default.

Screening cannot guarantee every secret is found. The manifest records screening version, result, and unknowns.

## 7.3 Redaction

Automatic partial redaction is not the default because it can change code meaning and line binding.

Allowed transformations:

- omit the item;
- replace a complete structured value with a typed placeholder only when a deterministic parser proves its boundary;
- include metadata only;
- require a safe source excerpt selected outside the denied value.

Every transformation and digest is recorded.

## 7.4 Untrusted instructions

Source, comments, documentation, issue templates, generated files, prompt files, Agent files, and Tool results remain untrusted unless selected through accepted Project instruction authority.

They cannot:

- change objective or criteria;
- add Tools;
- grant authority;
- change disclosure policy;
- request secrets;
- widen paths;
- choose provider or model;
- authorize Patch or Command;
- mark Evidence passing;
- accept completion.

# 8. Tool projection

## 8.1 Complete Tool set

```text
repo.search
repo.read
artifact.read
change.propose
```

There is no discovery or catalog Tool.

## 8.2 Workflow eligibility

| P0-W21 workflow step | Tools |
| --- | --- |
| `intent` | none |
| `investigation` | all four |
| `proposal` | all four |
| `approval` | none |
| `application` | none |
| `verification` | `artifact.read` only when a bounded current result must be summarized |
| `acceptance` | none |
| `reconciliation` | none |

This table consumes P0-W21 workflow-step names. It does not add a lifecycle transition.

P0-W23 owns Patch semantics. `change.propose` creates only a proposal for later deterministic validation and user review.

## 8.3 Common call contract

```text
tool_call_id
invocation_id
tool_name
arguments
arguments_digest
authority_reference
repository_state_binding | null
limit_snapshot
```

Result:

```text
tool_call_id
status
result_reference | inline_result
result_digest
repository_state_binding | null
completeness
warnings
continuation | null
```

Rules:

- arguments validate against a fixed selected schema;
- Tool presence does not grant authority;
- unknown Tool names fail the invocation;
- at most 12 Tool calls and eight provider turns;
- one Tool executes at a time;
- no parallel Tool calls;
- a Tool cannot call another Tool;
- a Tool cannot change the projection;
- stale Repository binding returns a structured stale result;
- Tool output passes secret and disclosure controls before provider return.

## 8.4 `repo.search`

Find bounded literal matches in eligible active-Repository text.

It cannot search the whole machine, reference repositories, `$KILN_HOME`, binary files, denied paths, or hosted data.

## 8.5 `repo.read`

Read one bounded active-Repository text range with exact state binding.

It cannot follow symlinks, read absolute paths, or disclose content without accepted policy.

## 8.6 `artifact.read`

Read one bounded excerpt from a Kiln-owned Artifact already authorized for this Run and provider destination.

It cannot enumerate all Artifacts, read secret Artifacts, change retention, or make content Evidence.

Maximum excerpt: 16,384 bytes.

## 8.7 `change.propose`

Return one normalized proposed change for later P0-W23 validation.

Allowed fields:

- summary;
- rationale;
- affected relative paths;
- proposed text Patch payload or Artifact reference;
- assumptions and unknowns;
- expected criterion impact.

It cannot:

- apply source changes;
- approve its proposal;
- execute a Command;
- change criteria;
- claim verification, acceptance, or completion.

Until P0-W23 integrates, `change.propose` remains a planning interface and does not settle Patch representation, digest, base binding, or application.

# 9. Large results and continuation

Inline results must remain under the accepted Tool limit.

Larger content becomes an immutable Artifact with:

- content digest;
- byte count;
- media type;
- sensitivity;
- trust;
- Repository state binding when applicable;
- completeness;
- creator operation;
- bounded excerpt;
- continuation method.

The provider receives at most a 16,384-byte Artifact excerpt plus digest and metadata.

Continuation is valid only for the same invocation, Artifact, disclosure decision, and state. It cannot widen total package, Tool-call, turn, elapsed, or disclosure limits.

# 10. Persistence and retention boundary

Persist references or normalized records for:

- invocation request;
- provider profile and model;
- Context manifest and package digest;
- Tool projection and digest;
- disclosure decisions;
- P0-W21 operation intent and terminal or unknown result reference;
- normalized Tool requests and results;
- visible final response Artifact;
- usage;
- warnings, failures, and unknowns;
- result digest and provider request ID when present.

Do not persist by default:

- credential values;
- complete HTTP headers;
- complete serialized request body;
- raw stream frames;
- provider-native hidden reasoning;
- duplicate source content when exact state and item digests suffice;
- provider-side logs;
- complete transient provider conversation.

A raw-payload diagnostic mode is outside the first contract because it can capture source, credentials, and reasoning.

# 11. Failure matrix

| Failure | Result | Effect classification | Next action |
| --- | --- | --- | --- |
| missing credential | `PROVIDER_CREDENTIAL_MISSING` | not dispatched | configure reference |
| stale Context | `STALE_CONTEXT` | not dispatched | rebuild |
| disclosure denied | `DISCLOSURE_DENIED` | not dispatched | change policy or omit |
| secret match | `SECRET_BLOCKED` | not dispatched | omit or provide safe source |
| invalid path | `PATH_DENIED` | no Tool effect | correct request |
| binary or invalid UTF-8 | `CONTENT_UNSUPPORTED` | no disclosure | use another source |
| package limit exceeded | `CONTEXT_LIMIT_BLOCKED` | not dispatched | deterministic reduction |
| unknown Tool | `TOOL_NOT_ALLOWED` | invalid provider result | fail invocation |
| invalid Tool arguments | `TOOL_ARGUMENTS_INVALID` | Tool not executed | fail invocation |
| stale Tool source | `STALE_SOURCE` | no content returned | rebuild or reread |
| known provider HTTP error | `PROVIDER_FAILED` | dispatched; known response | explicit new action only |
| rate limit | `PROVIDER_RATE_LIMITED` | known response | explicit later action |
| timeout before dispatch | `PROVIDER_LOCAL_TIMEOUT` | not dispatched | explicit retry allowed |
| timeout or connection loss after dispatch | operation `unknown` | uncertain hosted effect | P0-W21 reconciliation |
| malformed known terminal response | `PROVIDER_MALFORMED_RESULT` | known invalid result | inspect; new action |
| stream ends without terminal classification | operation `unknown` | uncertain result | reconciliation |
| cancellation before dispatch | `canceled_before_dispatch` | no hosted effect | return to workflow |
| cancellation after dispatch without terminal result | operation `unknown` | uncertain hosted effect | reconciliation |

# 12. Security invariants

The first-month implementation must prove:

1. MiniMax is the only real provider.
2. The configured model is explicit and no fallback occurs.
3. Credentials never enter durable or visible records.
4. Every disclosed source item has a current decision.
5. Context and Tools cannot grant authority.
6. Paths cannot escape the canonical root.
7. Symlink, special-file, binary, invalid-encoding, and oversized content is denied.
8. Mandatory secret paths cannot be overridden.
9. High-confidence secret matches block excerpts by default.
10. At most four Tool schemas enter a request.
11. Unused Tool schemas are absent.
12. No Tool can mutate source or execute a Command.
13. Provider-native reasoning is not persisted or treated as Evidence.
14. A dispatched request is not retried automatically.
15. Uncertain provider effects use P0-W21 unknown and orphan rules.

# 13. P0-W21 ownership audit

P0-W22 consumes these upstream facts:

- operation identity;
- intent recorded before dispatch;
- common operation states;
- terminal or unknown result observation;
- expected revision and idempotency;
- conservative restart and orphan handling.

P0-W22 does not define or change:

- Session, Task, or Run states;
- valid lifecycle transitions;
- transition authority;
- journal entry envelope;
- action-commit storage;
- projection ownership or replay;
- migration or startup behavior;
- terminal Session and Task alignment;
- completion transaction prerequisites.

Any later conflict resolves in favor of integrated P0-W21.

# 14. Implementation boundary

After a later Prompt 8-A authorization, this round can make these units safe to implement:

- provider behaviour and MiniMax adapter;
- deterministic fake provider;
- request, stream, result, and usage normalization;
- sealed Context manifest and package builder;
- fixed Tool projection;
- active-Repository observation, literal search, and bounded read;
- bounded Artifact read;
- disclosure checks;
- mandatory path and secret screening;
- large-result externalization and continuation;
- provider boundary fixtures.

It does not unlock:

- Patch validation, Approval, application, or rollback;
- registered Command execution;
- criterion Evidence, completion, Receipt, or acceptance;
- complete CLI delivery;
- Child Runs or Wave B work.

# 15. Prompt 3 dispositions

P0-W22 changes planning direction for:

- IU-08: one MiniMax M3 adapter and one deterministic fake;
- IU-09: one explicit package, fixed item classes, limits, and Tool projection;
- IU-13: large provider and Tool results become Artifact references, while storage is owned by P0-W24;
- IU-31: no general provider router or Capability broker is justified;
- `kiln-context.schema.json`: reduce retrieval-provider, Skill, semantic, observability, and generalized compiler fields;
- `kiln-execution.schema.json`: reduce Agent catalog, Skill, Terminal, broad Capability, and fallback fields;
- `kiln-capability.schema.json`: keep outside the required first-month subset except fixed result ideas used directly;
- `kiln-core.schema.json`: provider and Context references cannot require broad Agent or Client state.

# 16. Candidate Prompt 6-A scaffolding

Prompt 6-A can evaluate:

- provider behaviour and fake script contract;
- normalized invocation, event, result, and usage types;
- Context item, manifest, package, and digest types;
- Tool projection and workflow-eligibility validators;
- Repository observation, normalized path, search, read, continuation, and stale-source result types;
- disclosure policy and decision types;
- secret-screen result and mandatory path fixtures;
- malformed provider, timeout, cancellation, no-fallback, path-escape, symlink, binary, secret-canary, stale-Context, and oversized-result fixtures.

It must not add a provider router, general Context compiler, runtime Skills, code index, protocol adapter, Patch application, Command execution, or fake passing product gate.

# 17. External evidence

Official sources reviewed on 2026-07-28:

- MiniMax OpenAI SDK compatibility: `https://platform.minimax.io/docs/api-reference/text-openai-api`
- MiniMax Chat Completions API: `https://platform.minimax.io/docs/api-reference/text-chat-openai`
- MiniMax models endpoint: `https://platform.minimax.io/docs/api-reference/models/openai/list-models`
- MiniMax API credential guidance: `https://platform.minimax.io/docs/faq/about-apis`
- MiniMax API privacy policy: `https://platform.minimax.io/protocol/privacy-policy`

These sources support the endpoint, current M3 model, Bearer authentication, streaming, Tool definitions, `reasoning_split`, usage, and hosted privacy boundary. They do not prove provider-side deletion, non-retention, or a server-side cancellation guarantee.

# 18. Completion gate

P0-W22 passes only when:

- OD-01 remains unchanged;
- P0-W21 ownership remains unchanged;
- one endpoint, model, request, stream, result, usage, timeout, cancellation, malformed-result, and retry contract exists;
- one deterministic fake covers required success and failure paths;
- one ordered Context package has exact fields, digests, limits, inspection, staleness, and exclusions;
- all disclosed source items require current decisions;
- exact Repository root, path, ignore, symlink, file, encoding, size, search, read, and fingerprint rules exist;
- exactly four possible Tools exist and unused schemas are absent;
- secret values and denied source cannot enter provider Context;
- hidden reasoning and raw payloads are excluded from durable state;
- no lifecycle, journal, Patch, Command, Evidence, completion, CLI, Child, or deferred-system authority is introduced;
- the exact final planning-only head passes Repository validation.

Passing P0-W22 does not issue build authorization.
