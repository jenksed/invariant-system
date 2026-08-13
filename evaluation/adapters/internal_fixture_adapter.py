"""Internal fixture procedure adapter.

This adapter wraps the original ``scripts/arsenal_evaluate._run_recon_procedure``
function. It exists so the evaluator can be configured with a
uniform adapter interface (and the artifact can record the adapter
identity) without changing the existing canonical fixture-procedure
behavior.

This is the DEFAULT adapter used by the evaluator. The constructor
accepts the procedure function explicitly so the adapter does not
hold a stale import-time binding; the evaluator passes
``arsenal_evaluate._run_recon_procedure`` at adapter resolution time.
Tests that monkey-patch ``arsenal_evaluate._run_recon_procedure``
before invoking the CLI continue to work: the patched symbol IS the
one the evaluator passes in.
"""

from __future__ import annotations

from pathlib import Path
from typing import Callable

_ADAPTER_NAME = "internal-fixture-procedure"


class InternalFixtureProcedureAdapter:
    """Adapter wrapping the internal fixture procedure.

    ``name`` is the stable identifier recorded in the evaluation
    artifact's provenance. ``run`` defers to the procedure function
    passed at construction time so the adapter indirection adds zero
    behavior.
    """

    name = _ADAPTER_NAME

    def __init__(self, procedure: Callable[[Path], list[dict]] | None = None):
        # ``procedure`` is optional so direct construction (e.g.
        # from tests) is possible. When ``None``, the adapter falls
        # back to the canonical procedure by attribute lookup at
        # call time. The evaluator passes the procedure explicitly
        # so monkey-patches on the module symbol propagate.
        self._procedure = procedure

    def run(self, repo_path: Path) -> list[dict]:
        if self._procedure is not None:
            return self._procedure(repo_path)
        # Fallback: import and call the canonical procedure by
        # attribute lookup. Used when the adapter is constructed
        # directly (e.g. by a test) without the evaluator.
        import importlib  # local import to keep top-level cheap
        proc_mod = importlib.import_module("arsenal_evaluate")
        return proc_mod._run_recon_procedure(repo_path)
