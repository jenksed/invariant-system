#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

# Shared I/O primitives.
from arsenal_io import load_json

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WORLD = ROOT / "engineering/development_packs/dagger/worlds/tdd-python-container.json"
CAPABILITIES_DIR = ROOT / "arsenal/capabilities"
SUBSTRATE_CATALOG = ROOT / "arsenal/substrates/catalog.json"
SUBSTRATE_SELECTOR = ROOT / "scripts/arsenal_substrate.py"


class ContractError(RuntimeError):
    pass


def safe_repo_path(value: str) -> Path:
    pure = PurePosixPath(value)
    if pure.is_absolute() or ".." in pure.parts:
        raise ContractError(f"unsafe repository-relative path: {value}")
    resolved = (ROOT / Path(*pure.parts)).resolve()
    root = ROOT.resolve()
    if resolved != root and root not in resolved.parents:
        raise ContractError(f"path escapes repository: {value}")
    return resolved


def find_capability(capability_id: str) -> tuple[Path, dict[str, Any]]:
    for path in sorted(CAPABILITIES_DIR.glob("*.json")):
        data = load_json(path)
        capability = data.get("capability", {})
        if capability.get("id") == capability_id:
            return path, capability
    raise ContractError(f"unknown capability: {capability_id}")


def find_substrate(substrate_id: str) -> dict[str, Any]:
    catalog = load_json(SUBSTRATE_CATALOG)
    for substrate in catalog.get("substrates", []):
        if substrate.get("id") == substrate_id:
            return substrate
    raise ContractError(f"unknown substrate: {substrate_id}")


def hash_files(root: Path, inputs: list[str]) -> str:
    files: list[Path] = []
    for item in inputs:
        pure = PurePosixPath(item)
        if pure.is_absolute() or ".." in pure.parts:
            raise ContractError(f"unsafe definition input: {item}")
        path = root / Path(*pure.parts)
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            files.extend(
                candidate
                for candidate in path.rglob("*")
                if candidate.is_file()
                and "__pycache__" not in candidate.parts
                and candidate.suffix != ".pyc"
            )
        else:
            raise ContractError(f"definition input does not exist: {item}")

    digest = hashlib.sha256()
    for path in sorted(set(files), key=lambda p: p.relative_to(root).as_posix()):
        relative = path.relative_to(root).as_posix()
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).hexdigest().encode("ascii"))
        digest.update(b"\n")
    return digest.hexdigest()


def validate_manifest(path: Path) -> dict[str, Any]:
    data = load_json(path)
    if data.get("schema_version") != "1.0.0":
        raise ContractError("world manifest schema_version must be 1.0.0")
    world = data.get("world")
    if not isinstance(world, dict):
        raise ContractError("world manifest must contain object field 'world'")

    required = {
        "id", "version", "adapter", "dagger_version", "pack_root", "script",
        "definition_inputs", "substrate_id", "reality_rank", "capability_id",
        "capability_version", "verification_requirements", "reality_budget",
        "container", "raw_receipt_path", "receipt_path", "network", "secrets",
        "host_writes", "limitations",
    }
    missing = sorted(required - set(world))
    if missing:
        raise ContractError(f"world manifest missing fields: {', '.join(missing)}")

    if not re.fullmatch(r"world\.[a-z][a-z0-9.-]*", world["id"]):
        raise ContractError("invalid world id")
    if not re.fullmatch(r"\d+\.\d+\.\d+", world["version"]):
        raise ContractError("invalid world version")
    if world["adapter"] != "dagger":
        raise ContractError("ARS-06 v0 supports only the Dagger adapter")
    if not re.fullmatch(r"\d+\.\d+\.\d+", world["dagger_version"]):
        raise ContractError("dagger_version must be pinned semantic version")

    pack_root = safe_repo_path(world["pack_root"])
    if not pack_root.is_dir():
        raise ContractError("Dagger pack root does not exist")

    script = pack_root / world["script"]
    if not script.is_file():
        raise ContractError("Dagger world script does not exist")

    image = world.get("container", {}).get("image")
    if not isinstance(image, str) or not image or image.endswith(":latest") or image == "latest":
        raise ContractError("container image must use a non-latest pinned tag")
    if world.get("network") != "none-required":
        raise ContractError("ARS-06 tracer world must not require network access")
    if world.get("secrets") != "none":
        raise ContractError("ARS-06 tracer world must not require secrets")

    capability_path, capability = find_capability(world["capability_id"])
    if capability["version"] != world["capability_version"]:
        raise ContractError("world capability version does not match canonical capability")

    requirement_ids = {item["id"] for item in capability["verification"]["requirements"]}
    requested = world["verification_requirements"]
    if not isinstance(requested, list) or not requested:
        raise ContractError("verification_requirements must be a non-empty list")
    unknown_requirements = sorted(set(requested) - requirement_ids)
    if unknown_requirements:
        raise ContractError(
            "world references unknown canonical verification requirements: "
            + ", ".join(unknown_requirements)
        )

    substrate = find_substrate(world["substrate_id"])
    if substrate["reality_rank"] != world["reality_rank"]:
        raise ContractError("world reality rank does not match substrate catalog")
    if substrate["execution_surface"] != "local-container":
        raise ContractError("ARS-06 tracer must target the local-container execution surface")
    if substrate["selection_mode"] != "automatic":
        raise ContractError("ARS-06 tracer substrate must be automatically selectable")
    if "container-runtime" not in substrate["traits"]:
        raise ContractError("selected substrate does not advertise container-runtime proof")

    budget = world["reality_budget"]
    if budget.get("authority_profile") != "workspace-safe":
        raise ContractError("ARS-06 tracer must reuse workspace-safe authority")
    if budget.get("availability_profile") != "container-local":
        raise ContractError("ARS-06 tracer must use container-local availability")
    traits = budget.get("additional_required_traits")
    if traits != ["container-runtime"]:
        raise ContractError(
            "ARS-06 tracer must explicitly request only container-runtime as its stricter caller proof trait"
        )

    allowed = set(capability["execution"]["allowed"])
    prohibited = set(capability["execution"]["prohibited"])
    if "local-container" not in allowed or "local-container" in prohibited:
        raise ContractError("canonical capability does not permit local-container execution")

    raw_receipt = safe_repo_path(world["raw_receipt_path"])
    receipt = safe_repo_path(world["receipt_path"])
    if raw_receipt == receipt:
        raise ContractError("raw and composed receipt paths must differ")
    if world["host_writes"] != [world["raw_receipt_path"], world["receipt_path"]]:
        raise ContractError("host_writes must be exactly the two declared receipt paths")

    definition_inputs = world["definition_inputs"]
    if not isinstance(definition_inputs, list) or len(definition_inputs) < 3:
        raise ContractError("definition_inputs must declare the manifest, Dagger script, and fixture tree")
    definition_digest = hash_files(pack_root, definition_inputs)

    script_text = script.read_text(encoding="utf-8")
    required_script_fragments = [
        "#!/usr/bin/env dagger",
        f"from {image}",
        f"with-directory /pack ./{world['pack_root']}",
        "with-exec python run_world.py /pack/worlds/tdd-python-container.json",
        f"export {world['raw_receipt_path']}",
    ]
    missing_fragments = [fragment for fragment in required_script_fragments if fragment not in script_text]
    if missing_fragments:
        raise ContractError(
            "Dagger script does not match manifest boundary: "
            + "; ".join(missing_fragments)
        )

    return {
        "manifest_path": path.relative_to(ROOT).as_posix(),
        "manifest": data,
        "world": world,
        "capability_path": capability_path.relative_to(ROOT).as_posix(),
        "capability": capability,
        "substrate": substrate,
        "pack_root": pack_root,
        "script_path": script,
        "raw_receipt_path": raw_receipt,
        "receipt_path": receipt,
        "definition_digest": definition_digest,
    }


def dagger_version() -> str:
    try:
        proc = subprocess.run(
            ["dagger", "version"],
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
    except FileNotFoundError as exc:
        raise ContractError("dagger CLI is not installed or not on PATH") from exc
    if proc.returncode != 0:
        raise ContractError(f"dagger version failed: {proc.stdout.strip()}")
    match = re.search(r"\bv?(\d+\.\d+\.\d+)\b", proc.stdout)
    if not match:
        raise ContractError(f"could not parse dagger version: {proc.stdout.strip()}")
    return match.group(1)


def reality_budget_reports(context: dict[str, Any]) -> list[dict[str, Any]]:
    world = context["world"]
    reports: list[dict[str, Any]] = []
    for requirement in world["verification_requirements"]:
        command = [
            sys.executable,
            str(SUBSTRATE_SELECTOR),
            "select",
            "--capability", world["capability_id"],
            "--requirement", requirement,
            "--authority-profile", world["reality_budget"]["authority_profile"],
            "--availability-profile", world["reality_budget"]["availability_profile"],
            "--json",
        ]
        for trait in world["reality_budget"]["additional_required_traits"]:
            command.extend(["--require-trait", trait])
        proc = subprocess.run(
            command,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if proc.returncode != 0:
            raise ContractError(
                f"Reality Budget refused {requirement}: rc={proc.returncode}\n"
                f"{proc.stdout}{proc.stderr}"
            )
        try:
            report = json.loads(proc.stdout)
        except json.JSONDecodeError as exc:
            raise ContractError(f"Reality Budget did not emit valid JSON for {requirement}") from exc
        validate_selection_report(context, requirement, report)
        reports.append(report)
    return reports


def validate_selection_report(
    context: dict[str, Any], requirement: str, report: dict[str, Any]
) -> None:
    world = context["world"]
    if report.get("verdict") != "SELECTED":
        raise ContractError(
            f"proof-gated execution refused: {requirement} verdict is {report.get('verdict')}"
        )
    selected = report.get("selected")
    if not isinstance(selected, dict) or selected.get("id") != world["substrate_id"]:
        raise ContractError(
            f"proof-gated execution refused: {requirement} selected "
            f"{selected.get('id') if isinstance(selected, dict) else None}, "
            f"expected {world['substrate_id']}"
        )
    if selected.get("reality_rank") != world["reality_rank"]:
        raise ContractError("Reality Budget selected unexpected reality rank")


def verify_world_receipt(context: dict[str, Any], receipt: dict[str, Any]) -> None:
    world = context["world"]
    if receipt.get("schema_version") != "1.0.0":
        raise ContractError("world receipt schema version mismatch")
    if receipt.get("receipt_kind") != "dagger-world-evidence":
        raise ContractError("unexpected world receipt kind")
    if receipt.get("world", {}).get("id") != world["id"]:
        raise ContractError("world receipt id mismatch")
    if receipt.get("world", {}).get("version") != world["version"]:
        raise ContractError("world receipt version mismatch")
    if receipt.get("world", {}).get("definition_digest") != context["definition_digest"]:
        raise ContractError("world definition digest does not match checked-in pack")
    if receipt.get("adapter", {}).get("expected_version") != world["dagger_version"]:
        raise ContractError("world receipt Dagger version mismatch")
    if receipt.get("substrate") != {
        "id": world["substrate_id"],
        "reality_rank": world["reality_rank"],
    }:
        raise ContractError("world receipt substrate mismatch")
    if receipt.get("capability", {}).get("id") != world["capability_id"]:
        raise ContractError("world receipt capability mismatch")
    if receipt.get("capability", {}).get("version") != world["capability_version"]:
        raise ContractError("world receipt capability version mismatch")
    if receipt.get("capability", {}).get("verification_requirements") != world["verification_requirements"]:
        raise ContractError("world receipt verification requirements mismatch")
    if receipt.get("container", {}).get("image") != world["container"]["image"]:
        raise ContractError("world receipt container image mismatch")
    if receipt.get("execution") != {
        "network": world["network"],
        "secrets": world["secrets"],
        "host_writes": world["host_writes"],
    }:
        raise ContractError("world receipt execution boundary mismatch")
    results = receipt.get("results", {})
    if results.get("red_observed") is not True or not isinstance(results.get("red_exit_code"), int) or results["red_exit_code"] == 0:
        raise ContractError("world receipt did not prove the red phase")
    if results.get("green_observed") is not True or results.get("green_exit_code") != 0:
        raise ContractError("world receipt did not prove the green phase")
    if results.get("test_name") != "test_add":
        raise ContractError("world receipt does not identify the intended behavioral test")
    if receipt.get("limitations") != world["limitations"]:
        raise ContractError("world receipt limitations drifted from manifest")


def compose_receipt(
    context: dict[str, Any],
    reports: list[dict[str, Any]],
    raw_receipt: dict[str, Any],
    actual_dagger_version: str,
) -> dict[str, Any]:
    world = context["world"]
    return {
        "schema_version": "1.0.0",
        "receipt_kind": "arsenal-executable-world",
        "world": {
            "id": world["id"],
            "version": world["version"],
        },
        "capability": {
            "id": world["capability_id"],
            "version": world["capability_version"],
            "verification_requirements": world["verification_requirements"],
        },
        "proof_gate": {
            "selector": "arsenal/substrates",
            "additional_required_traits": world["reality_budget"]["additional_required_traits"],
            "reports": reports,
        },
        "adapter_runtime": {
            "id": "dagger",
            "version": actual_dagger_version,
        },
        "world_evidence": raw_receipt,
        "evidence_boundary": {
            "claim": (
                "Containerized execution observed the declared TDD red/green verification behavior "
                "inside the selected local-container world."
            ),
            "does_not_claim": world["limitations"],
        },
    }


def verify_composed_receipt(context: dict[str, Any], receipt: dict[str, Any]) -> None:
    world = context["world"]
    if receipt.get("schema_version") != "1.0.0":
        raise ContractError("composed receipt schema version mismatch")
    if receipt.get("receipt_kind") != "arsenal-executable-world":
        raise ContractError("unexpected composed receipt kind")
    if receipt.get("world") != {"id": world["id"], "version": world["version"]}:
        raise ContractError("composed receipt world identity mismatch")
    if receipt.get("adapter_runtime") != {
        "id": "dagger",
        "version": world["dagger_version"],
    }:
        raise ContractError("composed receipt runtime version mismatch")
    proof_gate = receipt.get("proof_gate", {})
    if proof_gate.get("additional_required_traits") != world["reality_budget"]["additional_required_traits"]:
        raise ContractError("composed receipt proof-gate trait mismatch")
    reports = proof_gate.get("reports")
    if not isinstance(reports, list) or len(reports) != len(world["verification_requirements"]):
        raise ContractError("composed receipt proof-gate reports missing")
    for requirement, report in zip(world["verification_requirements"], reports, strict=True):
        validate_selection_report(context, requirement, report)
    raw = receipt.get("world_evidence")
    if not isinstance(raw, dict):
        raise ContractError("composed receipt missing world evidence")
    verify_world_receipt(context, raw)


def command_validate(args: argparse.Namespace) -> int:
    context = validate_manifest(args.world)
    world = context["world"]
    print(
        "Dagger Executable World contract: PASS "
        f"({world['id']}; {world['capability_id']}; "
        f"{world['substrate_id']}@rank{world['reality_rank']})"
    )
    return 0


def command_preflight(args: argparse.Namespace) -> int:
    context = validate_manifest(args.world)
    reports = reality_budget_reports(context)
    for requirement, report in zip(
        context["world"]["verification_requirements"], reports, strict=True
    ):
        selected = report["selected"]
        print(
            f"PASS proof gate: {requirement} -> "
            f"{selected['id']}@rank{selected['reality_rank']}"
        )
    return 0


def command_run(args: argparse.Namespace) -> int:
    context = validate_manifest(args.world)
    expected = context["world"]["dagger_version"]
    actual = dagger_version()
    if actual != expected:
        raise ContractError(f"Dagger version mismatch: expected {expected}, got {actual}")

    reports = reality_budget_reports(context)

    raw_path = context["raw_receipt_path"]
    receipt_path = context["receipt_path"]
    raw_path.parent.mkdir(parents=True, exist_ok=True)
    raw_path.unlink(missing_ok=True)
    receipt_path.unlink(missing_ok=True)

    proc = subprocess.run(
        ["dagger", "--progress=plain", context["script_path"].relative_to(ROOT).as_posix()],
        cwd=ROOT,
        check=False,
    )
    if proc.returncode != 0:
        raise ContractError(f"Dagger world failed with exit code {proc.returncode}")
    if not raw_path.is_file():
        raise ContractError("Dagger world did not export its raw receipt")

    raw_receipt = load_json(raw_path)
    verify_world_receipt(context, raw_receipt)
    receipt = compose_receipt(context, reports, raw_receipt, actual)
    receipt_path.write_text(
        json.dumps(receipt, sort_keys=True, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    verify_composed_receipt(context, receipt)
    print(f"ARS-06 executable world: PASS ({receipt_path.relative_to(ROOT)})")
    return 0


def command_verify(args: argparse.Namespace) -> int:
    context = validate_manifest(args.world)
    receipt_path = args.receipt or context["receipt_path"]
    if not receipt_path.is_absolute():
        receipt_path = ROOT / receipt_path
    receipt = load_json(receipt_path)
    verify_composed_receipt(context, receipt)
    print(f"ARS-06 executable-world receipt: PASS ({receipt_path.relative_to(ROOT)})")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Project Arsenal ARS-06 Dagger world runner")
    parser.add_argument(
        "--world",
        type=Path,
        default=DEFAULT_WORLD,
        help="Path to the Dagger world manifest",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("validate")
    subparsers.add_parser("preflight")
    subparsers.add_parser("run")
    verify = subparsers.add_parser("verify")
    verify.add_argument("--receipt", type=Path)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    if not args.world.is_absolute():
        args.world = (ROOT / args.world).resolve()
    try:
        return {
            "validate": command_validate,
            "preflight": command_preflight,
            "run": command_run,
            "verify": command_verify,
        }[args.command](args)
    except (ContractError, OSError, json.JSONDecodeError) as exc:
        print(f"ARS-06 ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
