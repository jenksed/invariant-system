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

# Ownership layers answer: "who controls/owns the source of this
# artifact?"
#
# ``arsenal-protocol``     -- core protocol/execution vocabulary,
#                             canonical schemas, architecture doctrine.
# ``arsenal-distribution`` -- Arsenal's distribution identity
#                             (target support, schema registry).
# ``consumer-deployed``    -- per-repository configuration, generated
#                             accepted pin/identity state, and
#                             per-repo historical/qualification
#                             artifacts.
#
# Note: the old four-layer prose labeled "Layer 4 -- Fixtures, tests,
# historical evidence". This slice separates ownership from epistemic
# role: there is no fourth ownership layer. "Historical" is captured
# exclusively by ``state_role``.
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
