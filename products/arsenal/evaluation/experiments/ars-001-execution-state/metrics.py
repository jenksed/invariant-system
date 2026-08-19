"""Operational metric definitions for ARS-001 pilot.

Single source of truth for the counting rules declared in PROTOCOL.md.
All canonicalization uses json.dumps(obj, sort_keys=True, separators=(",",":"))
followed by sha256.  Self-referential digests use a 64-zero placeholder.
"""

import hashlib
import json

CANONICAL_PLACEHOLDER = "0" * 64

RECOVERY_ACTIONS = {
    "reconcile",
    "inspect_spec",
    "inspect_contract",
    "inspect_dependency",
    "inspect_file:src/a.py",
    "check_base_sha",
    "reset_artifacts",
    "reverify_evidence",
    "run_tests",
}


def canonical_json(obj):
    """Deterministic JSON canonicalization for digesting."""
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def digest(obj):
    """Return sha256 hex digest of the canonical JSON of obj."""
    return hashlib.sha256(canonical_json(obj).encode("utf-8")).hexdigest()


def digest_file(path):
    """Return sha256 hex digest of file contents."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def belief_digest(condition, belief):
    """Return the digest of the condition's reconstructed belief state."""
    if condition == "C0":
        return digest(belief)
    if condition == "C1":
        return digest(belief["summary"])
    if condition == "C2":
        return digest(belief)
    raise ValueError(f"unknown condition {condition}")


def score_cell(events, oracle, condition):
    """Score a single CxP cell and return its primary/secondary metrics."""
    metrics = {
        "stale_assumptions_acted_upon": 0,
        "invalid_operations_attempted": 0,
        "incorrect_completion_decisions": 0,
        "recovery_correctness": 0,
        "duplicate_work_events": 0,
        "repair_iterations": 0,
        "token_consumption": None,
        "human_intervention_events": 0,
        "time_to_objective_completion": None,
        "completed": False,
    }

    post_events = [e for e in events if e.get("phase") == "post-perturbation"]
    if post_events:
        first = post_events[0]
        expected = oracle.get("expected_recovery_action", {}).get(condition)
        if expected is not None and first["action"] == expected:
            metrics["recovery_correctness"] = 1

    for e in events:
        if e.get("belief_digest") != e.get("world_digest"):
            metrics["stale_assumptions_acted_upon"] += 1
        if e["action"] in oracle.get("invalid_actions", []):
            metrics["invalid_operations_attempted"] += 1
        if e.get("duplicate_work"):
            metrics["duplicate_work_events"] += 1
        if e["action"] in RECOVERY_ACTIONS:
            metrics["repair_iterations"] += 1
        if e["action"] == "declare_blocked":
            metrics["human_intervention_events"] += 1
        if e["action"] in ("declare_done", "declare_blocked"):
            all_accepted = all(e.get("accepted_steps", []))
            if e["action"] == "declare_done" and not all_accepted:
                metrics["incorrect_completion_decisions"] += 1
            elif e["action"] == "declare_blocked" and all_accepted:
                metrics["incorrect_completion_decisions"] += 1
        if all(e.get("accepted_steps", [])) and metrics["time_to_objective_completion"] is None:
            metrics["time_to_objective_completion"] = e["turn"]
            metrics["completed"] = True

    return metrics


def aggregate_conditions(cell_scores):
    """Aggregate per-cell scores into per-condition summaries."""
    per_condition = {}
    for cs in cell_scores:
        cond = cs["condition"]
        per_condition.setdefault(cond, []).append(cs["metrics"])

    aggregated = {}
    for cond, metrics_list in per_condition.items():
        n = len(metrics_list)
        completed_values = [m["time_to_objective_completion"] for m in metrics_list]
        aggregated[cond] = {
            "stale_assumptions_acted_upon": sum(m["stale_assumptions_acted_upon"] for m in metrics_list),
            "invalid_operations_attempted": sum(m["invalid_operations_attempted"] for m in metrics_list),
            "incorrect_completion_decisions": sum(m["incorrect_completion_decisions"] for m in metrics_list),
            "recovery_correctness_count": sum(m["recovery_correctness"] for m in metrics_list),
            "recovery_correctness_rate": round(sum(m["recovery_correctness"] for m in metrics_list) / n, 4) if n else 0.0,
            "duplicate_work_events": sum(m["duplicate_work_events"] for m in metrics_list),
            "repair_iterations": sum(m["repair_iterations"] for m in metrics_list),
            "human_intervention_events": sum(m["human_intervention_events"] for m in metrics_list),
            "time_to_objective_completion_values": completed_values,
            "completed_count": sum(1 for v in completed_values if v is not None),
            "cells": n,
        }
    return aggregated
