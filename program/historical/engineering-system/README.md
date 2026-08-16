# Engineering System

This repository coordinates **Project Arsenal**, **Loadout**, and **Kiln** as one product system. It is a program repository, not a fourth product and not a runtime dependency.

## The system

| Product | Question | Owns |
|---|---|---|
| [Arsenal](https://github.com/jenksed/project-arsenal) | What works? | Engineering intelligence, experimental methods, evaluation, qualification, and mechanism candidates |
| [Loadout](https://github.com/jenksed/loadout) | What can I do? | User experience, Workspaces, Goals, Capabilities, Skills, Packs, Catalog, and connector configuration |
| [Kiln](https://github.com/jenksed/kiln) | What actually happened, and may this pass? | Runs, runtime authority, effect execution, evidence, recovery, invalidation, and acceptance readiness |

The innovation flow branches:

- useful, repeatable, portable Arsenal methods may graduate into Loadout capabilities;
- necessary, objective, deterministically enforceable Arsenal findings may graduate into Kiln mechanisms.

The normal product experience is vertical:

1. a user states a Goal in Loadout;
2. Loadout resolves a Capability and creates a Work Envelope;
3. Kiln authorizes and records the Run;
4. Kiln returns a Run Result Envelope;
5. Loadout presents the result, evidence, and unresolved facts;
6. reviewed observations return to Arsenal for further learning.

> **Arsenal discovers what works. Loadout makes useful methods available. Kiln makes necessary truths unavoidable.**

## Repository scope

This repository owns only:

- accepted cross-product decisions;
- versioned boundary contracts and compatibility fixtures;
- the integrated proof scenario;
- launch gates and cross-repository work packages.

It must not contain product implementation, duplicate product roadmaps, model-specific business logic, or mutable narrative status that can be derived from GitHub.

## Current stage

**Launch-ready / final owner gate.** Static preparation is complete. No product writer begins until the combined prompt passes live environment preflight and the owner supplies the final authorization token in [program/LAUNCH-READINESS.md](program/LAUNCH-READINESS.md).

## Start here

1. [Product-system decision](decisions/0001-product-system.md)
2. [Current program state](program/PROJECT-STATE.md)
3. [Dependency map](program/DEPENDENCIES.md)
4. [Agent operating model](program/AGENT-OPERATING-MODEL.md)
5. [Launch readiness](program/LAUNCH-READINESS.md)
6. [Three work packages](program/work-packages/)
7. [First-wave launch package](program/launch/)
8. [Integrated proof](demo/90-DAY-PROOF.md)
