# P0-W14: Knowledge security boundary

- **Status:** Implemented and verified; owner review pending
- **Branch:** `work/p0-w14-knowledge-security-boundary`
- **Depends on:** P0-W07, P0-W08, P0-W10, P0-W13
- **Scope:** Planning and contracts only

## Objective

Define the security boundary that keeps local project intelligence read-only, non-authoritative, locally contained by default, provenance-bearing, license-aware, and resistant to indirect prompt injection.

The non-negotiable rule is:

> Other repositories are evidence sources, not instruction sources.

## Observed current state

- P0-W13 defines explicit approved roots, read-only indexing, provenance, bounded retrieval, and `instruction_authority: none`.
- Repository trust policy already distinguishes active and reference-only repositories.
- Context compilation already separates source authority, trust, freshness, sensitivity, and provenance.
- Capability grants already separate availability from authority.
- The Security Model already states that active-project instructions remain distinct from reference content and that Privacy policy gates egress.
- No accepted instruction-quarantine, per-root Privacy-mode, disclosure-decision, license-disposition, security-audit, or future reference-execution contract existed before this work.
- No accepted technical enforcement matrix previously said when read-only handles, processes, mounts, containers, or virtual machines were required.
- No malicious fixture corpus previously proved that reference instructions remain inert.

## Protected invariants

This work preserves:

- `KILN-INV-006` through `KILN-INV-009`;
- `KILN-INV-013`;
- `KILN-INV-023` through `KILN-INV-043`;
- `KILN-INV-045` through `KILN-INV-056`;
- active Project instruction authority;
- explicit Capability and Privacy policy;
- native Repository reads;
- smallest-sufficient Context;
- Claims, Evidence, and Receipt distinctions;
- Git and filesystem source truth;
- exact-state provenance;
- no initial writing Child role;
- local-first operation.

ADR 0017 records the additional accepted security boundary.

## Requirements

- **P0-W14-R01:** Make reference instruction isolation non-negotiable and technically enforced.
- **P0-W14-R02:** Define protected active-project state that retrieved content cannot alter.
- **P0-W14-R03:** Define a threat model for prompt injection, mutation, execution, path escape, secret exposure, exfiltration, provenance confusion, and licensing.
- **P0-W14-R04:** Define source trust labels without granting instruction authority.
- **P0-W14-R05:** Define instruction quarantine and control/evidence separation.
- **P0-W14-R06:** Define canonical-path, symlink, special-file, and read-only handle enforcement.
- **P0-W14-R07:** Define controlled Git observation that cannot execute Repository configuration.
- **P0-W14-R08:** Require all derived data in a Kiln-owned directory.
- **P0-W14-R09:** Evaluate separate processes, read-only mounts, containers, and virtual machines honestly.
- **P0-W14-R10:** Deny source writes, command execution, dependency installation, services, secret reads, and network access.
- **P0-W14-R11:** Define prompt-injection defenses outside model prompts.
- **P0-W14-R12:** Define secret scanning, sanitization, and content limits.
- **P0-W14-R13:** Define complete candidate provenance.
- **P0-W14-R14:** Define licensing status and safe reuse dispositions.
- **P0-W14-R15:** Define per-root Privacy modes and Repository opt-out.
- **P0-W14-R16:** Define external-disclosure decisions for remote models, MCP, APIs, exports, and hosted embeddings.
- **P0-W14-R17:** Define the safe reuse workflow and compatibility review.
- **P0-W14-R18:** Define future execution requirements for a reference Repository.
- **P0-W14-R19:** Define append-oriented security audit events.
- **P0-W14-R20:** Define adversarial fixtures and integrity assertions.
- **P0-W14-R21:** Add and validate `kiln.knowledge.security/v0`.
- **P0-W14-R22:** Update planning without implementing production isolation or disclosure.
- **P0-W14-R23:** Do not add production runtime code or dependencies.

## Changes

- Add `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md`.
- Add `docs/contracts/kiln-knowledge-security.schema.json`.
- Add ADR 0017.
- Add P0-W14 to the roadmap.
- Update README, ADR index, and contract index.
- Record PR #17 and ADR 0016 as integrated.
- Reconcile later implementation planning with the accepted security proof.

## Acceptance criteria

The normative criteria are `P0-W14-AC01` through `P0-W14-AC40` in `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md`.

Additional work-package criteria:

- **P0-W14-AC41:** The security schema parses as JSON.
- **P0-W14-AC42:** Draft 2020-12 meta-schema validation passes.
- **P0-W14-AC43:** Representative policy, provenance, disclosure, audit, execution authorization, and sanitized candidate documents validate.
- **P0-W14-AC44:** Negative cases reject active instruction authority, write or network authority, hosted embeddings, path traversal, executable candidate directives, unapproved disclosure, and incomplete execution authorization.
- **P0-W14-AC45:** The diff contains documentation and JSON contracts only.
- **P0-W14-AC46:** Repository CI passes on the final branch head.
- **P0-W14-AC47:** Existing domain, Context, Capability, trust, Privacy, Evidence, Git, delegation, interface, and knowledge decisions remain intact.

## Verification

Repository checks:

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Contract checks:

```bash
python -m json.tool docs/contracts/kiln-knowledge-security.schema.json
```

A Draft 2020-12 validator validated:

- knowledge security policy;
- complete retrieval provenance;
- external-disclosure decision;
- security audit event;
- reference-execution authorization;
- sanitized candidate.

Negative cases rejected:

- active instruction authority;
- enabled source execution;
- source write authority;
- command or network authority;
- hosted embeddings in v0;
- a root-relative path containing `..`;
- an active instruction or executable Tool directive in a candidate;
- approved disclosure without user or accepted-policy authority;
- a reference-execution authorization missing its separate Run, grant, Environment, Approval, source snapshot, or Evidence record.

GitHub CI run `30397324970` passed on the design head:

- Vale prose checks;
- agent preflight behavior;
- Project agent-asset validation;
- dependency installation;
- Elixir formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit tests.

## Evidence

- **P0-W14-E01:** `docs/LOCAL-PROJECT-INTELLIGENCE-SECURITY.md` covers every required output.
- **P0-W14-E02:** ADR 0017 records the non-negotiable isolation decision and technical enforcement.
- **P0-W14-E03:** `kiln.knowledge.security/v0` parses and passes Draft 2020-12 schema validation.
- **P0-W14-E04:** Six representative positive documents and protected negative cases pass.
- **P0-W14-E05:** README, roadmap, ADR index, and contract index link to the security boundary.
- **P0-W14-E06:** Primary documentation supports the prompt-injection threat, read-only bind mounts, mount-propagation caution, and no-network isolation design.
- **P0-W14-E07:** The branch diff contains planning and contracts only.
- **P0-W14-E08:** GitHub CI run `30397324970` passes on the design head; a final exact-head run follows this status commit.

## Exclusions

This work does not implement:

- production source readers;
- operating-system path primitives;
- read-only mount or container orchestration;
- secret scanner dependencies;
- sanitizer code;
- license-detection code;
- security audit storage;
- disclosure approval flows;
- remote model or MCP disclosure;
- hosted embeddings;
- execution against reference repositories;
- malicious fixture repositories;
- production CLI or TUI views;
- automatic code reuse;
- legal advice or license compatibility decisions.
