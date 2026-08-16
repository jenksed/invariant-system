# Trust and provenance source audit

Audit date: 2026-08-08

Scope: upstream standards and ecosystem surfaces that materially affect ARS-08 Trust & Authority Plane decisions.

## Agent Skills

Source: https://agentskills.io/specification

The Agent Skills specification defines `allowed-tools` as an optional, experimental field for pre-approved tools, and notes that support can vary by implementation.

Arsenal decision:

- parse an understood subset only as an authority **signal**;
- preserve unknown expressions for review;
- never treat the field as proof that a harness will enforce the boundary;
- never let a familiar Skill package format bypass quarantine.

GitHub also describes Agent Skills as an open standard and supports project/personal skill discovery across several locations:

https://docs.github.com/en/copilot/concepts/agents/about-agent-skills

That increases the usefulness of a package-neutral competence audit because third-party skills can now move across multiple agent surfaces.

## GitHub artifact attestations

Sources:

- https://docs.github.com/en/actions/concepts/security/artifact-attestations
- https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations
- https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/verify-attestations-offline

GitHub artifact attestations bind build provenance to artifact digests and expose repository/workflow/commit/event identity through signed claims. GitHub uses Sigstore for the mechanism and supports offline verification.

The GitHub documentation also makes an important distinction: an attestation is not a guarantee that the artifact is secure. Consumers still need policy criteria and an explicit risk decision.

Arsenal decision:

- preserve this separation between **provenance evidence** and **trust/authority policy**;
- do not claim that a signed third-party skill is safe merely because its origin is cryptographically attributable;
- leave GitHub-attestation verification as a later adapter rather than adding write-capable attestation infrastructure to ARS-08 v0 CI.

## Sigstore

Sources:

- https://docs.sigstore.dev/about/bundle/
- https://docs.sigstore.dev/cosign/verifying/verify/

Sigstore bundles are designed to carry the verification material and signed content needed to verify an artifact signature. Verification can also bind expected certificate identity/issuer or a supplied trust chain.

Arsenal decision:

- future provenance adapters should retain the verification bundle or stable evidence reference rather than reducing it to a boolean;
- trust roots and expected identities must be policy inputs;
- ARS-08 v0 does not emit a `sigstore_verified` claim because it does not perform that verification yet.

## SLSA 1.2

Sources:

- https://slsa.dev/spec/v1.2/
- https://slsa.dev/spec/v1.2/provenance
- https://slsa.dev/spec/v1.2/verifying-artifacts
- https://slsa.dev/spec/v1.2/verifying-source
- https://slsa.dev/spec/v1.2/verification_summary

SLSA 1.2 is the current approved specification as of this audit. Its verification model explicitly compares provenance to expectations and a configured root of trust; the 1.2 release also includes a Source Track and Verification Summary Attestation model.

Arsenal decision:

- borrow the expectation-driven verification model;
- distinguish exact-byte integrity, source identity, builder/signer identity, and policy;
- do not claim SLSA levels for agent skills or prompt packages;
- allow future adapters to consume provenance/VSA evidence when the package-production path actually supports it.

## Resulting ARS-08 principle

```text
provenance tells us what artifact/source/builder claim we can verify
+
review tells us what competence/authority we believe the exact bytes request
+
policy tells us what we are willing to authorize
=
trust decision
```

None of those terms substitutes for the others.
