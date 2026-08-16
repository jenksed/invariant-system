# Project Session Kickoff and Context Recovery

You are responsible for this outcome: **Begin a project session by recovering context, verifying current state, and immediately completing a coherent portion of real work.**

Do the work, not merely describe how someone else could do it. Use the available tools and source material inside the user's scope. Do not expose private chain-of-thought; report decisions, evidence, and results instead.

## Use when

- resuming an existing repository
- starting a new work session with prior plans, status, or handoff material
- the correct continuation point must be established before implementation

## Required inputs

- repository
- branch or intended branch
- session objective
- governing, status, plan, and handoff files
- constraints
- desired session boundary

If a required input can be recovered from the available repository, files, transcript, or tools, recover it rather than asking the user to repeat it. If a genuinely blocking input is unavailable, state the limitation and continue with the grounded portion of the work.

## Evidence and uncertainty

Separate **Confirmed**, **Strong signal**, **Reasonable hypothesis**, **Weak signal**, and **Unknown** when uncertainty matters. Do not promote familiarity, keyword overlap, or plausible inference into fact.

## Workflow

1. Read the repository's governing instructions before making changes.
2. Inspect branch, Git status, recent history, uncommitted changes, and the relevant project structure.
3. Recover the current objective, release boundary, important decisions, and last completed acceptance gate from project evidence.
4. Reconcile status claims with the actual repository. Do not repeat work already completed or trust stale planning documents.
5. Choose the smallest coherent session scope that materially advances the objective and respects the requested boundary.
6. Begin implementation rather than stopping after a plan. Preserve unrelated user changes and repository conventions.
7. Run targeted validation as work progresses, then run the acceptance checks appropriate to the completed slice.
8. Update status or handoff material when that is part of the repository's workflow and identify the exact continuation point.

## Safeguards

- Do not restart completed work.
- Do not ask questions already answered by project files.
- Do not discard or overwrite unrelated uncommitted work.
- Do not broaden scope without a concrete reason.
- Do not claim completion without evidence.

## Output contract

Produce the following, adapting the formatting to the task and artifact:
- recovered context
- decisions made
- work performed
- files changed
- validation results
- unresolved issues
- exact next action

## Validation

Before claiming completion, verify the consequential outputs using the strongest practical deterministic or inspectable checks available. Report failed, skipped, unavailable, and unverified checks explicitly. A partial but accurately bounded result is preferable to fabricated completeness.

## Stopping condition

Stop when the requested outcome is materially complete, the required outputs exist, and the evidence supports the completion claim. If that state cannot be reached, return the completed portion, the blocking evidence, and the exact next action rather than pretending the task is done.

## Final response

Keep the final handoff concise. State what was produced or concluded, the most important evidence, any unresolved uncertainty, and the next action only when work remains.
