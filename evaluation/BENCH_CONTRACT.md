# Arsenal Bench Contract v0

Schema-Version: 1.0.0

Arsenal Bench is the executable evaluation layer for Capability Contract v2.

It exists to distinguish four things that are easy to blur together:

1. a capability is **well specified**;
2. an evaluation case is **healthy enough to judge it**;
3. a capability **passes that case**;
4. the capability **improves agent outcomes relative to a control or ablation**.

Those are different claims and require different evidence.

## Evaluation case

Every case records:

- stable case ID and title;
- evaluation track;
- capability under test;
- whether the case is active in the current campaign;
- execution mode and execution status;
- fixture / starting-state contract;
- control, treatment, and optional ablation definition;
- expected behavior or deterministic expected result;
- Case Health checks;
- metrics worth observing.

A case with `status: designed-not-run` may shape future evaluation work, but it contributes **zero executed cases** to a lifecycle gate.

## Case Health Receipt

An evaluation cannot become trustworthy merely because its verifier returned green.

For each executed case, the runner emits a Case Health Receipt covering all applicable checks declared by the case. Initial checks include:

- `starting_state_reproducible`;
- `failure_reachable`;
- `success_reachable`;
- `acceptance_observable`;
- `expected_outcome_explicit`;
- `solution_not_leaked`;
- `verifier_independent`;
- `no_remote_credentials`.

`HEALTHY` means every required check is supported for that run. `UNHEALTHY` means the case cannot contribute lifecycle evidence even if the treatment output happens to look correct.

This is the **evaluate the evaluator** rule.

## Counterfactual and ablation receipts

Every case has a comparison contract.

Supported comparison kinds in v0:

- `control-treatment`;
- `ablation`;
- `multi-arm`;
- `contract-counterfactual`.

The receipt separately records the execution state of each arm. An unexecuted control remains `designed-not-run`.

A deterministic `contract-counterfactual` can establish an invariant such as "unsupported Azure IaC stops instead of borrowing an AWS-only validator." It cannot establish that a model would have made the unsafe choice without Arsenal.

Therefore every receipt includes a `claim_scope`.

## Provenance contract

For agent/model comparisons, future executable runs must preserve at least:

- task and fixture ID;
- repository revision / starting-state digest;
- Arsenal revision and capability version;
- model and model version/family when known;
- harness and harness version when known;
- enabled tools;
- authority surface;
- context intervention;
- token / cost / wall-time budgets when measurable;
- verifier identity/version;
- repetition number / seed when available.

Unknown provenance is recorded as unknown. It is never invented.

## Metrics

Bench may record outcome, process, efficiency, and durability metrics. Initial vocabulary includes:

### Outcome

- correctness / acceptance pass;
- false completion;
- unsafe action prevented;
- unsupported claim prevented;
- regression status.

### Process

- scope drift;
- reproduction before repair;
- ambiguity caught;
- verification depth;
- human intervention;
- repair cycles.

### Efficiency

- tokens;
- cost;
- wall time;
- tool calls;
- context size.

### Durability

- rediscovery actions;
- continuation quality;
- repeatability;
- later regression behavior.

Missing metrics remain `not-observed`; they are not converted into zeroes.

## Lifecycle gates

A suite may declare a lifecycle gate.

For `testing`:

1. `minimum_executed_cases` must be a positive integer;
2. every `required_case_id` must exist;
3. every required case must be `active: true`;
4. every required case must have an executable mode in the current campaign;
5. the exact receipt must show each required case executed, healthy, and passing;
6. the capability must reference the registered suite asset;
7. the capability evaluation state must be `candidate` or `qualified`.

For `stable`, ARS-02 v0 deliberately does not define a one-campaign shortcut. Stable remains a later multi-campaign qualification claim.

## Loss retention

Bench must not delete or hide:

- failed treatment runs;
- baseline wins;
- ablation wins;
- neutral outcomes;
- increased token/cost usage;
- verifier disagreement;
- blocked runs;
- unhealthy cases;
- cases invalidated after a benchmark audit.

The question is whether Arsenal helps, where, and at what cost—not how to manufacture a flattering score.

## Capability Evidence Passport

Each executable receipt includes a compact `capability_passport` containing:

- capability ID and version;
- lifecycle/evaluation state observed from the repository;
- suite ID;
- executed / passed / failed / designed-not-run counts;
- current claim scope;
- known limitations;
- evidence file.

This is the v0 seed of **proof-carrying capabilities**. Later slices may add signatures, lockfile integration, cross-model history, cost profiles, and provenance attestations.

## Separation from future systems

ARS-02 owns evaluation evidence.

It does not yet own:

- compiler/export generation (`ARS-03`);
- capability dependency routing (`ARS-04`);
- generalized execution substrate selection (`ARS-05`);
- run observability / flight recording (`ARS-07`);
- authority enforcement and third-party trust (`ARS-08`);
- model routing from demonstrated competence (`ARS-10` and later).
