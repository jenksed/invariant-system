# Finding Identity and Baselines

**Status:** Proposed

## 1. Definitions

### Inspection

The stable rule or analyzer check.

### Finding

The logical issue across source movement and repeated observations.

### Finding Occurrence

One exact observation on one Subject state.

## 2. Why line hashes fail

This is insufficient:

```text
hash(file + line + message)
```

It breaks when:

- lines move;
- a function moves;
- a file is renamed;
- tool wording changes;
- punctuation changes;
- one rule triggers twice nearby;
- tool version changes localization.

## 3. Fingerprint inputs

Initial strategy may use:

- Pack ID and version;
- tool ID and version;
- rule ID;
- normalized repository-relative path;
- category and severity;
- semantic symbol or declaration;
- AST or syntax anchor when available;
- normalized message class;
- bounded source-context hash;
- related location identity;
- trusted native fingerprint;
- fingerprint algorithm version.

## 4. Match levels

```text
exact
structural
candidate
none
```

### Exact

Canonical identity fields match.

### Structural

Rule, semantic anchor, and relevant context match despite movement.

### Candidate

Similarity exists but cannot safely establish identity.

Candidate matches never merge automatically. They remain distinct until explicitly classified or a stronger algorithm proves identity.

## 5. Versioning

Every Finding stores:

```text
fingerprint version
Pack version
parser version
tool version
```

A new algorithm produces a migration report:

```text
preserved
split
merged
unmatched
ambiguous
```

History is never silently rewritten.

## 6. State classification

Comparison output:

```text
introduced
preexisting
resolved
regressed
worsened
improved
moved
changed
ambiguous
```

`worsened` may include:

- increased severity;
- expanded affected scope;
- more occurrences under one logical Finding;
- lost suppression justification;
- newly failing enforcement mode.

## 7. Enforcement modes

### Audit

Record Findings without blocking solely because they exist.

Execution integrity, unknown state, and non-negotiable controls can still block.

### Ratchet

Permit explicit accepted existing debt.

Fail:

- introduced Findings;
- worsened Findings;
- regressed resolved Findings;
- expired baseline entries;
- incompatible baseline versions.

### Strict

Any required current Finding fails. Missing required tools and incomplete required output block.

## 8. Baseline entry

Every baseline entry records:

```text
Finding stable ID
Inspection and rule
first observed Subject
accepted rationale
owner
enforcement mode
optional expiration
last reproduced Subject
Pack, parser, tool, and fingerprint versions
status
```

A baseline is not a count and is not a wildcard unless the owner explicitly accepts that broader debt class.

## 9. Suppressions and waivers

A suppression changes how one Finding is reported or enforced.

A waiver accepts missing Evidence or lower Assurance for one exact Subject or bounded scope.

They are separate records.

Neither converts a Finding into proof that the code is correct.

## 10. Kiln dogfood adoption

Immediately strict:

- formatting;
- compiler warnings;
- required tests;
- compile-connected cycles;
- current contract validators;
- current Schema validators;
- agent-asset validation;
- Vale.

Initially audit:

- Credo strict;
- Dialyzer;
- advanced OTP design inspections;
- changed-line coverage;
- mutation testing;
- optional property-test recommendations.

Move a tool from audit to ratchet only when:

1. version is pinned;
2. parser passes conformance;
3. current Findings are reviewed;
4. baseline entries are explicit;
5. false-positive behavior is measured.

No Pack installs a dependency automatically.

## 11. Protected tests

- insert lines above Finding;
- move function in same file;
- rename file;
- change tool punctuation;
- change tool wording version;
- same rule twice in one function;
- same message in two symbols;
- context changes enough to invalidate identity;
- one Finding splits into two;
- two similar Findings must not merge;
- parser version change invalidates baseline;
- resolved Finding regresses;
- expired baseline blocks.
