#!/usr/bin/env python3
"""Validate a Kiln CLI result JSON document against $defs.cli_result.

Usage:
    python3 scripts/validate_cli_result_schema.py <path-to-json-file>

The script is read-only. It loads docs/contracts/kiln-first-month.schema.json
and validates the document at the given path against $defs.cli_result using
Draft 2020-12 semantics with format checking enabled. The validator uses the
pinned project-scoped jsonschema package.

Exit status:
    0  document validates
    1  document fails validation, validator missing, or file unreadable
"""

from __future__ import annotations

import json
import sys
from importlib.metadata import PackageNotFoundError, version
from pathlib import Path

EXPECTED_JSONSCHEMA_VERSION = "4.26.0"
ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "docs/contracts/kiln-first-month.schema.json"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <path-to-cli-result-json>", file=sys.stderr)
        return 1

    try:
        installed = version("jsonschema")
    except PackageNotFoundError as error:
        print(f"jsonschema not installed: {error}", file=sys.stderr)
        return 1

    if installed != EXPECTED_JSONSCHEMA_VERSION:
        print(
            f"jsonschema version {installed!r} installed; expected "
            f"{EXPECTED_JSONSCHEMA_VERSION!r}",
            file=sys.stderr,
        )
        return 1

    from jsonschema import Draft202012Validator, FormatChecker

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    cli_result = schema["$defs"]["cli_result"]
    document = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

    validator = Draft202012Validator(cli_result, format_checker=FormatChecker())
    errors = sorted(validator.iter_errors(document), key=lambda e: list(e.path))
    if errors:
        for error in errors:
            print(f"  - {'/'.join(map(str, error.path))}: {error.message}")
        return 1

    print("cli-result-schema: pass")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"cli-result-schema: {error}", file=sys.stderr)
        raise SystemExit(1) from error
