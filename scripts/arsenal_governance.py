"""Canonical governance vocabulary for Project Arsenal.

This module is the single source of truth for the closed vocabularies that
the Governance Compression 01 slice uses. They are intentionally separate
from ``arsenal_protocol.py`` so PR #24's protocol/execution vocabularies
(authority tokens, substrates, lifecycle/evaluation states, invocation,
mutation classes, resource roles/loads) remain the domain of the
core protocol module.

Three small vocabularies are defined here:

* ``OWNERSHIP_LAYERS`` -- who controls/owns the source of an artifact;
* ``STATE_ROLES`` -- what relationship an artifact has to the truth it
  carries;
* ``MATERIALIZATION_MODES`` -- how the artifact was produced
  (``authored`` vs ``generated``); this is optional metadata, not a
  state-role.

The vocabularies are deliberately small and frozen. Adding a new token
requires changing this file, its schema, and the canonical
characterization tests in ``test-arsenal-shared.py`` and
``test-arsenal-governance.py``.

Consumer configuration cannot redefine any of these vocabularies: the
governance loader imports from this module rather than from
``arsenal.project.json``.
"""

from __future__ import annotations

# Schema identity for the source-model schema. The loader in
# ``arsenal_source_model.py`` resolves it through
# ``arsenal_schema_registry.schema_id_for`` and refuses to proceed if
# the registry does not list it.
SOURCE_MODEL_SCHEMA_NAME = "governance-source-model"
SOURCE_MODEL_SCHEMA_VERSION = "1.0.0"

# The single machine-readable source-assignment file owned by Arsenal
# governance. It is the *index* of where facts live, not a duplicate
# copy of the facts themselves. See ``source-model.schema.json``.
SOURCE_MODEL_PATH = "arsenal/source-model.json"

# Ownership layers answer: "who is permitted to define or change
# this artifact?" (NOT "who consumes it" and NOT "what is the
# subject of this artifact?").
#
# The three layers are deliberately narrow. They partition the
# repository so that a single contributor question -- "is this
# canonical protocol semantics, canonical Project Arsenal
# distribution content, or per-consumer deployment state?" --
# answers unambiguously.
#
# ``arsenal-protocol``     -- universal Arsenal protocol semantics:
#                             closed vocabularies, schemas that define
#                             what valid Arsenal data IS, and the
#                             architecture doctrine that sets the
#                             ownership/state-role boundaries
#                             themselves. These define what a valid
#                             fragment, receipt, manifest, lockfile,
#                             or source-model looks like; they do
#                             not own which concrete instances
#                             Project Arsenal currently ships.
# ``arsenal-distribution`` -- canonical Project Arsenal distribution
#                             content: concrete Project Arsenal-owned
#                             capability fragments, the merged asset
#                             registry, the compiler export plan, the
#                             supported targets, the generated
#                             distribution packages, Project
#                             Arsenal's own qualification evidence
#                             and field-trial fixtures/reports, and
#                             Project Arsenal's own program
#                             roadmaps. A consumer project installs
#                             or compiles these artifacts but does
#                             not redefine them; a fork or vendor
#                             must publish its own content under its
#                             own source-model.
# ``consumer-deployed``    -- per-repository deployment state that a
#                             particular installation selects,
#                             accepts, pins, or configures. Today
#                             this is just ``arsenal.project.json``
#                             and ``.arsenal.lock``. The lockfile is
#                             a canonical generated+normative
#                             counter-example: it is produced by
#                             the compiler but the consumer
#                             installation owns and accepts it.
#
# Important anti-patterns:
#
# * Do NOT classify an artifact as consumer-deployed merely because
#   a consumer may eventually install it. If an artifact is
#   identical regardless of which consumer installed Project
#   Arsenal, it is arsenal-distribution, not consumer-deployed.
# * Do NOT classify an artifact as consumer-deployed merely because
#   it is "checked into the consumer's working tree". The
#   repository that contains this source model is Project
#   Arsenal's own repository; its content is
#   arsenal-distribution unless the artifact is one of the
#   consumer's two narrow choices.
# * Do NOT classify an artifact as arsenal-distribution merely
#   because it is "generated by Project Arsenal's compiler". The
#   competence lockfile is generated by the compiler but
#   consumer-deployed: the consumer accepts it as its pin. By
#   contrast, the generated distribution packages are
#   arsenal-distribution because they are Project Arsenal's
#   published output and a consumer's copy of them is a
#   downstream install, not a per-deployment state.
# * Do NOT use ownership to encode the SUBJECT of an artifact.
#   The KFT-0 field-trial fixture's subject is Kiln, but the
#   owner is Project Arsenal: Project Arsenal decides whether
#   the fixture is published, updated, or rewritten.
#
# Note: the old four-layer prose labeled "Layer 4 -- Fixtures,
# tests, historical evidence". This slice separates ownership from
# epistemic role: there is no fourth ownership layer. "Historical"
# is captured exclusively by ``state_role``.
OWNERSHIP_LAYERS = frozenset(
    {
        "arsenal-protocol",
        "arsenal-distribution",
        "consumer-deployed",
    }
)

# State roles answer: "what relationship does this artifact have to
# the truth it carries?"
#
# ``normative``   -- the artifact is the source of truth for the facts
#                    it owns within its scope. May legitimately change
#                    under its own strict schema (lifecycle, evaluation,
#                    lock state are all normative in this sense).
# ``derived``     -- a deterministic projection of one or more
#                    normative sources. Drift is a bug, not a status.
# ``historical``  -- a record of what was observed, decided, executed,
#                    or true at a specific point/state. Its value is
#                    provenance; it must not be rewritten merely
#                    because current truth has changed.
# ``narrative``   -- human-oriented explanation, rationale, or
#                    commentary. May reference normative facts but must
#                    not become the only machine-relevant source of
#                    mutable current state.
#
# These tokens are NOT lifecycle/evaluation states. Lifecycle and
# evaluation remain in ``arsenal_protocol.LIFECYCLE_STATES`` and
# ``arsenal_protocol.EVALUATION_STATES``.
STATE_ROLES = frozenset(
    {
        "normative",
        "derived",
        "historical",
        "narrative",
    }
)

# Materialization modes are an optional per-artifact attribute that
# records how the artifact was produced. They are deliberately
# separate from state role so that an artifact can be, for example,
# ``generated + normative`` (the consumer-accepted competence
# lockfile) or ``generated + historical`` (a qualification receipt).
#
# This vocabulary is intentionally minimal. If a future slice needs a
# new value, add it here and update the characterization tests.
MATERIALIZATION_MODES = frozenset(
    {
        "authored",
        "generated",
    }
)

# Required schema-version const for the source model.
SOURCE_MODEL_SCHEMA_VERSION_CONST = "1.0.0"

# Exit codes reused by ``arsenal_source_validate.py``. They extend
# ``arsenal_protocol.EXIT_CODE`` (a PASS becomes a zero exit). New
# failure codes are named below so callers do not have to learn a new
# taxonomy.
EXIT_CODE = {
    "PASS": 0,
    "MISSING_MODEL": 8,        # source-model file or schema is absent
    "SCHEMA_VIOLATION": 2,     # model fails its own JSON Schema
    "INVALID_REFERENCE": 3,    # registered artifact/fact does not exist
    "DUPLICATE_IDENTITY": 4,   # duplicate artifact or fact id
    "ROLE_VIOLATION": 5,       # role/ownership/mat value not in vocab
    "CONFLICTING_OWNER": 6,    # a fact has more than one normative owner
    "UNKNOWN": 8,
}
