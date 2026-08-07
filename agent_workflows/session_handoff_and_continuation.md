# Session Handoff and Continuation Pack

You are responsible for this outcome: **Capture enough verified context for another model or later session to continue without repeating discovery work.**

Do the work, not merely describe how someone else could do it. Use the available tools and source material inside the user's scope. Do not expose private chain-of-thought; report decisions, evidence, and results instead.

## Use when

- ending a substantial work session
- pausing with unfinished work
- transferring ownership to another agent or engineer

## Required inputs

- session transcript or notes
- repository
- Git state
- completed work
- validation results
- unresolved decisions
- relevant project files

If a required input can be recovered from the available repository, files, transcript, or tools, recover it rather than asking the user to repeat it. If a genuinely blocking input is unavailable, state the limitation and continue with the grounded portion of the work.

## Evidence and uncertainty

Separate **Confirmed**, **Strong signal**, **Reasonable hypothesis**, **Weak signal**, and **Unknown** when uncertainty matters. Do not promote familiarity, keyword overlap, or plausible inference into fact.

## Workflow

1. Restate the session objective and the verified scope actually attempted.
2. Record completed work only when supported by repository state or validation evidence.
3. List files changed and describe the consequential changes, not every trivial edit.
4. Record validation performed, including failed, skipped, or unavailable checks.
5. Capture important decisions and rationale that would otherwise be rediscovered.
6. Record repository, branch, commit, and working-tree state precisely enough to resume safely.
7. Separate required next work from optional ideas and unresolved questions.
8. State the exact continuation point, the first files or commands to inspect, and produce ready-to-use continuation instructions.

## Safeguards

- Do not describe planned work as completed.
- Do not omit failed tests or dirty working-tree state.
- Do not use vague instructions such as 'continue where we left off.'
- Do not bury the immediate next action under obsolete history.

## Output contract

Produce the following, adapting the formatting to the task and artifact:
- current status
- completed work
- files changed
- validation
- decisions
- known issues
- immediate next action
- continuation instructions
- first files and commands to inspect

## Validation

Before claiming completion, verify the consequential outputs using the strongest practical deterministic or inspectable checks available. Report failed, skipped, unavailable, and unverified checks explicitly. A partial but accurately bounded result is preferable to fabricated completeness.

## Stopping condition

Stop when the requested outcome is materially complete, the required outputs exist, and the evidence supports the completion claim. If that state cannot be reached, return the completed portion, the blocking evidence, and the exact next action rather than pretending the task is done.

## Final response

Keep the final handoff concise. State what was produced or concluded, the most important evidence, any unresolved uncertainty, and the next action only when work remains.
