#!/usr/bin/env python3
"""Validate the accepted first-month conformance Schema and fixtures.

This intentionally validates only the Prompt 6-A contract subset. It is not a
runtime JSON decoder, a general JSON Schema implementation, or product logic.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = ROOT / "docs/contracts/kiln-first-month.schema.json"
POSITIVE_PATH = ROOT / "test/fixtures/conformance/first_month_positive.json"
NEGATIVE_PATH = ROOT / "test/fixtures/conformance/first_month_negative.json"

DIGEST = re.compile(r"^sha256:[0-9a-f]{64}$")
RUN_STATES = {
    "ready",
    "running",
    "waiting_for_user",
    "orphaned",
    "completed",
    "failed",
    "canceled",
}
WORKFLOW_STEPS = {
    "intent",
    "investigation",
    "proposal",
    "approval",
    "application",
    "verification",
    "acceptance",
    "reconciliation",
}
OPERATION_STATES = {
    None,
    "intent_recorded",
    "started",
    "succeeded",
    "failed",
    "canceled",
    "unknown",
}
TOOLS = {"repo.search", "repo.read", "artifact.read", "change.propose"}
PATCH_OPERATIONS = {"add", "replace", "delete"}
EVIDENCE_STATUSES = {"pass", "fail", "blocked", "unknown"}
FRESHNESS = {"current", "stale", "unknown"}
COMPLETENESS = {"complete", "partial", "truncated", "missing", "unknown"}
CONTRADICTION = {"none", "present", "unknown"}
CRITERION_RESULTS = {"pass", "fail", "blocked", "unknown", "stale", "contradicted"}
COMMAND_STATUSES = {"succeeded", "failed", "timed_out", "canceled", "blocked", "unknown"}
CLI_EXITS = {0, 2, 3, 4, 5, 6, 7, 8, 9, 10}


def load(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def require(document: dict[str, Any], keys: set[str]) -> str | None:
    missing = sorted(keys - document.keys())
    return f"missing:{','.join(missing)}" if missing else None


def digest(value: Any) -> bool:
    return isinstance(value, str) and DIGEST.fullmatch(value) is not None


def safe_relative_path(value: Any) -> bool:
    if not isinstance(value, str) or not value or value.startswith("/") or "\x00" in value:
        return False
    return ".." not in Path(value).parts


def validate(document: dict[str, Any]) -> str | None:
    kind = document.get("kind")

    if kind == "run_projection":
        if error := require(
            document,
            {"session_id", "run_id", "run_state", "workflow_step", "operation_state", "revision"},
        ):
            return error
        if document["run_state"] not in RUN_STATES:
            return "run_state"
        if document["workflow_step"] not in WORKFLOW_STEPS:
            return "workflow_step"
        if document["operation_state"] not in OPERATION_STATES:
            return "operation_state"
        if not isinstance(document["revision"], int) or document["revision"] < 0:
            return "revision"
        return None

    if kind == "context_manifest":
        if error := require(
            document,
            {"provider", "model", "estimated_input_tokens", "tool_names", "package_digest", "fallback"},
        ):
            return error
        if document["provider"] != "minimax" or document["model"] != "MiniMax-M3":
            return "provider"
        if document["fallback"] is not False:
            return "fallback"
        if not isinstance(document["estimated_input_tokens"], int) or not 0 <= document["estimated_input_tokens"] <= 32_000:
            return "context_tokens"
        tool_names = document["tool_names"]
        if not isinstance(tool_names, list) or len(tool_names) > 4:
            return "tool_count"
        if len(tool_names) != len(set(tool_names)) or not set(tool_names) <= TOOLS:
            return "tool_set"
        if not digest(document["package_digest"]):
            return "digest"
        return None

    if kind == "patch_manifest":
        if error := require(
            document,
            {"patch_id", "base_repository_state_digest", "operations", "patch_digest", "total_after_image_bytes"},
        ):
            return error
        if not digest(document["base_repository_state_digest"]) or not digest(document["patch_digest"]):
            return "digest"
        operations = document["operations"]
        if not isinstance(operations, list) or not 1 <= len(operations) <= 32:
            return "patch_count"
        seen_paths: set[str] = set()
        for index, operation in enumerate(operations):
            if operation.get("operation_index") != index:
                return "patch_index"
            if operation.get("operation_kind") not in PATCH_OPERATIONS:
                return "patch_operation"
            path = operation.get("path")
            if not safe_relative_path(path):
                return "patch_path"
            if path in seen_paths:
                return "patch_duplicate_path"
            seen_paths.add(path)
            before = operation.get("before_digest")
            after = operation.get("after_digest")
            if before is not None and not digest(before):
                return "digest"
            if after is not None and not digest(after):
                return "digest"
            if operation["operation_kind"] == "add" and before is not None:
                return "patch_add_before"
            if operation["operation_kind"] == "delete" and after is not None:
                return "patch_delete_after"
            if operation["operation_kind"] == "replace" and (before is None or after is None):
                return "patch_replace_digest"
        total = document["total_after_image_bytes"]
        if not isinstance(total, int) or not 0 <= total <= 4_194_304:
            return "patch_bytes"
        return None

    if kind == "approval":
        if error := require(
            document,
            {"approval_id", "patch_digest", "base_repository_state_digest", "status", "actor_kind", "expires_at"},
        ):
            return error
        if document["actor_kind"] != "local_user":
            return "approval_actor"
        if document["status"] not in {"active", "consumed", "invalidated", "expired"}:
            return "approval_status"
        if not digest(document["patch_digest"]) or not digest(document["base_repository_state_digest"]):
            return "digest"
        return None

    if kind == "command_registration":
        if error := require(
            document,
            {"command_id", "executable_path", "shell", "network_requirement", "registration_digest"},
        ):
            return error
        if document["shell"] is not False:
            return "shell"
        if not isinstance(document["executable_path"], str) or not document["executable_path"].startswith("/"):
            return "executable_path"
        if document["network_requirement"] not in {"not_required", "required"}:
            return "network_requirement"
        if not digest(document["registration_digest"]):
            return "digest"
        return None

    if kind == "command_result":
        if error := require(
            document,
            {"command_result_id", "status", "process_group_cleanup", "result_digest"},
        ):
            return error
        status = document["status"]
        cleanup = document["process_group_cleanup"]
        if status not in COMMAND_STATUSES:
            return "command_status"
        if cleanup not in {"proved_gone", "not_started", "unknown"}:
            return "cleanup"
        if status in {"succeeded", "failed", "timed_out", "canceled"} and cleanup != "proved_gone":
            return "cleanup"
        if not digest(document["result_digest"]):
            return "digest"
        return None

    if kind == "evidence":
        if error := require(
            document,
            {
                "evidence_id",
                "criterion_id",
                "status",
                "freshness",
                "completeness",
                "contradiction",
                "repository_state_digest",
                "record_digest",
            },
        ):
            return error
        if document["status"] not in EVIDENCE_STATUSES:
            return "evidence_status"
        if document["freshness"] not in FRESHNESS:
            return "freshness"
        if document["completeness"] not in COMPLETENESS:
            return "completeness"
        if document["contradiction"] not in CONTRADICTION:
            return "contradiction"
        if document["status"] == "pass" and (
            document["freshness"] != "current"
            or document["completeness"] != "complete"
            or document["contradiction"] != "none"
        ):
            return "passing_evidence"
        if not digest(document["repository_state_digest"]) or not digest(document["record_digest"]):
            return "digest"
        return None

    if kind == "criterion_evaluation":
        if error := require(
            document,
            {"criterion_id", "result", "repository_state_digest", "evaluation_digest"},
        ):
            return error
        if document["result"] not in CRITERION_RESULTS:
            return "criterion_result"
        if not digest(document["repository_state_digest"]) or not digest(document["evaluation_digest"]):
            return "digest"
        return None

    if kind == "receipt":
        if error := require(
            document,
            {"receipt_id", "completion_record_reference", "authority", "manifest_digest"},
        ):
            return error
        if document["authority"] is not False:
            return "receipt_authority"
        if not digest(document["manifest_digest"]):
            return "digest"
        return None

    if kind == "cli_result":
        if error := require(
            document,
            {"schema", "command", "status", "exit_code", "errors", "warnings", "next_actions"},
        ):
            return error
        if document["schema"] != "kiln.cli.result/v1":
            return "cli_schema"
        if document["status"] not in {"ok", "denied", "blocked", "stale", "failed", "unknown", "unsupported"}:
            return "cli_status"
        if document["exit_code"] not in CLI_EXITS:
            return "cli_exit"
        expected = {"ok": {0}, "denied": {3}, "blocked": {4, 8}, "stale": {5}, "failed": {6, 10}, "unknown": {7}, "unsupported": {9}}
        if document["exit_code"] not in expected[document["status"]]:
            return "cli_exit"
        return None

    return "kind"


def schema_contract(schema: dict[str, Any]) -> None:
    if schema.get("$schema") != "https://json-schema.org/draft/2020-12/schema":
        raise AssertionError("schema draft changed")
    if schema.get("$id") != "https://kiln.local/contracts/kiln-first-month.schema.json":
        raise AssertionError("schema id changed")

    definitions = schema.get("$defs", {})
    required = {
        "run_projection",
        "context_manifest",
        "patch_manifest",
        "approval",
        "command_registration",
        "command_result",
        "evidence",
        "criterion_evaluation",
        "receipt",
        "cli_result",
    }
    if not required <= definitions.keys():
        raise AssertionError("required definitions missing")

    if set(definitions["run_projection"]["properties"]["run_state"]["enum"]) != RUN_STATES:
        raise AssertionError("run state Schema drift")
    if set(definitions["context_manifest"]["properties"]["tool_names"]["items"]["enum"]) != TOOLS:
        raise AssertionError("Tool Schema drift")
    if definitions["context_manifest"]["properties"]["tool_names"]["maxItems"] != 4:
        raise AssertionError("Tool count widened")
    if set(definitions["patch_operation"]["properties"]["operation_kind"]["enum"]) != PATCH_OPERATIONS:
        raise AssertionError("Patch operation Schema drift")
    if set(definitions["evidence"]["properties"]["status"]["enum"]) != EVIDENCE_STATUSES:
        raise AssertionError("Evidence status Schema drift")
    if definitions["receipt"]["properties"]["authority"].get("const") is not False:
        raise AssertionError("Receipt gained authority")
    if set(definitions["cli_result"]["properties"]["exit_code"]["enum"]) != CLI_EXITS:
        raise AssertionError("CLI exit Schema drift")


def main() -> int:
    schema = load(SCHEMA_PATH)
    positives = load(POSITIVE_PATH)
    negatives = load(NEGATIVE_PATH)

    schema_contract(schema)

    for index, document in enumerate(positives):
        error = validate(document)
        if error is not None:
            raise AssertionError(f"positive fixture {index} rejected: {error}")

    for index, case in enumerate(negatives):
        expected = case["expected_error"]
        actual = validate(case["document"])
        if actual != expected:
            raise AssertionError(
                f"negative fixture {index} expected {expected!r}, received {actual!r}"
            )

    print("validate-first-month-contracts: pass")
    print(f"positive fixtures: {len(positives)}")
    print(f"protected negative fixtures: {len(negatives)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
        print(f"validate-first-month-contracts: {error}", file=sys.stderr)
        raise SystemExit(1) from error
