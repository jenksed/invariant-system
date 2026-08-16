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

# Matches a non-empty relative path with no traversal or
# current-directory-only segments. Leading ``.`` is allowed only as
# the start of a real filename (e.g. ``.arsenal.lock``); bare
# ``.``, ``..``, ``./`` and ``../`` are rejected.
_SAFE_RELATIVE_RE = re.compile(r"^[^/]+(?:/[^/]+)*$")


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

    Rejects absolute paths, paths that contain ``..`` traversal or
    bare ``.`` segments, empty strings, and paths whose overall shape
    contains any segment that is ``""``, ``.``, or ``..``. Leading
    ``.`` is allowed only as the start of a real filename (e.g.
    ``.arsenal.lock``); bare ``.``, ``..``, ``./`` and ``../`` are
    all rejected.
    """
    if not raw or Path(raw).is_absolute():
        raise ValueError(f"{field} must be a safe repository-relative path: {raw!r}")
    if not _SAFE_RELATIVE_RE.match(raw):
        raise ValueError(f"{field} must be a safe repository-relative path: {raw!r}")
    if any(seg in ("", ".", "..") for seg in raw.split("/")):
        raise ValueError(f"{field} must be a safe repository-relative path: {raw!r}")
    return Path(raw)


def safe_repo_path(root: Path, raw: str, *, field: str) -> Path:
    """Validate ``raw`` against ``root`` and return a resolved Path.

    This is the canonical repository-path safety primitive. The source
    model loader and validator both call it so they cannot disagree on
    what counts as a safe repository-relative path.

    Rejects:

    * empty strings;
    * absolute paths (POSIX leading ``/`` and Windows drive letters);
    * any traversal segment (``..``);
    * a leading ``./`` prefix -- documented as rejected to keep path
      semantics explicit. Authors should write ``subdir/file`` rather
      than ``./subdir/file``;
    * any ``.`` segment (e.g. ``foo/./bar``);
    * a leading ``../`` prefix;
    * a resolved path that escapes ``root`` after symlink
      normalization (defense in depth even though traversal segments
      are already rejected above).

    Returns the absolute resolved Path when the input is safe.
    """
    # Reuse the existing string-level repository-path validator so
    # the canonical rules live in exactly one place. That validator
    # already rejects empty strings, absolute paths, traversal
    # segments, bare ``.`` segments, and a leading ``./``.
    safe_relative_path(raw, field=field)
    # Defense in depth: ensure the resolved path stays under root.
    resolved_root = root.resolve()
    resolved = (resolved_root / raw).resolve()
    if not resolved.is_relative_to(resolved_root):
        raise ValueError(f"{field} resolves outside the repository root: {raw!r}")
    return resolved