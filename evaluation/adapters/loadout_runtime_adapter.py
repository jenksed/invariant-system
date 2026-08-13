"""Loadout runtime adapter (ARS-W3 Phase 2).

This adapter shells out to the Loadout Repository Recon v1 procedure
running at the exact checkpoint supplied by the Loadout Wave 3
maintainer. It does NOT import Loadout source code (no Python
``import`` of any Loadout module) and does NOT depend on Loadout
runtime in the sense of bundling Loadout -- the adapter invokes a
Node.js bootstrap that dynamically imports the procedure from the
Loadout installation the operator points the adapter at.

How the adapter invokes Loadout
-------------------------------

The adapter writes a small ESM bootstrap to a private temp file
and runs it through ``node --input-type=module``. The bootstrap
dynamically imports ``runRepositoryRecon`` from the Loadout
installation path and prints the result as JSON to stdout. The
adapter parses stdout, captures the ``ReconResultV1`` shape, and
translates it into Arsenal findings.

The bootstrap does not embed Loadout source; it only references
the procedure by absolute path. The path is operator-supplied via
``--loadout-root PATH`` on the CLI; the adapter does not assume any
particular install location.

Translation contract
--------------------

The adapter maps Loadout's structured output to Arsenal findings
1:1, with no internal-procedure fallbacks:

* Every detected ``architecture_anchor`` becomes a presence
  finding (``actual=True``) at the anchor's path.
* Every ``unknown`` of the form ``architecture_anchor:KIND`` becomes
  presence findings (``actual=False``) at every canonical path of
  that kind Loadout would have checked (the canonical catalogues
  are mirrored here verbatim from the Loadout source so the
  translation is transparent and the adapter stays read-only).
* Constraints and non-anchor unknowns are intentionally NOT mapped
  to findings; the Arsenal evaluator expects a closed-shape finding
  vocabulary. Surfacing constraints as findings would silently
  introduce a vocabulary the rest of the pipeline does not
  consume.

Phase 2 invariants
------------------

* No Arsenal source import of Loadout. The Python adapter module
  has no ``import`` statements that reference Loadout code.
* No Arsenal runtime dependency on Loadout. The adapter shells
  out to Node.js (which is a Phase 2 runtime dependency only for
  operators who choose to enable this adapter); no Loadout code
  is bundled in Arsenal's distribution.
* The adapter is read-only with respect to the target repository.
  It does NOT install packs, write to ``.loadout/``, or otherwise
  mutate the target.
* A broken Loadout checkpoint produces strictly worse evaluation
  evidence. The adapter rejects runtimes that do not satisfy the
  ``loadout/repository-recon/v1`` schema; a procedure that throws
  is surfaced as an adapter error, not silently masked.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from .repository_recon_adapter import validate_findings

_ADAPTER_NAME = "loadout-runtime"
_EXPECTED_SCHEMA = "loadout/repository-recon/v1"

# Mirror of Loadout's canonical catalogues (verbatim from
# src/packs/repository-recon/run.ts at the W3 checkpoint
# d95927fbb675902d0fba992684b101ff60ff5a52). Keeping this
# mirror inside the adapter keeps the translation transparent
# and reviewable without importing Loadout at module load time.
_LOADOUT_ANCHOR_KIND_CANONICAL_PATHS: dict[str, list[str]] = {
    "governance": [
        "AGENTS.md",
        "CLAUDE.md",
        ".cursorrules",
        "CONVENTIONS.md",
        "CONTRIBUTING.md",
    ],
    "readme": [
        "README.md",
        "README",
        "README.txt",
        "readme.md",
        "readme",
    ],
    "manifest": [
        "package.json",
        "pyproject.toml",
        "setup.py",
        "Cargo.toml",
        "go.mod",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "composer.json",
        "Gemfile",
        "mix.exs",
        "pubspec.yaml",
    ],
    "source_root": ["src/", "lib/", "app/", "source/"],
    "docs_architecture": [
        "ARCHITECTURE.md",
        "ARCHITECTURE",
        "DESIGN.md",
        "docs/architecture",
        "docs/design",
        "docs",
    ],
    "test_root": ["tests/", "test/", "spec/", "__tests__/"],
    "ci_workflow": [
        ".github/workflows",
        ".circleci",
        ".buildkite",
        "azure-pipelines.yml",
        ".travis.yml",
        ".gitlab-ci.yml",
        "appveyor.yml",
        "Jenkinsfile",
    ],
    "build_config": [
        "tsconfig.json",
        "webpack.config.js",
        "rollup.config.js",
        "vite.config.ts",
        "vite.config.js",
        "esbuild.config.js",
        "Makefile",
        "CMakeLists.txt",
    ],
    "project_config": [
        ".editorconfig",
        ".eslintrc.json",
        ".eslintrc.js",
        ".prettierrc",
        ".prettierrc.json",
        ".prettierignore",
        "Dockerfile",
        "docker-compose.yml",
        ".gitignore",
        ".dockerignore",
    ],
}

# The bootstrap script. It is written to a private temp file at
# runtime and removed in a finally block. It does not embed Loadout
# source; it only references the procedure module by absolute path.
# ``--input-type=module`` makes the inline script an ESM module so
# top-level ``await import(...)`` is legal.
_BOOTSTRAP_SOURCE = """\
// Bootstrap for the Loadout Runtime Adapter (ARS-W3 Phase 2).
// Dynamically imports the procedure at the operator-supplied path
// and prints the result as a single JSON object on stdout.
const procPath = process.argv[2];
const repoRoot = process.argv[3];
const mod = await import(procPath);
if (typeof mod.runRepositoryRecon !== "function") {
  console.error("loadout-runtime adapter: " + procPath + " does not export runRepositoryRecon");
  process.exit(64);
}
const result = await mod.runRepositoryRecon(repoRoot);
process.stdout.write(JSON.stringify(result));
"""


class LoadoutRuntimeAdapter:
    """Adapter that shells out to the Loadout Repository Recon v1 procedure.

    Constructor arguments:

    * ``loadout_root``: the on-disk path to the Loadout installation
      (the directory that contains ``dist/packs/repository-recon/run.js``
      at the W3 checkpoint). Required.
    * ``case_paths``: optional mapping from case_id to repo_path,
      used for logging only (the adapter resolves ``repo_path``
      directly from ``run(repo_path)``).
    """

    name = _ADAPTER_NAME

    def __init__(
        self,
        loadout_root: Path,
        *,
        case_paths: dict[str, Path] | None = None,
    ):
        self.loadout_root = Path(loadout_root)
        self._case_paths = dict(case_paths) if case_paths else {}
        self._bootstrap_file: Path | None = None

    # ------------------------------------------------------------------
    # Adapter interface
    # ------------------------------------------------------------------

    def run(self, repo_path: Path) -> list[dict]:
        repo_path = Path(repo_path)
        # We refuse to silently fall back to the internal procedure
        # if Node is missing. The operator who selects this adapter
        # is asserting a Node runtime exists.
        if shutil.which("node") is None:
            raise RuntimeError(
                "loadout-runtime adapter requires node on PATH; install "
                "Node 20.x or use a different adapter"
            )
        proc_path = self._resolve_procedure_path()
        bootstrap = self._write_bootstrap()
        try:
            completed = subprocess.run(
                ["node", str(bootstrap),
                 str(proc_path), str(repo_path.resolve())],
                capture_output=True,
                text=True,
                timeout=60,
                check=False,
            )
        finally:
            # Clean up the bootstrap file even on failure.
            try:
                bootstrap.unlink()
            except FileNotFoundError:
                pass
        if completed.returncode != 0:
            stderr = (completed.stderr or "").strip()
            raise RuntimeError(
                f"loadout-runtime adapter: Loadout procedure exited with "
                f"code {completed.returncode}: {stderr}"
            )
        stdout = (completed.stdout or "").strip()
        if not stdout:
            raise RuntimeError(
                "loadout-runtime adapter: Loadout procedure produced no output"
            )
        try:
            result = json.loads(stdout)
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                f"loadout-runtime adapter: Loadout procedure output was not "
                f"valid JSON: {exc}; stdout={stdout[:200]!r}"
            ) from exc
        if not isinstance(result, dict):
            raise RuntimeError(
                "loadout-runtime adapter: Loadout procedure output is not an "
                f"object (got {type(result).__name__})"
            )
        if result.get("schema") != _EXPECTED_SCHEMA:
            raise RuntimeError(
                f"loadout-runtime adapter: Loadout procedure schema is "
                f"{result.get('schema')!r}, expected {_EXPECTED_SCHEMA!r}; "
                "the operator must point --loadout-root at the W3 checkpoint"
            )
        findings = _translate_recon_to_findings(result)
        validate_findings(findings)
        return findings

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _resolve_procedure_path(self) -> Path:
        """Locate the Loadout procedure module.

        Loadout ships both a built (``dist/packs/.../run.js``) and a
        source (``src/packs/.../run.ts``) copy. The runtime path is
        the canonical artifact (the built CLI has no TS loader); the
        source path is a dev fallback. Both are relative to the
        Loadout installation root.
        """
        candidates = [
            self.loadout_root / "dist" / "packs" / "repository-recon" / "run.js",
            self.loadout_root / "src" / "packs" / "repository-recon" / "run.ts",
        ]
        for c in candidates:
            if c.is_file():
                return c
        raise FileNotFoundError(
            f"loadout-runtime adapter: cannot locate runRepositoryRecon under "
            f"{self.loadout_root!r}; expected one of: "
            f"{[str(c) for c in candidates]}"
        )

    def _write_bootstrap(self) -> Path:
        """Write the ESM bootstrap to a private temp file and return its path."""
        # Use a stable, prefix-tagged filename so debugging is easy.
        fd, name = tempfile.mkstemp(
            prefix="arsenal-loadout-bootstrap-", suffix=".mjs"
        )
        try:
            with open(fd, "w", encoding="utf-8") as fh:
                fh.write(_BOOTSTRAP_SOURCE)
        except Exception:
            try:
                Path(name).unlink()
            except FileNotFoundError:
                pass
            raise
        self._bootstrap_file = Path(name)
        return self._bootstrap_file


# ----------------------------------------------------------------------
# Pure helpers (module-level for testability).
# ----------------------------------------------------------------------


def _translate_recon_to_findings(recon_result: dict) -> list[dict]:
    """Translate a ``ReconResultV1`` dict into Arsenal findings.

    The translation is intentionally narrow and 1:1 with Loadout's
    output. Every detected anchor produces a presence finding with
    ``actual=True``; every anchor-of-KIND unknown produces presence
    findings (``actual=False``) for every canonical path of that
    KIND. Arsenal-specific paths that Loadout does not catalog are
    NOT synthesized here -- the evaluator will report FAILURE for
    assertions on those paths, which is the honest output-driven
    signal that Loadout's catalogue differs from Arsenal's.
    """
    findings: list[dict] = []
    anchors = recon_result.get("architecture_anchors") or []
    detected_paths: set[str] = set()
    for anchor in anchors:
        if not isinstance(anchor, dict):
            continue
        path = anchor.get("path")
        kind = anchor.get("kind")
        if not isinstance(path, str) or not path:
            continue
        if not isinstance(kind, str) or not kind:
            continue
        detected_paths.add(path)
        findings.append({
            "kind": "presence",
            "subject": f"{kind}:{path}",
            "evidence": path,
            "actual": True,
        })
    unknowns = recon_result.get("unknowns") or []
    for unknown in unknowns:
        if not isinstance(unknown, dict):
            continue
        subject = unknown.get("subject")
        if not isinstance(subject, str):
            continue
        m = re.match(r"^architecture_anchor:([a-z_]+)$", subject)
        if not m:
            continue
        kind = m.group(1)
        for canonical_path in _LOADOUT_ANCHOR_KIND_CANONICAL_PATHS.get(kind, ()):
            if canonical_path in detected_paths:
                continue
            findings.append({
                "kind": "presence",
                "subject": f"{kind}:{canonical_path}",
                "evidence": canonical_path,
                "actual": False,
            })
    return findings
