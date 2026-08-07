# Diagnose a Bug Through a Tight Feedback Loop

Use for hard bugs, regressions, flakes, or performance failures where staring at code is likely to anchor the investigation.

## Governing rule

**Do not build a causal theory before you have a signal capable of detecting this exact bug.**

The first product of diagnosis is a tight feedback loop.

## Phase 1 — Build the loop

Prefer, roughly in this order:

1. failing behavior test at the highest useful seam;
2. CLI/HTTP reproduction script;
3. browser automation;
4. replay of captured request/event data;
5. small throwaway harness;
6. property/fuzz loop;
7. automated bisection/differential comparison;
8. structured human-in-the-loop script as last resort.

Tighten the loop until it is:

- **red-capable** — asserts the user's exact symptom;
- **repeatable** — deterministic, or for flakes has a sufficiently high measured reproduction rate;
- **fast** — short enough to run repeatedly;
- **agent-runnable** where possible.

Run it and preserve a red receipt before proceeding.

If no usable loop can be built, stop and state what evidence/access is missing rather than inventing a theory.

## Phase 2 — Reproduce and minimize

Confirm the loop catches the same failure the user reported.

Shrink inputs, state, callers, config, and steps one at a time while keeping the loop red. Stop when each remaining element is load-bearing.

## Phase 3 — Hypothesize

Create 3–5 ranked, falsifiable hypotheses.

For each, state the observable prediction that would be true if it caused the failure. Reject hypotheses that cannot produce a testable prediction.

Use relevant domain knowledge from the user to re-rank, but do not block if the user is unavailable and evidence is sufficient.

## Phase 4 — Probe

Test hypotheses one variable at a time.

Prefer debugger/REPL inspection, then targeted instrumentation at discriminating boundaries. Tag temporary debug instrumentation so cleanup is deterministic.

For performance regressions, measure/bisect with a baseline rather than spraying logs.

## Phase 5 — Regression test and fix

At the correct public seam:

1. turn the minimized repro into a failing regression test;
2. watch it fail;
3. implement the smallest correct fix;
4. watch it pass;
5. rerun the original feedback loop.

If no seam can express the real failure pattern, record that architecture limitation rather than adding a misleading test.

## Phase 6 — Cleanup and receipt

Before completion:

- original repro is green;
- regression test passes or missing seam is explicitly documented;
- temporary instrumentation is removed;
- root cause and falsified alternatives are summarized;
- resulting architecture follow-up is separated from the bug fix unless required for correctness.

The debugging report should name the loop command/artifact, root cause, fix, regression evidence, and any follow-up.