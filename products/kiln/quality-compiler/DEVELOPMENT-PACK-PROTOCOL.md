# Development Pack Protocol

**Status:** Draft protocol design  
**Proposed protocol:** `kiln.development_pack/v1alpha1`  
**Public boundary:** Supervised external process

## 1. Objective

Development Packs provide language, framework, toolchain, and repository-specific intelligence without receiving ambient Kiln authority.

The public boundary follows the existing Kiln decision to prefer a versioned protocol over supervised external processes.

## 2. Non-goals

The protocol does not allow a Pack to:

- run Project Commands;
- mutate source;
- install dependencies;
- register arbitrary executables;
- grant Capabilities;
- choose secrets or network;
- approve a Patch;
- pass a criterion;
- invoke a model;
- store authoritative state.

## 3. Transport

Initial transport:

```text
Pack process stdin/stdout
+ length-prefixed frames
+ UTF-8 JSON payload
+ explicit protocol version
+ request identity
+ content digest
+ bounded size
```

Stderr is diagnostic output and never protocol data.

The final encoding may change before v1. The semantic operations and failure classifications matter more than JSON itself.

## 4. Process environment

A Pack process receives:

- Kiln-owned temporary working directory;
- minimal fixed environment;
- no inherited secrets;
- no network grant;
- no writable Repository path;
- no arbitrary executable authority;
- bounded time, output, memory, and process count where supported.

Source or Artifact content is supplied only through bounded explicit inputs.

## 5. Frame

Conceptual frame:

```text
magic
protocol version
message kind
request ID
payload byte count
payload digest
payload
```

Requirements:

- reject oversized payload before allocation where possible;
- validate byte count;
- validate UTF-8;
- validate digest;
- reject unknown required fields;
- preserve unknown optional extension fields only when explicitly supported;
- no partial success after malformed trailing data.

## 6. Lifecycle

Borrow the useful request lifecycle from LSP:

```text
request
progress
partial result
cancel
terminal response
```

Every accepted request receives exactly one terminal classification:

```text
succeeded
failed
canceled
timed_out
crashed
protocol_error
unknown
```

Cancellation does not permit the invocation to disappear.

## 7. Operations

Version `v1alpha1` supports:

```text
hello
describe
detect
plan
parse
impact
policy_metadata
shutdown
```

### `hello`

Negotiates:

- protocol versions;
- Pack identity and digest;
- supported operations;
- size limits;
- feature flags.

### `describe`

Returns immutable manifest metadata and declared tool templates, analyzers, inspections, and effects.

### `detect`

Input:

- bounded path manifest;
- selected file digests;
- accepted Project metadata.

Output:

- exact or heuristic project matches;
- evidence for each match;
- ambiguities;
- unsupported conditions.

Detection must not read the Repository directly.

### `plan`

Input:

- accepted criteria and Claims;
- changed-path manifest;
- project detection;
- accepted tool availability;
- Assurance;
- risk and policy metadata;
- prior current Findings.

Output:

- proposed Gates;
- dependencies;
- criterion coverage suggestions;
- omitted Gates;
- fallbacks;
- limitations.

Kiln validates and accepts the final Evidence Plan.

### `parse`

Input:

- immutable output Artifact metadata;
- bounded content or controlled Artifact descriptor;
- parser identity;
- tool identity.

Output:

- diagnostic candidates;
- parser warnings;
- completeness;
- unparsed regions;
- native fingerprints.

Kiln owns canonical paths, validation, and stable Finding identity.

### `impact`

Input:

- changed files or symbols;
- accepted compiler or dependency metadata;
- Project structure;
- requested phase.

Output:

- affected units;
- selected test suggestions;
- risk classes;
- confidence;
- blind spots;
- full fallback requirement.

### `policy_metadata`

Returns:

- policy IDs;
- descriptions;
- deterministic configuration schema;
- recommended minimum Assurance;
- risk triggers.

It does not evaluate authority or accept configuration.

## 8. Effects declaration

Every Pack operation and proposed Gate declares:

```text
reads source content
loads Project code
executes Project code
macroexpands or generates
writes caches
reads environment
requires network
requires secrets
mutates Repository
```

Pack protocol operations should normally be non-mutating and retry-safe.

Gate effects describe the Project tool that Kiln may later execute through registered Commands.

## 9. Error classifications

```text
unsupported_version
invalid_handshake
invalid_frame
frame_too_large
unknown_operation
invalid_request
invalid_response
digest_mismatch
timeout
canceled
process_crash
truncated_response
policy_violation
```

No error produces an empty successful result.

## 10. Trust classes

### Bundled

Shipped and reviewed with Kiln. Still receives explicit process limits.

### Reviewed

Installed from an accepted digest and source. No ambient authority.

### Untrusted

May be used only for operations whose isolation and information disclosure are accepted. Default no source content, no network, and no secrets.

Trust class does not grant Project Command execution.

## 11. Compatibility

The Pack Manifest records:

```text
Pack version
protocol range
schema versions
supported host profiles
tool format versions
fingerprint versions
```

Protocol v1 must not freeze until:

- deterministic fake Pack passes conformance;
- Elixir Pack runs against Kiln;
- TypeScript Pack proves portability;
- no language-specific field is required in the core protocol.

## 12. Conformance

Required fixtures include:

- valid handshake;
- no project match;
- ambiguous match;
- plan success;
- parse success;
- impact fallback;
- malformed frame;
- oversized frame;
- digest mismatch;
- crash;
- timeout;
- cancel;
- partial result then crash;
- invalid path;
- attempt to request forbidden authority.

See [conformance](conformance/).
