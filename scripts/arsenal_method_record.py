#!/usr/bin/env python3
"""Deterministic validation of Project Arsenal Qualified Method Records.

This is a small fail-closed CLI. It enforces the documented
``engineering-system/qualified-method-record/v0`` semantics on every
record under ``evaluation/method-records/`` that does NOT carry
``fixture: true``.

Validation surface:

* the schema identity is exactly ``engineering-system/qualified-method-record/v0``;
* the record matches the canonical JSON schema under
  ``evaluation/method-records/qualified-method-record.v0.schema.json``;
* ``status`` is one of ``experimental`` or ``qualified``;
* ``qualified`` records must declare
  ``confidence = qualified-for-declared-context``;
* experimental records must declare non-empty ``observed_failures`` and a
  confidence level that is NOT ``qualified-for-declared-context``;
* the declared ``qualified_for.contexts`` and ``exclusions`` are both
  non-empty (negative knowledge is first-class per the contract);
* the record digest in ``provenance.record_digest`` matches a SHA-256
  computed over the record itself with the digest replaced by its
  declared value;
* the ``method_id`` is unique within the records directory.

Records marked ``fixture: true`` are loaded for completeness but their
``procedure_ref``, ``arsenal_commit``, and ``record_digest`` are allowed
to be placeholders; they are NOT subject to the
``qualified_for.contexts``/``exclusions`` checks.

The script exits non-zero on the first failure class it observes. Each
failure prints ``ERROR <message>`` to stderr.
"""

from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

try:
    import yaml  # type: ignore
except ModuleNotFoundError:  # pragma: no cover
    yaml = None  # type: ignore

ROOT = Path(__file__).resolve().parents[1]
RECORDS_DIR = ROOT / "evaluation" / "method-records"
SCHEMA_PATH = RECORDS_DIR / "qualified-method-record.v0.schema.json"
SCHEMA_ID = "engineering-system/qualified-method-record/v0"

CONTRACT_DIR = ROOT / "evaluation" / "method-records" / "qualification-gaps"

# Stable, schema-version-pinned error tokens. The CLI tests assert on
# these strings; do not rename without updating the negative suite.
EXIT_CODE = {
    "PASS": 0,
    "MISSING_RECORDS_DIR": 2,
    "MISSING_SCHEMA": 2,
    "INVALID_YAML": 3,
    "SCHEMA_VIOLATION": 4,
    "CONTRACT_VIOLATION": 5,
    "INVALID_DIGEST": 6,
    "DUPLICATE_METHOD_ID": 7,
    "UNKNOWN": 8,
}

DIGEST_RE = re.compile(r"^sha256:[A-Fa-f0-9]{64}$")
STATUSES = ("experimental", "qualified")
EXPERIMENTAL_CONFIDENCE = ("unqualified-fixture", "bounded", "limited")


class MethodRecordError(Exception):
    pass


def _load_yaml(path: Path) -> dict:
    if yaml is None:
        raise MethodRecordError(
            "PyYAML is required to validate method records; "
            "install pyyaml or run scripts/test-method-record.py"
        )
    with path.open("r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, dict):
        raise MethodRecordError(f"{path}: record must be a YAML mapping")
    return data


def _load_schema(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def _resolve_refs(node, schema: dict) -> dict:
    """Minimal $ref resolver for the local schema.

    The v0 schema is closed-shape and contains no external $refs, but
    ``internalResolver=True`` style behavior is provided so future
    revisions can rely on this primitive.
    """
    if isinstance(node, dict):
        if "$ref" in node and isinstance(node["$ref"], str) and node["$ref"].startswith("#/"):
            ref = node["$ref"][2:]
            target = schema
            for segment in ref.split("/"):
                target = target[segment]
            return _resolve_refs(target, schema)
        return {k: _resolve_refs(v, schema) for k, v in node.items()}
    if isinstance(node, list):
        return [_resolve_refs(item, schema) for item in node]
    return node


def _validate_against_schema(record: dict, schema: dict) -> list[str]:
    """Validate ``record`` against ``schema`` with a small closed-shape subset.

    Implementing a full Draft 2020-12 validator is out of scope for this
    slice. The v0 schema is small and closed-shape; we walk every node
    and enforce the constraints the schema declares that are observable
    without a JSON-Schema runtime: required, additionalProperties,
    type, enum, pattern, minLength, minItems, maxItems, and the allOf
    branches.
    """
    errors: list[str] = []
    resolved = _resolve_refs(schema, schema)

    def _expect_type(value, types: list[str], location: str) -> None:
        if "null" in types and value is None:
            return
        py_type_map = {
            "string": str,
            "integer": int,
            "number": (int, float),
            "boolean": bool,
            "array": list,
            "object": dict,
            "null": type(None),
        }
        for t in types:
            target = py_type_map[t]
            if t == "boolean" and not isinstance(value, bool):
                continue
            if t == "integer" and isinstance(value, bool):
                # booleans are not integers even if isinstance(value, int) is True.
                continue
            if isinstance(value, target):
                return
        errors.append(
            f"{location}: expected type {types!r}, got {type(value).__name__}"
        )

    def _walk(node, schema_node, location: str) -> None:
        if not isinstance(schema_node, dict):
            return
        # additionalProperties
        if (
            schema_node.get("additionalProperties") is False
            and isinstance(node, dict)
        ):
            allowed = set(schema_node.get("properties", {}).keys())
            extras = sorted(set(node) - allowed)
            if extras:
                errors.append(
                    f"{location}: additional properties not permitted: {extras}"
                )
        # required
        if isinstance(node, dict) and "required" in schema_node:
            missing = sorted(set(schema_node["required"]) - set(node))
            if missing:
                errors.append(
                    f"{location}: missing required fields {missing}"
                )
        # properties
        if isinstance(node, dict) and "properties" in schema_node:
            for key, sub_schema in schema_node["properties"].items():
                if key in node:
                    _walk(node[key], sub_schema, f"{location}.{key}")
        # type / const
        if "type" in schema_node:
            types = schema_node["type"]
            if isinstance(types, str):
                types = [types]
            _expect_type(node, types, location)
        if "const" in schema_node:
            if node != schema_node["const"]:
                errors.append(
                    f"{location}: expected const {schema_node['const']!r}, got {node!r}"
                )
        if "enum" in schema_node:
            if node not in schema_node["enum"]:
                errors.append(
                    f"{location}: value {node!r} not in enum {schema_node['enum']!r}"
                )
        # string constraints
        if isinstance(node, str):
            if "minLength" in schema_node and len(node) < schema_node["minLength"]:
                errors.append(
                    f"{location}: string shorter than minLength "
                    f"{schema_node['minLength']} ({len(node)}): {node!r}"
                )
            if "pattern" in schema_node and not re.fullmatch(
                schema_node["pattern"], node
            ):
                errors.append(
                    f"{location}: value {node!r} does not match pattern "
                    f"{schema_node['pattern']!r}"
                )
        # array constraints
        if isinstance(node, list):
            if "minItems" in schema_node and len(node) < schema_node["minItems"]:
                errors.append(
                    f"{location}: array has fewer items than minItems "
                    f"{schema_node['minItems']} ({len(node)})"
                )
            if "maxItems" in schema_node and len(node) > schema_node["maxItems"]:
                errors.append(
                    f"{location}: array has more items than maxItems "
                    f"{schema_node['maxItems']} ({len(node)})"
                )
            if "items" in schema_node:
                for i, item in enumerate(node):
                    _walk(item, schema_node["items"], f"{location}[{i}]")
        # allOf: every branch must satisfy
        if "allOf" in schema_node:
            for i, branch in enumerate(schema_node["allOf"]):
                # The branches in this schema are conditional: an "if"
                # with no "then" is a no-op; with a "then" the branch
                # only applies when the if matches.
                if "if" in branch:
                    if_match = _matches_if(node, branch["if"])
                    if if_match and "then" in branch:
                        _walk(node, branch["then"], f"{location}<allOf[{i}].then>")

    def _matches_if(node, if_schema: dict) -> bool:
        if not isinstance(node, dict) or not isinstance(if_schema, dict):
            return False
        for key, sub_schema in if_schema.get("properties", {}).items():
            if key not in node:
                continue
            value = node[key]
            # Const / enum only — sufficient for the v0 schema's if-branches.
            if "const" in sub_schema and value != sub_schema["const"]:
                return False
            if "enum" in sub_schema and value not in sub_schema["enum"]:
                return False
        # All required keys on the if-schema must be present on the node.
        for key in if_schema.get("required", []):
            if key not in node:
                return False
        return True

    _walk(record, resolved, "$")
    return errors


def _compute_record_digest(record: dict, declared_digest: str) -> bool:
    """Compute the canonical SHA-256 of the record (with the digest
    field replaced by a fixed placeholder) and compare to ``declared_digest``.

    The digest is self-referential: the value of
    ``provenance.record_digest`` appears inside the record body that is
    hashed. To break the cycle, the canonicalization step replaces the
    field with a stable placeholder (a 64-zero hex digest). The author
    of a record computes the digest exactly the same way the validator
    does; the file's ``provenance.record_digest`` is therefore the
    *output* of the canonicalization, not part of the input.

    Canonicalization rules for v0:

    * the record is serialized as JSON with ``sort_keys=True`` and
      ``separators=(",", ":")`` (no whitespace);
    * the ``provenance.record_digest`` value is replaced by the
      64-zero placeholder ``sha256:000...000`` before hashing;
    * the SHA-256 is hex-encoded lower-case and prefixed ``sha256:``.
    """
    placeholder = "sha256:" + ("0" * 64)
    payload = json.loads(json.dumps(record, sort_keys=True))
    provenance = payload.get("provenance", {})
    provenance["record_digest"] = placeholder
    payload["provenance"] = provenance
    serialized = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    computed = "sha256:" + hashlib.sha256(serialized.encode("utf-8")).hexdigest()
    return computed == declared_digest


def validate_record(record: dict, *, path: Path) -> list[str]:
    """Validate one record and return a list of error strings.

    Errors are returned as a list so callers can collect across the
    whole directory.
    """
    errors: list[str] = []
    if not isinstance(record, dict):
        return [f"{path}: record must be a mapping"]

    # Schema identity must match.
    schema_value = record.get("schema")
    if schema_value != SCHEMA_ID:
        errors.append(
            f"{path}: schema identity must be {SCHEMA_ID!r}, got {schema_value!r}"
        )

    # Validate against the JSON schema (closed-shape + invariants).
    if SCHEMA_PATH.is_file():
        try:
            schema = _load_schema(SCHEMA_PATH)
            errors.extend(
                f"{path}: {err}"
                for err in _validate_against_schema(record, schema)
            )
        except Exception as exc:
            errors.append(f"{path}: failed to load schema: {exc}")
    else:
        errors.append(
            f"{path}: missing schema at {_display(SCHEMA_PATH)}"
        )

    is_fixture = record.get("fixture") is True

    # Status checks (defensive beyond the schema).
    status = record.get("status")
    if status not in STATUSES:
        # Already reported by the schema validator.
        pass
    elif status == "qualified" and not is_fixture:
        confidence = record.get("evaluation", {}).get("confidence")
        if confidence != "qualified-for-declared-context":
            errors.append(
                f"{path}: status=qualified requires "
                f"confidence=qualified-for-declared-context, got {confidence!r}"
            )

    # Digest check (records that are not fixtures).
    provenance = record.get("provenance", {}) if isinstance(record, dict) else {}
    declared_digest = provenance.get("record_digest")
    if not is_fixture:
        if not (isinstance(declared_digest, str) and DIGEST_RE.match(declared_digest)):
            errors.append(
                f"{path}: provenance.record_digest must be a 64-hex sha256 digest"
            )
        elif not _compute_record_digest(record, declared_digest):
            errors.append(
                f"{path}: provenance.record_digest does not match canonical sha256 "
                f"of the record itself"
            )

    # Contexts and exclusions: non-empty for non-fixture records.
    if not is_fixture:
        qualified_for = record.get("qualified_for", {})
        if isinstance(qualified_for, dict):
            contexts = qualified_for.get("contexts", [])
            exclusions = qualified_for.get("exclusions", [])
            if not isinstance(contexts, list) or not contexts:
                errors.append(
                    f"{path}: qualified_for.contexts must be non-empty"
                )
            if not isinstance(exclusions, list) or not exclusions:
                errors.append(
                    f"{path}: qualified_for.exclusions must be non-empty"
                )

    # The qualified-method-record contract says qualification is evidence
    # about a method, NOT runtime authority. Defensive negative-knowledge
    # check: the record must NOT claim filesystem/network/Git/production
    # authority in any of its fields.
    serialized = json.dumps(record, sort_keys=True).lower()
    for forbidden in (
        "filesystem.write",
        "network.write",
        "git.write",
        "production.mutate",
        "cloud.remote",
    ):
        if forbidden in serialized:
            errors.append(
                f"{path}: record claims runtime authority {forbidden!r} which "
                f"the contract forbids"
            )

    return errors


def iter_records(records_dir: Path) -> list[Path]:
    if not records_dir.is_dir():
        return []
    return sorted(records_dir.glob("*.yaml")) + sorted(records_dir.glob("*.yml"))


def _display(path: Path) -> str:
    """Return a repository-relative path string when possible."""
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def validate_directory(records_dir: Path = RECORDS_DIR) -> list[str]:
    """Validate every record under ``records_dir`` and return errors.

    The schema file under ``records_dir`` is excluded.
    """
    errors: list[str] = []
    seen_method_ids: dict[str, Path] = {}
    paths = [
        p for p in iter_records(records_dir)
        if p.resolve() != SCHEMA_PATH.resolve()
    ]
    if not paths:
        try:
            rel = records_dir.relative_to(ROOT)
        except ValueError:
            rel = records_dir
        return [f"no method records found under {rel}"]
    for path in paths:
        try:
            record = _load_yaml(path)
        except Exception as exc:
            errors.append(f"{_display(path)}: invalid YAML: {exc}")
            continue
        errs = validate_record(record, path=path)
        errors.extend(errs)
        mid = record.get("method_id") if isinstance(record, dict) else None
        if isinstance(mid, str):
            prior = seen_method_ids.get(mid)
            if prior is not None:
                errors.append(
                    f"{_display(path)}: duplicate method_id {mid!r}; "
                    f"first seen at {_display(prior)}"
                )
            else:
                seen_method_ids[mid] = path
    return errors


def main() -> int:
    if not RECORDS_DIR.is_dir():
        print(f"ERROR missing records dir: {RECORDS_DIR}", file=sys.stderr)
        return EXIT_CODE["MISSING_RECORDS_DIR"]
    if not SCHEMA_PATH.is_file():
        print(f"ERROR missing schema: {SCHEMA_PATH}", file=sys.stderr)
        return EXIT_CODE["MISSING_SCHEMA"]
    errors = validate_directory(RECORDS_DIR)
    if errors:
        for err in errors:
            print(f"ERROR {err}", file=sys.stderr)
        # Classify by substring across ALL error messages (not just the
        # first). The priority order matches the most-specific failure
        # class observed anywhere in the error list.
        priority = [
            ("invalid yaml", "INVALID_YAML"),
            ("missing schema", "MISSING_SCHEMA"),
            ("schema identity must be", "SCHEMA_VIOLATION"),
            ("additional properties", "SCHEMA_VIOLATION"),
            ("expected type", "SCHEMA_VIOLATION"),
            ("enum", "SCHEMA_VIOLATION"),
            ("expected const", "SCHEMA_VIOLATION"),
            ("does not match pattern", "SCHEMA_VIOLATION"),
            ("shorter than minlength", "SCHEMA_VIOLATION"),
            ("fewer items than minitems", "SCHEMA_VIOLATION"),
            ("status=qualified requires", "CONTRACT_VIOLATION"),
            ("contexts must be non-empty", "CONTRACT_VIOLATION"),
            ("exclusions must be non-empty", "CONTRACT_VIOLATION"),
            ("runtime authority", "CONTRACT_VIOLATION"),
            ("record_digest does not match", "INVALID_DIGEST"),
            ("record_digest must be", "INVALID_DIGEST"),
            ("duplicate method_id", "DUPLICATE_METHOD_ID"),
        ]
        joined = "\n".join(errors).lower()
        for needle, code in priority:
            if needle in joined:
                return EXIT_CODE[code]
        return EXIT_CODE["UNKNOWN"]
    count = len(list(RECORDS_DIR.glob("*.yaml")) + list(RECORDS_DIR.glob("*.yml")))
    try:
        display = RECORDS_DIR.relative_to(ROOT)
    except ValueError:
        display = RECORDS_DIR
    print(f"arsenal method records: PASS ({count} record(s) under {display})")
    return EXIT_CODE["PASS"]


if __name__ == "__main__":
    raise SystemExit(main())
