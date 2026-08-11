#!/usr/bin/env python3
"""Deterministic validation of the Project Arsenal governance source model.

This is a small fail-closed CLI that runs the bounded checks a
governance-aware CI step needs. It does NOT generate projections,
audit Markdown prose, or extend into Decision Record or projection
territory.

Validation surface:

* canonical closed vocabularies for ownership, state role, and
  materialization;
* duplicate artifact and fact identities;
* one normative owner per fact (the model is not a second copy of
  domain values);
* every owner_artifact resolves to a declared artifact id;
* every pattern-style artifact points to files that actually exist;
* the model itself is structurally consistent with its JSON schema
  (only the keys the schema permits).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import arsenal_governance
import arsenal_io
import arsenal_schema_registry
import arsenal_source_model

ROOT = Path(__file__).resolve().parents[1]


def _resolve_artifact_path(art: dict, root: Path) -> Path | None:
    if "path" in art:
        return root / art["path"]
    if "path_pattern" in art:
        # The first segment of a bounded pattern is a directory
        # relative to the root. Anything else fails closed.
        pat = art["path_pattern"]
        if pat.startswith("/") or pat.startswith("./") or pat.startswith("../"):
            return None
        if ".." in pat.split("/"):
            return None
        candidate = root / pat.split("/", 1)[0]
        return candidate if candidate.is_dir() else None
    return None


def _check_vocabulary(errors: list[str], model: dict) -> None:
    seen_artifact_ids: set[str] = set()
    for art in model["artifacts"]:
        aid = art["id"]
        if aid in seen_artifact_ids:
            errors.append(f"duplicate artifact id: {aid}")
        seen_artifact_ids.add(aid)
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
    artifact_ids = {a["id"] for a in model["artifacts"]}
    fact_owner: dict[str, str] = {}
    seen_fact_ids: set[str] = set()
    for fact in model["facts"]:
        fid = fact["id"]
        if fid in seen_fact_ids:
            errors.append(f"duplicate fact id: {fid}")
        seen_fact_ids.add(fid)
        owner = fact["owner_artifact"]
        if owner not in artifact_ids:
            errors.append(
                f"fact {fid!r}: owner_artifact {owner!r} is not a registered "
                f"artifact id"
            )
            continue
        if fid in fact_owner and fact_owner[fid] != owner:
            errors.append(
                f"fact {fid!r}: has more than one normative owner "
                f"({fact_owner[fid]!r}, {owner!r})"
            )
        elif fid not in fact_owner:
            fact_owner[fid] = owner


def _check_paths(errors: list[str], model: dict, root: Path) -> None:
    for art in model["artifacts"]:
        if "path" in art:
            p = root / art["path"]
            if not p.is_file():
                errors.append(
                    f"artifact {art['id']!r}: declared path does not exist: {art['path']}"
                )
            continue
        pat = art["path_pattern"]
        # Repository-relative only. No traversal. Must be a real family.
        if pat.startswith("/") or pat.startswith("./") or pat.startswith("../"):
            errors.append(
                f"artifact {art['id']!r}: path_pattern must be repository-relative: {pat!r}"
            )
            continue
        if ".." in pat.split("/"):
            errors.append(
                f"artifact {art['id']!r}: path_pattern must not contain traversal: {pat!r}"
            )
            continue
        # Walk the head segment as a directory under the root.
        head = pat.split("/", 1)[0]
        base = root / head
        if not base.is_dir():
            errors.append(
                f"artifact {art['id']!r}: pattern base directory missing: {head}"
            )
            continue
        # Use a bounded glob under the base. Refuse recursive descent
        # (``**``) to keep the surface explicit.
        if "**" in pat:
            errors.append(
                f"artifact {art['id']!r}: recursive '**' patterns are not allowed: {pat!r}"
            )
            continue
        tail = pat.split("/", 1)[1] if "/" in pat else "*"
        matches = sorted(base.glob(tail))
        if not matches:
            errors.append(
                f"artifact {art['id']!r}: pattern {pat!r} matches no files"
            )


def _check_schema_registry(errors: list[str], model: dict, root: Path) -> None:
    try:
        arsenal_schema_registry.schema_id_for(
            root, arsenal_governance.SOURCE_MODEL_SCHEMA_NAME
        )
    except Exception as exc:
        errors.append(f"source-model schema not registered: {exc}")


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
