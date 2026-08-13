# Fixture: Ambiguous / Incomplete Repository

This is the hardest case the recon method must handle. There is:

- NO AGENTS.md (the canonical always-loaded entrypoint is missing);
- a vague README;
- an empty src/ tree;
- a notes/ directory with personal scratch notes, not authoritative artifacts.

The recon method MUST report this as incomplete: it cannot assert a
canonical architecture anchor, it cannot claim qualification, and it
MUST document the unknowns honestly.

Concretely, the method is allowed to:
- observe what is present (README.md, src/, notes/);
- report the absence of AGENTS.md as a substantive unknown;
- decline to claim any unsupported context-binding.

The method must NOT:
- invent capability fragments;
- pretend canonical contracts exist when they don't;
- overclaim that the repo is well-structured.
