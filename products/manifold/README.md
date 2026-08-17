# Manifold

Intelligence selection and allocation for Invariant.

## Purpose

Given a role requirement, task characteristics, runtime constraints, and
qualification evidence, decide **which qualified intelligence configuration
should perform this work now**.

## Inputs

- Role requirement (what the work demands)
- Task characteristics (shape, risk, context needs)
- Runtime constraints (cost, latency, availability, tooling)
- Qualification evidence (Bench receipts, Capability Evidence Passports,
  Qualified Method Records)

## Output

An intelligence assignment / selection decision, with the evidence it was
based on.

## Boundary

- **Bench** (inside Arsenal) asks: *Can this configuration perform this
  role?* — it produces qualification evidence.
- **Manifold** asks: *Which qualified configuration should perform it now?* —
  it consumes that evidence to select.
- **Kiln** asks: *Is the work authorized, and what actually happened?* — it
  governs execution and records truth.

## Non-authority

Manifold must not:

- execute work;
- mutate repositories;
- grant or expand Kiln authority;
- qualify models (that is Bench's job);
- fabricate or launder evidence;
- become a generic workflow engine or agent-fleet manager.

## Status

Activated selection-only runtime: `src/selector.py` + `tests/test_selector.py`;
boundary enforced by `./invariant check boundaries`. The selector is
stdlib-only data in/out — no process, network, environment, or sibling-product
surface — and Manifold still owns no execution authority, mutation, qualification,
or orchestration. Manifold continues to grow only when Invariant Development
Loop v0 needs selection among more than one qualified intelligence
configuration; the activated surface here is the minimal runtime allowed to
support that bounded decision.
