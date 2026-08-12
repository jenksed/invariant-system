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
the contract; this module enforces it. The two are kept in lock-step:

* **Closed shape.** Each record type has a fixed, explicit
  ``ALLOWED_*_KEYS`` set. ANY key not in that set is rejected,
  including keys nobody anticipated (e.g. ``current_status``,
  ``banana``, ``cached_value``, ``operational_state``).
* **Required fields, types, and identifiers.** Every schema-required
  field is checked. Wrong types and invalid identifiers (uppercase,
  leading invalid character, too short, whitespace, path-like) are
  rejected.
* **Uniqueness.** ``owns_facts`` is ``uniqueItems``; the loader
  rejects duplicate fact ids inside one artifact.
* **Path vs path_pattern XOR.** Every artifact declares exactly one
  of ``path`` or ``path_pattern``. Both is rejected; neither is
  rejected. The repository-relative safety primitive
  ``arsenal_io.safe_repo_path`` is used for both shapes so loader
  and validator cannot disagree.
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
import re
from pathlib import Path
from typing import Any

import arsenal_governance
import arsenal_io
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

# Schema-derived structural rules. The loader enforces exactly the
# same constraints the published schema declares. Keeping this list
# in one place makes drift visible: any future schema change here is
# caught by the ``test_source_model_loads_against_canonical_schema``
# characterization test.
ID_PATTERN = r"^[a-z][a-z0-9.-]*$"
ID_MIN_LENGTH = 3

# Required fields beyond what the schema already marks closed-shape.
REQUIRED_ARTIFACT_FIELDS = (
    "id",
    "ownership",
    "state_role",
    "owns_facts",
)
REQUIRED_FACT_FIELDS = ("id", "owner_artifact")

# Fields whose declared JSON type is a string (not optional, no
# list/object allowed). ``materialization`` is optional and may be
# absent; the remaining string fields are required.
ARTIFACT_REQUIRED_STRING_FIELDS = ("ownership", "state_role")
ARTIFACT_OPTIONAL_STRING_FIELDS = ("materialization",)


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


def _check_id(value: Any, *, location: str) -> str:
    """Validate an identifier against the schema's id contract.

    The schema declares ``pattern: ^[a-z][a-z0-9.-]*$`` with
    ``minLength: 3``. Anything else (uppercase, leading invalid
    character, whitespace, slash, too short) is rejected.
    """
    if not isinstance(value, str):
        raise ValueError(
            f"{location}: id must be a string, got {type(value).__name__}"
        )
    if len(value) < ID_MIN_LENGTH:
        raise ValueError(
            f"{location}: id {value!r} is shorter than the {ID_MIN_LENGTH}-character minimum"
        )
    if not re.match(ID_PATTERN, value):
        raise ValueError(
            f"{location}: id {value!r} does not match pattern {ID_PATTERN!r}"
        )
    return value


def _check_required_string_field(
    art: dict, *, field: str, location: str
) -> None:
    value = art.get(field)
    if not isinstance(value, str):
        raise ValueError(
            f"{location}: required field {field!r} must be a string; "
            f"got {type(value).__name__} {value!r}"
        )


def load_source_model(root: Path) -> dict:
    """Load and structurally validate the source model.

    Returns a normalized dict with sorted artifact and fact lists and
    the canonical schema document. The loader is the structural
    fail-closed boundary: schema-required fields, types, identifiers,
    uniqueItems, closed shape, and the path XOR are all enforced here.
    Semantic checks (closed vocabularies, duplicate identities,
    cross-references between ``fact.owner_artifact`` and
    ``artifact.owns_facts``, pattern path existence) are delegated to
    ``validate_source_model``.
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

    seen_artifact_ids: set[str] = set()
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
        location = f"{path}: artifacts[{i}]"
        # Schema-required fields beyond id.
        for field in REQUIRED_ARTIFACT_FIELDS:
            if field not in art:
                raise ValueError(
                    f"{location}: missing required field {field!r}"
                )
        # id presence + format.
        aid = _check_id(art.get("id"), location=location)
        if aid in seen_artifact_ids:
            raise ValueError(
                f"{location}: duplicate artifact id {aid!r}"
            )
        seen_artifact_ids.add(aid)
        # Required string fields must be strings (not lists/objects).
        for field in ARTIFACT_REQUIRED_STRING_FIELDS:
            _check_required_string_field(
                art, field=field, location=location
            )
        # Optional materialization, if present, must be a string.
        if "materialization" in art and not isinstance(
            art["materialization"], str
        ):
            raise ValueError(
                f"{location}: optional field 'materialization' must be a string "
                f"when present; got {type(art['materialization']).__name__}"
            )
        # owns_facts must be a list with unique items.
        owns = art["owns_facts"]
        if not isinstance(owns, list):
            raise ValueError(
                f"{location}: 'owns_facts' must be a list; got {type(owns).__name__}"
            )
        if len(set(owns)) != len(owns):
            raise ValueError(
                f"{location}: 'owns_facts' must not contain duplicate fact ids"
            )
        # path vs path_pattern XOR.
        if not (("path" in art) ^ ("path_pattern" in art)):
            raise ValueError(
                f"{location} ({aid!r}): must declare exactly one of 'path' "
                f"or 'path_pattern' (XOR); both present is rejected, "
                f"neither present is rejected"
            )
        # Repository-relative path safety for plain ``path``.
        if "path" in art:
            arsenal_io.safe_repo_path(root, art["path"], field=f"artifact {aid!r} path")
        # ``path_pattern`` head segment is also repository-relative.
        elif "path_pattern" in art:
            pat = art["path_pattern"]
            head = pat.split("/", 1)[0]
            if head:
                arsenal_io.safe_repo_path(
                    root, head, field=f"artifact {aid!r} path_pattern head"
                )

    seen_fact_ids: set[str] = set()
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
        location = f"{path}: facts[{i}]"
        # Schema-required fields.
        for field in REQUIRED_FACT_FIELDS:
            if field not in fact:
                raise ValueError(
                    f"{location}: missing required field {field!r}"
                )
        fid = _check_id(fact["id"], location=location)
        if fid in seen_fact_ids:
            raise ValueError(
                f"{location}: duplicate fact id {fid!r}"
            )
        seen_fact_ids.add(fid)
        # owner_artifact must be a valid id.
        _check_id(
            fact["owner_artifact"],
            location=f"{location} owner_artifact",
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
        return [arsenal_io.safe_repo_path(root, artifact["path"], field="pattern")]
    pattern = artifact["path_pattern"]
    base = root
    if "/" in pattern:
        head, _, tail = pattern.partition("/")
        if head:
            candidate = arsenal_io.safe_repo_path(
                root, head, field="pattern head"
            )
            if candidate.is_dir():
                base = candidate
                pattern = tail
    return sorted(base.glob(pattern))


def artifacts_for_fact(model: dict, fact_id: str) -> list[dict]:
    """Return the list of artifacts whose ``owns_facts`` includes ``fact_id``."""
    return [a for a in model["artifacts"] if fact_id in a.get("owns_facts", [])]