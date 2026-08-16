# Conformance Scaffold

This directory seeds future deterministic validation of Development Packs and Quality Compiler data.

## Current fixtures

- valid Development Pack Manifest;
- Critical Assurance escalation;
- introduced compiler Finding;
- empirical Evidence Contribution;
- Critical Verification Obligation.

## Required future negative corpus

Protocol:

- malformed frame;
- wrong byte count;
- invalid UTF-8;
- digest mismatch;
- oversized request;
- unknown operation;
- timeout;
- cancellation;
- Pack crash;
- partial response then crash;
- forbidden authority request.

Findings:

- line movement;
- file rename;
- wording change;
- duplicate similar Findings;
- ambiguous candidate;
- fingerprint version migration.

Impact:

- indirect dependency miss;
- dynamic dispatch;
- config change;
- generated public API;
- full-fallback requirement.

Assurance:

- Rapid request escalated by Critical path;
- budget cannot satisfy Critical;
- explicit waiver;
- non-waivable unknown effect.

## Success rule

A Pack does not conform merely because it can execute its happy path. Conformance must prove bounded failure, truthful unknown state, raw-output preservation, and no authority expansion.
