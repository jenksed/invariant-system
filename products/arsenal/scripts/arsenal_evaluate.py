#!/usr/bin/env python3
"""Project Arsenal Repository Recon Method Evaluation (ARS-04).

This script evaluates the canonical Repository Recon method
(``repository-recon/architecture-anchor-incremental``) against a
bounded, deterministic local-repository corpus and emits an evaluation
artifact that:

* identifies the method and its declared version;
* names the contexts the method is qualified for (per the canonical
  QMR) and the corpus contexts actually exercised;
* reports per-case successes, misses, unsupported claims, unknowns,
  failures, and concrete evidence references;
* computes a deterministic run digest so the artifact is reproducible;
* declares the resulting epistemic conclusion for the method (which
  MUST remain ``experimental`` in v0 -- the system is allowed to
  conclude ``experimental -> experimental``);
* describes the qualification gap honestly;
* optionally emits a revised QMR that records the run as new
  evidence; the revised QMR is always ``experimental`` and never
  promotes capability lifecycle or evaluation state.

Scope:

* The script does NOT exercise runtime authority, network, or git
  writes. Every file it reads is a tracked or fixture file.
* The script does NOT auto-promote capability.lifecycle or
  capability.evaluation.status. Those values are owned by the
  canonical capability fragment and a qualification receipt.
* The script does NOT invent a composite quality score. The
  per-case metrics and the run digest are honest counts of what
  was observed, not a synthetic benchmark.

Usage:

    python3 scripts/arsenal_evaluate.py repository-recon \\
        --corpus evaluation/method-cases/corpus.manifest.json \\
        --out .arsenal-eval/repository-recon-evaluation.v0.json

    python3 scripts/arsenal_evaluate.py validate \\
        --artifact .arsenal-eval/repository-recon-evaluation.v0.json

Exit codes (ARS-04):

    0  PASS                  -- evaluation completed deterministically
    2  MISSING_CORPUS        -- corpus manifest is missing or unreadable
    3  INVALID_CORPUS        -- corpus manifest fails its own shape checks
    4  MISSING_METHOD_RECORD -- the canonical QMR is missing
    5  METHOD_RECORD_INVALID -- the canonical QMR fails validation
    6  CASE_ERROR            -- a case could not be loaded or its repo
                                does not exist
    7  UNSUPPORTED           -- the user asked for a subcommand or
                                method that is not yet supported
    8  UNKNOWN               -- unexpected failure (see stderr)

The script never returns ``1`` so a non-zero exit is always
machine-classifiable.
"""

from __future__ import annotations

import argparse
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
METHOD_RECORDS_DIR = ROOT / "evaluation" / "method-records"
METHOD_CASES_DIR = ROOT / "evaluation" / "method-cases"
ADAPTERS_DIR = ROOT / "evaluation" / "adapters"
DEFAULT_CORPUS = METHOD_CASES_DIR / "corpus.manifest.json"
DEFAULT_OUT = ROOT / ".arsenal-eval" / "repository-recon-evaluation.v0.json"

# Canonical method identity. ARS-04 evaluates the existing Repository
# Recon QMR. The string MUST match the method_id emitted by the
# canonical QMR. If a later QMR supersedes it, this constant must be
# updated deliberately so the evaluator never silently re-evaluates an
# unrelated method.
TARGET_METHOD_ID = "repository-recon/architecture-anchor-incremental"
TARGET_CAPABILITY_ID = "capability.recon"
TARGET_METHOD_VERSION = "0.1.0"

EXIT_CODE = {
    "PASS": 0,
    "MISSING_CORPUS": 2,
    "INVALID_CORPUS": 3,
    "MISSING_METHOD_RECORD": 4,
    "METHOD_RECORD_INVALID": 5,
    "CASE_ERROR": 6,
    "UNSUPPORTED": 7,
    "UNKNOWN": 8,
}

# The Qualification Gap vocabulary is intentionally small and honest.
# These are the only allowed ``qualification_gap`` strings the
# evaluator may emit. Any other value is a configuration error.
ALLOWED_GAP_LABELS = frozenset(
    {
        "no-qualification-receipt-bound-to-capability",
        "no-behavioral-efficacy-evidence",
        "bounded-evaluator-only",
        "experimental-to-experimental",
    }
)

# The epistemic conclusion vocabulary is also closed. The evaluator
# may only emit one of these tokens. The v0 evaluator must conclude
# ``experimental``; promotion to ``qualified`` is not implemented in
# v0 and requires an additional, separate design.
ALLOWED_EPISTEMIC_CONCLUSIONS = frozenset({"experimental"})


# ---------------------------------------------------------------------------
# Method record loading (small adapter over arsenal_method_record).
# ---------------------------------------------------------------------------

def _find_method_record(records_dir: Path, method_id: str) -> Path:
    """Return the path to the QMR file for ``method_id``.

    Raises ``FileNotFoundError`` with a stable message when no record
    is found. The canonical QMR is identified by its method_id; this
    keeps the evaluator's selection logic deterministic and refuses
    to silently evaluate a record the operator did not name.
    """
    if yaml is None:
        raise RuntimeError(
            "PyYAML is required to load the canonical QMR; "
            "install pyyaml or run scripts/test-arsenal-evaluate.py"
        )
    for path in sorted(records_dir.glob("*.yaml")) + sorted(records_dir.glob("*.yml")):
        with path.open("r", encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        if isinstance(data, dict) and data.get("method_id") == method_id:
            return path
    raise FileNotFoundError(
        f"no QMR found for method_id {method_id!r} under {_rel(records_dir)}"
    )


def _load_method_record(path: Path) -> dict:
    """Load the canonical QMR as a dict and return a *frozen* summary
    suitable for embedding in the evaluation artifact.

    The summary contains only the identity, version, qualified_for,
    and provenance fields the evaluator needs to bind the run to the
    QMR. It does NOT include the full QMR body so the artifact stays
    compact and the QMR's ``provenance.record_digest`` remains the
    authoritative record digest.
    """
    if yaml is None:
        raise RuntimeError("PyYAML is required to load the canonical QMR")
    with path.open("r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: QMR must be a YAML mapping")
    return {
        "method_id": data.get("method_id"),
        "method_version": data.get("method_version"),
        "status": data.get("status"),
        "qualified_for": data.get("qualified_for"),
        "provenance": {
            "arsenal_commit": data.get("provenance", {}).get("arsenal_commit"),
            "record_digest": data.get("provenance", {}).get("record_digest"),
        },
        "procedure_ref": data.get("procedure_ref"),
        "_path": _rel(path),
    }


# ---------------------------------------------------------------------------
# Corpus loading.
# ---------------------------------------------------------------------------

def _load_corpus(path: Path) -> dict:
    """Load and minimally validate the corpus manifest."""
    if not path.is_file():
        raise FileNotFoundError(f"corpus manifest not found: {_rel(path)}")
    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise ValueError(f"corpus manifest must be an object: {_rel(path)}")
    corpus = data.get("corpus")
    if not isinstance(corpus, dict):
        raise ValueError(f"corpus manifest missing 'corpus' object: {_rel(path)}")
    if corpus.get("method_id") != TARGET_METHOD_ID:
        raise ValueError(
            f"corpus method_id {corpus.get('method_id')!r} does not match "
            f"target {TARGET_METHOD_ID!r}"
        )
    if corpus.get("capability_id") != TARGET_CAPABILITY_ID:
        raise ValueError(
            f"corpus capability_id {corpus.get('capability_id')!r} does not match "
            f"target {TARGET_CAPABILITY_ID!r}"
        )
    cases = corpus.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError(f"corpus manifest has no cases: {_rel(path)}")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError(f"corpus case must be an object: {case!r}")
        cid = case.get("id")
        if not isinstance(cid, str) or not cid:
            raise ValueError(f"corpus case missing id: {case!r}")
        if cid in seen:
            raise ValueError(f"corpus case id duplicate: {cid!r}")
        seen.add(cid)
        rel = case.get("path")
        if not isinstance(rel, str) or not rel:
            raise ValueError(f"corpus case {cid!r} missing path")
    return corpus


# ---------------------------------------------------------------------------
# Method run procedure.
# ---------------------------------------------------------------------------
#
# The Repository Recon method's procedure is, per its canonical QMR,
# a static, deterministic, read-only inspector of on-disk state. The
# procedure does NOT consult any expected.json, it does NOT consult
# the corpus manifest, and it does NOT consult the evaluator. It
# produces a list of findings (kind, subject, evidence_path, actual)
# that the evaluator then compares against the expected assertions.
#
# The procedure is intentionally a separate function so:
#   * tests can stub it (replacing its output) to prove the
#     evaluator's behavior is output-driven;
#   * the procedure's output is the sole ground truth consulted by
#     the evaluator -- the fixture state is never re-inspected
#     during assertion evaluation;
#   * the procedure can be exercised independently of the corpus
#     loading and artifact assembly logic.

# Canonical anchors scanned by the procedure. Each anchor is a
# (evidence_path, subject, kind) triple. ``kind`` is the canonical
# classification of the anchor (informational; the assertion's
# kind drives the comparison logic). The procedure emits one
# finding per anchor whose ``actual`` is ``path.exists()``; the
# evaluator decides whether a presence or absence assertion
# matches that observation.
PRESENCE_ANCHORS: tuple[tuple[str, str], ...] = (
    ("AGENTS.md", "AGENTS.md"),
    ("README.md", "README.md"),
    ("src/main.py", "src/"),
    ("engineering/doctrine/CORE.md", "engineering/doctrine/CORE.md"),
    ("arsenal/capabilities/recon.json", "arsenal/capabilities/recon.json"),
    ("evaluation/method-records/example.yaml", "evaluation/method-records/example.yaml"),
    ("scripts/recon_method.py", "scripts/recon_method.py"),
)

# Anchors the procedure classifies as absence-typed. These are
# canonical ownership layers; the procedure still emits a finding
# for each, with ``actual = path.exists()``, so either a presence
# or an absence assertion can match the same anchor.
ABSENCE_ANCHORS: tuple[tuple[str, str], ...] = (
    ("engineering/", "engineering/doctrine"),
    ("arsenal/capabilities/", "arsenal/capabilities"),
    ("evaluation/method-records/", "evaluation/method-records"),
)

CAPABILITY_IDENTITY_PATH = "arsenal/capabilities/recon.json"

# Adapter surface (ARS-W3). The evaluator can be configured to
# invoke an external procedure via an adapter; the default is the
# internal fixture procedure. The closed vocabulary here mirrors the
# adapter names defined under ``evaluation/adapters/``.
ADAPTER_INTERNAL = "internal-fixture-procedure"
ADAPTER_SHELL_LOADOUT = "shell-loadout-recon"
ADAPTER_LOADOUT_RUNTIME = "loadout-runtime"
ALLOWED_ADAPTERS = frozenset(
    {ADAPTER_INTERNAL, ADAPTER_SHELL_LOADOUT, ADAPTER_LOADOUT_RUNTIME}
)


def _resolve_adapter(
    adapter_name: str,
    *,
    adapter_input: str | None,
    loadout_root: str | None = None,
):
    """Resolve an adapter by name. Returns the adapter instance.

    The internal adapter takes no input. The shell adapter requires
    ``adapter_input`` (a path to a findings JSON file). The Loadout
    runtime adapter requires ``loadout_root`` (a path to the Loadout
    installation directory).
    """
    if adapter_name not in ALLOWED_ADAPTERS:
        raise ValueError(
            f"unknown adapter {adapter_name!r}; "
            f"allowed: {sorted(ALLOWED_ADAPTERS)}"
        )
    if not ADAPTERS_DIR.is_dir():
        raise FileNotFoundError(
            f"adapter package missing: {_rel(ADAPTERS_DIR)}"
        )
    # Ensure the adapter package is importable.
    sys.path.insert(0, str(ROOT))
    if adapter_name == ADAPTER_INTERNAL:
        from evaluation.adapters.internal_fixture_adapter import (  # type: ignore
            InternalFixtureProcedureAdapter,
        )
        # Pass the procedure function at construction time so
        # monkey-patches on the module symbol flow through. The
        # adapter stores it; ``run`` calls it directly.
        return InternalFixtureProcedureAdapter(procedure=_run_recon_procedure)
    if adapter_name == ADAPTER_SHELL_LOADOUT:
        if not adapter_input:
            raise ValueError(
                f"adapter {adapter_name!r} requires --adapter-input PATH"
            )
        from evaluation.adapters.shell_loadout_adapter import (  # type: ignore
            ShellLoadoutReconAdapter,
        )
        return ShellLoadoutReconAdapter(Path(adapter_input))
    if adapter_name == ADAPTER_LOADOUT_RUNTIME:
        if not loadout_root:
            raise ValueError(
                f"adapter {adapter_name!r} requires --loadout-root PATH"
            )
        from evaluation.adapters.loadout_runtime_adapter import (  # type: ignore
            LoadoutRuntimeAdapter,
        )
        return LoadoutRuntimeAdapter(Path(loadout_root))
    raise ValueError(f"unhandled adapter {adapter_name!r}")


def _run_recon_procedure(repo_path: Path) -> list[dict]:
    """Invoke the Repository Recon method's procedure on ``repo_path``.

    The procedure is deterministic and read-only. It returns a list
    of findings, each shaped as:

        {
            "kind":    "presence" | "absence" | "capability_identity",
            "subject": <canonical subject string>,
            "evidence": <repo-relative path string>,
            "actual":  <bool for presence/absence, dict for
                         capability_identity, None when unreadable>,
        }

    The procedure never inspects any expected.json, corpus manifest,
    or evaluator-internal state. For non-capability anchors,
    ``actual`` is the raw ``path.exists()`` observation so the same
    finding can satisfy either a presence or an absence assertion.
    For the capability fragment anchor, two findings are emitted:
    one presence observation (``actual = path.exists()``) and one
    capability_identity observation (``actual = parsed dict or
    None``). Findings are emitted in a stable order: presence
    anchors first (in declaration order), then absence anchors
    (in declaration order), then the capability identity anchor.
    """
    findings: list[dict] = []
    for evidence_rel, subject in PRESENCE_ANCHORS:
        if evidence_rel == CAPABILITY_IDENTITY_PATH:
            continue
        findings.append({
            "kind": "presence",
            "subject": subject,
            "evidence": evidence_rel,
            "actual": (repo_path / evidence_rel).exists(),
        })
    for evidence_rel, subject in ABSENCE_ANCHORS:
        findings.append({
            "kind": "absence",
            "subject": subject,
            "evidence": evidence_rel,
            "actual": (repo_path / evidence_rel).exists(),
        })
    target = repo_path / CAPABILITY_IDENTITY_PATH
    # Presence observation for the capability fragment.
    findings.append({
        "kind": "presence",
        "subject": "arsenal/capabilities/recon.json",
        "evidence": CAPABILITY_IDENTITY_PATH,
        "actual": target.exists(),
    })
    # Capability identity observation (richer actual value).
    actual_cap: dict | None = None
    if target.exists():
        try:
            with target.open("r", encoding="utf-8") as fh:
                cap_doc = json.load(fh)
            cap = cap_doc.get("capability") if isinstance(cap_doc, dict) else None
            if isinstance(cap, dict):
                actual_cap = {
                    "id": cap.get("id"),
                    "lifecycle": cap.get("lifecycle"),
                    "evaluation_status": (cap.get("evaluation") or {}).get("status"),
                }
        except (OSError, json.JSONDecodeError):
            actual_cap = None
    findings.append({
        "kind": "capability_identity",
        "subject": "arsenal/capabilities/recon.json",
        "evidence": CAPABILITY_IDENTITY_PATH,
        "actual": actual_cap,
    })
    return findings


# ---------------------------------------------------------------------------
# Case loading and assertion evaluation.
# ---------------------------------------------------------------------------

def _load_case(case: dict) -> dict:
    """Resolve and minimally validate a single case.

    The on-disk shape is:
        <case.path>/
            repo/                 # the local fixture repository
            expected.json         # the expected assertions

    The ``repo/`` directory is intentionally NOT a git working copy;
    the recon method only inspects on-disk state, so the case
    fixtures remain portable and have no git/network dependency.
    """
    rel = case["path"]
    case_path = ROOT / rel
    repo_path = case_path / "repo"
    expected_path = case_path / "expected.json"
    if not case_path.is_dir():
        raise FileNotFoundError(f"case directory missing: {rel}")
    if not repo_path.is_dir():
        raise FileNotFoundError(f"case repo directory missing: {rel}/repo")
    if not expected_path.is_file():
        raise FileNotFoundError(f"case expected.json missing: {rel}/expected.json")
    with expected_path.open("r", encoding="utf-8") as fh:
        expected = json.load(fh)
    if not isinstance(expected, dict):
        raise ValueError(f"{rel}/expected.json: must be a JSON object")
    return {
        "id": case["id"],
        "context_kind": case.get("context_kind"),
        "repo_path": repo_path,
        "expected": expected,
    }


def _evaluate_assertion(assertion: dict, procedure_outputs: list[dict]) -> dict:
    """Evaluate one expected assertion against the procedure's outputs.

    The procedure's outputs are the SOLE ground truth consulted. The
    fixture state is never re-inspected by this function. If the
    procedure did not produce a finding for the assertion's
    ``evidence_path``, the outcome is ``FAILURE`` with a message
    naming the missing anchor -- which proves the evaluation is
    output-driven, not fixture-presence-driven.

    For ``presence`` and ``absence`` assertions, the procedure
    emits a single ``actual = path.exists()`` finding per anchor
    and the assertion's ``kind`` decides whether presence or
    absence is the success condition. For ``capability_identity``
    assertions the procedure emits a separate finding carrying the
    parsed capability fields; matching is by ``evidence_path`` and
    ``kind == capability_identity``.
    """
    kind = assertion.get("kind")
    subject = assertion.get("subject", "<missing>")
    evidence_rel = assertion.get("evidence_path")
    if not isinstance(evidence_rel, str) or not evidence_rel:
        return {
            "id": assertion.get("id"),
            "kind": kind,
            "subject": subject,
            "outcome": "FAILURE",
            "expected": assertion.get("expected"),
            "actual": None,
            "evidence": None,
            "message": "assertion missing evidence_path",
        }

    if kind in ("presence", "absence"):
        matches = [f for f in procedure_outputs if f.get("evidence") == evidence_rel]
    elif kind == "capability_identity":
        matches = [
            f for f in procedure_outputs
            if f.get("evidence") == evidence_rel
            and f.get("kind") == "capability_identity"
        ]
    else:
        matches = []

    if not matches:
        # The procedure never produced a finding the evaluator can
        # match against. The evaluation is honestly reported as a
        # FAILURE -- not a silent pass.
        return {
            "id": assertion.get("id"),
            "kind": kind,
            "subject": subject,
            "outcome": "FAILURE",
            "expected": assertion.get("expected"),
            "actual": None,
            "evidence": evidence_rel,
            "message": (
                f"procedure did not produce a finding for evidence_path "
                f"{evidence_rel!r} with kind={kind!r}"
            ),
        }

    finding = matches[0]
    actual = finding.get("actual")

    if kind == "presence":
        outcome = "SUCCESS" if actual is True else "MISS"
    elif kind == "absence":
        outcome = "SUCCESS" if actual is False else "MISS"
    elif kind == "capability_identity":
        if not isinstance(actual, dict):
            outcome = "FAILURE"
            actual = None
        else:
            expected = {
                "id": assertion.get("expected_id"),
                "lifecycle": assertion.get("expected_lifecycle"),
                "evaluation_status": assertion.get("expected_evaluation_status"),
            }
            ok = all(
                actual.get(k) == v
                for k, v in expected.items()
                if v is not None
            )
            outcome = "SUCCESS" if ok else "MISS"
    else:
        outcome = "FAILURE"
        actual = None

    return {
        "id": assertion.get("id"),
        "kind": kind,
        "subject": subject,
        "outcome": outcome,
        "expected": assertion.get("expected"),
        "actual": actual,
        "evidence": evidence_rel,
    }


def _evaluate_case(case: dict, adapter) -> dict:
    """Run the procedure and compare its outputs against expected assertions.

    The procedure is invoked ONCE per case via ``adapter.run``. The
    findings are the sole ground truth the evaluator compares against;
    the fixture state is not re-inspected during assertion evaluation.

    The aggregate categorizes assertions into:

    * ``successes``        -- the procedure's output matches the
                              expected value.
    * ``misses``           -- the procedure produced a finding whose
                              actual value does NOT match the
                              expected value.
    * ``failures``         -- the procedure did not produce a
                              matching finding at all (the
                              evaluation is honestly output-driven).
    * ``unknowns``         -- context-specific gaps the case
                              intentionally documents (e.g. the
                              absence of AGENTS.md in an incomplete
                              repo). These are reported as first-class
                              negative knowledge, not as bugs.
    * ``unsupported_claims`` -- claims the case authorises the
                              evaluator to observe as NOT supported
                              by the procedure's output. Surfacing
                              them keeps the method honest.
    """
    expected = case["expected"]
    expected_assertions = expected.get("expected_assertions") or []
    expected_unknowns = set(expected.get("unknowns_required") or [])
    expected_unknowns |= set(expected.get("unknowns_allowed") or [])
    unsupported_allowed = set(expected.get("unsupported_claims_allowed") or [])

    procedure_outputs = adapter.run(case["repo_path"])

    observations: list[dict] = []
    for assertion in expected_assertions:
        observations.append(_evaluate_assertion(assertion, procedure_outputs))

    successes = [o["id"] for o in observations if o["outcome"] == "SUCCESS"]
    misses = [o["id"] for o in observations if o["outcome"] == "MISS"]
    failures = [o["id"] for o in observations if o["outcome"] == "FAILURE"]

    # Case-derived unknowns: the case is allowed (or required) to
    # document unknowns; the evaluator reports them verbatim.
    unknowns: list[str] = sorted(expected_unknowns)
    unsupported: list[str] = sorted(unsupported_allowed)

    return {
        "case_id": case["id"],
        "context_kind": case.get("context_kind"),
        "repo_path": _rel(case["repo_path"]),
        "expected_context": expected.get("context_kind"),
        "expected_epistemic_conclusion": expected.get("expected_epistemic_conclusion"),
        "procedure_output_count": len(procedure_outputs),
        "observation_count": len(observations),
        "successes": successes,
        "misses": misses,
        "failures": failures,
        "unknowns": unknowns,
        "unsupported_claims": unsupported,
        "observations": observations,
    }


# ---------------------------------------------------------------------------
# Artifact assembly and determinism.
# ---------------------------------------------------------------------------

def _deterministic_artifact_payload(payload: dict) -> str:
    """Serialize ``payload`` in the canonical form used to compute
    the run digest.

    The digest is the SHA-256 of the JSON serialization of the
    artifact with the ``run_digest`` field replaced by the
    64-zero placeholder. This mirrors the QMR digest rule (see
    ``scripts/arsenal_method_record.py``) and keeps digest
    semantics coherent across the two record families.
    """
    payload = json.loads(json.dumps(payload, sort_keys=True))
    payload["run_digest"] = "sha256:" + ("0" * 64)
    return json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def _compute_run_digest(payload: dict) -> str:
    serialized = _deterministic_artifact_payload(payload).encode("utf-8")
    return "sha256:" + hashlib.sha256(serialized).hexdigest()


def _assess_qualification_gap(case_results: list[dict]) -> tuple[list[dict], str]:
    """Determine the qualification gap for the whole run.

    The gap is a small, honest label drawn from
    ``ALLOWED_GAP_LABELS``. The v0 evaluator's gap is always
    ``experimental-to-experimental`` because the system is
    permitted to conclude ``experimental -> experimental`` -- the
    qualification bar is not yet crossed -- and the canonical
    capability state for ``capability.recon`` is still
    ``draft``/``unassessed``.

    The list of ``gaps`` carries the per-label rationale so the
    artifact is self-explanatory without an external doc.

    The returned string is the *primary* gap label (the one that
    names the epistemic conclusion). Additional per-rationale
    labels are reported as a list to keep the closed vocabulary
    observable in the artifact body.
    """
    gaps: list[dict] = []
    any_miss = any(c["misses"] for c in case_results)
    any_failure = any(c["failures"] for c in case_results)
    if any_miss or any_failure:
        gaps.append({
            "label": "bounded-evaluator-only",
            "rationale": (
                "at least one case produced a miss or failure; the "
                "evaluator is bounded by what is on disk in each fixture"
            ),
        })
    gaps.append({
        "label": "no-behavioral-efficacy-evidence",
        "rationale": (
            "ARS-04 evaluates structural recon behavior only; "
            "behavioral efficacy requires a controlled model/harness "
            "run that is designed-not-run in v0"
        ),
    })
    gaps.append({
        "label": "no-qualification-receipt-bound-to-capability",
        "rationale": (
            "no qualification receipt exists for capability.recon; the "
            "QMR remains experimental and the capability stays "
            "draft/unassessed"
        ),
    })
    gaps.append({
        "label": "experimental-to-experimental",
        "rationale": (
            "the qualification bar is not crossed; the v0 evaluator is "
            "explicitly allowed to conclude experimental -> experimental"
        ),
    })
    invalid = [g["label"] for g in gaps if g["label"] not in ALLOWED_GAP_LABELS]
    if invalid:
        raise ValueError(f"non-allowlisted gap labels: {invalid}")
    return gaps, "experimental-to-experimental"


def _assemble_artifact(
    method: dict,
    corpus: dict,
    case_results: list[dict],
    arsenal_commit: str | None,
    *,
    adapter: dict | None = None,
) -> dict:
    """Assemble the final evaluation artifact.

    The artifact is intentionally compact but every field carries a
    meaning. The artifact is the input to the ``validate`` subcommand
    and the binding evidence a future QMR can cite.

    ``adapter`` records the procedure-invocation adapter identity
    (the wrapper through which the procedure was invoked). The
    default is the internal fixture procedure; an external adapter
    (e.g. the shell Loadout Recon placeholder) is recorded when the
    evaluator is configured with ``--adapter``.
    """
    total_assertions = sum(c["observation_count"] for c in case_results)
    total_success = sum(len(c["successes"]) for c in case_results)
    total_miss = sum(len(c["misses"]) for c in case_results)
    total_failure = sum(len(c["failures"]) for c in case_results)
    total_unknowns = sum(len(c["unknowns"]) for c in case_results)
    total_unsupported = sum(len(c["unsupported_claims"]) for c in case_results)

    gap_entries, gap_label = _assess_qualification_gap(case_results)
    conclusion = "experimental"
    if conclusion not in ALLOWED_EPISTEMIC_CONCLUSIONS:
        raise ValueError(f"non-allowlisted conclusion: {conclusion!r}")

    contexts_evaluated = [c["context_kind"] for c in case_results if c.get("context_kind")]
    contexts_declared = method.get("qualified_for", {}).get("contexts", [])

    # Adapter identity is mandatory so the artifact is always
    # self-describing. The default adapter is the internal fixture
    # procedure; the evaluator never silently switches.
    if adapter is None:
        adapter = {
            "name": ADAPTER_INTERNAL,
            "input": None,
            "module": "scripts.arsenal_evaluate:_run_recon_procedure",
        }

    payload: dict = {
        "schema_version": "1.0.0",
        "schema": "arsenal/method-evaluation/v0",
        "method": {
            "method_id": method["method_id"],
            "method_version": method["method_version"],
            "method_record_path": method["_path"],
            "method_record_digest": method["provenance"].get("record_digest"),
            "method_status": method["status"],
            "procedure_ref": method.get("procedure_ref"),
        },
        "capability": {
            "id": TARGET_CAPABILITY_ID,
        },
        "contexts": {
            "declared_by_method": contexts_declared,
            "exercised_by_corpus": contexts_evaluated,
        },
        "corpus": {
            "id": corpus.get("id"),
            "title": corpus.get("title"),
            "path": _rel(DEFAULT_CORPUS),
        },
        "provenance": {
            "arsenal_commit": arsenal_commit,
            "evaluator": "scripts/arsenal_evaluate.py",
            "model": "not-applicable",
            "harness": "deterministic-python-adapter",
            "remote_credentials_used": False,
            "adapter": adapter,
        },
        "metrics": {
            "cases_total": len(case_results),
            "assertions_evaluated": total_assertions,
            "assertions_supported": total_success,
            "assertions_missed": total_miss,
            "assertions_failed": total_failure,
            "unknowns_documented": total_unknowns,
            "unsupported_claims_documented": total_unsupported,
            "evidence_references": sum(
                1 for c in case_results for o in c["observations"] if o.get("evidence")
            ),
            "repetitions": 1,
        },
        "case_results": case_results,
        "qualification_gap": {
            "label": gap_label,
            "gaps": gap_entries,
        },
        "epistemic_conclusion": conclusion,
        "qmr_revisions": {
            "auto_promote_method_status": False,
            "auto_promote_capability_lifecycle": False,
            "auto_promote_capability_evaluation_status": False,
            "emit_revised_qmr": True,
            "revised_qmr_status": "experimental",
        },
        "limitations": [
            "ARS-04 evaluates structural recon behavior over on-disk fixtures; "
            "it does not exercise any model or harness.",
            "The corpus is bounded by what the evaluator can write to disk; "
            "wider real-world repositories must be evaluated by a separate, "
            "future design.",
            "The evaluator never promotes capability.lifecycle or "
            "capability.evaluation.status. Those are owned by the canonical "
            "capability fragment and the qualification receipts.",
            "A revised QMR is emitted as evidence (status: experimental) but "
            "is not authoritative; authority over capability state remains "
            "with the canonical capability fragment.",
            "ARS-W3 Phase 2 added the loadout-runtime adapter so the evaluator "
            "can invoke the Loadout W3 Repository Recon v1 procedure "
            "(d95927fbb675902d0fba992684b101ff60ff5a52). The v0 qualified-method-record "
            "contract has no adapter concept; the canonical QMR's procedure_ref "
            "is a single SHA-256 and cannot simultaneously bind to multiple "
            "adapters. Promoting the QMR to qualified therefore requires a "
            "contract evolution that introduces an adapter concept (adapter "
            "identity, adapter_version, adapter_input_provenance) and a "
            "productized-vs-fixture status qualifier; this is the W3 Phase 2 "
            "graduation gap and is documented in docs/arsenal-method-evaluation.md.",
            "When the canonical Arsenal corpus is run through the loadout-runtime "
            "adapter, the metrics show assertions_failed > 0 for paths Loadout does "
            "not catalog (e.g. arsenal/capabilities/recon.json, "
            "engineering/doctrine/CORE.md, scripts/recon_method.py). This is the "
            "honest output-driven signal that Loadout's catalogue differs from "
            "Arsenal's; the corpus is Arsenal-canonical and not a fair test for "
            "the Loadout productized target until a Loadout-canonical corpus exists.",
        ],
    }
    payload["run_digest"] = _compute_run_digest(payload)
    return payload


def _build_adapter_block(adapter, args) -> dict:
    """Build the ``provenance.adapter`` block for the artifact.

    The block records the adapter identity (name), the input path
    (when applicable), the module path (when applicable), and the
    Loadout installation root (when applicable). Every field is
    stable across runs so the run_digest remains deterministic.
    """
    block: dict = {
        "name": adapter.name,
        "input": None,
        "module": None,
        "loadout_root": None,
    }
    if adapter.name == ADAPTER_INTERNAL:
        block["module"] = (
            "evaluation.adapters.internal_fixture_adapter:"
            "InternalFixtureProcedureAdapter"
        )
    elif adapter.name == ADAPTER_SHELL_LOADOUT:
        block["input"] = (
            _rel(Path(args.adapter_input).resolve())
            if args.adapter_input
            else None
        )
        block["module"] = (
            "evaluation.adapters.shell_loadout_adapter:"
            "ShellLoadoutReconAdapter"
        )
    elif adapter.name == ADAPTER_LOADOUT_RUNTIME:
        block["loadout_root"] = (
            _rel(Path(args.loadout_root).resolve())
            if args.loadout_root
            else None
        )
        block["module"] = (
            "evaluation.adapters.loadout_runtime_adapter:"
            "LoadoutRuntimeAdapter"
        )
    return block


def _emit_revised_qmr(artifact: dict, out_path: Path) -> str:
    """Emit a revised QMR that binds the run as new evidence.

    The revised QMR:

    * keeps ``status: experimental`` -- the system is NOT permitted
      to conclude ``qualified`` in v0;
    * records the run as a new evidence reference;
    * records the new observed strengths and observed failures
      derived from the run;
    * sets ``provenance.record_digest`` to the canonical SHA-256 of
      the new record body (with the digest replaced by the
      64-zero placeholder).

    The new QMR is emitted into ``out_path`` (or its default). The
    caller decides whether to commit it; the evaluator never
    auto-commits or auto-pushes.
    """
    method_id = artifact["method"]["method_id"]
    if method_id != TARGET_METHOD_ID:
        raise ValueError(
            f"refusing to emit revised QMR for non-canonical method {method_id!r}"
        )
    # Build a YAML-shaped record using the same key order the
    # existing canonical record uses, so future reviewers find the
    # fields where they expect them.
    strengths: list[str] = []
    for case in artifact["case_results"]:
        if case["successes"] and not case["misses"] and not case["failures"]:
            strengths.append(
                f"{case['case_id']}: asserted the canonical recon "
                f"context in a deterministic fixture"
            )
    if not strengths:
        strengths.append(
            "no-case-passed-clearly-this-run-serves-as-negative-evidence"
        )
    failures: list[str] = [
        f"{case['case_id']}: misses={len(case['misses'])} "
        f"failures={len(case['failures'])} "
        f"unknowns={len(case['unknowns'])}"
        for case in artifact["case_results"]
    ]
    failures.append(
        "no-qualification-receipt-bound-to-capability.recon"
    )
    failures.append(
        "no-behavioral-efficacy-evidence-in-v0"
    )

    # We assemble the record as a dict and let the validator compute
    # the canonical digest. To keep this slice minimal, the record
    # is written in YAML-friendly shape; the validator reads it
    # back and re-canonicalizes.
    body: dict = {
        "schema": "engineering-system/qualified-method-record/v0",
        "method_id": method_id,
        "method_version": TARGET_METHOD_VERSION,
        "status": "experimental",
        "qualified_for": {
            "outcome": "understand-a-repository",
            "contexts": [
                "local-git-repository-with-AGENTS.md",
                "local-git-repository-with-arsenal-canonical-contracts",
            ],
            "exclusions": [
                "incomplete-or-ambiguous-local-repositories",
                "behavioral-efficacy-claims-about-model-performance",
                "runtime-authority-or-production-system-mutation",
                "engineering-system-and-loadout-source-repositories-themselves",
            ],
        },
        "inputs": [
            "repository-state-reference",
            "arsenal-capability-fragment-set",
            "canonical-engineering-doctrine-pointer",
            "project-decision-record-set",
        ],
        "outputs": [
            "architecture-anchor-map",
            "epistemic-lifecycle-summary",
            "inventory-of-canonical-ownership",
            "gap-register-with-provenance",
        ],
        "procedure_ref": "sha256:" + ("0" * 64),  # placeholder, replaced below
        "evaluation": {
            "evidence_refs": [
                f"evaluation/method-cases/{c['case_id']}"
                for c in artifact["case_results"]
            ] + [
                artifact["corpus"]["path"],
            ],
            "models": ["not-applicable"],
            "repositories": [c["repo_path"] for c in artifact["case_results"]],
            "observed_strengths": strengths,
            "observed_failures": failures,
            "confidence": "bounded",
            "qualification_gap": (
                "qualification requires a qualification receipt bound to "
                "capability.recon for a declared target and adapter; no such "
                "receipt has been emitted by scripts/arsenal_bench.py. "
                "ARS-04 evaluation artifact run_digest="
                f"{artifact['run_digest']}."
            ),
        },
        "provenance": {
            "arsenal_commit": artifact["provenance"].get("arsenal_commit"),
            "record_digest": "sha256:" + ("0" * 64),  # placeholder, replaced below
        },
    }

    # Canonicalize the digest using the same rule as
    # arsenal_method_record._compute_record_digest. We import the
    # validator lazily to avoid a hard import cycle.
    sys.path.insert(0, str(ROOT / "scripts"))
    from arsenal_method_record import _compute_record_digest  # type: ignore

    # The procedure_ref field is part of the record body; we cannot
    # leave it as the zero placeholder forever. The canonical QMR
    # uses a real procedure_ref. We re-use the canonical QMR's
    # procedure_ref so the revised record's digest rule applies the
    # same body. The original QMR's procedure_ref is exposed via
    # the artifact's method block; we read it from there.
    canonical_procedure_ref = artifact["method"].get("procedure_ref")
    if (
        isinstance(canonical_procedure_ref, str)
        and re.match(r"^sha256:[A-Fa-f0-9]{64}$", canonical_procedure_ref)
    ):
        body["procedure_ref"] = canonical_procedure_ref
    digest = _compute_record_digest(body, body["provenance"]["record_digest"])
    if not digest:
        # _compute_record_digest returns True/False; recompute the
        # value with the placeholder then assign.
        placeholder = "sha256:" + ("0" * 64)
        payload = json.loads(json.dumps(body, sort_keys=True))
        payload["provenance"]["record_digest"] = placeholder
        serialized = json.dumps(payload, sort_keys=True, separators=(",", ":"))
        body["provenance"]["record_digest"] = (
            "sha256:" + hashlib.sha256(serialized.encode("utf-8")).hexdigest()
        )

    if yaml is None:
        raise RuntimeError("PyYAML is required to emit a revised QMR")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as fh:
        yaml.safe_dump(body, fh, sort_keys=False, allow_unicode=True)
    return _rel(out_path)


# ---------------------------------------------------------------------------
# CLI commands.
# ---------------------------------------------------------------------------

def _rel(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def cmd_repository_recon(args) -> int:
    """Run the Repository Recon method evaluation and emit artifacts.

    The default corpus lives at
    ``evaluation/method-cases/corpus.manifest.json``; the default
    output lives at
    ``.arsenal-eval/repository-recon-evaluation.v0.json``; the
    default revised QMR lives at
    ``.arsenal-eval/repository-recon.method-record.v0.yaml``.

    All three defaults can be overridden on the command line.

    The ``--adapter`` option configures the procedure-invocation
    adapter. The default is ``internal-fixture-procedure`` (the
    canonical procedure in this script). ``shell-loadout-recon``
    reads findings from a JSON file (``--adapter-input``). The
    adapter identity is recorded in the artifact's
    ``provenance.adapter`` block so the artifact is always
    self-describing about which procedure produced the findings.
    """
    corpus_path = Path(args.corpus) if args.corpus else DEFAULT_CORPUS
    if not corpus_path.is_absolute():
        corpus_path = ROOT / corpus_path
    if not corpus_path.is_file():
        print(f"ERROR missing corpus: {_rel(corpus_path)}", file=sys.stderr)
        return EXIT_CODE["MISSING_CORPUS"]
    try:
        corpus = _load_corpus(corpus_path)
    except (ValueError, FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"ERROR invalid corpus: {exc}", file=sys.stderr)
        return EXIT_CODE["INVALID_CORPUS"]

    record_path = _find_method_record(METHOD_RECORDS_DIR, TARGET_METHOD_ID)
    try:
        method = _load_method_record(record_path)
    except (ValueError, OSError) as exc:
        print(f"ERROR invalid QMR: {exc}", file=sys.stderr)
        return EXIT_CODE["METHOD_RECORD_INVALID"]

    # Resolve the adapter BEFORE loading cases so a missing or
    # broken adapter fails loudly (case loading is the next step
    # and would mask the adapter error).
    try:
        adapter = _resolve_adapter(
            args.adapter,
            adapter_input=args.adapter_input,
            loadout_root=args.loadout_root,
        )
    except (ValueError, FileNotFoundError, OSError) as exc:
        print(f"ERROR adapter: {exc}", file=sys.stderr)
        return EXIT_CODE["UNKNOWN"]

    # For the shell adapter, hand it a case_paths map so the
    # adapter can resolve per-case findings by canonical path.
    # Two passes: first load all cases and build the case_paths
    # map, then iterate to evaluate. This is necessary because
    # the adapter is constructed before the cases are loaded, and
    # the shell adapter's case_paths must be populated before the
    # first evaluation call.
    case_errors: list[str] = []
    case_paths: dict[str, Path] = {}
    loaded_cases: list[dict] = []
    for case in corpus["cases"]:
        try:
            loaded = _load_case(case)
        except (FileNotFoundError, ValueError) as exc:
            case_errors.append(f"{case.get('id', '<unknown>')}: {exc}")
            continue
        case_paths[case["id"]] = loaded["repo_path"]
        loaded_cases.append(loaded)

    if case_errors:
        for err in case_errors:
            print(f"ERROR {err}", file=sys.stderr)
        return EXIT_CODE["CASE_ERROR"]

    if not loaded_cases:
        print("ERROR corpus resolved to zero cases", file=sys.stderr)
        return EXIT_CODE["CASE_ERROR"]

    # If the shell adapter was selected, install the case_paths map
    # so per-case lookups work. The internal adapter ignores this.
    if adapter.name == ADAPTER_SHELL_LOADOUT:
        adapter._case_paths = case_paths  # type: ignore[attr-defined]

    case_results: list[dict] = []
    for loaded in loaded_cases:
        case_results.append(_evaluate_case(loaded, adapter))

    import os
    arsenal_commit = os.environ.get("GITHUB_SHA") or None
    adapter_block = _build_adapter_block(adapter, args)
    artifact = _assemble_artifact(
        method, corpus, case_results, arsenal_commit, adapter=adapter_block
    )

    out_path = Path(args.out) if args.out else DEFAULT_OUT
    if not out_path.is_absolute():
        out_path = ROOT / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as fh:
        json.dump(artifact, fh, sort_keys=True, indent=2, ensure_ascii=False)
        fh.write("\n")
    print(
        f"arsenal method evaluation: PASS "
        f"method={artifact['method']['method_id']}@{artifact['method']['method_version']} "
        f"cases={artifact['metrics']['cases_total']} "
        f"assertions={artifact['metrics']['assertions_evaluated']} "
        f"conclusion={artifact['epistemic_conclusion']} "
        f"run_digest={artifact['run_digest']}"
    )
    print(f"artifact: {_rel(out_path)}")

    if args.revised_qmr:
        revised_path = Path(args.revised_qmr)
        if not revised_path.is_absolute():
            revised_path = ROOT / revised_path
        revised_rel = _emit_revised_qmr(artifact, revised_path)
        print(f"revised_qmr: {revised_rel}")
    return EXIT_CODE["PASS"]


def cmd_validate(args) -> int:
    """Validate a previously-emitted evaluation artifact.

    The validator is intentionally strict: a corrupted or
    non-deterministic artifact must be detected so a downstream
    consumer can refuse to cite it. The checks mirror the
    assembly logic and are intentionally non-redundant with the
    QMR validator (different schemas, different shapes).
    """
    artifact_path = Path(args.artifact)
    if not artifact_path.is_absolute():
        artifact_path = ROOT / artifact_path
    if not artifact_path.is_file():
        print(f"ERROR missing artifact: {_rel(artifact_path)}", file=sys.stderr)
        return EXIT_CODE["MISSING_CORPUS"]
    with artifact_path.open("r", encoding="utf-8") as fh:
        artifact = json.load(fh)
    errors: list[str] = []
    if artifact.get("schema") != "arsenal/method-evaluation/v0":
        errors.append("schema is not arsenal/method-evaluation/v0")
    if artifact.get("method", {}).get("method_id") != TARGET_METHOD_ID:
        errors.append(
            f"method.method_id must be {TARGET_METHOD_ID!r}"
        )
    if artifact.get("epistemic_conclusion") not in ALLOWED_EPISTEMIC_CONCLUSIONS:
        errors.append(
            f"epistemic_conclusion must be one of "
            f"{sorted(ALLOWED_EPISTEMIC_CONCLUSIONS)}"
        )
    gap = artifact.get("qualification_gap", {})
    if gap.get("label") not in ALLOWED_GAP_LABELS:
        errors.append(
            f"qualification_gap.label must be one of "
            f"{sorted(ALLOWED_GAP_LABELS)}"
        )
    qmr_revisions = artifact.get("qmr_revisions", {})
    if qmr_revisions.get("auto_promote_method_status") is not False:
        errors.append("qmr_revisions.auto_promote_method_status must be false")
    if qmr_revisions.get("auto_promote_capability_lifecycle") is not False:
        errors.append(
            "qmr_revisions.auto_promote_capability_lifecycle must be false"
        )
    if qmr_revisions.get("auto_promote_capability_evaluation_status") is not False:
        errors.append(
            "qmr_revisions.auto_promote_capability_evaluation_status must be false"
        )
    if qmr_revisions.get("revised_qmr_status") != "experimental":
        errors.append("qmr_revisions.revised_qmr_status must be experimental")
    declared = artifact.get("run_digest")
    expected = _compute_run_digest(artifact)
    if declared != expected:
        errors.append(
            f"run_digest does not match canonical SHA-256 of the artifact "
            f"(declared={declared}, expected={expected})"
        )
    if errors:
        for err in errors:
            print(f"ERROR {err}", file=sys.stderr)
        return EXIT_CODE["INVALID_CORPUS"]
    metrics = artifact.get("metrics", {})
    print(
        f"arsenal method evaluation artifact: PASS "
        f"method={artifact['method']['method_id']} "
        f"cases={metrics.get('cases_total')} "
        f"assertions={metrics.get('assertions_evaluated')} "
        f"run_digest={artifact['run_digest']}"
    )
    return EXIT_CODE["PASS"]


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="command", required=True)

    rr = sub.add_parser("repository-recon", help=__doc__)
    rr.add_argument(
        "--corpus",
        default=str(DEFAULT_CORPUS.relative_to(ROOT)),
        help="Path to the corpus manifest (default: %(default)s)",
    )
    rr.add_argument(
        "--out",
        default=str(DEFAULT_OUT.relative_to(ROOT)),
        help="Path to the evaluation artifact output (default: %(default)s)",
    )
    rr.add_argument(
        "--revised-qmr",
        default=None,
        help=(
            "Optional path to emit a revised QMR binding the run as "
            "evidence. The revised QMR is always status: experimental; "
            "the evaluator never auto-promotes the method or its "
            "underlying capability."
        ),
    )
    rr.add_argument(
        "--adapter",
        default=ADAPTER_INTERNAL,
        choices=sorted(ALLOWED_ADAPTERS),
        help=(
            "Adapter used to invoke the Repository Recon procedure "
            "(default: %(default)s). The adapter identity is recorded "
            "in the artifact's provenance.adapter block. The shell "
            "adapter requires --adapter-input."
        ),
    )
    rr.add_argument(
        "--adapter-input",
        default=None,
        help=(
            "Path to the adapter input (findings JSON for "
            "shell-loadout-recon). Required when --adapter is "
            "shell-loadout-recon; ignored otherwise."
        ),
    )
    rr.add_argument(
        "--loadout-root",
        default=None,
        help=(
            "Path to the Loadout installation root (the directory "
            "containing dist/packs/repository-recon/run.js). Required "
            "when --adapter is loadout-runtime; ignored otherwise."
        ),
    )
    rr.set_defaults(func=cmd_repository_recon)

    v = sub.add_parser("validate", help="Validate a previously-emitted evaluation artifact.")
    v.add_argument("--artifact", required=True, help="Path to the evaluation artifact JSON")
    v.set_defaults(func=cmd_validate)
    return p


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except (FileNotFoundError, ValueError, OSError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return EXIT_CODE["UNKNOWN"]


if __name__ == "__main__":
    raise SystemExit(main())
