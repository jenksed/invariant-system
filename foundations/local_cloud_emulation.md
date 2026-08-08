# Local Cloud Emulation

Status: draft

Local cloud emulation is an engineering method for answering cloud-dependent questions in a local, reproducible environment before escalating to a remote provider account.

The emulator is not the authority. It is an execution surface whose evidence must be scoped to the behavior it can actually reproduce.

## Purpose

Use local cloud emulation to make cloud-backed implementation, diagnosis, infrastructure validation, and agent execution:

- faster than repeated remote round-trips;
- safer than giving broad cloud credentials to an agent or local development loop;
- reproducible across engineers and CI jobs;
- inspectable through deterministic fixtures and receipts;
- explicit about what remains unproved until real-cloud verification.

## Core loop

1. **Discover the cloud dependency** — identify provider, services, operations, data-plane protocols, infrastructure tooling, and any container-backed engines involved.
2. **Choose the local surface** — prefer the smallest emulator/configuration that can answer the current engineering question.
3. **Establish fidelity scope** — record which required operations are supported and which semantics are known to differ from the provider.
4. **Build a deterministic fixture** — create only the resources and state required to reproduce or exercise the behavior.
5. **Execute the real-shaped path** — use the same SDK, CLI, protocol, or IaC interface the application normally uses wherever practical.
6. **Assert behavior and state** — verify externally observable effects rather than accepting successful API responses as sufficient proof.
7. **Reset and replay** — prove the environment can be reconstructed without hidden manual state.
8. **Escalate deliberately** — identify the smallest remaining question that requires a real cloud account and request explicit authorization before executing it.

## Evidence classes

Local cloud work should distinguish at least these evidence claims:

- **Protocol verified** — the client can make the required request through the emulator's provider-shaped interface.
- **Behavior verified** — the intended externally observable behavior occurred locally.
- **Fidelity scoped** — the exact operations and material emulator limitations were checked for the exercised path.
- **Cloud verified** — the behavior was independently exercised against the actual provider.

Do not collapse these into a single claim such as "AWS verified" or "works in cloud."

## Emulator selection

Prefer an emulator when it materially reduces risk or iteration cost and can answer the question with adequate fidelity.

Do not use an emulator as a substitute for:

- provider behavior explicitly documented as unsupported or divergent;
- production quotas, control-plane timing, regional behavior, IAM semantics, billing, or other provider-specific characteristics that the emulator does not reproduce;
- final cutover evidence when the acceptance contract explicitly requires the real provider.

## Agent safety boundary

When a supported local emulator can answer the engineering question, local execution is the default. Real-cloud mutation is an escalation.

An agent should not receive production credentials merely because cloud-shaped code is under development. Prefer dummy/local credentials and loopback endpoints until a named remaining question requires remote execution.

## Reproducibility rule

A successful local run is weak evidence if it depends on unknown pre-existing emulator state.

Completion-quality evidence should be reproducible from one of:

- a clean ephemeral environment plus versioned initialization fixtures;
- a documented snapshot with provenance and a deterministic restore procedure;
- a deliberately persistent development state whose required assumptions are enumerated and independently checked.

## Composition

This method is emulator-neutral. A Development Pack supplies concrete commands, endpoints, health checks, persistence behavior, known fidelity limits, and verification gates for a specific local-cloud implementation.

Floci is the first Project Arsenal implementation of this method, not part of the universal definition.

## Completion criterion

Local cloud emulation has done its job when the engineer or agent can state exactly what was proven locally, reproduce that proof from controlled state, identify the emulator assumptions involved, and name any remaining real-cloud verification without overstating the evidence.