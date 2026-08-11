"""Loader for the Project Arsenal governance source model.

The source model is a small JSON index that records:

* which artifacts in the repository carry which governance facts;
* the ownership layer of each artifact;
* the state role of each artifact;
* an optional materialization mode.

The loader imports the closed vocabularies from
``arsenal_governance`` and the JSON schema for the source model from
``arsenal_schema_registry`` rather than from
``arsenal.project.json``. Consumer configuration therefore cannot
redefine any of these values.

Structural enforcement model
---------------------------

The loader is the canonical authority for the source model's
structural contract. ``arsenal/source-model.schema.json`` documents
the contract; this module enforces it. The two are checked together
so the published schema and the runtime defense cannot drift:

* **Closed shape.** Each record type has a fixed, explicit
  ``ALLOWED_*_KEYS`` set. ANY key not in that set is rejected,
  including keys nobody anticipated (e.g. ``current_status``,
  ``banana``, ``cached_value``, ``operational_state``). The earlier
  ``FORBIDDEN_ARTIFACT_VALUE_KEYS`` blacklist is now a secondary,
  diagnostic-only layer: it produces a more specific error message
  for known domain-value-shaped keys but is NOT the fail-closed
  boundary.
* **Path vs path_pattern XOR.** Every artifact declares exactly one
  of ``path`` or ``path_pattern``. Both is rejected; neither is
  rejected.
* **One owner per fact.** Every fact has exactly one ``owner_artifact``.
  The state_role of that artifact tells us what kind of representation
  the fact is (normative/derived/historical/narrative); it is NOT
  correct to call every owner "normative".
* **Notes is non-authoritative.** The ``notes`` field is free-form
  documentation. Validators, projections, and governance queries
  must never consult it for domain truth.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import arsenal_governance
import arsenal_schema_registry

SOURCE_MODEL_PATH = Path("arsenal/source-model.json")

# Closed shape: every key on each record type MUST be in the
# corresponding set. Any other key is rejected by the loader.
ALLOWED_TOP_KEYS = frozenset(
    {"schema_version", "artifacts", "facts"}
)
ALLOWED_ARTIFACT_KEYS = frozenset(
    {
        "id",
        "path",
        "path_pattern",
        "ownership",
        "state_role",
        "materialization",
        "owns_facts",
        "notes",
    }
)
ALLOWED_FACT_KEYS = frozenset(
    {"id", "owner_artifact", "locator", "notes"}
)

# Diagnostic-only blacklist: produces a specific error message when
# the source model attempts to copy a known domain value, but is NOT
# the fail-closed boundary. Closed-shape enforcement above is the
# boundary; this list only sharpens the error.
FORBIDDEN_ARTIFACT_VALUE_KEYS = {
    "value",
    "schema_version",
    "supported_targets",
    "lifecycle",
    "evaluation",
    "evaluation_status",
    "adapter_version",
    "suite_id",
    "enabled_targets",
    "package_name",
    "capability_id",
    "primary_asset_sha256",
    "package_sha256",
}


def source_model_path(root: Path) -> Path:
    if root.is_file():
        return root
    return root / SOURCE_MODEL_PATH


def _load_schema_document(root: Path) -> dict:
    """Load the source-model JSON schema through the canonical registry.

    The registry resolves the canonical $id URL and the schema path;
    we only need the structural shape, which the registry already
    provides. This keeps consumer config out of the loop.
    """
    schema_id = arsenal_schema_registry.schema_id_for(
        root, arsenal_governance.SOURCE_MODEL_SCHEMA_NAME
    )
    schema_path = root / "arsenal" / "source-model.schema.json"
    if not schema_path.is_file():
        raise FileNotFoundError(
            f"missing source-model schema: {schema_path} (declared $id: {schema_id})"
        )
    with schema_path.open("r", encoding="utf-8") as f:
        return json.load(f)


def load_source_model(root: Path) -> dict:
    """Load and structurally validate the source model.

    Returns a normalized dict with sorted artifact and fact lists and
    the canonical schema document. The loader is the structural
    fail-closed boundary: unknown top-level, artifact, or fact keys
    are rejected. Semantic checks (closed vocabularies, duplicate
    identities, fact-owner uniqueness, pattern path existence) are
    delegated to ``validate_source_model``.
    """
    path = source_model_path(root)
    if not path.is_file():
        raise FileNotFoundError(
            f"missing source model: {path} -- the source model is canonical "
            f"governance data and must be checked in"
        )
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: source model must be an object")

    # Top-level closed shape.
    bad_top = sorted(set(data) - ALLOWED_TOP_KEYS)
    if bad_top:
        raise ValueError(
            f"{path}: unknown top-level key(s) {bad_top}; allowed: "
            f"{sorted(ALLOWED_TOP_KEYS)}"
        )

    if data.get("schema_version") != arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST:
        raise ValueError(
            f"{path}: unsupported schema_version {data.get('schema_version')!r}; "
            f"expected {arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST!r}"
        )

    artifacts = data.get("artifacts")
    facts = data.get("facts")
    if not isinstance(artifacts, list):
        raise ValueError(f"{path}: artifacts must be a list")
    if not isinstance(facts, list):
        raise ValueError(f"{path}: facts must be a list")

    for i, art in enumerate(artifacts):
        if not isinstance(art, dict):
            raise ValueError(f"{path}: artifacts[{i}] must be an object")
        # Closed shape: reject every key not on the allowed list.
        bad = sorted(set(art) - ALLOWED_ARTIFACT_KEYS)
        if bad:
            raise ValueError(
                f"{path}: artifacts[{i}] ({art.get('id')!r}) carries unknown "
                f"key(s) {bad}; the source model is closed-shape and only "
                f"permits: {sorted(ALLOWED_ARTIFACT_KEYS)}"
            )
        # Diagnostic-only: produce a sharper error for known
        # value-shaped keys, but the closed-shape check above is the
        # real boundary.
        leaked = sorted(set(art) & FORBIDDEN_ARTIFACT_VALUE_KEYS)
        if leaked:
            raise ValueError(
                f"{path}: artifacts[{i}] ({art.get('id')!r}) carries value-shaped "
                f"key(s) {leaked}; the source model is an index, not a copy of "
                f"domain values"
            )
        if "id" not in art:
            raise ValueError(f"{path}: artifacts[{i}] missing 'id'")
        if not (("path" in art) ^ ("path_pattern" in art)):
            raise ValueError(
                f"{path}: artifacts[{i}] ({art.get('id')!r}) must declare exactly "
                f"one of 'path' or 'path_pattern' (XOR); both present is rejected, "
                f"neither present is rejected"
            )

    for i, fact in enumerate(facts):
        if not isinstance(fact, dict):
            raise ValueError(f"{path}: facts[{i}] must be an object")
        bad = sorted(set(fact) - ALLOWED_FACT_KEYS)
        if bad:
            raise ValueError(
                f"{path}: facts[{i}] ({fact.get('id')!r}) carries unknown "
                f"key(s) {bad}; the source model is closed-shape and only "
                f"permits: {sorted(ALLOWED_FACT_KEYS)}"
            )

    # Sort for deterministic output and stable equality assertions.
    artifacts_sorted = sorted(artifacts, key=lambda a: a["id"])
    facts_sorted = sorted(facts, key=lambda f: f["id"])

    return {
        "schema_version": arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST,
        "schema_document": _load_schema_document(root),
        "artifacts": artifacts_sorted,
        "facts": facts_sorted,
        "source_path": str(path.relative_to(root)) if root.is_dir() else str(path),
    }


def resolve_pattern(artifact: dict, root: Path) -> list[Path]:
    """Resolve a ``path_pattern`` artifact into a deterministic list of paths.

    Patterns may match files OR directories (e.g.
    ``distribution/agent-skills/*`` resolves the family of generated
    package directories). This matches the validator's
    ``_check_paths`` semantics; the two agree on what counts as a
    "registered family". An empty result is returned when the pattern
    matches nothing -- callers that need strict existence should
    assert against the validator, which still rejects empty matches.
    """
    if "path" in artifact:
        return [root / artifact["path"]]
    pattern = artifact["path_pattern"]
    base = root
    if "/" in pattern:
        head, _, tail = pattern.partition("/")
        if head and head not in {".", ".."}:
            candidate = root / head
            if candidate.is_dir():
                base = candidate
                pattern = tail
    return sorted(base.glob(pattern))


def artifacts_for_fact(model: dict, fact_id: str) -> list[dict]:
    """Return the list of artifacts whose ``owns_facts`` includes ``fact_id``."""
    return [a for a in model["artifacts"] if fact_id in a.get("owns_facts", [])]
