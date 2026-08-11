"""Shared I/O and digest primitives for Project Arsenal domain scripts.

Every CLI script imports sha256_bytes, canonical_json, load_json,
write_json, and safe_relative_path from here so the format of digests,
the canonical form of generated JSON, and the rules for repository
path safety live in exactly one place.

This module deliberately exposes a narrow surface. It does NOT include
config loading, target registry loading, or capability lookups; those
own their own cohesive modules.
"""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any

# Matches a non-empty relative path with no traversal segments.
_SAFE_RELATIVE_RE = re.compile(r"^[^./][^/]*(?:/[^/]+)*$")


def sha256_bytes(data: bytes) -> str:
    """Return "sha256:<hex>" for the given bytes.

    Every receipt, lockfile, manifest, and capability fragment uses this
    digest format. Centralizing it keeps the prefix and encoding uniform
    across the repository.
    """
    return "sha256:" + hashlib.sha256(data).hexdigest()


def canonical_json(data: Any) -> bytes:
    """Return bytes for the canonical JSON encoding of `data`.

    Canonical form: sort keys, no whitespace, UTF-8, trailing newline.
    Used by the compiler lockfile, manifest, and any other artifact
    that must hash deterministically.
    """
    return (
        json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        + "\n"
    ).encode("utf-8")


def load_json(path: Path) -> Any:
    """Load JSON from `path`. Raises with the path context if malformed."""
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: invalid JSON: {exc}") from exc


def write_json(path: Path, data: Any) -> None:
    """Write JSON to `path` in canonical form, creating parents as needed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(data, sort_keys=True, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def safe_relative_path(raw: str, *, field: str) -> Path:
    """Validate and return a safe repository-relative path string.

    Rejects absolute paths, paths that contain ".." traversal segments,
    and empty strings. Used by every script that reads a path from a
    registry, manifest, or suite definition.
    """
    if not raw or ".." in Path(raw).parts or Path(raw).is_absolute():
        raise ValueError(f"{field} must be a safe repository-relative path: {raw!r}")
    if not _SAFE_RELATIVE_RE.match(raw):
        raise ValueError(f"{field} must be a safe repository-relative path: {raw!r}")
    return Path(raw)