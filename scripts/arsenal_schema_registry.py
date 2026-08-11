"""Arsenal-owned schema identity registry.

Every Project Arsenal JSON Schema declares a `$id` URL of the form
`https://<host>/schema/<name>-<version>.json`. The host, name, and
version live in `arsenal/schema-registry.json`. This module is the
only authority for mapping a schema name to its `$id`.

Consumer configuration cannot redefine schema identity. A fork or
vendor that wants a different schema $id must publish a different
schema-registry.json at the canonical path; downstream readers will
look it up there. This keeps the $id canonical across the Arsenal
distribution.
"""

from __future__ import annotations

from pathlib import Path

from arsenal_io import load_json

SCHEMA_REGISTRY_PATH = Path("arsenal/schema-registry.json")
SCHEMA_REGISTRY_VERSION = "1.0.0"


def load_schema_registry(root: Path) -> dict:
    """Return the schema registry loaded from arsenal/schema-registry.json.

    Raises if the registry is missing or malformed. The host is required;
    the schemas dict may be empty in tests.
    """
    path = root / SCHEMA_REGISTRY_PATH
    if not path.is_file():
        raise FileNotFoundError(
            f"missing Arsenal schema registry: {path} -- this file is part of "
            f"the Arsenal distribution and must be checked in"
        )
    doc = load_json(path)
    if not isinstance(doc, dict):
        raise ValueError(f"{path}: schema registry must be an object")
    if doc.get("schema_version") != SCHEMA_REGISTRY_VERSION:
        raise ValueError(
            f"{path}: unsupported schema-registry schema_version "
            f"{doc.get('schema_version')!r}; expected {SCHEMA_REGISTRY_VERSION!r}"
        )
    host = doc.get("host")
    if not isinstance(host, str) or not host:
        raise ValueError(f"{path}: schema registry must declare a string host")
    if not isinstance(doc.get("schemas"), dict):
        raise ValueError(f"{path}: schema registry must declare a 'schemas' object")
    return doc


def schema_id_for(root: Path, name: str) -> str:
    """Return the canonical `$id` URL for the named schema."""
    registry = load_schema_registry(root)
    schemas = registry.get("schemas", {})
    if name not in schemas:
        raise KeyError(
            f"unknown schema {name!r} in registry; known: {sorted(schemas)}"
        )
    entry = schemas[name]
    return f"https://{registry['host']}/schema/{name}-{entry['version']}.json"