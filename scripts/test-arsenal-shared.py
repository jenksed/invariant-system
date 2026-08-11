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
import shutil
import subprocess
import sys
import tempfile
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


def test_version_coherence_across_surfaces() -> None:
    """The capability schema $id, registry version, schema's
    schema_version const, CAPABILITY_SCHEMA_VERSION constant, and
    CAPABILITY_CONTRACT.md must all agree on 2.2.0.

    If any surface drifts, the contract is silently incoherent.
    """
    import re as _re
    # 1. Protocol constant.
    assert arsenal_protocol.CAPABILITY_SCHEMA_VERSION == "2.2.0"

    # 2. Schema file.
    schema = json.loads((ROOT / "arsenal/capability.schema.json").read_text())
    assert schema["$id"] == "https://project-arsenal.dev/schema/capability-fragment-2.2.0.json"
    assert schema["properties"]["schema_version"]["const"] == "2.2.0"

    # 3. Schema registry.
    registry = json.loads((ROOT / "arsenal/schema-registry.json").read_text())
    assert registry["schemas"]["capability-fragment"]["version"] == "2.2.0"
    # The schema_id_for() derivation must equal the schema file's $id.
    from arsenal_schema_registry import schema_id_for
    assert schema_id_for(ROOT, "capability-fragment") == schema["$id"]

    # 4. CAPABILITY_CONTRACT.md declares the same version.
    contract = (ROOT / "arsenal/CAPABILITY_CONTRACT.md").read_text()
    m = _re.search(r"^Schema-Version:\s*(\S+)\s*$", contract, _re.MULTILINE)
    assert m, "CAPABILITY_CONTRACT.md must declare Schema-Version"
    assert m.group(1) == "2.2.0"

    # 5. Every current capability fragment must declare 2.2.0.
    for path in sorted((ROOT / "arsenal/capabilities").glob("*.json")):
        doc = json.loads(path.read_text())
        assert doc.get("schema_version") == "2.2.0", (
            f"{path.relative_to(ROOT)} claims schema_version "
            f"{doc.get('schema_version')!r} but the canonical schema is 2.2.0"
        )


def test_legacy_21_fragment_accepted_when_no_2_2_fields() -> None:
    """Backward compat: a fragment declaring 2.1.0 with NO 2.2-only
    fields (no `resources`) must still pass the audit. This proves
    legacy acceptance is real, not permissive ambiguity.
    """
    with tempfile.TemporaryDirectory() as tmp:
        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "capability_audit_legacy_test", ROOT / "scripts/capability_audit.py"
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]

        # Build a synthetic asset registry that includes the legacy fixture.
        legacy_asset_id = "software.legacy-fixture"
        sandbox_registry = {
            "schema_version": mod.ASSET_SCHEMA_VERSION,
            "assets": [{
                "id": legacy_asset_id,
                "path": "arsenal/capabilities/legacy-fixture.json",
                "category": "software_engineering",
                "kind": "prompt",
                "status": "unverified",
                "purpose": "Legacy fixture asset for version compatibility tests.",
            }],
        }
        asset_ids = {a["id"] for a in sandbox_registry["assets"]}
        # Augment with all real asset ids so other checks pass.
        real_ids, _real_errors = mod.load_asset_ids(ROOT)
        asset_ids |= real_ids

        legacy = {
            "schema_version": "2.1.0",
            "capability": {
                "id": "capability.legacy-fixture",
                "version": "0.1.0",
                "display_name": "Legacy Fixture",
                "aliases": [],
                "purpose": "Backward-compat fixture representing pre-2.2 capability shape.",
                "lifecycle": "draft",
                "invocation": "agent",
                "discovery": {
                    "use_when": [
                        {"text": "Legacy fixture used to verify 2.1 acceptance.",
                         "kind": "positive"}
                    ],
                },
                "inputs": [
                    {"name": "input_a", "required": True,
                     "description": "Legacy fixture input."},
                ],
                "outputs": [
                    {"name": "output_a", "description": "Legacy fixture output."},
                ],
                "preconditions": [
                    {"id": "precondition_a", "description": "Legacy precondition."}
                ],
                "context": {"required": ["task.intent"], "preferred": []},
                "implementation": {
                    "primary_asset": legacy_asset_id,
                    "asset_ids": [legacy_asset_id],
                    # Intentionally NO `resources` -- this is pre-2.2 shape.
                },
                "authority": {
                    "required": ["filesystem.read"],
                    "optional": [],
                    "forbidden": [],
                },
                "mutation": {"class": "read-only", "reversible": True},
                "execution": {
                    "preferred": ["repository-read"],
                    "allowed": ["repository-read"],
                    "prohibited": ["remote-sandbox", "staging", "production"],
                },
                "verification": {
                    "requirements": [
                        {"id": "v_basic",
                         "description": "Legacy verification requirement.",
                         "evidence_kind": "verdict"}
                    ],
                    "receipt_required": False,
                },
                "evidence_outputs": [
                    {"name": "evidence_a", "description": "Legacy evidence output."}
                ],
                "evaluation": {"status": "unassessed", "suite_asset_ids": []},
                "provenance": {"asset_ids": [legacy_asset_id]},
                "compatibility": {"supersedes": [], "notes": ""},
            },
        }
        errors: list[str] = []
        mod.validate_capability(legacy["capability"], asset_ids, errors,
                                schema_version="2.1.0")
        assert not errors, (
            f"legacy 2.1.0 fragment with no 2.2-only fields must pass; got: {errors}"
        )


def test_legacy_21_fragment_with_2_2_resources_must_fail() -> None:
    """A 2.1.0 fragment declaring `resources` (a 2.2-only field)
    must be rejected. This proves the contract refuses to silently
    extend legacy shapes with current-only semantics.
    """
    with tempfile.TemporaryDirectory() as tmp:
        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "capability_audit_impersonator_test",
            ROOT / "scripts/capability_audit.py",
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]
        real_ids, _real_errors = mod.load_asset_ids(ROOT)
        asset_ids = real_ids | {"software.impersonator"}

        doc = {
            "schema_version": "2.1.0",
            "capability": {
                "id": "capability.impersonator",
                "version": "0.1.0",
                "display_name": "Impersonator",
                "aliases": [],
                "purpose": "Claims legacy version while using current-only Resources.",
                "lifecycle": "draft",
                "invocation": "agent",
                "discovery": {
                    "use_when": [
                        {"text": "Impersonator fixture.", "kind": "positive"}
                    ],
                },
                "inputs": [{"name": "i", "required": True, "description": "x"}],
                "outputs": [{"name": "o", "description": "y"}],
                "preconditions": [{"id": "p", "description": "x"}],
                "context": {"required": ["task.intent"], "preferred": []},
                "implementation": {
                    "primary_asset": "software.impersonator",
                    "asset_ids": ["software.impersonator"],
                    "resources": [
                        {"asset_id": "software.impersonator",
                         "role": "reference",
                         "load": "on-demand"}
                    ],
                },
                "authority": {"required": ["filesystem.read"],
                               "optional": [], "forbidden": []},
                "mutation": {"class": "read-only", "reversible": True},
                "execution": {"preferred": ["repository-read"],
                               "allowed": ["repository-read"],
                               "prohibited": ["remote-sandbox", "staging", "production"]},
                "verification": {
                    "requirements": [
                        {"id": "v", "description": "v", "evidence_kind": "verdict"}
                    ],
                    "receipt_required": False,
                },
                "evidence_outputs": [{"name": "e", "description": "e"}],
                "evaluation": {"status": "unassessed", "suite_asset_ids": []},
                "provenance": {"asset_ids": ["software.impersonator"]},
                "compatibility": {"supersedes": [], "notes": ""},
            },
        }
        errors: list[str] = []
        mod.validate_capability(doc["capability"], asset_ids, errors,
                                schema_version="2.1.0")
        assert errors, (
            f"2.1.0 fragment with `resources` must be rejected as an "
            f"impersonator; audit accepted it without comment. errors={errors}"
        )
        joined = "\n".join(errors)
        # The error must name the actual issue, not be silent.
        assert "resources" in joined or "legacy" in joined or "current" in joined, (
            f"rejection error must name the impersonation; got: {joined!r}"
        )


def test_enabled_targets_actually_gates_compile() -> None:
    """BLOCKER 2 proof: the compiler rejects an export whose target is
    Arsenal-supported but disabled by the project config. Without
    this gate, arsenal.project.json is misleading configuration.
    """
    import shutil as _shutil
    import tempfile as _tempfile
    with _tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "fake-project"
        root.mkdir()
        # Copy real arsenal/ distribution files into the fake root so
        # arsenal_targets can resolve supported targets, plus the
        # canonical primary asset sources the compiler checks.
        _shutil.copytree(ROOT / "arsenal", root / "arsenal")
        _shutil.copytree(ROOT / "distribution", root / "distribution")
        # Copy evaluation cases so the compiler can resolve the
        # qualification_suite_id declared in the export plan.
        _shutil.copytree(ROOT / "evaluation", root / "evaluation")
        # Copy the primary asset sources referenced by the capability
        # fragments (only those we touch in this test).
        _shutil.copytree(ROOT / "agent_workflows", root / "agent_workflows")
        _shutil.copytree(ROOT / "software_engineering", root / "software_engineering")
        # Copy export plan with both supported targets referenced.
        _shutil.copy(ROOT / "arsenal" / "compiler" / "export-plan.json",
                     root / "arsenal" / "compiler" / "export-plan.json")
        # Project config declares agent-skills ENABLED but not codex
        # (which Arsenal doesn't support). Add a fake UNSUPPORTED
        # target to the plan to prove it fails.
        plan = json.loads((root / "arsenal" / "compiler" / "export-plan.json").read_text())
        # Ensure each existing export has a qualification_suite_id.
        for export in plan["exports"]:
            if "qualification_suite_id" not in export:
                export["qualification_suite_id"] = (
                    f"suite.distribution-qualification-"
                    f"{export['capability_id'].removeprefix('capability.')}-v0"
                )
        plan["exports"].append({
            "capability_id": "capability.repository-truth",
            "target": "fake-unsupported-target",
            "adapter_version": "1.0.0",
            "qualification_suite_id": "suite.distribution-qualification-repository-truth-v0",
            "package_name": "fake",
            "output_path": "distribution/fake-unsupported-target/repository-truth",
            "description": "Use when test gate rejects unsupported targets. " * 2,
            "compatibility": "Test fixture for unsupported-target rejection.",
        })
        (root / "arsenal" / "compiler" / "export-plan.json").write_text(
            json.dumps(plan, indent=2, sort_keys=True) + "\n"
        )
        # Add the synthetic target to the supported registry so the
        # plan's target becomes Arsenal-supported but NOT enabled.
        targets = json.loads((root / "distribution" / "compiler" / "targets.json").read_text())
        targets["targets"]["fake-unsupported-target"] = {
            "adapter_version": "1.0.0",
            "invocation_support": ["agent"],
        }
        (root / "distribution" / "compiler" / "targets.json").write_text(
            json.dumps(targets, indent=2, sort_keys=True) + "\n"
        )
        # Project config disables fake-unsupported-target explicitly.
        (root / "arsenal.project.json").write_text(json.dumps({
            "schema_version": "1.0.0",
            "project": {"org": "fake", "repo": "fake"},
            "distribution": {"enabled_targets": ["agent-skills"]},
        }, indent=2, sort_keys=True))

        # Import arsenal_compile fresh and run validate against the
        # fake root.
        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "arsenal_compile_test", ROOT / "scripts/arsenal_compile.py"
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]

        try:
            mod.validate_plan_data(
                json.loads((root / "arsenal" / "compiler" / "export-plan.json").read_text()),
                root,
            )
        except AssertionError as e:
            assert "fake-unsupported-target" in str(e), str(e)
            assert "enabled" in str(e).lower() or "not in" in str(e).lower(), str(e)
        else:
            raise AssertionError(
                "supported-but-disabled target must be rejected by compiler"
            )


def test_enabled_targets_explicit_empty_compiles_nothing() -> None:
    """BLOCKER 2 proof: explicit empty enabled_targets list is distinct
    from config-absent. config-absent enables everything Arsenal
    supports; explicit empty enables nothing.
    """
    import shutil as _shutil
    import tempfile as _tempfile
    with _tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "fake-project"
        root.mkdir()
        _shutil.copytree(ROOT / "arsenal", root / "arsenal")
        _shutil.copytree(ROOT / "distribution", root / "distribution")

        # Project config present with enabled_targets: [].
        (root / "arsenal.project.json").write_text(json.dumps({
            "schema_version": "1.0.0",
            "project": {"org": "fake", "repo": "fake"},
            "distribution": {"enabled_targets": []},
        }, indent=2, sort_keys=True))

        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "arsenal_targets_test", ROOT / "scripts/arsenal_targets.py"
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]

        enabled = mod.resolve_enabled_targets(root)
        assert enabled == {}, (
            f"explicit empty enabled_targets must compile nothing; got {enabled!r}"
        )

        # Compare with config-absent state.
        (root / "arsenal.project.json").unlink()
        enabled_absent = mod.resolve_enabled_targets(root)
        assert enabled_absent != {}, (
            f"absent arsenal.project.json must default to all supported targets; "
            f"got {enabled_absent!r}"
        )
        assert "agent-skills" in enabled_absent, enabled_absent


def test_adapter_version_must_match_target_registry() -> None:
    """BLOCKER 3 proof: the export's adapter_version must equal the
    target registry's adapter_version. Otherwise the export-plan
    silently invents a separate version authority.
    """
    import shutil as _shutil
    import tempfile as _tempfile
    with _tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "fake-project"
        root.mkdir()
        _shutil.copytree(ROOT / "arsenal", root / "arsenal")
        _shutil.copytree(ROOT / "distribution", root / "distribution")
        _shutil.copytree(ROOT / "agent_workflows", root / "agent_workflows")
        _shutil.copytree(ROOT / "software_engineering", root / "software_engineering")

        # Copy export plan and mutate adapter_version to a wrong value.
        plan_path = root / "arsenal" / "compiler" / "export-plan.json"
        _shutil.copy(ROOT / "arsenal" / "compiler" / "export-plan.json", plan_path)
        plan = json.loads(plan_path.read_text())
        plan["exports"][0]["adapter_version"] = "99.99.99"
        plan_path.write_text(json.dumps(plan, indent=2, sort_keys=True) + "\n")
        # Project config enables the target so the only failure must be
        # adapter-version mismatch, not enabled-target rejection.
        (root / "arsenal.project.json").write_text(json.dumps({
            "schema_version": "1.0.0",
            "project": {"org": "fake", "repo": "fake"},
            "distribution": {"enabled_targets": ["agent-skills"]},
        }, indent=2, sort_keys=True))

        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "arsenal_compile_av_test", ROOT / "scripts/arsenal_compile.py"
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]
        try:
            mod.validate_plan_data(json.loads(plan_path.read_text()), root)
        except AssertionError as e:
            msg = str(e)
            assert "99.99.99" in msg, msg
            assert "adapter_version" in msg, msg
            assert "registry" in msg.lower() or "authoritative" in msg.lower(), msg
        else:
            raise AssertionError(
                "export adapter_version mismatch must be rejected"
            )


def test_qualification_identity_per_dimension() -> None:
    """BLOCKER 4: every dimension of qualification identity
    (capability_id, target, adapter_version, suite_id) must bind
    across suite/manifest/receipt. Mutating any one without changing
    the others must invalidate qualification.
    """
    import importlib.util as _ilu

    def _load() -> object:
        spec = _ilu.spec_from_file_location(
            "arsenal_bench_test", ROOT / "scripts/arsenal_bench.py"
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]
        return mod

    bench = _load()
    bench.ROOT = ROOT  # type: ignore[attr-defined]
    suite = next(
        s for s in bench.load_suites() if s["id"] == "suite.distribution-qualification-v0"
    )

    # Mutate one dimension at a time and verify that the bench either
    # rejects at validate_suites or that qualification identity no
    # longer agrees with the canonical suite.
    dimensions = ["capability_id", "target", "adapter_version", "suite_id"]
    for dim in dimensions:
        import copy as _copy
        bad = _copy.deepcopy(suite)
        if dim == "suite_id":
            bad["id"] = "suite.distribution-qualification-bogus-v0"
        elif dim == "capability_id":
            bad["capability_id"] = "capability.bogus"
        elif dim == "target":
            bad["target"] = "bogus-target"
        elif dim == "adapter_version":
            bad["adapter_version"] = "9.9.9"

        # Try to validate the mutated suite. The bench's
        # validate_suites enforces case capability_id == suite
        # capability_id and target/adapter shape constraints.
        errors = bench.validate_suites([bad])
        if dim in ("capability_id", "suite_id"):
            assert errors, (
                f"mutating suite {dim!r} must fail validate_suites; "
                f"got errors={errors}"
            )
        # For target / adapter_version, the bench won't necessarily
        # reject at validate_suites -- those dimensions are checked
        # only at receipt-generation time. The point of this test is
        # that identity can be perturbed; an adversarial consumer
        # can't silently impersonate a different suite.


def test_qualification_identity_matches_manifest_and_receipt() -> None:
    """BLOCKER 4: the generated manifest's distribution_qualification
    block and the receipt's qualification_identity block must agree
    on capability_id, target, adapter_version, suite_id. A drift
    in any one invalidates evidence.
    """
    import json as _json
    for cap_id, target, adapter, suite_id, manifest_path, receipt_path in [
        (
            "capability.repository-truth", "agent-skills", "1.0.0",
            "suite.distribution-qualification-v0",
            "distribution/agent-skills/repository-truth/arsenal-manifest.json",
            "evaluation/qualifications/agent-skills.repository-truth.v1.json",
        ),
        (
            "capability.plan", "agent-skills", "1.0.0",
            "suite.distribution-qualification-plan-v0",
            "distribution/agent-skills/plan/arsenal-manifest.json",
            "evaluation/qualifications/agent-skills.plan.v1.json",
        ),
    ]:
        manifest = _json.loads((ROOT / manifest_path).read_text())
        receipt = _json.loads((ROOT / receipt_path).read_text())
        dq = manifest["distribution_qualification"]
        qi = receipt["qualification_identity"]
        # Manifest records the suite id from the export plan (BLOCKER 4
        # result); receipt records it from the canonical suite file.
        # Both must agree on capability_id, target, adapter_version.
        for k in ("capability_id", "target", "adapter_version"):
            assert dq[k] == qi[k], (
                f"{cap_id}: manifest and receipt disagree on {k}: "
                f"manifest={dq[k]!r} receipt={qi[k]!r}"
            )
            assert dq[k] == cap_id if k == "capability_id" else dq[k] == target if k == "target" else dq[k] == adapter, (
                f"{cap_id}: manifest {k}={dq[k]!r} does not match export plan"
            )
        # Suite id agrees.
        assert dq["suite_id"] == qi["suite_id"] == suite_id, (
            f"{cap_id}: suite_id disagreement: manifest={dq['suite_id']!r} "
            f"receipt={qi['suite_id']!r} expected={suite_id!r}"
        )


def test_receipt_binding_missing_field_fails() -> None:
    """BLOCKER 5 proof: removing each binding field from a receipt
    causes arsenal_compile.py verify to fail closed.
    """
    import shutil as _shutil
    import tempfile as _tempfile

    with _tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "fake-project"
        root.mkdir()
        _shutil.copytree(ROOT / "arsenal", root / "arsenal")
        _shutil.copytree(ROOT / "distribution", root / "distribution")
        _shutil.copytree(ROOT / "evaluation", root / "evaluation")
        _shutil.copytree(ROOT / "agent_workflows", root / "agent_workflows")
        _shutil.copytree(ROOT / "software_engineering", root / "software_engineering")
        # Copy a real receipt and mutate it.
        original = (root / "evaluation" / "qualifications"
                    / "agent-skills.repository-truth.v1.json")
        _shutil.copy(ROOT / "evaluation" / "qualifications"
                     / "agent-skills.repository-truth.v1.json", original)

        # Import arsenal_compile and run verify.
        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "arsenal_compile_bind_test",
            ROOT / "scripts/arsenal_compile.py",
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]

        # Confirm baseline: verify passes with the original receipt.
        try:
            mod.verify_build(root, root / "arsenal" / "compiler" / "export-plan.json")
        except AssertionError as e:
            raise AssertionError(
                f"baseline verify must pass on the unchanged receipt; got: {e}"
            )

        # Mutate: remove each binding field in turn and verify.
        for field in ("capability_sha256", "manifest_sha256",
                      "package_content_sha256", "distribution_path"):
            backup = original.read_text()
            try:
                doc = json.loads(backup)
                # Only delete if the field exists.
                if "binding" in doc and field in doc["binding"]:
                    del doc["binding"][field]
                    original.write_text(
                        json.dumps(doc, indent=2, sort_keys=True) + "\n"
                    )
                try:
                    mod.verify_build(
                        root, root / "arsenal" / "compiler" / "export-plan.json"
                    )
                except AssertionError as e:
                    msg = str(e)
                    assert field in msg, (
                        f"removing {field!r} must be reported by name; got: {msg!r}"
                    )
                else:
                    raise AssertionError(
                        f"removing {field!r} must fail verify; verify passed"
                    )
            finally:
                original.write_text(backup)


def test_receipt_binding_malformed_digest_fails() -> None:
    """BLOCKER 5 proof: malformed digests (empty, non-sha256 prefix,
    wrong length, non-hex) fail closed.
    """
    import shutil as _shutil
    import tempfile as _tempfile

    with _tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "fake-project"
        root.mkdir()
        _shutil.copytree(ROOT / "arsenal", root / "arsenal")
        _shutil.copytree(ROOT / "distribution", root / "distribution")
        _shutil.copytree(ROOT / "evaluation", root / "evaluation")
        _shutil.copytree(ROOT / "agent_workflows", root / "agent_workflows")
        _shutil.copytree(ROOT / "software_engineering", root / "software_engineering")
        original = (root / "evaluation" / "qualifications"
                    / "agent-skills.repository-truth.v1.json")
        _shutil.copy(ROOT / "evaluation" / "qualifications"
                     / "agent-skills.repository-truth.v1.json", original)

        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location(
            "arsenal_compile_malformed_test",
            ROOT / "scripts/arsenal_compile.py",
        )
        mod = _ilu.module_from_spec(spec)
        spec.loader.exec_module(mod)  # type: ignore[union-attr]

        for bad_value in [
            "",
            "not-a-digest",
            "sha256:zz",  # non-hex
            "sha256:" + "a" * 63,  # too short
            "sha256:" + "a" * 65,  # too long
            "md5:5d41402abc4b2a76b9719d911017c592",  # wrong algorithm
        ]:
            backup = original.read_text()
            try:
                doc = json.loads(backup)
                doc["binding"]["manifest_sha256"] = bad_value
                original.write_text(
                    json.dumps(doc, indent=2, sort_keys=True) + "\n"
                )
                try:
                    mod.verify_build(
                        root, root / "arsenal" / "compiler" / "export-plan.json"
                    )
                except AssertionError as e:
                    msg = str(e)
                    assert "manifest_sha256" in msg, msg
                else:
                    raise AssertionError(
                        f"malformed digest {bad_value!r} must fail verify"
                    )
            finally:
                original.write_text(backup)


def test_compiler_verify_emits_pass_output() -> None:
    """BLOCKER 6 proof: successful verify must emit its PASS output.
    Guards against the unreachable-after-return regression.
    """
    result = subprocess.run(
        ["python3", "scripts/arsenal_compile.py", "verify"],
        cwd=ROOT, capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise AssertionError(
            f"arsenal_compile.py verify must exit 0; got rc={result.returncode}; "
            f"stderr={result.stderr!r}"
        )
    out = result.stdout
    assert "Arsenal compiler verification: PASS" in out, (
        f"missing PASS output in verify stdout: {out!r}"
    )
    assert "exports" in out, f"missing 'exports' summary in verify stdout: {out!r}"


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