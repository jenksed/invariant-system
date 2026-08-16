# Quality Compiler Threat Model

**Status:** Proposed

## 1. Protected assets

- Repository source and exact state;
- Patch authority;
- Project policies;
- secrets;
- command registrations;
- Evidence integrity;
- Finding history and baselines;
- user acceptance;
- Receipts;
- Pack protocol trust.

## 2. Threat actors and failure sources

- malicious or compromised Pack;
- buggy Pack;
- malicious Project source;
- analyzer that executes source unexpectedly;
- model attempting authority expansion;
- malformed native tool output;
- parser confusion;
- stale cache or summary;
- baseline abuse;
- false or optimistic verifier;
- process descendant surviving timeout;
- user misunderstanding a downgrade;
- toolchain replacement.

## 3. Pack authority threats

### Threat

Pack requests arbitrary command execution or source mutation.

### Control

Packs only describe Gates and parse bounded results. Kiln owns all Commands and Patch mutation.

### Protected test

A Pack response containing executable path, shell string, source write, secret request, or network authority is rejected.

## 4. Information disclosure threats

### Threat

Pack receives more source, secrets, environment, or Artifact data than required.

### Control

Bounded explicit request fields, minimal environment, no inherited secrets, no Repository path, sensitivity policy, request Artifact digest.

## 5. Process threats

### Threat

Pack or analyzer forks descendants, hangs, floods output, or survives cancellation.

### Control

Supervised process, limits, process-tree ownership where supported, TERM/KILL/probe, bounded frames, terminal unknown when cleanup is not proved.

## 6. Parser threats

### Threat

Malformed output causes crash, false empty pass, path escape, resource exhaustion, or diagnostic identity confusion.

### Control

Total parsers, bounded input, immutable raw Artifact, explicit parser warnings, no pass when required structure cannot be established, canonical path validation.

## 7. Evidence laundering

### Threat

Heuristic or partial output is presented as strong proof.

### Control

Guarantee class, completeness, scope, assumptions, and deterministic consolidation.

## 8. Stale Evidence

### Threat

Results from a prior Repository state, tool version, Pack version, or environment are reused.

### Control

Exact dependency digests and automatic invalidation.

## 9. Baseline abuse

### Threat

New debt is hidden under broad ignores or old baselines.

### Control

Per-Finding baseline entries, version compatibility, expiration, introduced/worsened/regressed classification, no candidate auto-match.

## 10. Assurance downgrade confusion

### Threat

User requests Rapid for a Critical change and receives a misleading “verified” result.

### Control

Automatic risk escalation, explicit waiver record, achieved Assurance displayed, non-waivable integrity controls.

## 11. Model self-verification

### Threat

Implementer model approves its own work.

### Control

Independent Verifier Child, separate Context, no mutation, no user-decision authority, counterexample-oriented output.

## 12. Toolchain substitution

### Threat

Executable, interpreter, compiler, Pack, or parser changes while registration or baseline remains accepted.

### Control

Identity digests, revalidation, baseline incompatibility, stale Evidence.

## 13. Repository side effects

### Threat

A “verification” tool mutates source, generated files, caches, or external systems unexpectedly.

### Control

Gate effect declaration, Environment selection, pre/post Repository observation, registered output paths, unknown classification for unclassified effects.

## 14. Denial of service

### Threat

Combinatorial Gate plan, huge reports, repeated identical repairs, Pack output flood.

### Control

Plan limits, frame limits, Artifact limits, bounded retries, identical-failure stop, unchanged-Patch stop, resource budgets.

## 15. False confidence from formal methods

### Threat

Bounded solver result is marketed as universal proof.

### Control

Explicit Guarantee and scope, assumptions, bounds, and Formal Assurance requirements.

## 16. Security review triggers

Review when:

- public Pack distribution is proposed;
- Pack signing or update enters scope;
- remote execution enters scope;
- source content is sent to third-party Pack processes;
- networked analyzers enter scope;
- untrusted code executes on host;
- formal attestation signing is added;
- automatic waivers are proposed.
