#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import platform
import subprocess
import sys
from pathlib import Path

PACK = Path("/pack")
FIXTURE = PACK / "fixtures" / "tdd-red-green"


def file_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tree_digest(root: Path, inputs: list[str]) -> str:
    files: list[Path] = []
    for item in inputs:
        path = root / item
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
            raise SystemExit(f"definition input does not exist: {item}")

    digest = hashlib.sha256()
    for path in sorted(set(files), key=lambda p: p.relative_to(root).as_posix()):
        relative = path.relative_to(root).as_posix()
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(file_digest(path).encode("ascii"))
        digest.update(b"\n")
    return digest.hexdigest()


def run_case(name: str) -> tuple[int, str]:
    result = subprocess.run(
        [sys.executable, "-m", "unittest", "-v"],
        cwd=FIXTURE / name,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return result.returncode, result.stdout


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: run_world.py /pack/worlds/<manifest>.json")

    manifest_path = Path(sys.argv[1])
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    world = manifest["world"]

    red_rc, red_output = run_case("red")
    green_rc, green_output = run_case("green")

    red_observed = red_rc != 0 and "test_add" in red_output and "FAILED" in red_output
    green_observed = green_rc == 0 and "test_add" in green_output and "OK" in green_output

    if not red_observed:
        print(red_output, file=sys.stderr)
        raise SystemExit("red phase did not fail for the intended test")
    if not green_observed:
        print(green_output, file=sys.stderr)
        raise SystemExit("green phase did not pass the same intended test")

    fixture_digest = tree_digest(PACK, ["fixtures/tdd-red-green"])
    definition_digest = tree_digest(PACK, world["definition_inputs"])

    receipt = {
        "schema_version": "1.0.0",
        "receipt_kind": "dagger-world-evidence",
        "world": {
            "id": world["id"],
            "version": world["version"],
            "definition_digest": definition_digest,
        },
        "adapter": {
            "id": "dagger",
            "expected_version": world["dagger_version"],
        },
        "substrate": {
            "id": world["substrate_id"],
            "reality_rank": world["reality_rank"],
        },
        "capability": {
            "id": world["capability_id"],
            "version": world["capability_version"],
            "verification_requirements": world["verification_requirements"],
        },
        "container": {
            "image": world["container"]["image"],
            "python_version": platform.python_version(),
        },
        "fixture_digest": fixture_digest,
        "execution": {
            "network": world["network"],
            "secrets": world["secrets"],
            "host_writes": world["host_writes"],
        },
        "results": {
            "red_observed": red_observed,
            "red_exit_code": red_rc,
            "green_observed": green_observed,
            "green_exit_code": green_rc,
            "test_name": "test_add",
        },
        "limitations": world["limitations"],
    }

    Path("/receipt.json").write_text(
        json.dumps(receipt, sort_keys=True, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
