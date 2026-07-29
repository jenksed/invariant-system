# <WORK-ID>: <Objective>

**Document type:** Implementation plan  
**Status:** Proposed | Accepted | In progress | Blocked | Complete  
**Parent slice:** None | <P1-SXX>  
**Branch:** `<class>/<work-id>-<purpose>`  
**Depends on:** None | <WORK-ID list>

## Slice contribution

When this plan belongs to a vertical slice, state:

- the slice's user-visible outcome;
- the exact behavior this ticket adds;
- the slice gate, demo step, and slice verification manifest that consume this ticket's Evidence;
- the behavior that remains unreachable, disabled, or deferred after merge.

A ticket does not claim the entire slice complete unless the aggregate gate and demo pass against the exact tested state.

A ticket closeout record or slice verification manifest is not a product Receipt. A product Receipt is sealed only after committed product completion under P0-W24.

## Objective

State one mergeable outcome for this ticket or planning work package.

## Observed current state

Use only direct Repository, Command, test, runtime, or version-matched documentation Evidence.

| Observation | Evidence | Collected by | Date or commit |
| --- | --- | --- | --- |
| <Observed fact> | `<path:symbol>`, `<command>` exit `<status>`, or Artifact | <actor> | <date or SHA> |

## Assumptions and unknowns

### Assumptions

- **<ASSUMPTION-ID>:** <Temporary assumption and reason>

### Unknowns

- **<UNKNOWN-ID>:** Unknown. Verify with <cheapest reliable method>.

## Requirements

Use Easy Approach to Requirements Syntax-compatible statements when applicable.

- **<WORK-ID>-R01:** The <system> shall <response>.
- **<WORK-ID>-R02:** When <trigger>, the <system> shall <response>.

## Security boundary

State:

- allowed Resources and paths;
- denied capabilities;
- authority and policy inputs;
- network, secret, filesystem, process, and external-disclosure behavior;
- failure or degraded-isolation behavior;
- protected invariants from the parent slice.

Do not defer a security boundary that becomes necessary in this ticket.

## Proposed changes

Describe proposed behavior. Do not describe it as current behavior.

1. <Change>
2. <Change>

## Expected files or components

| Path or component | Expected change | Status |
| --- | --- | --- |
| `<path>` | <change> | Proposed |

Do not invent a path only to complete this table. Write `Unknown` when discovery is required.

## Acceptance criteria

- **<WORK-ID>-AC01**
  - **Given** <observable initial state>
  - **When** <one action or event>
  - **Then** <observable result>
  - **Evidence:** <required Command, output, Artifact, implementation Evidence manifest, or runtime observation>

## Deterministic verification

```bash
<exact command>
```

State the expected exit status or output for each command.

Tests must not require a live provider, external protocol server, public network, or nondeterministic clock unless the plan labels that path as an optional smoke test and provides a deterministic fixture for CI.

## Demo contribution

State the exact step this ticket enables in the parent slice demo.

```text
<P1-SXX-D01 step>
```

When the ticket has its own focused demo helper, identify it separately. Do not duplicate the aggregate slice demo unnecessarily.

## Required completion Evidence

| Evidence ID | Acceptance criterion | Required Evidence |
| --- | --- | --- |
| <WORK-ID>-E01 | <WORK-ID>-AC01 | <Command output, structured result, path, Artifact, implementation Evidence manifest, or runtime observation> |

### Slice gate contribution

| Slice gate or verification manifest | Contribution |
| --- | --- |
| <P1-SXX-G01> | <Evidence supplied by this ticket> |
| <P1-SXX-V01> | <manifest items or references supplied by this ticket> |

## Explicit exclusions

- <Behavior or component that this ticket does not include>

State exclusions aggressively. A future architecture seam is not a reason to implement it now.

## Completion record

Complete this section before merge.

**Result:** Complete | Implemented but unverified | Blocked | Abandoned

### Acceptance status

| Criterion | Status | Evidence ID | Result |
| --- | --- | --- | --- |
| <WORK-ID>-AC01 | Pass | <WORK-ID>-E01 | <concise result> |

### Verification executed

| Command or check | Exit status | Evidence location |
| --- | --- | --- |
| `<command>` | `<status>` | <PR log, Artifact, implementation Evidence manifest, or report> |

### Demo and slice status

- Ticket demo contribution: Pass | Fail | Blocked | Not yet exercised
- Parent slice gate affected: `<P1-SXX-GXX>`
- Slice verification manifest updated: Yes | No | Not applicable
- Slice completion claimed: No | Yes with exact aggregate Evidence

### Failures and warnings

- None observed. | <failure or warning>

### Remaining unknowns and exclusions

- <unknown or exclusion>

### Repository state

- Commit: `<SHA>`
- Branch: `<branch>`
- Diff reviewed: Yes | No
- Exact CI run: `<run or status>`
- Parent slice status after merge: <unchanged | advanced with reason>
