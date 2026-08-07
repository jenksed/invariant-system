# Prototype to Answer One Design Question

A prototype is disposable code/artifact whose purpose is to answer one named question before production implementation commits to the answer.

## Frame the question first

State:

- the exact question;
- what observation would answer it;
- what the prototype intentionally will not prove.

If the question is vague, use grilling before building.

## Choose fidelity deliberately

Examples:

- state/logic uncertainty → interactive state model or narrow harness;
- UI uncertainty → several materially different variations that can be compared quickly;
- API/integration uncertainty → spike against a sandbox/fixture;
- performance uncertainty → measurement harness with representative data.

Use the cheapest artifact with enough fidelity to answer the question.

## Prototype rules

- mark it clearly as prototype/non-production;
- trivial to run;
- minimize persistence/infrastructure unless those are the question;
- expose relevant state/measurements visibly;
- skip production polish, broad error handling, abstractions, and unrelated tests;
- do not let prototype shortcuts leak into production by accident.

## Capture learning

When the question is answered, record:

- question;
- observed evidence;
- verdict/decision;
- remaining uncertainty;
- pointer to the prototype when preserving it is useful.

Fold the validated decision into the real plan/spec. The prototype is evidence, not the production implementation by default.

## Wayfinding

In a Wayfinding map, a prototype node resolves when its concrete artifact has produced enough evidence to answer the node's question. That resolution may unlock or invalidate later decision nodes.