#!/usr/bin/env python3
"""Validate the Repository Truth Agent Skills distribution and ARS-03 compiler regression."""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "distribution/agent-skills/repository-truth"
SKILL = PACKAGE / "SKILL.md"
SNAPSHOT = PACKAGE / "references/repository_truth_audit.md"
MANIFEST = PACKAGE / "arsenal-manifest.json"
CANONICAL = ROOT / "agent_workflows/repository_truth_audit.md"
CAPABILITY = ROOT / "arsenal/capabilities/repository-truth.json"
LOCK = ROOT / ".arsenal.lock"
QUICKSTART = ROOT / "docs/use/repository-truth-quickstart.md"

NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        raise AssertionError("SKILL.md must begin with YAML frontmatter")
    marker = text.find("\n---\n", 4)
    if marker == -1:
        raise AssertionError("SKILL.md frontmatter is not terminated")

    raw = text[4:marker]
    body = text[marker + 5 :]
    fields: dict[str, str] = {}
    for line in raw.splitlines():
        if not line or line[0].isspace() or ":" not in line:
            continue
        key, value = line.split(":", 1)
        fields[key.strip()] = value.strip().strip('"')
    return fields, body


def main() -> int:
    for path in (SKILL, SNAPSHOT, MANIFEST, CANONICAL, CAPABILITY, LOCK, QUICKSTART):
        assert path.is_file(), f"missing distribution/compiler file: {path.relative_to(ROOT)}"

    canonical_bytes = CANONICAL.read_bytes()
    snapshot_bytes = SNAPSHOT.read_bytes()
    assert snapshot_bytes == canonical_bytes, (
        "distribution snapshot drifted from canonical Repository Truth; "
        "regenerate with scripts/arsenal_compile.py build"
    )

    text = SKILL.read_text(encoding="utf-8")
    fields, body = parse_frontmatter(text)

    name = fields.get("name", "")
    description = fields.get("description", "")
    compatibility = fields.get("compatibility", "")

    assert name == "repository-truth"
    assert len(name) <= 64 and NAME_RE.fullmatch(name), "invalid Agent Skills name"
    assert description and len(description) <= 1024, "invalid Agent Skills description"
    assert "Use when" in description, "description must include discovery context"
    assert len(compatibility) <= 500, "compatibility field exceeds Agent Skills limit"
    assert len(body.splitlines()) < 500, "SKILL.md body should remain compact"

    required_markers = [
        "references/repository_truth_audit.md",
        "generated discovery and packaging adapter",
        "Do not hand-edit this package",
        "Capability contract",
        "Authority boundary",
        "arsenal-manifest.json",
    ]
    for marker in required_markers:
        assert marker in body, f"SKILL.md missing generated boundary marker: {marker}"

    capability_doc = json.loads(CAPABILITY.read_text(encoding="utf-8"))
    cap = capability_doc["capability"]
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    lock = json.loads(LOCK.read_text(encoding="utf-8"))

    assert manifest["capability"]["id"] == cap["id"]
    assert manifest["capability"]["version"] == cap["version"]
    assert manifest["capability"]["lifecycle"] == cap["lifecycle"]
    assert manifest["capability"]["evaluation"] == cap["evaluation"]
    assert manifest["authority"] == cap["authority"]
    assert manifest["source"]["primary_asset_id"] == cap["implementation"]["primary_asset"]
    assert manifest["source"]["primary_asset_path"] == "agent_workflows/repository_truth_audit.md"

    locked = next(item for item in lock["capabilities"] if item["id"] == cap["id"])
    assert locked["version"] == cap["version"]
    assert locked["lifecycle"] == cap["lifecycle"]
    assert locked["evaluation"] == cap["evaluation"]
    assert locked["primary_asset"]["id"] == cap["implementation"]["primary_asset"]
    assert any(item["target"] == "agent-skills" for item in locked["exports"])

    assert cap["id"] in text
    assert cap["implementation"]["primary_asset"] in text
    assert "agent_workflows/repository_truth_audit.md" in text

    quickstart = QUICKSTART.read_text(encoding="utf-8")
    for marker in (
        "scripts/install-repository-truth-skill --project",
        ".agents/skills/repository-truth",
        "distribution/agent-skills/repository-truth",
        "ARS-03",
        "Codex",
    ):
        assert marker in quickstart, f"quickstart missing required marker: {marker}"

    print("ARS-00B/ARS-03 Repository Truth distribution: PASS")
    print(f"canonical bytes: {len(canonical_bytes)}")
    print(f"skill body lines: {len(body.splitlines())}")
    print(f"capability: {cap['id']} {cap['version']} ({cap['lifecycle']}/{cap['evaluation']['status']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
