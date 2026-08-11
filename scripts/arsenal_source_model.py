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
"""

from __future__ import annotations

import fnmatch
import json
from pathlib import Path
from typing import Any

import arsenal_governance
import arsenal_schema_registry

SOURCE_MODEL_PATH = Path("arsenal/source-model.json")
REQUIRED_ARTIFACT_KEYS = {
    "id",
    "ownership",
    "state_role",
    "owns_facts",
}
# Per-artifact anti-duplication guard. The source model stores only
# classification and locator metadata; it must never carry a domain
# value.
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
    resolved pattern expansions. Validation of semantic invariants
    (closed vocabularies, duplicate identities, etc.) is left to
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

    # Anti-duplication: reject any artifact entry that carries a
    # value-shaped key. The source model is an index, not a copy.
    for i, art in enumerate(artifacts):
        if not isinstance(art, dict):
            raise ValueError(f"{path}: artifacts[{i}] must be an object")
        bad = sorted(set(art) & FORBIDDEN_ARTIFACT_VALUE_KEYS)
        if bad:
            raise ValueError(
                f"{path}: artifacts[{i}] ({art.get('id')!r}) carries value-shaped "
                f"key(s) {bad}; the source model is an index, not a copy of "
                f"domain values"
            )
        if "id" not in art:
            raise ValueError(f"{path}: artifacts[{i}] missing 'id'")
        if not (("path" in art) ^ ("path_pattern" in art)):
            raise ValueError(
                f"{path}: artifacts[{i}] ({art.get('id')!r}) must declare exactly "
                f"one of 'path' or 'path_pattern'"
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
    """Resolve a ``path_pattern`` artifact into a deterministic list of paths."""
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
    matched = sorted(p for p in base.glob(pattern) if p.is_file())
    if not matched:
        # Pattern matches nothing yet is tolerated: capability families
        # may be empty in a future state. The validator emits a
        # non-fatal notice for empty patterns.
        return []
    return matched


def artifacts_for_fact(model: dict, fact_id: str) -> list[dict]:
    """Return the list of artifacts whose ``owns_facts`` includes ``fact_id``."""
    return [a for a in model["artifacts"] if fact_id in a.get("owns_facts", [])]
