#!/usr/bin/env python3
from __future__ import annotations

import copy
import importlib.util
import json
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts/arsenal_dagger.py"
WORLD_PATH = ROOT / "engineering/development_packs/dagger/worlds/tdd-python-container.json"

spec = importlib.util.spec_from_file_location("arsenal_dagger", MODULE_PATH)
assert spec and spec.loader
arsenal_dagger = importlib.util.module_from_spec(spec)
spec.loader.exec_module(arsenal_dagger)


def expect_contract_error(label: str, mutator) -> None:
    source = json.loads(WORLD_PATH.read_text(encoding="utf-8"))
    mutated = copy.deepcopy(source)
    mutator(mutated)
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "world.json"
        path.write_text(json.dumps(mutated), encoding="utf-8")
        try:
            arsenal_dagger.validate_manifest(path)
        except arsenal_dagger.ContractError:
            print(f"PASS negative world case: {label}")
            return
    raise AssertionError(f"expected ContractError for {label}")


def main() -> int:
    context = arsenal_dagger.validate_manifest(WORLD_PATH)
    print("PASS valid ARS-06 Dagger world manifest")

    digest_a = arsenal_dagger.hash_files(
        context["pack_root"], context["world"]["definition_inputs"]
    )
    digest_b = arsenal_dagger.hash_files(
        context["pack_root"], context["world"]["definition_inputs"]
    )
    assert digest_a == digest_b == context["definition_digest"]
    print("PASS deterministic world-definition digest")

    expect_contract_error(
        "latest container image",
        lambda data: data["world"]["container"].update({"image": "python:latest"}),
    )
    expect_contract_error(
        "wrong substrate",
        lambda data: data["world"].update(
            {"substrate_id": "substrate.local-emulator", "reality_rank": 6}
        ),
    )
    expect_contract_error(
        "unknown capability verification requirement",
        lambda data: data["world"].update(
            {"verification_requirements": ["red_observed", "not_real"]}
        ),
    )
    expect_contract_error(
        "proof gate without explicit container-runtime trait",
        lambda data: data["world"]["reality_budget"].update(
            {"additional_required_traits": []}
        ),
    )
    expect_contract_error(
        "remote authority profile",
        lambda data: data["world"]["reality_budget"].update(
            {"authority_profile": "local-cloud-safe"}
        ),
    )
    expect_contract_error(
        "path traversal",
        lambda data: data["world"].update({"script": "../../escape.dagger"}),
    )

    selected = {
        "verdict": "SELECTED",
        "selected": {
            "id": context["world"]["substrate_id"],
            "reality_rank": context["world"]["reality_rank"],
        },
    }
    arsenal_dagger.validate_selection_report(context, "red_observed", selected)
    print("PASS proof gate accepts exact Reality Budget selection")

    wrong_rank = copy.deepcopy(selected)
    wrong_rank["selected"]["reality_rank"] = 5
    try:
        arsenal_dagger.validate_selection_report(context, "red_observed", wrong_rank)
    except arsenal_dagger.ContractError:
        print("PASS proof gate rejects wrong reality rank")
    else:
        raise AssertionError("proof gate accepted wrong reality rank")

    wrong_substrate = copy.deepcopy(selected)
    wrong_substrate["selected"]["id"] = "substrate.local-process"
    try:
        arsenal_dagger.validate_selection_report(
            context, "red_observed", wrong_substrate
        )
    except arsenal_dagger.ContractError:
        print("PASS proof gate rejects wrong substrate")
    else:
        raise AssertionError("proof gate accepted wrong substrate")

    non_selected = {"verdict": "SUBSTRATE_GAP", "selected": None}
    try:
        arsenal_dagger.validate_selection_report(
            context, "red_observed", non_selected
        )
    except arsenal_dagger.ContractError:
        print("PASS proof gate rejects non-selected verdict")
    else:
        raise AssertionError("proof gate accepted non-selected verdict")

    print("ARS-06 Dagger world contract suite: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
