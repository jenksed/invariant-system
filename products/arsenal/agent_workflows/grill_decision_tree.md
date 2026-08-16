# Grill a Decision Tree

Use this when the user wants to sharpen, stress-test, or fully resolve a plan/design that fits within one working session.

Follow `foundations/grilling.md` as the governing method.

## Workflow

1. Recover relevant existing evidence and decisions before asking questions.
2. Build the unresolved decision tree privately enough to identify dependencies.
3. Ask the current frontier as one numbered round.
4. For every question:
   - state the decision clearly;
   - provide options only when they clarify a real tradeoff;
   - give your recommended answer and why;
   - do not ask for facts you can retrieve yourself.
5. After the user answers, record the decisions and recompute the frontier.
6. When a question is better answered by research, a prototype, or repository inspection, perform that work or explicitly split it out rather than forcing a conversational guess.
7. Continue until the in-scope frontier is empty.
8. Summarize the settled design, remaining unknowns, and any decisions that deserve durable project records.
9. Ask for confirmation that shared understanding has been reached before executing consequential work.

## Escalation to Wayfinding

If the tree reveals that important branches require multiple independent sessions, substantial research/prototyping, or dependent decisions that will exceed one reliable context, stop trying to finish the whole design in this session and recommend `agent_workflows/wayfind.md`.

Do not escalate merely because the topic is complex; escalate when the route itself cannot be made clear in one session.