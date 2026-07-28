# Session model

A session is one durable attempt to move a repository objective toward verified completion.

## Conceptual phases

```text
Intent
  → Orientation
  → Investigation
  → Change
  → Verification
  → Reconciliation
  → Completion
```

These are runtime concepts, not separate agents or mandatory model turns.

## Session state

A session should eventually track:

- user intent and completion contract;
- workspace path and repository identity;
- Git branch, commit, and dirty state;
- repository fingerprints;
- orientation facts and freshness;
- provider and model requests;
- tool requests and executions;
- capability decisions;
- observed file mutations;
- verification evidence;
- unresolved findings;
- checkpoints;
- interruption and recovery state;
- completion claims and acceptance.

## Event journal

The durable record should be append-oriented. Candidate events include:

- `SessionStarted`
- `IntentRecorded`
- `WorkspaceOpened`
- `OrientationCaptured`
- `ModelRequestStarted`
- `ToolRequested`
- `CapabilityGranted`
- `ToolExecutionStarted`
- `ToolExecutionCompleted`
- `FileMutationObserved`
- `RepositoryFingerprintCaptured`
- `VerificationCompleted`
- `EvidenceInvalidated`
- `CheckpointCreated`
- `SessionInterrupted`
- `SessionResumed`
- `CompletionClaimed`
- `CompletionAccepted`
- `CompletionRejected`

Not every streamed token needs its own durable event. Event granularity must support reconstruction without producing meaningless volume.

## Recovery rule

OTP restores runtime structure. The event journal and repository observations restore known work state.

Recovery must never transform an interrupted or unknown operation into a successful one.

## Completion rule

A model response is a claim. Completion requires current evidence or an explicit disclosure of what remains unproven.
