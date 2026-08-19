"""Deterministic experiment runner for ARS-001 pilot."""

import copy
import json
import os
import shutil
import subprocess
import sys
import tempfile

from metrics import (
    CANONICAL_PLACEHOLDER,
    aggregate_conditions,
    belief_digest,
    canonical_json,
    digest,
    digest_file,
    score_cell,
)

HARNESS_VERSION = "0.1.0"
HARNESS_IDENTITY = f"ars-001-harness/{HARNESS_VERSION}"
MODEL_IDENTITY = "deterministic-scripted-policy-v0"
SCHEMA = "arsenal/ars-001-pilot/v0"

STEP_ACTIONS = [
    "inspect_spec",
    "inspect_contract",
    "run_tests",
    "update_dependency",
    "edit_src_a",
    "verify_completion",
]


def _load_fixture(experiment_dir):
    fixture_dir = os.path.join(experiment_dir, "fixtures")
    with open(os.path.join(fixture_dir, "task.json"), "r", encoding="utf-8") as f:
        task_steps = json.load(f)
    with open(os.path.join(fixture_dir, "world.json"), "r", encoding="utf-8") as f:
        world = json.load(f)
    with open(os.path.join(fixture_dir, "oracle.json"), "r", encoding="utf-8") as f:
        oracle = json.load(f)
    with open(os.path.join(fixture_dir, "fixture_manifest.json"), "r", encoding="utf-8") as f:
        manifest = json.load(f)
    return {
        "task_steps": task_steps,
        "world": world,
        "oracle": oracle,
        "manifest": manifest,
        "target": {
            "implementation_content": "def feature():\n    return 42\n",
            "implementation_digest": digest({"content": "def feature():\n    return 42\n"}),
            "dependency_version": "2.0.0",
            "dependency_digest": digest({"version": "2.0.0"}),
        },
    }


def _repo_digest(world):
    return digest(world["repo"])


def _subdigests(world):
    return {
        "base_sha": digest(world["base_sha"]),
        "dependency_version": digest(world["dependency_version"]),
        "repo": _repo_digest(world),
        "test_result": digest(world["test_result"]),
        "artifacts": digest(world["artifacts"]),
    }


def _world_digest(world):
    return digest(world)


def _accepted_steps(world, task_steps, target):
    repo = world["repo"]
    acc = [False] * len(task_steps)
    acc[0] = any(e["action"] == "inspect_spec" for e in world["command_log"])

    last_contract_binding = None
    for e in world["command_log"]:
        if e["action"] == "inspect_contract":
            last_contract_binding = e.get("binding")
    acc[1] = last_contract_binding == repo["repo/shared-contract.yaml"]["digest"]

    repo_d = _repo_digest(world)
    tr = world["test_result"]
    acc[2] = tr["passed"] and tr["state_binding"] == repo_d

    dep_target = target["dependency_version"]
    acc[3] = (
        world["dependency_version"] == dep_target
        and any(
            e["action"] == "update_dependency" and e.get("binding") == dep_target
            for e in world["command_log"]
        )
    )

    impl_digest = target["implementation_digest"]
    acc[4] = (
        repo["repo/src/a.py"]["digest"] == impl_digest
        and any(
            e["action"] == "edit_src_a" and e.get("binding") == impl_digest
            for e in world["command_log"]
        )
    )

    acc[5] = all(acc[:5])
    return acc


def _infer_current_step_from_transcript(transcript):
    completed = set()
    for ev in transcript:
        a = ev["action"]
        if a == "inspect_spec":
            completed.add(0)
        elif a == "inspect_contract":
            completed.add(1)
        elif a == "run_tests":
            completed.add(2)
        elif a == "update_dependency":
            completed.add(3)
        elif a == "edit_src_a":
            completed.add(4)
        elif a == "verify_completion":
            completed.add(5)
    for i in range(len(STEP_ACTIONS)):
        if i not in completed:
            return i
    return len(STEP_ACTIONS)


def _generate_summary(transcript):
    completed = set()
    for ev in transcript:
        a = ev["action"]
        if a == "inspect_spec":
            completed.add(0)
        elif a == "inspect_contract":
            completed.add(1)
        elif a == "run_tests":
            completed.add(2)
        elif a == "update_dependency":
            completed.add(3)
        elif a == "edit_src_a":
            completed.add(4)
        elif a == "verify_completion":
            completed.add(5)
    current_step = len(STEP_ACTIONS)
    for i in range(len(STEP_ACTIONS)):
        if i not in completed:
            current_step = i
            break
    return {
        "current_step": current_step,
        "completed_steps": sorted(completed),
        "last_action": transcript[-1]["action"] if transcript else None,
    }


def _c2_ledger(world, task_steps, target):
    acc = _accepted_steps(world, task_steps, target)
    ledger = []
    for i, step in enumerate(task_steps):
        if acc[i]:
            req = step["required_action"]
            binding = None
            for e in reversed(world["command_log"]):
                if e["action"] == req:
                    binding = e.get("binding")
                    break
            ledger.append(
                {
                    "step_id": step["id"],
                    "status": "completed",
                    "evidence_ref": {"action": req, "binding": binding},
                }
            )
        else:
            ledger.append(
                {
                    "step_id": step["id"],
                    "status": "pending",
                    "evidence_ref": None,
                }
            )
    return ledger


def _c2_evidence_stale(explicit_state, world, task_steps, target):
    for entry in explicit_state["task_ledger"]:
        if entry["status"] != "completed" or not entry.get("evidence_ref"):
            continue
        ref = entry["evidence_ref"]
        expected = _expected_binding(ref["action"], world)
        if ref["binding"] != expected:
            return True
    return False


def _expected_binding(action, world):
    repo = world["repo"]
    if action == "inspect_spec":
        return repo["repo/spec.md"]["digest"]
    if action == "inspect_contract":
        return repo["repo/shared-contract.yaml"]["digest"]
    if action == "run_tests":
        return _repo_digest(world)
    if action == "update_dependency":
        return world["dependency_version"]
    if action == "edit_src_a":
        return repo["repo/src/a.py"]["digest"]
    if action == "verify_completion":
        return _world_digest(world)
    return None


def _is_duplicate(action, world, target):
    repo = world["repo"]
    if action == "update_dependency":
        return (
            world["dependency_version"] == target["dependency_version"]
            and any(e["action"] == "update_dependency" for e in world["command_log"])
        )
    if action == "run_tests":
        repo_d = _repo_digest(world)
        tr = world["test_result"]
        return tr["passed"] and tr["state_binding"] == repo_d
    if action == "edit_src_a":
        impl_digest = target["implementation_digest"]
        return (
            repo["repo/src/a.py"]["digest"] == impl_digest
            and any(e["action"] == "edit_src_a" for e in world["command_log"])
        )
    return False


def _apply_action(world, action, target):
    w = copy.deepcopy(world)
    repo = w["repo"]
    if action == "run_tests":
        repo_d = _repo_digest(w)
        w["test_result"] = {"passed": True, "output": "ok", "state_binding": repo_d}
        w["command_log"].append({"action": "run_tests", "binding": repo_d})
    elif action == "update_dependency":
        dep = target["dependency_version"]
        w["dependency_version"] = dep
        w["command_log"].append({"action": "update_dependency", "binding": dep})
    elif action == "edit_src_a":
        impl = target["implementation_content"]
        impl_digest = target["implementation_digest"]
        repo["repo/src/a.py"] = {"content": impl, "digest": impl_digest}
        w["command_log"].append({"action": "edit_src_a", "binding": impl_digest})
    elif action == "reset_artifacts":
        w["artifacts"] = {}
        w["command_log"].append({"action": "reset_artifacts", "binding": ""})
    elif action == "inspect_spec":
        w["command_log"].append(
            {"action": "inspect_spec", "binding": repo["repo/spec.md"]["digest"]}
        )
    elif action == "inspect_contract":
        w["command_log"].append(
            {
                "action": "inspect_contract",
                "binding": repo["repo/shared-contract.yaml"]["digest"],
            }
        )
    elif action == "inspect_dependency":
        w["command_log"].append(
            {"action": "inspect_dependency", "binding": w["dependency_version"]}
        )
    elif action == "inspect_file:src/a.py":
        w["command_log"].append(
            {
                "action": "inspect_file:src/a.py",
                "binding": repo["repo/src/a.py"]["digest"],
            }
        )
    elif action == "check_base_sha":
        w["command_log"].append(
            {"action": "check_base_sha", "binding": w["base_sha"]}
        )
    elif action == "reverify_evidence":
        w["command_log"].append({"action": "reverify_evidence", "binding": ""})
    return w


def _apply_mutation(world, mutation, target):
    w = copy.deepcopy(world)
    mtype = mutation["type"]
    if mtype == "change_file":
        path = mutation["path"]
        content = mutation["new_content"]
        w["repo"][path] = {"content": content, "digest": digest({"content": content})}
    elif mtype == "change_base_sha":
        w["base_sha"] = mutation["new_base_sha"]
    elif mtype == "change_dependency":
        w["dependency_version"] = mutation["new_version"]
    elif mtype == "stale_test_result":
        w["test_result"] = {
            "passed": mutation["passed"],
            "output": "cached",
            "state_binding": mutation["state_binding"],
        }
    elif mtype == "pre_execute_command":
        a = mutation["action"]
        if a == "update_dependency":
            dep = target["dependency_version"]
            w["dependency_version"] = dep
            w["command_log"].append({"action": "update_dependency", "binding": dep})
    elif mtype == "rebase":
        w["base_sha"] = mutation["new_base_sha"]
        for path, content in mutation["file_changes"].items():
            w["repo"][path] = {"content": content, "digest": digest({"content": content})}
    elif mtype == "add_artifact":
        w["artifacts"][mutation["key"]] = mutation["data"]
    return w


def _initialize_belief(condition, world, task_steps, target):
    if condition == "C0":
        return []
    if condition == "C1":
        return {"transcript": [], "summary": _generate_summary([])}
    if condition == "C2":
        return {
            "observed_world": {
                "digest": _world_digest(world),
                "subdigests": _subdigests(world),
            },
            "task_ledger": _c2_ledger(world, task_steps, target),
            "command_effect_log": [],
        }
    raise ValueError(f"unknown condition {condition}")


def _update_belief(condition, belief, world, action, task_steps, target):
    if condition == "C0":
        belief.append({"action": action})
    elif condition == "C1":
        belief["transcript"].append({"action": action})
        belief["summary"] = _generate_summary(belief["transcript"])
    elif condition == "C2":
        belief["observed_world"] = {
            "digest": _world_digest(world),
            "subdigests": _subdigests(world),
        }
        belief["task_ledger"] = _c2_ledger(world, task_steps, target)
        belief["command_effect_log"].append(
            {"action": action, "world_digest": _world_digest(world)}
        )


def _c2_recovery_action(mismatch_keys, current_step, world):
    if "artifacts" in mismatch_keys or world.get("artifacts"):
        return "reset_artifacts"
    if "base_sha" in mismatch_keys:
        return "check_base_sha"
    if "dependency_version" in mismatch_keys:
        return "inspect_dependency"
    if "test_result" in mismatch_keys:
        return "run_tests"
    if "repo" in mismatch_keys:
        if current_step == 1:
            return "inspect_contract"
        if current_step == 4:
            return "inspect_file:src/a.py"
        return "reconcile"
    return "reconcile"


def _choose_action_c0(belief):
    step = _infer_current_step_from_transcript(belief)
    if step < len(STEP_ACTIONS):
        return STEP_ACTIONS[step]
    return "declare_done"


def _choose_action_c1(belief):
    summary = belief["summary"]
    step = summary["current_step"]
    if step < len(STEP_ACTIONS):
        return STEP_ACTIONS[step]
    return "declare_done"


def _choose_action_c2(belief, world, task_steps, target):
    current_step = len(task_steps)
    for i, entry in enumerate(belief["task_ledger"]):
        if entry["status"] != "completed":
            current_step = i
            break

    observed = belief["observed_world"]["subdigests"]
    actual = _subdigests(world)
    mismatch_keys = [k for k in observed if observed[k] != actual[k]]
    if _c2_evidence_stale(belief, world, task_steps, target):
        mismatch_keys.append("evidence")

    if mismatch_keys:
        # Reconcile belief before acting so the recovery action itself is not scored stale.
        belief["observed_world"] = {
            "digest": _world_digest(world),
            "subdigests": actual,
        }
        return _c2_recovery_action(mismatch_keys, current_step, world)

    # Skip duplicates
    if current_step < len(task_steps):
        candidate = STEP_ACTIONS[current_step]
        if _is_duplicate(candidate, world, target):
            return "noop"
        return candidate
    return "verify_completion"


def _choose_action(condition, belief, world, task_steps, target):
    if condition == "C0":
        return _choose_action_c0(belief)
    if condition == "C1":
        return _choose_action_c1(belief)
    if condition == "C2":
        return _choose_action_c2(belief, world, task_steps, target)
    raise ValueError(f"unknown condition {condition}")


def _make_event(turn, phase, condition, action, belief, world, accepted_steps, duplicate_work):
    return {
        "turn": turn,
        "phase": phase,
        "condition": condition,
        "action": action,
        "belief_digest": belief_digest(condition, belief),
        "world_digest": _world_digest(world),
        "accepted_steps": accepted_steps,
        "duplicate_work": duplicate_work,
    }


def _condition_mutation_side_effects(condition, belief, world, perturbation, snapshot_world, task_steps, target):
    pid = perturbation["id"]
    if pid == "P-07":
        if condition == "C0":
            belief.clear()
        elif condition == "C1":
            belief["transcript"] = []
            belief["summary"] = _generate_summary([])
        elif condition == "C2":
            # Restore explicit state to the snapshot world.
            belief["observed_world"] = {
                "digest": _world_digest(world),
                "subdigests": _subdigests(world),
            }
            belief["task_ledger"] = _c2_ledger(world, task_steps, target)
    elif pid == "P-12" and condition == "C2":
        binding = perturbation["mutation"]["binding"]
        step_index = perturbation["mutation"]["step_index"]
        if 0 <= step_index < len(belief["task_ledger"]):
            entry = belief["task_ledger"][step_index]
            if entry["status"] == "completed":
                entry["evidence_ref"]["binding"] = binding


def _run_cell(condition, perturbation, fixture):
    task_steps = fixture["task_steps"]
    target = fixture["target"]
    world = copy.deepcopy(fixture["world"])
    belief = _initialize_belief(condition, world, task_steps, target)
    events = []
    phase = "pre-perturbation"
    turn = 0
    snapshot_world = None
    inj_step = perturbation["injection_step"]

    max_pre = max(inj_step + 5, 12)
    while True:
        acc = _accepted_steps(world, task_steps, target)
        if sum(acc) >= inj_step:
            snapshot_world = copy.deepcopy(world)
            break
        if turn >= max_pre:
            snapshot_world = copy.deepcopy(world)
            break
        turn += 1
        action = _choose_action(condition, belief, world, task_steps, target)
        dup = _is_duplicate(action, world, target)
        world = _apply_action(world, action, target)
        _update_belief(condition, belief, world, action, task_steps, target)
        acc = _accepted_steps(world, task_steps, target)
        events.append(_make_event(turn, phase, condition, action, belief, world, acc, dup))
        if action in ("declare_done", "declare_blocked"):
            return events

    world = _apply_mutation(world, perturbation["mutation"], target)
    _condition_mutation_side_effects(
        condition, belief, world, perturbation, snapshot_world, task_steps, target
    )
    phase = "post-perturbation"

    max_post = 12
    for _ in range(max_post):
        turn += 1
        action = _choose_action(condition, belief, world, task_steps, target)
        dup = _is_duplicate(action, world, target)
        world = _apply_action(world, action, target)
        _update_belief(condition, belief, world, action, task_steps, target)
        acc = _accepted_steps(world, task_steps, target)
        events.append(_make_event(turn, phase, condition, action, belief, world, acc, dup))
        if action in ("declare_done", "declare_blocked"):
            break
        if all(acc):
            # Continue one more turn to allow verify/declare if needed, but stop loop soon.
            pass

    return events


def _repository_sha(experiment_dir):
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "HEAD"],
            cwd=experiment_dir,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return out.strip()
    except Exception:
        return "unknown"


def _write_jsonl(path, records):
    _ensure_dir(os.path.dirname(path))
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for r in records:
            f.write(canonical_json(r) + "\n")


def _ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def run_experiment(experiment_dir):
    fixture = _load_fixture(experiment_dir)
    oracle = fixture["oracle"]
    perturbations = oracle["perturbations"]
    conditions = ["C0", "C1", "C2"]

    evidence_dir = os.path.join(experiment_dir, "evidence", "pilot-0")
    raw_dir = os.path.join(evidence_dir, "raw")
    if os.path.isdir(evidence_dir):
        shutil.rmtree(evidence_dir)
    _ensure_dir(raw_dir)

    cell_scores = []
    for condition in conditions:
        for pert in perturbations:
            events = _run_cell(condition, pert, fixture)
            cell = {"condition": condition, "perturbation": pert["id"], "events": events}
            metrics = score_cell(events, pert, condition)
            cell_scores.append({"condition": condition, "perturbation": pert["id"], "metrics": metrics})
            log_path = os.path.join(raw_dir, f"{condition}_{pert['id']}.jsonl")
            _write_jsonl(log_path, events)

    aggregated = aggregate_conditions(cell_scores)

    results = {
        "schema": SCHEMA,
        "protocol_version": "v0",
        "experiment_id": "ARS-001",
        "pilot_id": "pilot-0",
        "claim_scope": "fixture/harness/mechanism-only",
        "provenance": {
            "harness_identity": HARNESS_IDENTITY,
            "model_identity": MODEL_IDENTITY,
            "remote_credentials_used": False,
            "arsenal_commit": CANONICAL_PLACEHOLDER,
            "repository_sha": _repository_sha(experiment_dir),
            "runtime_identity": "python3 stdlib only",
        },
        "fixture_identity": {
            "fixture_id": fixture["manifest"]["fixture_id"],
            "fixture_digest": fixture["manifest"]["fixture_digest"],
        },
        "limitations": [
            "Deterministic scripted policy is not a model.",
            "Pilot discriminates fixture/harness behavior and condition mechanics, not model cognition.",
            "Results are bound to this fixture/task family.",
            "Token consumption is not observed.",
        ],
        "metrics": {
            "per_condition": aggregated,
            "per_cell": [
                {
                    "condition": cs["condition"],
                    "perturbation": cs["perturbation"],
                    "metrics": cs["metrics"],
                }
                for cs in cell_scores
            ],
        },
        "run_digest": CANONICAL_PLACEHOLDER,
    }

    # Compute run_digest excluding self and mutable provenance fields.
    digest_input = copy.deepcopy(results)
    digest_input["run_digest"] = CANONICAL_PLACEHOLDER
    digest_input["provenance"]["arsenal_commit"] = CANONICAL_PLACEHOLDER
    digest_input["provenance"]["repository_sha"] = CANONICAL_PLACEHOLDER
    results["run_digest"] = digest(digest_input)

    results_path = os.path.join(evidence_dir, "results.v0.json")
    with open(results_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(canonical_json(results))
    return results


def _print_table(aggregated):
    print("\nPer-condition primary metrics")
    print("-" * 80)
    header = (
        f"{'Condition':<12}"
        f"{'Stale':>8}"
        f"{'Invalid':>10}"
        f"{'Incorrect':>12}"
        f"{'Recovery':>10}"
        f"{'Duplicate':>11}"
        f"{'Repair':>9}"
        f"{'Human':>8}"
    )
    print(header)
    print("-" * 80)
    for cond in ("C0", "C1", "C2"):
        m = aggregated[cond]
        line = (
            f"{cond:<12}"
            f"{m['stale_assumptions_acted_upon']:>8}"
            f"{m['invalid_operations_attempted']:>10}"
            f"{m['incorrect_completion_decisions']:>12}"
            f"{m['recovery_correctness_count']:>10}"
            f"{m['duplicate_work_events']:>11}"
            f"{m['repair_iterations']:>9}"
            f"{m['human_intervention_events']:>8}"
        )
        print(line)
    print("-" * 80)


def determinism_check(experiment_dir):
    source_files = [
        "build_fixture.py",
        "harness.py",
        "metrics.py",
        "README.md",
        "PROTOCOL.md",
    ]
    with tempfile.TemporaryDirectory() as tmp:
        dirs = [os.path.join(tmp, "a"), os.path.join(tmp, "b")]
        for d in dirs:
            _ensure_dir(d)
            for name in source_files:
                src = os.path.join(experiment_dir, name)
                if os.path.exists(src):
                    shutil.copy2(src, d)
            # Build fixtures and run in each isolated copy.
            subprocess.run(
                [sys.executable, "build_fixture.py"],
                cwd=d,
                check=True,
            )
            subprocess.run(
                [sys.executable, "harness.py", "run"],
                cwd=d,
                check=True,
            )

        manifest_a = os.path.join(dirs[0], "fixtures", "fixture_manifest.json")
        manifest_b = os.path.join(dirs[1], "fixtures", "fixture_manifest.json")
        results_a = os.path.join(dirs[0], "evidence", "pilot-0", "results.v0.json")
        results_b = os.path.join(dirs[1], "evidence", "pilot-0", "results.v0.json")

        fixture_digest_a = json.load(open(manifest_a, "r", encoding="utf-8"))["fixture_digest"]
        fixture_digest_b = json.load(open(manifest_b, "r", encoding="utf-8"))["fixture_digest"]
        run_digest_a = json.load(open(results_a, "r", encoding="utf-8"))["run_digest"]
        run_digest_b = json.load(open(results_b, "r", encoding="utf-8"))["run_digest"]

        ok = (
            fixture_digest_a == fixture_digest_b
            and run_digest_a == run_digest_b
        )
        status = "PASS" if ok else "FAIL"
        print(f"fixture_digest_a: {fixture_digest_a}")
        print(f"fixture_digest_b: {fixture_digest_b}")
        print(f"run_digest_a:     {run_digest_a}")
        print(f"run_digest_b:     {run_digest_b}")
        print(f"determinism-check: {status}")
        return ok


def main():
    experiment_dir = os.path.dirname(os.path.abspath(__file__))
    if len(sys.argv) < 2:
        print("Usage: python3 harness.py run|determinism-check")
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "run":
        results = run_experiment(experiment_dir)
        _print_table(results["metrics"]["per_condition"])
        print(f"\nfixture_digest: {results['fixture_identity']['fixture_digest']}")
        print(f"run_digest:     {results['run_digest']}")
    elif cmd == "determinism-check":
        ok = determinism_check(experiment_dir)
        sys.exit(0 if ok else 1)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)


if __name__ == "__main__":
    main()
