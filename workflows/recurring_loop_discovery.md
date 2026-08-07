# Discover a Recurring Loop Worth Systematizing

Use when the user wants to turn a repeated activity into a reusable workflow, automation, or prompt package.

## Find the loop

A **loop** is a recurring real-world activity. A **workflow** is its explicit executable specification.

Identify:

- what repeats;
- what triggers each run (event or schedule);
- inputs/state available at trigger time;
- deterministic work that can happen automatically;
- reasoning/AI work genuinely needed;
- external side effects;
- failure/retry behavior;
- evidence that the run succeeded;
- where human judgment is actually required.

## Push human checkpoints right

Do as much safe, reversible preparation as possible before asking the human to act. A human checkpoint should present a decision-ready brief, not raw intermediate work.

Do not invent a checkpoint merely because AI is involved; some workflows are deterministic and some can run autonomously inside structural boundaries.

## Grill until implementable

Use Decision-Tree Grilling on unresolved workflow semantics. The workflow spec is complete when an implementer can build it without inventing triggers, state transitions, permissions, failure behavior, or completion evidence.

## Output

Feed the resulting workflow definition into `prompt_design/workflow_to_prompt_package_architect.md` when the implementation should be prompt/agent based, or into normal software/automation planning when infrastructure is the right executor.