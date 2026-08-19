"""Deterministic fixture generator for ARS-001 pilot."""

import json
import os
import shutil

from metrics import canonical_json, digest, digest_file, CANONICAL_PLACEHOLDER

EXPERIMENT_DIR = os.path.dirname(os.path.abspath(__file__))
FIXTURES_DIR = os.path.join(EXPERIMENT_DIR, "fixtures")
REPO_DIR = os.path.join(FIXTURES_DIR, "repo")


def _ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def _write_file(path, content):
    _ensure_dir(os.path.dirname(path))
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content)


def _content_digest(content):
    return digest({"content": content})


def build():
    if os.path.isdir(FIXTURES_DIR):
        shutil.rmtree(FIXTURES_DIR)
    _ensure_dir(REPO_DIR)
    _ensure_dir(os.path.join(REPO_DIR, "src"))

    file_specs = {
        "repo/spec.md": "Feature specification v1\n\nImplement feature returning 42.\n",
        "repo/src/a.py": "pass\n",
        "repo/src/b.py": "def helper():\n    return 1\n",
        "repo/shared-contract.yaml": "contract:\n  version: 1\n",
    }

    files = {}
    for rel_path, content in file_specs.items():
        full = os.path.join(FIXTURES_DIR, rel_path)
        _write_file(full, content)
        files[rel_path] = {
            "sha256": digest_file(full),
            "size": len(content.encode("utf-8")),
        }

    implementation_content = "def feature():\n    return 42\n"
    target_dependency = "2.0.0"

    world = {
        "repo": {
            rel: {"content": content, "digest": _content_digest(content)}
            for rel, content in file_specs.items()
        },
        "base_sha": "abc123",
        "dependency_version": "1.0.0",
        "test_result": {"passed": False, "output": "not run", "state_binding": CANONICAL_PLACEHOLDER},
        "command_log": [],
        "artifacts": {},
    }

    task_steps = [
        {
            "id": "S1",
            "description": "Inspect spec and confirm task scope",
            "required_action": "inspect_spec",
        },
        {
            "id": "S2",
            "description": "Inspect shared contract and confirm validity",
            "required_action": "inspect_contract",
        },
        {
            "id": "S3",
            "description": "Run tests and cache result with state binding",
            "required_action": "run_tests",
        },
        {
            "id": "S4",
            "description": "Update dependency to target version",
            "required_action": "update_dependency",
        },
        {
            "id": "S5",
            "description": "Implement feature in src/a.py",
            "required_action": "edit_src_a",
        },
        {
            "id": "S6",
            "description": "Verify completion",
            "required_action": "verify_completion",
        },
    ]

    perturbations = [
        {
            "id": "P-01",
            "name": "observed file changed externally",
            "injection_step": 4,
            "mutation": {
                "type": "change_file",
                "path": "repo/src/a.py",
                "new_content": "def feature():\n    return 43\n",
            },
            "expected_recovery_action": {
                "C0": "edit_src_a",
                "C1": "edit_src_a",
                "C2": "inspect_file:src/a.py",
            },
            "invalid_actions": ["edit_src_a"],
            "completable": True,
        },
        {
            "id": "P-02",
            "name": "base SHA changed",
            "injection_step": 1,
            "mutation": {"type": "change_base_sha", "new_base_sha": "def456"},
            "expected_recovery_action": {
                "C0": "inspect_contract",
                "C1": "inspect_contract",
                "C2": "check_base_sha",
            },
            "invalid_actions": [],
            "completable": True,
        },
        {
            "id": "P-03",
            "name": "dependency changed",
            "injection_step": 3,
            "mutation": {"type": "change_dependency", "new_version": "1.1.0"},
            "expected_recovery_action": {
                "C0": "update_dependency",
                "C1": "update_dependency",
                "C2": "inspect_dependency",
            },
            "invalid_actions": ["update_dependency"],
            "completable": True,
        },
        {
            "id": "P-04",
            "name": "previous test result became stale",
            "injection_step": 2,
            "mutation": {
                "type": "stale_test_result",
                "passed": True,
                "state_binding": "stale-binding-0000000000000000000000000000000000000000000000000000000000000000",
            },
            "expected_recovery_action": {
                "C0": "update_dependency",
                "C1": "update_dependency",
                "C2": "run_tests",
            },
            "invalid_actions": ["update_dependency", "edit_src_a"],
            "completable": True,
        },
        {
            "id": "P-05",
            "name": "command already executed",
            "injection_step": 3,
            "mutation": {
                "type": "pre_execute_command",
                "action": "update_dependency",
            },
            "expected_recovery_action": {
                "C0": "update_dependency",
                "C1": "update_dependency",
                "C2": "edit_src_a",
            },
            "invalid_actions": [],
            "completable": True,
        },
        {
            "id": "P-06",
            "name": "partial effect occurred before interruption",
            "injection_step": 4,
            "mutation": {
                "type": "change_file",
                "path": "repo/src/a.py",
                "new_content": "def feature():\n    return 4",
            },
            "expected_recovery_action": {
                "C0": "edit_src_a",
                "C1": "edit_src_a",
                "C2": "inspect_file:src/a.py",
            },
            "invalid_actions": ["edit_src_a"],
            "completable": True,
        },
        {
            "id": "P-07",
            "name": "process restarted",
            "injection_step": 2,
            "mutation": {"type": "process_restart", "snapshot_step": 1},
            "expected_recovery_action": {
                "C0": "inspect_spec",
                "C1": "inspect_spec",
                "C2": "run_tests",
            },
            "invalid_actions": [],
            "completable": True,
        },
        {
            "id": "P-08",
            "name": "worktree rebased",
            "injection_step": 5,
            "mutation": {
                "type": "rebase",
                "new_base_sha": "xyz789",
                "file_changes": {
                    "repo/src/a.py": "def feature():\n    return 41\n",
                },
            },
            "expected_recovery_action": {
                "C0": "verify_completion",
                "C1": "verify_completion",
                "C2": "reconcile",
            },
            "invalid_actions": ["declare_done"],
            "completable": True,
        },
        {
            "id": "P-09",
            "name": "another worker changed a shared contract",
            "injection_step": 1,
            "mutation": {
                "type": "change_file",
                "path": "repo/shared-contract.yaml",
                "new_content": "contract:\n  version: 2\n",
            },
            "expected_recovery_action": {
                "C0": "inspect_contract",
                "C1": "inspect_contract",
                "C2": "inspect_contract",
            },
            "invalid_actions": [],
            "completable": True,
        },
        {
            "id": "P-10",
            "name": "failed attempt left artifacts",
            "injection_step": 4,
            "mutation": {
                "type": "add_artifact",
                "key": "failed_attempt",
                "data": {"errors": ["build failed"]},
            },
            "expected_recovery_action": {
                "C0": "edit_src_a",
                "C1": "edit_src_a",
                "C2": "reset_artifacts",
            },
            "invalid_actions": ["edit_src_a"],
            "completable": True,
        },
        {
            "id": "P-11",
            "name": "repository and conversational history disagree",
            "injection_step": 3,
            "mutation": {"type": "change_base_sha", "new_base_sha": "ghi789"},
            "expected_recovery_action": {
                "C0": "update_dependency",
                "C1": "update_dependency",
                "C2": "check_base_sha",
            },
            "invalid_actions": ["update_dependency"],
            "completable": True,
        },
        {
            "id": "P-12",
            "name": "evidence references an obsolete repository state",
            "injection_step": 5,
            "mutation": {"type": "stale_evidence", "step_index": 1, "binding": "obsolete-binding-000000000000000000000000000000000000000000000000000000000000"},
            "expected_recovery_action": {
                "C0": "verify_completion",
                "C1": "verify_completion",
                "C2": "reverify_evidence",
            },
            "invalid_actions": [],
            "completable": True,
        },
    ]

    oracle = {"perturbations": perturbations}

    fixture = {
        "schema": "arsenal/ars-001-fixture/v0",
        "fixture_id": "ars-001-execution-state-pilot-0",
        "target": {
            "implementation_content": implementation_content,
            "implementation_digest": _content_digest(implementation_content),
            "dependency_version": target_dependency,
            "dependency_digest": _content_digest(target_dependency),
        },
        "task_steps": task_steps,
        "world": world,
        "oracle": oracle,
    }

    _write_file(os.path.join(FIXTURES_DIR, "task.json"), canonical_json(task_steps))
    _write_file(os.path.join(FIXTURES_DIR, "world.json"), canonical_json(world))
    _write_file(os.path.join(FIXTURES_DIR, "oracle.json"), canonical_json(oracle))

    for rel_path in ("task.json", "world.json", "oracle.json"):
        full = os.path.join(FIXTURES_DIR, rel_path)
        files[rel_path] = {"sha256": digest_file(full), "size": os.path.getsize(full)}

    manifest = {
        "schema": "arsenal/ars-001-fixture-manifest/v0",
        "fixture_id": fixture["fixture_id"],
        "files": files,
        "fixture_digest": CANONICAL_PLACEHOLDER,
    }
    manifest["fixture_digest"] = digest({**manifest, "fixture_digest": CANONICAL_PLACEHOLDER})
    _write_file(os.path.join(FIXTURES_DIR, "fixture_manifest.json"), canonical_json(manifest))


if __name__ == "__main__":
    build()
