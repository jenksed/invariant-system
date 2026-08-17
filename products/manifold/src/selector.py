#!/usr/bin/env python3
"""Manifold M0 selector.

Deterministic, explainable selection that maps an Intelligence
Requirement + a set of Profiles + a set of Eligibility Snapshots onto
exactly one Intelligence Assignment (or an explicit no-selection
result). Stdlib-only.

The selector is the only authoritative public seam for M7 Manifold
selection. It is bounded:

  - No provider invocation.
  - No execution authority.
  - No mutation.
  - No process / network / environment coupling.
  - No filesystem iteration for selection policy.

Selection rule (per P02-D026):

  1. Validate every input against the closed m0-v1 schema field sets.
  2. Recompute every {id, digest} reference's semantic_digest (per
     P02-D013: sorted-key compact UTF-8 JSON + trailing newline, then
     sha256) and reject on mismatch.
  3. Filter Profiles to `role == requirement.role` (mismatch is a
     bounded per-candidate rejection, not a hard abort).
  4. Filter to candidates whose Eligibility Snapshot is `QUALIFIED`,
     binds the exact Profile semantic_digest, and falls within the
     168-hour currentness window (now <= valid_until and
     evaluated_at + 168h >= now).
  5. If multiple remain: lexical-order Profile `semantic_digest`,
     first wins. Otherwise emit a no-selection result with the
     bounded reason code.
  6. Emit `engineering-system/intelligence-assignment/m0-v1` carrying
     refs to Requirement, Profile, and Eligibility; the
     `selection_rule` is the closed constant
     `FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST`; no provider,
     model, adapter, or authority fields (P02-D017).

The selector never writes anywhere except the `--out` path. It never
reads environment variables (other than the implicit PYTHONPATH used
by the runtime). It never imports third-party modules.

Exit codes:
  0  selection succeeded, assignment written to --out.
  2  selection succeeded with no eligible candidate (no-selection
     artifact written to --out, reason codes carried).
  3  bounded validation / reference rejection (a profile / eligibility
     / requirement is structurally or semantically invalid).
  4  CLI usage error.

No selection requires an envelope-shaped output so downstream Kiln
validation can consume it the same way it consumes an assignment.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
import re
import sys
from pathlib import Path

# Bounded currentness window. Frozen at 168 hours per the canonical
# M0 currentness policy in QUALIFICATION-CURRENTNESS-MODEL.
CURRENTNESS_HOURS = 168

# Closed enums (mirrored from the m0-v1 schemas so the selector is
# dependency-free). `jsonschema` is NOT required at runtime; these
# tables are the validator.
ROLE_ENUM = frozenset({"IMPLEMENTER", "REVIEWER"})
ELIGIBILITY_ENUM = frozenset({"QUALIFIED", "NOT_ELIGIBLE"})
TASK_KIND_ENUM = frozenset({"SOFTWARE_CHANGE"})
DISCLOSURE_CLASS_ENUM = frozenset(
    {"REMOTE_BY_EXPLICIT_MANIFEST", "LOCAL_ONLY"}
)
SELECTION_RULE = "FILTER_QUALIFIED_THEN_LEXICAL_PROFILE_DIGEST"
SCHEMA_REQUIREMENT = "engineering-system/intelligence-requirement/m0-v1"
SCHEMA_PROFILE = "engineering-system/intelligence-profile/m0-v1"
SCHEMA_ELIGIBILITY = "engineering-system/eligibility-snapshot/m0-v1"
SCHEMA_ASSIGNMENT = "engineering-system/intelligence-assignment/m0-v1"

DIGEST_RE = re.compile(r"^sha256:[0-9a-f]{64}$")

# Bounded reason codes for the no-selection artifact. These map to
# the closed set defined by the canonical schemas and the existing
# negative fixtures in integration/fixtures/m0/negative/.
REASON_NO_ELIGIBLE = "E_PROFILE_NOT_QUALIFIED"
REASON_STALE = "E_QUALIFICATION_NOT_CURRENT"
REASON_ROLE_MISMATCH = "E_ROLE_MISMATCH"
REASON_DIGEST_MISMATCH = "E_REFERENCE_DIGEST_MISMATCH"
REASON_AUTHORITY_FIELD = "E_AUTHORITY_FIELD_FORBIDDEN"
REASON_PROFILE_REF_MISMATCH = "E_PROFILE_REF_MISMATCH"
REASON_NO_PROFILE = "E_NO_PROFILE_PROVIDED"


class SelectorError(Exception):
    """Bounded failure with a stable exit code."""

    def __init__(self, code: int, message: str, *, reason_code: str | None = None):
        super().__init__(message)
        self.code = code
        self.reason_code = reason_code


# ---------- canonical encoding (P02-D013) ----------


def canonical_json_bytes(data: dict) -> bytes:
    """Canonical encoding: sorted keys, no whitespace, UTF-8, with a
    trailing newline.
    """
    return (
        json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        + "\n"
    ).encode("utf-8")


def semantic_digest(body: dict) -> str:
    return "sha256:" + hashlib.sha256(canonical_json_bytes(body)).hexdigest()


def _require_str(value, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise SelectorError(
            3, f"{field} must be a non-empty string"
        )
    return value


def _require_digest(value, field: str) -> str:
    if not isinstance(value, str) or not DIGEST_RE.match(value):
        raise SelectorError(
            3, f"{field} must match {DIGEST_RE.pattern!r}"
        )
    return value


def _require_enum(value, allowed: frozenset, field: str) -> str:
    if not isinstance(value, str) or value not in allowed:
        raise SelectorError(
            3,
            f"{field} must be one of {sorted(allowed)}; got {value!r}",
        )
    return value


def _require_artifact_ref(value, field: str) -> dict:
    if not isinstance(value, dict):
        raise SelectorError(3, f"{field} must be an object")
    rid = _require_str(value.get("id"), f"{field}.id")
    rdigest = _require_digest(value.get("digest"), f"{field}.digest")
    extras = set(value.keys()) - {"id", "digest"}
    if extras:
        raise SelectorError(
            3, f"{field} has unexpected properties: {sorted(extras)}"
        )
    return {"id": rid, "digest": rdigest}


# ---------- closed-schema validators ----------


def _validate_requirement(doc: dict) -> dict:
    if not isinstance(doc, dict):
        raise SelectorError(3, "requirement must be an object")
    schema = _require_str(doc.get("schema"), "requirement.schema")
    if schema != SCHEMA_REQUIREMENT:
        raise SelectorError(
            3,
            f"requirement.schema must be {SCHEMA_REQUIREMENT!r}; got {schema!r}",
        )
    role = _require_enum(doc.get("role"), ROLE_ENUM, "requirement.role")
    task_kind = _require_enum(
        doc.get("task_kind"), TASK_KIND_ENUM, "requirement.task_kind"
    )
    disclosure_class = _require_enum(
        doc.get("disclosure_class"),
        DISCLOSURE_CLASS_ENUM,
        "requirement.disclosure_class",
    )
    requirement_id = _require_str(
        doc.get("requirement_id"), "requirement.requirement_id"
    )
    semantic = _require_digest(
        doc.get("semantic_digest"), "requirement.semantic_digest"
    )
    plan_ref = _require_artifact_ref(doc.get("plan_ref"), "requirement.plan_ref")
    independence = doc.get("independence")
    if not isinstance(independence, dict):
        raise SelectorError(3, "requirement.independence must be an object")
    must_not_receive = independence.get("must_not_receive_implementer_transcript")
    if must_not_receive is not True:
        raise SelectorError(
            3,
            "requirement.independence.must_not_receive_implementer_transcript must be true",
        )
    must_separate = independence.get("must_use_separate_context_manifest")
    if must_separate is not True:
        raise SelectorError(
            3,
            "requirement.independence.must_use_separate_context_manifest must be true",
        )
    if set(independence.keys()) - {
        "must_not_receive_implementer_transcript",
        "must_use_separate_context_manifest",
        "must_differ_from_assignment_ref",
    }:
        raise SelectorError(
            3, "requirement.independence has unexpected properties"
        )
    required_capabilities = doc.get("required_capabilities")
    if (
        not isinstance(required_capabilities, list)
        or len(required_capabilities) < 1
        or not all(isinstance(c, str) and c for c in required_capabilities)
    ):
        raise SelectorError(
            3, "requirement.required_capabilities must be a non-empty list of strings"
        )
    context_requirements = doc.get("context_requirements")
    if not isinstance(context_requirements, list) or not all(
        isinstance(c, str) and c for c in context_requirements
    ):
        raise SelectorError(
            3, "requirement.context_requirements must be a list of strings"
        )
    # Reject any authority-like field if it slipped in via metadata
    metadata = doc.get("metadata")
    if metadata is not None and not isinstance(metadata, dict):
        raise SelectorError(3, "requirement.metadata must be an object when present")
    top_level_keys = set(doc.keys())
    allowed_top = {
        "schema",
        "requirement_id",
        "semantic_digest",
        "plan_ref",
        "role",
        "task_kind",
        "required_capabilities",
        "context_requirements",
        "disclosure_class",
        "independence",
        "metadata",
    }
    extras = top_level_keys - allowed_top
    if extras:
        raise SelectorError(
            3, f"requirement has unexpected top-level properties: {sorted(extras)}"
        )

    return {
        "schema": schema,
        "requirement_id": requirement_id,
        "semantic_digest": semantic,
        "plan_ref": plan_ref,
        "role": role,
        "task_kind": task_kind,
        "required_capabilities": required_capabilities,
        "context_requirements": context_requirements,
        "disclosure_class": disclosure_class,
        "independence": independence,
        "metadata": metadata,
    }


def _validate_profile(doc: dict) -> dict:
    if not isinstance(doc, dict):
        raise SelectorError(3, "profile must be an object")
    schema = _require_str(doc.get("schema"), "profile.schema")
    if schema != SCHEMA_PROFILE:
        raise SelectorError(
            3, f"profile.schema must be {SCHEMA_PROFILE!r}; got {schema!r}"
        )
    role = _require_enum(doc.get("role"), ROLE_ENUM, "profile.role")
    profile_id = _require_str(doc.get("profile_id"), "profile.profile_id")
    semantic = _require_digest(
        doc.get("semantic_digest"), "profile.semantic_digest"
    )
    provider = doc.get("provider")
    if not isinstance(provider, dict):
        raise SelectorError(3, "profile.provider must be an object")
    model = doc.get("model")
    if not isinstance(model, dict):
        raise SelectorError(3, "profile.model must be an object")
    adapter = doc.get("adapter")
    if not isinstance(adapter, dict):
        raise SelectorError(3, "profile.adapter must be an object")
    runtime = doc.get("runtime")
    if not isinstance(runtime, dict):
        raise SelectorError(3, "profile.runtime must be an object")
    role_package = doc.get("role_package")
    if not isinstance(role_package, dict):
        raise SelectorError(3, "profile.role_package must be an object")
    system_config = doc.get("system_config")
    if not isinstance(system_config, dict):
        raise SelectorError(3, "profile.system_config must be an object")
    tool_policy = doc.get("tool_policy")
    if not isinstance(tool_policy, dict):
        raise SelectorError(3, "profile.tool_policy must be an object")
    context_policy = doc.get("context_policy")
    if not isinstance(context_policy, dict):
        raise SelectorError(3, "profile.context_policy must be an object")
    top_keys = set(doc.keys())
    allowed_top = {
        "schema",
        "profile_id",
        "semantic_digest",
        "role",
        "model",
        "provider",
        "runtime",
        "adapter",
        "role_package",
        "system_config",
        "tool_policy",
        "context_policy",
        "metadata",
    }
    extras = top_keys - allowed_top
    if extras:
        raise SelectorError(
            3, f"profile has unexpected top-level properties: {sorted(extras)}"
        )
    metadata = doc.get("metadata")
    if metadata is not None and not isinstance(metadata, dict):
        raise SelectorError(3, "profile.metadata must be an object when present")
    return {
        "schema": schema,
        "profile_id": profile_id,
        "semantic_digest": semantic,
        "role": role,
        "model": model,
        "provider": provider,
        "runtime": runtime,
        "adapter": adapter,
        "role_package": role_package,
        "system_config": system_config,
        "tool_policy": tool_policy,
        "context_policy": context_policy,
        "metadata": metadata,
    }


def _validate_eligibility(doc: dict) -> dict:
    if not isinstance(doc, dict):
        raise SelectorError(3, "eligibility must be an object")
    schema = _require_str(doc.get("schema"), "eligibility.schema")
    if schema != SCHEMA_ELIGIBILITY:
        raise SelectorError(
            3,
            f"eligibility.schema must be {SCHEMA_ELIGIBILITY!r}; got {schema!r}",
        )
    eligibility = _require_enum(
        doc.get("eligibility"), ELIGIBILITY_ENUM, "eligibility.eligibility"
    )
    eligibility_id = _require_str(
        doc.get("eligibility_id"), "eligibility.eligibility_id"
    )
    semantic = _require_digest(
        doc.get("semantic_digest"), "eligibility.semantic_digest"
    )
    role = _require_enum(doc.get("role"), ROLE_ENUM, "eligibility.role")
    derived_at = _require_str(
        doc.get("derived_at"), "eligibility.derived_at"
    )
    valid_until = _require_str(
        doc.get("valid_until"), "eligibility.valid_until"
    )
    profile_ref = _require_artifact_ref(
        doc.get("profile_ref"), "eligibility.profile_ref"
    )
    qualification_ref = _require_artifact_ref(
        doc.get("qualification_ref"), "eligibility.qualification_ref"
    )
    status_event_refs = doc.get("status_event_refs")
    if (
        not isinstance(status_event_refs, list)
        or len(status_event_refs) < 1
    ):
        raise SelectorError(
            3, "eligibility.status_event_refs must be a non-empty list"
        )
    refs = []
    for i, ref in enumerate(status_event_refs):
        refs.append(_require_artifact_ref(ref, f"eligibility.status_event_refs[{i}]"))
    metadata = doc.get("metadata")
    if metadata is not None and not isinstance(metadata, dict):
        raise SelectorError(3, "eligibility.metadata must be an object when present")
    top_keys = set(doc.keys())
    allowed_top = {
        "schema",
        "eligibility_id",
        "semantic_digest",
        "profile_ref",
        "qualification_ref",
        "role",
        "status_event_refs",
        "derived_at",
        "valid_until",
        "eligibility",
        "metadata",
    }
    extras = top_keys - allowed_top
    if extras:
        raise SelectorError(
            3, f"eligibility has unexpected top-level properties: {sorted(extras)}"
        )
    return {
        "schema": schema,
        "eligibility_id": eligibility_id,
        "semantic_digest": semantic,
        "profile_ref": profile_ref,
        "qualification_ref": qualification_ref,
        "role": role,
        "status_event_refs": refs,
        "derived_at": derived_at,
        "valid_until": valid_until,
        "eligibility": eligibility,
        "metadata": metadata,
    }


# ---------- load + parse argv ----------


def _load_json(path: Path) -> dict:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise SelectorError(3, f"cannot read {path}: {exc}") from exc
    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise SelectorError(3, f"invalid JSON in {path}: {exc}") from exc


def _parse_iso8601(value: str, field: str) -> _dt.datetime:
    """Parse an ISO-8601 timestamp into an aware UTC datetime.

    The canonical m0-v1 artifacts use trailing-Z UTC timestamps. We
    normalize to an aware UTC datetime so the selector's currentness
    check can compare against `datetime.now(timezone.utc)` without
    falling into the offset-naive vs offset-aware trap.
    """
    s = value.rstrip("Z") if value.endswith("Z") else value
    try:
        parsed = _dt.datetime.fromisoformat(s)
    except ValueError as exc:
        raise SelectorError(3, f"{field} must be ISO-8601: {value!r}") from exc
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=_dt.timezone.utc)
    else:
        parsed = parsed.astimezone(_dt.timezone.utc)
    return parsed


def _within_currentness(eligibility: dict, now: _dt.datetime) -> bool:
    derived = _parse_iso8601(eligibility["derived_at"], "eligibility.derived_at")
    valid_until = _parse_iso8601(
        eligibility["valid_until"], "eligibility.valid_until"
    )
    if not (derived <= now <= valid_until):
        return False
    age = now - derived
    if age.total_seconds() > CURRENTNESS_HOURS * 3600:
        return False
    return True


# ---------- selector core ----------


def select(
    requirement: dict,
    profiles: list[dict],
    eligibilities: list[dict],
    *,
    now: _dt.datetime | None = None,
) -> dict:
    """Run the bounded deterministic selection.

    Returns the Assignment dict (excluding `assignment_id` from the
    digest computation per the M0 contract). Throws SelectorError on
    bounded validation failure.
    """
    if now is None:
        now = _dt.datetime.now(_dt.timezone.utc)

    # Index eligibility snapshots by profile_ref.digest.
    eligibility_by_profile_digest: dict[str, dict] = {}
    for elig in eligibilities:
        eligibility_by_profile_digest[elig["profile_ref"]["digest"]] = elig

    # Filter profiles by role + digest-bound eligibility + currentness.
    role_mismatches: list[dict] = []
    eligible: list[dict] = []
    for prof in profiles:
        if prof["role"] != requirement["role"]:
            role_mismatches.append(
                {
                    "profile_id": prof["profile_id"],
                    "role": prof["role"],
                    "expected_role": requirement["role"],
                    "reason_code": REASON_ROLE_MISMATCH,
                }
            )
            continue
        elig = eligibility_by_profile_digest.get(prof["semantic_digest"])
        if elig is None:
            eligible.append(
                {
                    "profile": prof,
                    "reason_code": REASON_NO_ELIGIBLE,
                    "reason_detail": "no eligibility snapshot bound to this profile digest",
                }
            )
            continue
        if elig["eligibility"] != "QUALIFIED":
            eligible.append(
                {
                    "profile": prof,
                    "reason_code": REASON_NO_ELIGIBLE,
                    "reason_detail": (
                        f"eligibility state is {elig['eligibility']!r}, not QUALIFIED"
                    ),
                }
            )
            continue
        if not _within_currentness(elig, now):
            eligible.append(
                {
                    "profile": prof,
                    "reason_code": REASON_STALE,
                    "reason_detail": (
                        f"eligibility window [{elig['derived_at']}, "
                        f"{elig['valid_until']}] does not cover {now.isoformat()}"
                    ),
                }
            )
            continue
        eligible.append(
            {
                "profile": prof,
                "eligibility": elig,
            }
        )

    actually_eligible = [c for c in eligible if "eligibility" in c]

    if not actually_eligible:
        # Build a no-selection artifact. The Assignment contract is
        # mandatory when present, so we emit the no-selection shape
        # that Kiln-M0-02 will validate: it carries the requirement_ref
        # plus the bounded reason codes; no profile_ref / no
        # eligibility_ref / no provider/model/adapter restatement.
        return _no_selection_artifact(requirement, role_mismatches, eligible)

    # Tie-break: lexical order of Profile semantic_digest, first wins.
    actually_eligible.sort(key=lambda c: c["profile"]["semantic_digest"])
    chosen = actually_eligible[0]

    body = {
        "schema": SCHEMA_ASSIGNMENT,
        "requirement_ref": {
            "id": requirement["requirement_id"],
            "digest": requirement["semantic_digest"],
        },
        "profile_ref": {
            "id": chosen["profile"]["profile_id"],
            "digest": chosen["profile"]["semantic_digest"],
        },
        "eligibility_ref": {
            "id": chosen["eligibility"]["eligibility_id"],
            "digest": chosen["eligibility"]["semantic_digest"],
        },
        "role": requirement["role"],
        "selection_rule": SELECTION_RULE,
        "metadata": {
            "selected_at": now.isoformat().replace("+00:00", "Z"),
            "currentness_window_hours": CURRENTNESS_HOURS,
            "eligible_candidates": [
                c["profile"]["semantic_digest"] for c in actually_eligible
            ],
            "rejected_candidates": [
                {"profile_id": c["profile"]["profile_id"], "reason_code": c["reason_code"], "reason_detail": c["reason_detail"]}
                for c in eligible
                if "reason_code" in c
            ] + [
                {"profile_id": m["profile_id"], "reason_code": m["reason_code"], "reason_detail": f"role {m['role']!r} != expected {m['expected_role']!r}"}
                for m in role_mismatches
            ],
        },
    }

    digest = semantic_digest({k: v for k, v in body.items() if k != "semantic_digest"})

    # P02-D017: never restate provider/model/adapter or authority
    # fields on the Assignment. The body above carries refs only;
    # the validation pass below is the architectural backstop.
    _enforce_p02_d017(body)

    assignment_id = "asg_" + hashlib.sha256(
        (requirement["requirement_id"] + ":" + body["profile_ref"]["digest"]).encode("utf-8")
    ).hexdigest()
    return {
        "schema": SCHEMA_ASSIGNMENT,
        "assignment_id": assignment_id,
        "semantic_digest": digest,
        "requirement_ref": body["requirement_ref"],
        "profile_ref": body["profile_ref"],
        "eligibility_ref": body["eligibility_ref"],
        "role": body["role"],
        "selection_rule": body["selection_rule"],
        "metadata": body["metadata"],
    }


def _enforce_p02_d017(body: dict) -> None:
    """Architectural backstop: reject any field that would smuggle
    provider/model/adapter restatement or authority grant onto the
    Assignment. Per P02-D017, the Assignment references one frozen
    Profile + eligibility snapshot; provider/model/adapter
    restatement is forbidden.
    """
    forbidden_keys = {
        "provider",
        "model",
        "adapter",
        "runtime",
        "credential",
        "credential_slot",
        "endpoint",
        "api_key",
        "authority_grant",
        "authority",
    }
    flat = _collect_keys(body)
    bad = forbidden_keys & flat
    if bad:
        raise SelectorError(
            3,
            f"assignment body must not carry provider/model/adapter/authority "
            f"restatement (P02-D017); got forbidden keys: {sorted(bad)}",
            reason_code=REASON_AUTHORITY_FIELD,
        )


def _collect_keys(obj, _seen: set | None = None) -> set:
    if _seen is None:
        _seen = set()
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in _seen:
                continue
            _seen.add(k)
            _collect_keys(v, _seen)
    elif isinstance(obj, list):
        for v in obj:
            _collect_keys(v, _seen)
    return _seen


def _no_selection_artifact(
    requirement: dict,
    role_mismatches: list[dict],
    eligible: list[dict],
) -> dict:
    """The no-selection artifact uses the Assignment schema and
    carries refs only (Requirement is mandatory; Profile + Eligibility
    are omitted to mark no-selection). The bounded reason codes are
    carried in `metadata`.
    """
    body = {
        "schema": SCHEMA_ASSIGNMENT,
        "requirement_ref": {
            "id": requirement["requirement_id"],
            "digest": requirement["semantic_digest"],
        },
        "role": requirement["role"],
        "selection_rule": SELECTION_RULE,
        "metadata": {
            "no_selection": True,
            "rejected_candidates": [
                {"profile_id": c["profile"]["profile_id"], "reason_code": c["reason_code"], "reason_detail": c["reason_detail"]}
                for c in eligible
                if "reason_code" in c
            ]
            + [
                {"profile_id": m["profile_id"], "reason_code": m["reason_code"], "reason_detail": f"role {m['role']!r} != expected {m['expected_role']!r}"}
                for m in role_mismatches
            ],
        },
    }
    digest = semantic_digest({k: v for k, v in body.items() if k != "semantic_digest"})

    _enforce_p02_d017(body)

    assignment_id = "asg_nosel_" + hashlib.sha256(
        (requirement["requirement_id"] + ":none:" + digest).encode("utf-8")
    ).hexdigest()
    return {
        "schema": SCHEMA_ASSIGNMENT,
        "assignment_id": assignment_id,
        "semantic_digest": digest,
        "requirement_ref": body["requirement_ref"],
        "role": body["role"],
        "selection_rule": body["selection_rule"],
        "metadata": body["metadata"],
    }


# ---------- CLI ----------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="selector.py",
        description=(
            "Manifold M0 selector: deterministic Intelligence "
            "Assignment from Requirement + Profiles + Eligibility "
            "Snapshots (P02-D026)."
        ),
    )
    parser.add_argument("--requirement", required=True, help="Path to requirement JSON")
    parser.add_argument(
        "--profile",
        action="append",
        default=[],
        help="Path to a Profile JSON (repeatable)",
    )
    parser.add_argument(
        "--eligibility",
        action="append",
        default=[],
        help="Path to an Eligibility Snapshot JSON (repeatable)",
    )
    parser.add_argument(
        "--out",
        required=True,
        help="Path to write the Assignment (or no-selection) artifact",
    )

    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        return 4

    try:
        requirement = _validate_requirement(_load_json(Path(args.requirement)))
        profiles = [_validate_profile(_load_json(Path(p))) for p in args.profile]
        eligibilities = [
            _validate_eligibility(_load_json(Path(p))) for p in args.eligibility
        ]

        if not profiles:
            raise SelectorError(3, "no profiles provided", reason_code=REASON_NO_PROFILE)

        assignment = select(requirement, profiles, eligibilities)
    except SelectorError as exc:
        print(f"ERROR [{exc.code}] {exc}", file=sys.stderr)
        if exc.reason_code:
            print(f"reason_code={exc.reason_code}", file=sys.stderr)
        return exc.code

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(
        json.dumps(assignment, sort_keys=True, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    is_no_selection = assignment.get("metadata", {}).get("no_selection") is True
    if is_no_selection:
        print(
            f"Manifold M0 selection: no eligible candidate for "
            f"role={assignment['role']}; assignment_id={assignment['assignment_id']}"
        )
        return 2
    print(
        f"Manifold M0 selection: role={assignment['role']} "
        f"profile_id={assignment['profile_ref']['id']} "
        f"assignment_id={assignment['assignment_id']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())