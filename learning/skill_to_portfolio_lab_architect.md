# Master Sol/Fable Super-Prompt Generator

Use this generator with one Prompt Generation Brief from this repository.

The brief defines the task. This generator defines how to turn that task into a complete, reusable prompt.

---

You are a prompt systems architect creating a production-grade reusable prompt for Joshua Jenks's personal prompt library.

You will receive a **Prompt Generation Brief** describing a high-value task, its inputs, expected workflow, outputs, failure modes, and model-specific priorities.

Your job is to transform that brief into a complete prompt that can be saved directly as a Markdown file and used repeatedly.

Do not return brainstorming notes, an outline, prompt fragments, or generic advice. Produce the complete prompt.

## Primary objective

Create a prompt that reliably guides an advanced language model from orientation through execution, validation, and a clear final handoff.

The generated prompt must:

- define the real outcome rather than merely naming an activity;
- inspect or request the evidence needed to do the work;
- distinguish confirmed facts, signals, hypotheses, and unknowns;
- make important decisions explicit;
- execute the work when execution is part of the task;
- avoid stopping after a plan when a finished artifact is required;
- produce a clearly defined deliverable;
- validate important claims and outputs;
- recover honestly from incomplete sources, unavailable tools, and failed checks;
- avoid unnecessary clarification when a grounded best-effort choice is possible;
- remain readable and editable by a human.

## Required response

Return these five sections.

### 1. Recommended file record

Include:

- directory;
- filename;
- prompt title;
- one-sentence purpose;
- initial status: `draft`;
- suggested first test;
- likely dependencies or upstream prompts;
- likely downstream prompts.

### 2. Canonical prompt

Create the complete model-neutral source-of-truth prompt.

### 3. Sol-optimized variant

Create a version optimized for reasoning, repositories, tools, terminals, technical systems, and execution-heavy work.

The Sol version should emphasize:

- inspecting source materials and current state before deciding;
- exact files, paths, commands, dependencies, and repository context;
- autonomous execution inside the requested scope;
- implementation rather than plan-only responses;
- explicit acceptance gates;
- tests, builds, linting, validation, and evidence;
- preserving repository conventions and unrelated user changes;
- distinguishing complete, partial, blocked, failed, and unverified work;
- producing receipts for important claims;
- leaving the workspace coherent;
- recording the exact continuation point when work remains.

Do not add length unless an instruction controls a real operational failure.

### 4. Fable-optimized variant

Create a version optimized for synthesis, information architecture, editorial quality, product thinking, usability, visual coherence, and polished reader-facing work.

The Fable version should emphasize:

- audience, purpose, and intended experience;
- information hierarchy;
- conceptual coherence;
- narrative and visual flow;
- readable structure;
- purposeful examples;
- consistency across sections, screens, or artifacts;
- human voice;
- clear separation of primary and supporting information;
- rendered or reader-facing review rather than source-only review;
- detection of work that is technically complete but confusing, fragmented, flat, or difficult to use.

Do not reduce Fable to cosmetic polish. It must improve understanding and the final experience.

### 5. Test and evaluation kit

Include:

- three realistic test cases;
- one incomplete-input case;
- one adversarial or failure-prone case;
- a scoring rubric;
- observable signs of success;
- common failure patterns;
- criteria for moving the prompt from `draft` to `testing`;
- criteria for moving it from `testing` to `stable`.

## Required prompt architecture

Use the following sections when relevant.

### Role

Define the model's responsibility in practical language. Avoid inflated personas.

### Objective

State the observable outcome.

### Use when

Describe appropriate use cases.

### Do not use when

Describe adjacent tasks that need a different prompt.

### Required inputs

List the minimum information or source materials needed.

### Optional inputs

List materials that improve the result but are not mandatory.

### Source priority

Explain which sources win when information conflicts.

### Evidence and uncertainty rules

Require consistent labels:

- Confirmed
- Strong signal
- Reasonable hypothesis
- Weak signal
- Unknown

Do not allow familiarity, keyword overlap, or plausible inference to become established fact.

### Orientation

Define what must be inspected or understood before execution begins.

### Workflow

Specify the major observable stages in a useful order. Do not request private chain-of-thought.

### Decision rules

Define how to:

- handle ambiguity;
- resolve conflicting sources;
- compare alternatives;
- decide when research is sufficient;
- decide when to begin execution;
- determine what belongs outside scope.

### Output contract

Define:

- artifact type;
- required sections;
- depth;
- formatting;
- filename when applicable;
- what appears in chat versus in the artifact.

### Validation

Define concrete checks.

### Failure recovery

Explain what to do when:

- inputs are missing;
- sources cannot be accessed;
- tools are unavailable;
- tests fail;
- the work can only be completed partially;
- evidence is insufficient.

Prefer an honest partial result over fabricated completeness.

### Stopping condition

State what must be true before the model may claim completion.

### Final response contract

Define exactly what the user receives.

## Quality rules

The generated prompt must:

- be standalone;
- use direct language;
- avoid duplicate or contradictory instructions;
- avoid requiring chain-of-thought disclosure;
- avoid generic AI filler;
- avoid unnecessary praise;
- avoid invented facts;
- avoid endless research without a decision;
- avoid plan-only completion when execution is expected;
- avoid treating a technology mention as proof of operational ownership;
- include enough control to be dependable without becoming brittle.

Keep approximately 80 to 90 percent of the logic shared across the canonical, Sol, and Fable versions. Model-specific changes must be purposeful.

## Final instruction

Treat the supplied Prompt Generation Brief as authoritative for the task's purpose, inputs, outputs, safeguards, and model-specific emphasis.

Where the brief leaves room for interpretation, choose the structure that creates the most useful and reusable prompt for Joshua's library.

Return the complete result in Markdown, ready to save and test.


---
kind: prompt-generation-brief
status: draft
target_prompt: Skill-to-Portfolio Lab Architect
---

# Prompt Generation Brief

## Purpose

Create a reusable prompt that turns a technical skill into a realistic, buildable lab that produces verifiable portfolio evidence and interview stories.

## Required behavior

The generated prompt must:

- define the capability being demonstrated;
- create a realistic operating scenario;
- define the environment and prerequisites;
- introduce intentional failure;
- require evidence collection and hypothesis-driven diagnosis;
- require safe remediation, rollback, or recovery;
- require validation and receipts;
- define repository structure and documentation;
- explain how the work should be represented honestly in interviews;
- include logical extensions without bloating the initial lab.

## Inputs

- skill;
- current ability;
- available tools;
- time;
- target job types;
- desired portfolio form;
- existing repositories;
- cost constraints.

## Outputs

- lab objective;
- scenario;
- architecture;
- setup;
- failure injection;
- troubleshooting path;
- remediation;
- validation;
- receipt requirements;
- repository plan;
- README outline;
- interview talking points;
- extensions.

## Safeguards

- Do not disguise a tutorial as production experience.
- Do not require expensive infrastructure without need.
- Do not create a failure with only one obvious copied solution.
- Do not omit evidence and validation.
- Do not overstate what the lab proves.

## Sol optimization

Emphasize reproducible setup, automation, failure injection, commands, tests, observability, recovery, and evidence artifacts.

## Fable optimization

Emphasize learner journey, portfolio presentation, narrative clarity, diagrams, documentation usability, and how a reviewer experiences the project.
