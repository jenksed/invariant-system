#!/usr/bin/env python3
"""Validate the first-month Schema and fixture Schema dispositions.

The script uses the pinned project-scoped jsonschema package. It performs no
network access and does not replace the separate semantic validator.
"""

from __future__ import annotations

import json
import sys
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path
from typing import Any, Iterable

EXPECTED_JSONSCHEMA_VERSION = "4.26.0"
ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "docs/contracts/kiln-first-month.schema.json"
POSITIVE_PATH = ROOT / "test/fixtures/conformance/first_month_positive.json"
NEGATIVE_PATH = ROOT / "test/fixtures/conformance/first_month_negative.json"


def load(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def iter_refs(value: Any) -> Iterable[str]:
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "$ref" and isinstance(child, str):
                yield child
            else:
                yield from iter_refs(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_refs(child)


def error_path(error: Any) -> tuple[str, ...]:
    return tuple(str(part) for part in error.path)


def require_pinned_package() -> None:
    try:
        installed = version("jsonschema")
    except PackageNotFoundError as error:
        raise AssertionError(
            "jsonschema is not installed; run "
            "python3 -m pip install -r requirements/conformance.txt"
        ) from error

    if installed != EXPECTED_JSONSCHEMA_VERSION:
        raise AssertionError(
            f"jsonschema version {installed!r} is installed; "
            f"expected {EXPECTED_JSONSCHEMA_VERSION!r}"
        )


def main() -> int:
    require_pinned_package()

    from jsonschema import Draft202012Validator, FormatChecker

    schema = load(SCHEMA_PATH)
    positives = load(POSITIVE_PATH)
    negatives = load(NEGATIVE_PATH)

    Draft202012Validator.check_schema(schema)

    remote_refs = sorted(ref for ref in iter_refs(schema) if not ref.startswith("#"))
    if remote_refs:
        raise AssertionError(
            "first-month Schema contains non-local $ref values: " + ", ".join(remote_refs)
        )

    validator = Draft202012Validator(schema, format_checker=FormatChecker())

    for index, document in enumerate(positives):
        errors = sorted(validator.iter_errors(document), key=error_path)
        if errors:
            raise AssertionError(
                f"positive fixture {index} failed Schema validation: {errors[0].message}"
            )

    schema_rejections = 0
    semantic_only = 0

    for index, case in enumerate(negatives):
        disposition = case.get("expected_validation")
        if not isinstance(disposition, dict):
            raise AssertionError(f"negative fixture {index} lacks expected_validation")

        schema_expectation = disposition.get("schema")
        semantic_expectation = disposition.get("semantic")

        if schema_expectation not in {"accept", "reject"}:
            raise AssertionError(
                f"negative fixture {index} has invalid Schema disposition {schema_expectation!r}"
            )
        if semantic_expectation != "reject":
            raise AssertionError(
                f"negative fixture {index} must remain protected by semantic rejection"
            )

        errors = sorted(validator.iter_errors(case["document"]), key=error_path)
        actual = "reject" if errors else "accept"

        if actual != schema_expectation:
            detail = errors[0].message if errors else "document was accepted"
            raise AssertionError(
                f"negative fixture {index} expected Schema {schema_expectation}, "
                f"received {actual}: {detail}"
            )

        if actual == "reject":
            schema_rejections += 1
        else:
            semantic_only += 1

    print("validate-json-schema-contracts: pass")
    print(f"jsonschema version: {EXPECTED_JSONSCHEMA_VERSION}")
    print(f"positive fixtures: {len(positives)}")
    print(f"Schema-rejected negatives: {schema_rejections}")
    print(f"semantic-only negatives: {semantic_only}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"validate-json-schema-contracts: {error}", file=sys.stderr)
        raise SystemExit(1) from error
