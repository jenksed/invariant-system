#!/usr/bin/env python3
"""Deterministic validation of the Project Arsenal governance source model.

This is a small fail-closed CLI that runs the bounded checks a
governance-aware CI step needs. It does NOT generate projections,
audit Markdown prose, or extend into Decision Record or projection
territory.

Validation surface:

* canonical closed vocabularies for ownership, state role, and
  materialization;
* exactly one owning artifact per fact (the model is not a second
  copy of domain values); the artifact's state_role tells us whether
  the fact is normative, derived, historical, or narrative;
* every owner_artifact resolves to a declared artifact id;
* every artifact's ``owns_facts`` cross-references match the
  ``facts[]`` list bidirectionally (no dangling IDs in either
  direction; the model answers "who owns this fact?" with one
  semantic answer regardless of which API asks);
* every path-style and pattern-style artifact points to a file or
  directory family that actually exists and stays under the
  repository root (the shared ``arsenal_io.safe_repo_path`` primitive
  is used so loader and validator cannot disagree);
* the model itself is structurally consistent with its JSON schema
  (closed-shape, required fields, types, identifiers, optional
  string types, ``uniqueItems``, and the path XOR are all enforced
  by the loader; duplicate artifact/fact ids are likewise a
  loader-side structural check and report SCHEMA_VIOLATION rc=2).
  The validator complements the loader's structural checks with
  semantic invariants that depend on the model's content rather
  than its raw shape.

Closed-shape, required-field, and duplicate-identity enforcement
live in ``arsenal_source_model.load_source_model``. The validator
here focuses on semantic checks.
"""

from __future__ import annotations

import sys
from pathlib import Path

import arsenal_governance
import arsenal_io
import arsenal_schema_registry
import arsenal_source_model

ROOT = Path(__file__).resolve().parents[1]


def _check_vocabulary(errors: list[str], model: dict) -> None:
    # Duplicate artifact ids are rejected by the loader as a
    # structural check (``load_source_model`` records each id and
    # raises on collision). The validator therefore never sees a
    # loaded model that contains duplicates, and does not need its
    # own duplicate check here. Duplicate fact ids are likewise
    # rejected by the loader; both report SCHEMA_VIOLATION (rc=2).
    for art in model["artifacts"]:
        aid = art["id"]
        if art["ownership"] not in arsenal_governance.OWNERSHIP_LAYERS:
            errors.append(
                f"artifact {aid!r}: unknown ownership layer {art['ownership']!r}; "
                f"allowed: {sorted(arsenal_governance.OWNERSHIP_LAYERS)}"
            )
        if art["state_role"] not in arsenal_governance.STATE_ROLES:
            errors.append(
                f"artifact {aid!r}: unknown state role {art['state_role']!r}; "
                f"allowed: {sorted(arsenal_governance.STATE_ROLES)}"
            )
        mat = art.get("materialization")
        if mat is not None and mat not in arsenal_governance.MATERIALIZATION_MODES:
            errors.append(
                f"artifact {aid!r}: unknown materialization {mat!r}; "
                f"allowed: {sorted(arsenal_governance.MATERIALIZATION_MODES)}"
            )


def _check_fact_owners(errors: list[str], model: dict) -> None:
    """Cross-check ``fact.owner_artifact`` against ``artifact.owns_facts``.

    The semantic invariant is: every fact has exactly one owning
    artifact, AND that owning artifact must list the fact in its
    ``owns_facts`` array. The validator enforces both directions:

    * forward: for every fact, ``fact.id`` appears in the owner's
      ``owns_facts``;
    * backward: for every entry in any artifact's ``owns_facts``,
      that fact id exists in ``facts[]`` and points back to the
      same artifact.

    Without this, the source model can answer "who owns this fact?"
    differently depending on which API is asked.
    """
    artifact_ids = {a["id"] for a in model["artifacts"]}
    artifacts_by_id = {a["id"]: a for a in model["artifacts"]}
    # Duplicate fact ids are rejected by the loader as a structural
    # check; the validator never sees a loaded model that contains
    # duplicates, so no duplicate check is needed here.
    for fact in model["facts"]:
        fid = fact["id"]
        owner = fact["owner_artifact"]
        if owner not in artifact_ids:
            errors.append(
                f"fact {fid!r}: owner_artifact {owner!r} is not a registered "
                f"artifact id"
            )
            continue
        # Forward coherence: owner.owns_facts must include this fact.
        owns_list = artifacts_by_id[owner].get("owns_facts", [])
        if fid not in owns_list:
            errors.append(
                f"fact {fid!r}: owner_artifact {owner!r} does not list "
                f"this fact in owns_facts; the source model has exactly "
                f"one owning artifact per fact and the two views must agree"
            )

    # Backward coherence: every entry in any artifact's owns_facts
    # must correspond to a real fact pointing back to the same
    # artifact.
    fact_owner_by_id: dict[str, str] = {
        f["id"]: f["owner_artifact"] for f in model["facts"]
    }
    for art in model["artifacts"]:
        for fid in art.get("owns_facts", []):
            owner = fact_owner_by_id.get(fid)
            if owner is None:
                errors.append(
                    f"artifact {art['id']!r}: owns_facts references unknown "
                    f"fact id {fid!r}"
                )
                continue
            if owner != art["id"]:
                errors.append(
                    f"artifact {art['id']!r}: owns_facts references fact "
                    f"{fid!r} whose owner_artifact is {owner!r}; the source "
                    f"model has exactly one owning artifact per fact and the "
                    f"two views must agree"
                )


def _check_paths(errors: list[str], model: dict, root: Path) -> None:
    for art in model["artifacts"]:
        aid = art["id"]
        if "path" in art:
            try:
                resolved = arsenal_io.safe_repo_path(
                    root, art["path"], field=f"artifact {aid!r} path"
                )
            except ValueError as exc:
                errors.append(str(exc))
                continue
            if not resolved.is_file():
                errors.append(
                    f"artifact {aid!r}: declared path does not exist: {art['path']}"
                )
            continue
        pat = art["path_pattern"]
        # Use the shared primitive on the head segment so the path
        # family cannot escape the repository root.
        try:
            head_resolved = arsenal_io.safe_repo_path(
                root, pat.split("/", 1)[0], field=f"artifact {aid!r} path_pattern head"
            )
        except ValueError as exc:
            errors.append(str(exc))
            continue
        if not head_resolved.is_dir():
            errors.append(
                f"artifact {aid!r}: pattern base directory missing: {pat.split('/', 1)[0]}"
            )
            continue
        # Refuse recursive descent (``**``) to keep the surface
        # explicit.
        if "**" in pat:
            errors.append(
                f"artifact {aid!r}: recursive '**' patterns are not allowed: {pat!r}"
            )
            continue
        tail = pat.split("/", 1)[1] if "/" in pat else "*"
        matches = sorted(head_resolved.glob(tail))
        if not matches:
            errors.append(
                f"artifact {aid!r}: pattern {pat!r} matches no files"
            )


def _check_schema_registry(errors: list[str], model: dict, root: Path) -> None:
    try:
        arsenal_schema_registry.schema_id_for(
            root, arsenal_governance.SOURCE_MODEL_SCHEMA_NAME
        )
    except Exception as exc:
        errors.append(f"source-model schema not registered: {exc}")


# Mapping from error substring to the documented exit-code token.
# Errors not covered by a specific substring fall back to UNKNOWN.
# Duplicate artifact/fact ids are detected by the loader as part of
# the structural boundary and are classified as SCHEMA_VIOLATION;
# the taxonomy reserves no separate code for duplicates.
_EXIT_CODE_RULES: tuple[tuple[str, str], ...] = (
    ("missing source model", "MISSING_MODEL"),
    ("source-model load error", "SCHEMA_VIOLATION"),
    ("unknown key", "SCHEMA_VIOLATION"),
    ("unknown top-level key", "SCHEMA_VIOLATION"),
    ("missing required field", "SCHEMA_VIOLATION"),
    ("must be a string", "SCHEMA_VIOLATION"),
    ("must be a list", "SCHEMA_VIOLATION"),
    ("does not match pattern", "SCHEMA_VIOLATION"),
    ("shorter than the", "SCHEMA_VIOLATION"),
    ("must declare exactly one of", "SCHEMA_VIOLATION"),
    ("duplicate fact ids", "SCHEMA_VIOLATION"),
    ("duplicate artifact id", "SCHEMA_VIOLATION"),
    ("duplicate fact id", "SCHEMA_VIOLATION"),
    ("unknown ownership layer", "ROLE_VIOLATION"),
    ("unknown state role", "ROLE_VIOLATION"),
    ("unknown materialization", "ROLE_VIOLATION"),
    ("not a registered artifact id", "INVALID_REFERENCE"),
    ("does not list this fact in owns_facts", "CONFLICTING_OWNER"),
    ("references unknown fact id", "CONFLICTING_OWNER"),
    ("whose owner_artifact is", "CONFLICTING_OWNER"),
    ("resolves outside the repository root", "SCHEMA_VIOLATION"),
    ("traversal", "SCHEMA_VIOLATION"),
    ("repository-relative", "SCHEMA_VIOLATION"),
    ("recursive '**'", "SCHEMA_VIOLATION"),
    ("must not traverse", "SCHEMA_VIOLATION"),
    ("must not contain '.' segments", "SCHEMA_VIOLATION"),
)


def _classify_error(message: str) -> str:
    for needle, code in _EXIT_CODE_RULES:
        if needle in message:
            return code
    return "UNKNOWN"


def validate_source_model(root: Path = ROOT) -> list[str]:
    """Run the bounded source-model validation surface and return errors."""
    errors: list[str] = []
    try:
        model = arsenal_source_model.load_source_model(root)
    except FileNotFoundError as exc:
        return [str(exc)]
    except Exception as exc:
        return [f"source-model load error: {exc}"]

    _check_vocabulary(errors, model)
    _check_fact_owners(errors, model)
    _check_paths(errors, model, root)
    _check_schema_registry(errors, model, root)
    return errors


def main() -> int:
    errors = validate_source_model(ROOT)
    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        # Pick the most-specific exit code based on the highest
        # classification across the reported errors. Schema-level
        # violations are the most specific; otherwise the first
        # match wins.
        priority = [
            "MISSING_MODEL",
            "SCHEMA_VIOLATION",
            "INVALID_REFERENCE",
            "ROLE_VIOLATION",
            "CONFLICTING_OWNER",
        ]
        codes = {_classify_error(e) for e in errors}
        for code in priority:
            if code in codes:
                return arsenal_governance.EXIT_CODE[code]
        return arsenal_governance.EXIT_CODE["UNKNOWN"]
    artifact_count = len(arsenal_source_model.load_source_model(ROOT)["artifacts"])
    fact_count = len(arsenal_source_model.load_source_model(ROOT)["facts"])
    print(
        f"governance source-model: PASS "
        f"({artifact_count} artifacts, {fact_count} facts)"
    )
    return arsenal_governance.EXIT_CODE["PASS"]


if __name__ == "__main__":
    raise SystemExit(main())
