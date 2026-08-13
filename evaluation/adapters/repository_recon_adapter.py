"""Repository Recon adapter protocol (ARS-W3 Phase 1).

An adapter wraps a Repository Recon procedure and presents it to the
ARS-04 evaluator in the documented findings shape. The protocol is
intentionally minimal so a future Loadout productized procedure (or
any other procedure that satisfies the shape contract) can be plugged
in without changing the evaluator's invocation logic.

The protocol is a duck-typed Protocol class: any object exposing
``name`` and ``run(repo_path)`` satisfies the contract. We use
``typing.Protocol`` so static type checkers (and human readers) can
recognize the contract without forcing a rigid base class.
"""

from __future__ import annotations

from pathlib import Path
from typing import Protocol


# Canonical findings shape accepted by the evaluator. Any adapter
# returning a list of dicts shaped like this is acceptable. The shape
# mirrors what ``scripts/arsenal_evaluate._run_recon_procedure``
# returns; the two are kept coherent by the test suite.
#
# Each finding has exactly:
#
#   * kind:     "presence" | "absence" | "capability_identity"
#   * subject:  canonical subject string (human-readable)
#   * evidence: repo-relative path string the finding inspects
#   * actual:   raw observation. For presence/absence findings,
#               actual is a bool (path.exists()). For
#               capability_identity findings, actual is a dict
#               ({id, lifecycle, evaluation_status}) or None when
#               the capability fragment is missing/unreadable.
#
# An adapter that returns findings with unknown ``kind`` values is
# accepted by the evaluator -- the evaluator only matches findings
# whose ``evidence`` matches an assertion's ``evidence_path`` -- but
# the artifact's case_results.observations would then report FAILURE
# for any assertion that expected a known kind.
ALLOWED_KINDS = frozenset({"presence", "absence", "capability_identity"})


class RepositoryReconAdapter(Protocol):
    """Duck-typed contract an adapter must satisfy.

    The evaluator does not check the type at runtime; it only calls
    ``adapter.name`` and ``adapter.run(repo_path)``. The Protocol
    class is here for documentation and static checking.
    """

    name: str
    """Stable identifier of the adapter.

    Examples:
      * ``internal-fixture-procedure``
      * ``shell-loadout-recon``

    The name MUST be stable across runs so the evaluation artifact
    can record it as provenance and the digest can remain
    deterministic.
    """

    def run(self, repo_path: Path) -> list[dict]:
        """Invoke the procedure and return findings.

        ``repo_path`` is the on-disk path to the repository under
        inspection. The adapter MUST be deterministic and read-only
        with respect to ``repo_path`` (no writes, no network, no
        remote credentials). The returned list MUST satisfy
        ``ALLOWED_KINDS`` for each finding's ``kind`` field, and
        MUST be ordered deterministically (the evaluator does NOT
        sort; it iterates in order).
        """
        ...


def validate_findings(findings: list[dict]) -> None:
    """Refuse findings that violate the adapter contract.

    The evaluator calls this in defense-in-depth mode (it does not
    silently accept garbage). Raises ``ValueError`` on the first
    shape violation it observes so the failure mode is loud.
    """
    if not isinstance(findings, list):
        raise ValueError(
            f"adapter returned non-list findings: {type(findings).__name__}"
        )
    for i, f in enumerate(findings):
        if not isinstance(f, dict):
            raise ValueError(f"finding[{i}] is not a dict: {f!r}")
        kind = f.get("kind")
        if kind not in ALLOWED_KINDS:
            raise ValueError(
                f"finding[{i}].kind {kind!r} not in {sorted(ALLOWED_KINDS)}"
            )
        if not isinstance(f.get("subject"), str) or not f.get("subject"):
            raise ValueError(f"finding[{i}].subject must be a non-empty string")
        if not isinstance(f.get("evidence"), str) or not f.get("evidence"):
            raise ValueError(f"finding[{i}].evidence must be a non-empty string")
