"""Shell/Loadout Recon adapter (ARS-W3 Phase 1 placeholder).

This adapter is the Phase 1 placeholder for the eventual Loadout
``loadout run --plan <plan>`` invocation. It does NOT shell out to
Loadout; Loadout's interface is not yet concrete and the Wave 3
frozen invariants forbid runtime coupling between Arsenal and
Loadout in Phase 1. Instead, the shell adapter reads pre-emitted
findings from a JSON file on disk.

The shape of the JSON file mirrors the adapter contract:

    {
      "schema": "arsenal/repository-recon-findings/v0",
      "findings": {
        "<case_id>": [ <finding>, <finding>, ... ],
        ...
      }
    }

A finding is a dict shaped like the canonical procedure output
(``kind``, ``subject``, ``evidence``, ``actual``).

The adapter refuses to silently fall back to the internal fixture
procedure. If the JSON file is missing or a case is not present,
the adapter raises ``FileNotFoundError`` (a hard error). The
evaluator's CLI surfaces this as an UNKNOWN exit. This preserves
the Phase 1 invariant: a broken candidate (wrong findings, missing
findings) MUST produce worse evaluation evidence, never silent
"the internal procedure saved the day".

Phase 2 transition note (NOT IMPLEMENTED HERE):
    When Loadout's procedure interface is concrete and stable, a
    NEW adapter class (e.g. ``LoadoutRuntimeAdapter``) can be added
    next to this one that shells out to ``loadout run --plan <plan>``
    and parses the produced findings. The current shell adapter
    remains as a deterministic test/fixture surface and is NOT
    replaced.
"""

from __future__ import annotations

import json
from pathlib import Path

from .repository_recon_adapter import validate_findings

_ADAPTER_NAME = "shell-loadout-recon"
_FINDINGS_SCHEMA = "arsenal/repository-recon-findings/v0"


class ShellLoadoutReconAdapter:
    """Adapter that reads pre-emitted findings from a JSON file.

    The constructor accepts the path to a JSON file containing the
    findings keyed by ``case_id``. The adapter then satisfies
    ``run(repo_path)`` by looking up the case_id whose
    ``repo_path`` matches the requested path. If no case matches,
    the adapter raises ``FileNotFoundError`` so the evaluator can
    fail loudly.
    """

    name = _ADAPTER_NAME

    def __init__(self, findings_path: Path, *, case_paths: dict[str, Path] | None = None):
        """Construct a shell adapter backed by ``findings_path``.

        ``case_paths`` is an optional mapping from ``case_id`` to
        ``repo_path``. When provided, ``run(repo_path)`` looks up
        the case whose path matches. When absent, the adapter
        matches case keys by string equality on the path (which is
        fragile across symlinks/canonicalization; tests SHOULD pass
        ``case_paths`` for determinism).
        """
        self.findings_path = Path(findings_path)
        self._case_paths = dict(case_paths) if case_paths else {}
        self._findings = self._load_findings(self.findings_path)

    @staticmethod
    def _load_findings(path: Path) -> dict[str, list[dict]]:
        if not path.is_file():
            raise FileNotFoundError(
                f"shell-loadout-recon adapter: findings file missing: {path}"
            )
        with path.open("r", encoding="utf-8") as fh:
            data = json.load(fh)
        if not isinstance(data, dict):
            raise ValueError(
                f"shell-loadout-recon adapter: {path}: top-level must be an object"
            )
        schema = data.get("schema")
        if schema != _FINDINGS_SCHEMA:
            raise ValueError(
                f"shell-loadout-recon adapter: {path}: schema must be "
                f"{_FINDINGS_SCHEMA!r}, got {schema!r}"
            )
        findings = data.get("findings")
        if not isinstance(findings, dict):
            raise ValueError(
                f"shell-loadout-recon adapter: {path}: 'findings' must be an object"
            )
        # Validate every case's findings eagerly so a broken
        # adapter fails at construction time, not at run time.
        loaded: dict[str, list[dict]] = {}
        for case_id, case_findings in findings.items():
            if not isinstance(case_id, str) or not case_id:
                raise ValueError(
                    f"shell-loadout-recon adapter: {path}: case_id "
                    f"must be a non-empty string, got {case_id!r}"
                )
            validate_findings(case_findings)
            loaded[case_id] = case_findings
        return loaded

    def run(self, repo_path: Path) -> list[dict]:
        # Resolve repo_path to a case_id. When case_paths is
        # configured, we match by canonical path equality. Otherwise
        # we accept any case_id whose path string equals repo_path
        # (test-only convenience).
        case_id = self._resolve_case_id(repo_path)
        if case_id is None:
            raise FileNotFoundError(
                f"shell-loadout-recon adapter: no findings registered for "
                f"repo_path {repo_path!r}"
            )
        if case_id not in self._findings:
            # The corpus expected this case but the findings file
            # did not register findings for it. Refuse silently --
            # raise so the evaluator fails loudly.
            raise FileNotFoundError(
                f"shell-loadout-recon adapter: case_id {case_id!r} resolved "
                f"from repo_path {repo_path!r} but the findings file at "
                f"{self.findings_path!r} has no entry for it"
            )
        return list(self._findings[case_id])

    def _resolve_case_id(self, repo_path: Path) -> str | None:
        if self._case_paths:
            target = Path(repo_path).resolve()
            for case_id, configured_path in self._case_paths.items():
                if Path(configured_path).resolve() == target:
                    return case_id
            return None
        # Fallback: match by string equality on path.
        target = str(Path(repo_path).resolve())
        for case_id, _ in self._findings.items():
            if case_id == target:
                return case_id
        return None
