#!/usr/bin/env python3
"""Characterization tests for shared Arsenal modules.

These tests prove the new shared modules (arsenal_protocol, arsenal_io,
arsenal_targets) preserve the exact values and behaviors the domain
scripts depend on. They are not a replacement for the existing domain
test suites; they are the characterization safety net that lets us
refactor domain scripts to use the shared modules without losing
behavior.

If any of these tests fails, a domain script's vocabulary or I/O has
drifted from the canonical Arsenal protocol.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import arsenal_io  # noqa: E402
import arsenal_protocol  # noqa: E402
import arsenal_targets  # noqa: E402


def test_protocol_authority_matches_legacy_hardcode() -> None:
    """The canonical AUTHORITY vocabulary must equal the historical
    hardcoded set used by arsenal_trust.py, arsenal_substrate.py, and
    capability_audit.py. If this drifts, the vocabulary has diverged
    silently between modules.
    """
    legacy = {
        "filesystem.read", "filesystem.write", "shell.execute",
        "network.read", "network.write", "git.read", "git.write",
        "tracker.read", "tracker.write", "secrets.read",
        "cloud.local", "cloud.remote", "production.mutate",
        "human.confirmation",
    }
    assert arsenal_protocol.AUTHORITY == legacy, (
        f"protocol AUTHORITY diverged from legacy hardcode: "
        f"diff={arsenal_protocol.AUTHORITY ^ legacy}"
    )


def test_protocol_substrates_match_legacy_hardcode() -> None:
    """Canonical substrate vocabulary must equal the historical set."""
    legacy = {
        "reasoning-only", "repository-read", "local-process",
        "local-container", "local-emulator", "local-cluster",
        "remote-sandbox", "shared-nonproduction", "staging",
        "production", "user-mediated",
    }
    assert arsenal_protocol.SUBSTRATES == legacy


def test_protocol_lifecycle_and_evaluation_unchanged() -> None:
    """Lifecycle and evaluation state vocabularies are protocol."""
    assert arsenal_protocol.LIFECYCLE_STATES == {"draft", "testing", "stable", "deprecated"}
    assert arsenal_protocol.EVALUATION_STATES == {
        "unassessed", "planned", "candidate", "qualified",
    }
    assert arsenal_protocol.DISTRIBUTION_QUALIFICATION_STATES == {
        "unassessed", "candidate", "qualified",
    }
    assert arsenal_protocol.INVOCATIONS == {"human", "agent", "composed"}
    assert arsenal_protocol.MUTATION_CLASSES == {
        "read-only", "workspace-write", "external-write", "high-consequence",
    }


def test_protocol_schema_versions_unchanged() -> None:
    assert arsenal_protocol.CAPABILITY_SCHEMA_VERSION == "2.2.0"
    assert arsenal_protocol.CAPABILITY_SCHEMA_LEGACY == {"2.0.0", "2.1.0"}
    assert arsenal_protocol.ASSET_SCHEMA_VERSION == "1.0.0"
    assert arsenal_protocol.LOCK_SCHEMA_VERSION == "1.0.0"
    assert arsenal_protocol.SUITE_SCHEMA_VERSION == "1.0.0"
    assert arsenal_protocol.COMPILER_VERSION == "0.1.0"


def test_protocol_resource_matrix_is_intentional() -> None:
    """The role x load compatibility matrix must be self-consistent."""
    readable = {"instructions", "reference", "template"}
    executable = {"script", "fixture", "asset"}
    assert arsenal_protocol.READABLE_ROLES == readable
    assert arsenal_protocol.EXECUTABLE_ROLES == executable
    # All resource roles must be partitioned cleanly.
    all_roles = readable | executable
    assert all_roles == arsenal_protocol.RESOURCE_ROLES


def test_protocol_write_authority_is_subset_of_authority() -> None:
    assert arsenal_protocol.WRITE_AUTHORITY <= arsenal_protocol.AUTHORITY


def test_io_sha256_is_stable_and_prefixed() -> None:
    h = arsenal_io.sha256_bytes(b"hello")
    assert h.startswith("sha256:")
    assert h == "sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"


def test_io_canonical_json_is_byte_stable() -> None:
    a = arsenal_io.canonical_json({"b": 1, "a": 2})
    b = arsenal_io.canonical_json({"a": 2, "b": 1})
    assert a == b
    # Trailing newline so textual concatenation stays consistent.
    assert a.endswith(b"\n")


def test_io_safe_relative_path_rejects_traversal() -> None:
    arsenal_io.safe_relative_path("foo/bar.json", field="path")
    try:
        arsenal_io.safe_relative_path("../escape", field="path")
    except ValueError as e:
        assert ".." in str(e)
        return
    raise AssertionError("safe_relative_path should reject '..' segments")


def test_io_safe_relative_path_rejects_absolute() -> None:
    try:
        arsenal_io.safe_relative_path("/etc/passwd", field="path")
    except ValueError:
        return
    raise AssertionError("safe_relative_path should reject absolute paths")


def test_io_safe_relative_path_rejects_empty() -> None:
    try:
        arsenal_io.safe_relative_path("", field="path")
    except ValueError:
        return
    raise AssertionError("safe_relative_path should reject empty paths")


def test_targets_loads_supported_registry() -> None:
    targets = arsenal_targets.load_supported_targets(ROOT)
    assert "agent-skills" in targets
    agent = targets["agent-skills"]
    assert agent["adapter_version"] == "1.0.0"
    assert "agent" in agent["invocation_support"]
    assert "composed" in agent["invocation_support"]
    # human is intentionally NOT supported for agent-skills.
    assert "human" not in agent["invocation_support"]


def test_targets_default_to_all_supported_when_no_project_config() -> None:
    """A repository without arsenal.project.json compiles every
    supported target. This preserves the pre-refactor default where
    export-plan.json enumerated the targets directly.
    """
    # Ensure no arsenal.project.json interferes.
    config_path = ROOT / "arsenal.project.json"
    had_config = config_path.is_file()
    saved = config_path.read_text() if had_config else None
    if had_config:
        config_path.unlink()
    try:
        enabled = arsenal_targets.resolve_enabled_targets(ROOT)
        assert "agent-skills" in enabled
    finally:
        if had_config:
            config_path.write_text(saved)


def test_targets_unsupported_target_is_rejected() -> None:
    """A project cannot enable a target Arsenal does not ship."""
    config_path = ROOT / "arsenal.project.json"
    had_config = config_path.is_file()
    saved = config_path.read_text() if had_config else None
    if had_config:
        config_path.unlink()
    try:
        bad = {
            "schema_version": arsenal_targets.PROJECT_CONFIG_VERSION,
            "project": {"org": "test", "repo": "test"},
            "distribution": {"enabled_targets": ["bogus-target"]},
        }
        config_path.write_text(json.dumps(bad, indent=2, sort_keys=True))
        try:
            arsenal_targets.resolve_enabled_targets(ROOT)
        except ValueError as e:
            assert "bogus-target" in str(e)
            return
        raise AssertionError("resolve_enabled_targets should reject unsupported target")
    finally:
        if had_config:
            config_path.write_text(saved)
        else:
            config_path.unlink(missing_ok=True)


def test_targets_rejects_unknown_invocation_support() -> None:
    """The target registry validator must reject invocations outside
    the canonical INVOCATIONS vocabulary. Project configuration cannot
    invent new invocations through target registry entries.
    """
    # Write a temporary registry that declares an invalid invocation.
    import tempfile
    with tempfile.NamedTemporaryFile(
        "w", suffix=".json", delete=False,
    ) as f:
        path = Path(f.name)
    try:
        path.write_text(json.dumps({
            "schema_version": "1.0.0",
            "targets": {
                "bogus-target": {
                    "adapter_version": "1.0.0",
                    "invocation_support": ["imaginary-invocation"],
                },
            },
        }))
        try:
            arsenal_targets.load_supported_targets(path)
        except ValueError as e:
            assert "imaginary-invocation" in str(e)
            return
        raise AssertionError("load_supported_targets should reject unknown invocation")
    finally:
        path.unlink()


def main() -> int:
    tests = [v for k, v in globals().items() if k.startswith("test_")]
    failures = 0
    for fn in tests:
        try:
            fn()
            print(f"PASS {fn.__name__}")
        except AssertionError as e:
            print(f"FAIL {fn.__name__}: {e}")
            failures += 1
        except Exception as e:
            print(f"ERROR {fn.__name__}: {type(e).__name__}: {e}")
            failures += 1
    if failures:
        print(f"ARS-SHARED: {failures} failure(s)")
        return 1
    print("ARS-SHARED characterization suite: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())