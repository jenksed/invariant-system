# Cloud Execution Boundary

Status: draft

The **Cloud Execution Boundary** defines when cloud-shaped work may stay local and when an agent or engineer is allowed to cross into a real provider account.

The default is not "never touch the cloud." The default is **use the lowest-blast-radius execution surface that can answer the current question**.

## Boundary states

### Local

Use a local emulator, local container engine, fake credentials, loopback endpoints, and controlled fixtures.

This is the preferred state for:

- normal implementation loops;
- cloud SDK integration work;
- most infrastructure syntax/provisioning checks;
- reproduction of supported provider behavior;
- destructive experiments;
- agent-driven exploration;
- CI scenarios that do not require provider-only semantics.

### Remote non-production

Use a specifically authorized sandbox, test account, project, subscription, or tenancy when the remaining acceptance claim cannot be established locally.

Remote execution should be scoped by:

- account/project/subscription/tenancy;
- region;
- credentials and role;
- allowed services/actions;
- cost/time ceiling where material;
- cleanup responsibility;
- evidence to collect.

### Production

Production mutation is a distinct escalation and must never be inferred from permission to use a sandbox or from the existence of credentials.

Follow the repository's production change, review, deployment, and rollback controls.

## Escalation test

Before crossing from local to remote, answer:

1. **What exact question remains unanswered locally?**
2. **Why can the emulator not answer it?** Cite an unsupported operation, semantic gap, environmental dependency, or explicit acceptance requirement.
3. **What is the smallest remote scope that can answer it?**
4. **What mutation is required?** Prefer read-only or disposable resources where possible.
5. **What evidence will close the question?**
6. **How will resources and credentials be cleaned up or revoked?**

If these cannot be stated, the remote execution is not yet justified.

## Credential rule

Do not place real cloud credentials in an agent context merely for convenience.

Prefer:

1. local dummy credentials;
2. narrowly scoped temporary sandbox credentials;
3. brokered/tool-mediated capabilities that hide raw secrets;
4. production credentials only through the repository's explicit deployment mechanism.

Credentials prove authorization, not intent. A harness should still constrain destructive or high-impact operations even when credentials technically allow them.

## IaC rule

Infrastructure-as-code should normally pass local syntax/static validation and any supported emulator-backed provisioning checks before a remote plan/apply.

A local apply is not evidence that the provider will accept every resource or semantic. The fidelity ledger determines what the local result earns.

## Failure rule

Do not silently "fall back to AWS/Azure/GCP/OCI" when a local emulator returns an unsupported operation. Treat unsupported fidelity as a visible boundary condition and decide whether to:

- redesign the local test;
- test a smaller invariant;
- use a different local component;
- explicitly escalate to a remote sandbox.

## Completion criterion

The execution boundary is respected when every real-cloud mutation can be traced to a named unanswered question, explicit authorization and scope, bounded credentials/capabilities, and a defined evidence/cleanup result.