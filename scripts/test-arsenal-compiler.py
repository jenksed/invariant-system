#!/usr/bin/env python3
"""Negative and determinism tests for ARS-03 compiler/export contracts."""
from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/arsenal_compile.py"
SPEC = importlib.util.spec_from_file_location("arsenal_compile", SCRIPT)
assert SPEC and SPEC.loader
compiler = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(compiler)


def expect_fail(label: str, plan: dict) -> None:
    try:
        compiler.validate_plan_data(plan, ROOT)
    except (AssertionError, KeyError, TypeError, ValueError):
        print(f"PASS negative case: {label}")
        return
    raise AssertionError(f"negative case unexpectedly passed: {label}")


def main() -> int:
    plan = compiler.load_json(ROOT / "arsenal/compiler/export-plan.json")
    exports = compiler.validate_plan_data(plan, ROOT)
    assert len(exports) == 1
    print("PASS valid ARS-03 export plan")

    bad = copy.deepcopy(plan)
    bad["exports"].append(copy.deepcopy(bad["exports"][0]))
    expect_fail("duplicate capability/target export", bad)

    bad = copy.deepcopy(plan)
    bad["exports"][0]["capability_id"] = "capability.does-not-exist"
    expect_fail("unknown capability", bad)

    bad = copy.deepcopy(plan)
    bad["exports"][0]["target"] = "imaginary-harness"
    expect_fail("unsupported target", bad)

    bad = copy.deepcopy(plan)
    bad["exports"][0]["output_path"] = "../escape/repository-truth"
    expect_fail("path traversal", bad)

    bad = copy.deepcopy(plan)
    bad["exports"][0]["package_name"] = "Repository Truth"
    expect_fail("invalid package name", bad)

    bad = copy.deepcopy(plan)
    bad["exports"][0]["description"] = "No discovery marker here."
    expect_fail("missing Agent Skills discovery context", bad)

    with tempfile.TemporaryDirectory(prefix="arsenal-compiler-test-") as tmp:
        tmp_root = Path(tmp)
        lock_a, files_a = compiler.build_outputs(ROOT, tmp_root / "a", ROOT / "arsenal/compiler/export-plan.json")
        lock_b, files_b = compiler.build_outputs(ROOT, tmp_root / "b", ROOT / "arsenal/compiler/export-plan.json")
        assert compiler.canonical_json(lock_a) == compiler.canonical_json(lock_b)
        assert len(files_a) == len(files_b) == 3

        out_rel = Path(plan["exports"][0]["output_path"])
        problems = compiler.compare_trees(tmp_root / "a" / out_rel, tmp_root / "b" / out_rel)
        assert not problems, problems
        print("PASS deterministic double-build")

        skill = tmp_root / "b" / out_rel / "SKILL.md"
        skill.write_text(skill.read_text(encoding="utf-8") + "\n# manual drift\n", encoding="utf-8")
        problems = compiler.compare_trees(tmp_root / "a" / out_rel, tmp_root / "b" / out_rel)
        assert any("generated file drift: SKILL.md" in p for p in problems), problems
        print("PASS generated-package drift detection")

        manifest = json.loads((tmp_root / "a" / out_rel / "arsenal-manifest.json").read_text(encoding="utf-8"))
        cap = exports[0]["_cap_record"]["capability"]
        assert manifest["capability"]["id"] == cap["id"]
        assert manifest["capability"]["version"] == cap["version"]
        assert manifest["capability"]["lifecycle"] == cap["lifecycle"]
        assert manifest["capability"]["evaluation"] == cap["evaluation"]
        assert manifest["authority"] == cap["authority"]
        assert manifest["source"]["primary_asset_id"] == cap["implementation"]["primary_asset"]
        print("PASS proof-carrying manifest fidelity")

    print("ARS-03 compiler negative/determinism suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
