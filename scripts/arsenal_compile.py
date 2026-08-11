#!/usr/bin/env python3
"""Deterministic Project Arsenal capability compiler and competence lockfile generator."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / "arsenal/compiler/export-plan.json"
LOCK_PATH = ROOT / ".arsenal.lock"
COMPILER_VERSION = "0.1.0"
LOCK_SCHEMA_VERSION = "1.0.0"
SUPPORTED_TARGETS = {"agent-skills"}
# Invocation requirements that each target adapter must demonstrate it preserves.
# Targets whose metadata cannot preserve the boundary must fail closed.
TARGET_INVOCATION_SUPPORT: dict[str, set[str]] = {
    # Agent Skills frontmatter does not currently expose explicit invocation
    # semantics; until the target can preserve the boundary, only
    # invocation != "human" may be exported.
    "agent-skills": {"agent", "composed"},
}
PACKAGE_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
# Per-role target subdirectory inside the generated package.
ROLE_DIR: dict[str, str] = {
    "instructions": "references",
    "reference": "references",
    "template": "templates",
    "script": "scripts",
    "fixture": "fixtures",
    "asset": "assets",
}
# Documented policy: always-loaded instructions content must fit within the
# adapter's body budget. The agent-skills SKILL.md should remain readable
# without an explicit cap, but we record a soft ceiling so the compiler can
# warn (not reject) when content exceeds it. Limits are documented policy,
# not external contract.
INSTRUCTIONS_ALWAYS_LOADED_SOFT_LIMIT_BYTES = 32_768


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def canonical_json(data: Any) -> bytes:
    return (json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + "\n").encode("utf-8")


def safe_relative_path(raw: str, *, field: str) -> Path:
    path = Path(raw)
    if not raw or path.is_absolute() or ".." in path.parts:
        raise AssertionError(f"{field} must be a safe repository-relative path: {raw!r}")
    return path


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_capabilities(root: Path) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for path in sorted((root / "arsenal/capabilities").glob("*.json")):
        doc = load_json(path)
        cap = doc["capability"]
        cap_id = cap["id"]
        if cap_id in result:
            raise AssertionError(f"duplicate capability id: {cap_id}")
        result[cap_id] = {"path": path, "document": doc, "capability": cap}
    return result


def load_assets(root: Path) -> dict[str, dict[str, Any]]:
    files = [root / "arsenal/registry.json"] + sorted((root / "arsenal/registry.d").glob("*.json"))
    assets: dict[str, dict[str, Any]] = {}
    for path in files:
        doc = load_json(path)
        if doc.get("schema_version") != "1.0.0":
            raise AssertionError(f"unsupported registry schema in {path.relative_to(root)}")
        for asset in doc.get("assets", []):
            asset_id = asset["id"]
            if asset_id in assets:
                raise AssertionError(f"duplicate asset id across registry fragments: {asset_id}")
            assets[asset_id] = asset
    return assets


def validate_plan_data(plan: dict[str, Any], root: Path) -> list[dict[str, Any]]:
    if plan.get("schema_version") != "1.0.0":
        raise AssertionError("export plan schema_version must be 1.0.0")
    if plan.get("compiler_version") != COMPILER_VERSION:
        raise AssertionError(
            f"export plan compiler_version must be {COMPILER_VERSION}; got {plan.get('compiler_version')!r}"
        )
    exports = plan.get("exports")
    if not isinstance(exports, list) or not exports:
        raise AssertionError("export plan must contain at least one export")

    capabilities = load_capabilities(root)
    assets = load_assets(root)
    seen: set[tuple[str, str]] = set()
    normalized: list[dict[str, Any]] = []

    for export in exports:
        required = {
            "capability_id",
            "target",
            "adapter_version",
            "package_name",
            "output_path",
            "description",
            "compatibility",
        }
        missing = sorted(required - set(export))
        if missing:
            raise AssertionError(f"export missing required fields: {', '.join(missing)}")

        cap_id = export["capability_id"]
        target = export["target"]
        key = (cap_id, target)
        if key in seen:
            raise AssertionError(f"duplicate capability/target export: {cap_id} -> {target}")
        seen.add(key)

        if cap_id not in capabilities:
            raise AssertionError(f"unknown capability in export plan: {cap_id}")
        if target not in SUPPORTED_TARGETS:
            raise AssertionError(f"unsupported export target: {target}")

        package_name = export["package_name"]
        if not isinstance(package_name, str) or not PACKAGE_RE.fullmatch(package_name):
            raise AssertionError(f"invalid package_name: {package_name!r}")

        output_rel = safe_relative_path(export["output_path"], field="output_path")
        if output_rel.parts[:2] != ("distribution", "agent-skills"):
            raise AssertionError("agent-skills output_path must live under distribution/agent-skills")
        if output_rel.name != package_name:
            raise AssertionError("output_path basename must equal package_name")

        if not isinstance(export["description"], str) or not export["description"]:
            raise AssertionError("description must be non-empty")
        if "Use when" not in export["description"]:
            raise AssertionError("Agent Skills description must include 'Use when' discovery context")
        if len(export["description"]) > 1024:
            raise AssertionError("Agent Skills description exceeds 1024 characters")
        if not isinstance(export["compatibility"], str) or len(export["compatibility"]) > 500:
            raise AssertionError("Agent Skills compatibility must be a string <= 500 characters")

        # Invocation preservation: target adapters that cannot preserve
        # the capability's required invocation boundary must fail closed.
        cap = capabilities[cap_id]["capability"]
        invocation = cap.get("invocation")
        supported = TARGET_INVOCATION_SUPPORT.get(target)
        if supported is None:
            raise AssertionError(f"target {target!r} has no declared invocation support policy")
        if invocation not in supported:
            raise AssertionError(
                f"target {target!r} cannot preserve invocation {invocation!r}; "
                f"supported invocations: {sorted(supported)}"
            )

        # Behavior-neutrality: behavioral discovery must come from canonical data.
        # The export plan may keep target-specific packaging hints but must not
        # duplicate the canonical discovery text.
        discovery = cap.get("discovery") or {}
        canonical_use = " | ".join(
            e.get("text", "").strip()
            for e in discovery.get("use_when", []) or []
            if isinstance(e, dict)
        )
        if canonical_use and canonical_use in export["description"]:
            raise AssertionError(
                "export plan description duplicates canonical discovery.use_when text; "
                "let the compiler derive discovery rather than re-stating it"
            )

        cap = capabilities[cap_id]["capability"]
        primary_asset_id = cap["implementation"]["primary_asset"]
        if primary_asset_id not in assets:
            raise AssertionError(f"capability primary asset is not registered: {primary_asset_id}")
        source_rel = safe_relative_path(assets[primary_asset_id]["path"], field="primary asset path")
        source_path = root / source_rel
        if not source_path.is_file():
            raise AssertionError(f"registered primary asset does not exist: {source_rel}")

        normalized.append(
            {
                **export,
                "_cap_record": capabilities[cap_id],
                "_asset": assets[primary_asset_id],
                "_all_assets": assets,
                "_source_path": source_path,
                "_output_rel": output_rel,
            }
        )

    return normalized


def yaml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def render_agent_skill(
    export: dict[str, Any],
    source_rel: Path,
    bundled: dict[str, bytes],
    embedded_instructions: list[tuple[str, bytes]],
    resource_map: dict[str, dict[str, str]],
) -> str:
    """Render the generated SKILL.md body.

    The resource_map is an explicit asset_id -> {path, role, load} mapping
    built by build_agent_skill so the renderer never has to guess or
    reverse-lookup. Every declared resource must appear in the map.
    """
    cap = export["_cap_record"]["capability"]
    package = export["package_name"]
    source_asset_id = cap["implementation"]["primary_asset"]
    required = ", ".join(f"`{x}`" for x in cap["authority"]["required"]) or "none"
    optional = ", ".join(f"`{x}`" for x in cap["authority"]["optional"]) or "none"
    forbidden = ", ".join(f"`{x}`" for x in cap["authority"]["forbidden"]) or "none"
    allowed = ", ".join(f"`{x}`" for x in cap["execution"]["allowed"]) or "none"
    prohibited = ", ".join(f"`{x}`" for x in cap["execution"]["prohibited"]) or "none"

    output_lines = "\n".join(
        f"- `{item['name']}` — {item['description']}" for item in cap["outputs"]
    )

    # Discovery is canonical truth; render it deterministically here so the
    # generated body does not need to receive it via the export plan.
    discovery = cap.get("discovery") or {}
    use_when = discovery.get("use_when") or []
    do_not_use_when = discovery.get("do_not_use_when") or []
    use_lines = "\n".join(f"- {entry['text']}" for entry in use_when if isinstance(entry, dict))
    do_not_use_lines = "\n".join(f"- {entry['text']}" for entry in do_not_use_when if isinstance(entry, dict))
    discovery_block = (
        f"## When to use\n\n{use_lines}\n"
        if use_lines else ""
    )
    if do_not_use_lines:
        discovery_block += f"\n## Do not use when\n\n{do_not_use_lines}\n"

    invocation = cap.get("invocation", "agent")

    # Build the bundled-resources section deterministically from the
    # explicit resource_map. The primary asset gets a stable "Primary
    # reference" anchor; every other declared resource is listed in
    # sorted asset_id order with its explicit packaging path.
    cap_resources = cap.get("implementation", {}).get("resources") or []
    primary_id = cap["implementation"]["primary_asset"]
    resource_lines_parts: list[str] = []
    seen_paths: set[str] = set()
    if primary_id in resource_map:
        primary_rel = resource_map[primary_id]["path"]
        resource_lines_parts.append(f"- Primary reference: [`{primary_rel}`]({primary_rel})")
        seen_paths.add(primary_rel)
    for entry in sorted(cap_resources, key=lambda e: e["asset_id"]):
        asset_id = entry["asset_id"]
        if asset_id == primary_id:
            continue
        info = resource_map.get(asset_id)
        if not info:
            raise AssertionError(
                f"declared resource {asset_id!r} is not present in the explicit resource map"
            )
        target_rel = info["path"]
        role = info["role"]
        load = info["load"]
        if target_rel in seen_paths:
            raise AssertionError(
                f"resource {asset_id!r} packaged to {target_rel!r} collides with another declared resource"
            )
        resource_lines_parts.append(
            f"- `{asset_id}` ({role}/{load}): [`{target_rel}`]({target_rel})"
        )
        seen_paths.add(target_rel)
    resource_lines = "\n".join(resource_lines_parts) if resource_lines_parts else "_(none)_"

    # Always-loaded instructions content is appended to the body so the
    # entrypoint can carry small activation content without forcing a
    # separate read.
    instructions_section = ""
    if embedded_instructions:
        chunks: list[str] = []
        for asset_id, content in embedded_instructions:
            decoded = content.decode("utf-8", errors="replace").rstrip()
            chunks.append(f"### Always-loaded instructions: `{asset_id}`\n\n{decoded}\n")
        instructions_section = "\n## Always-loaded instructions\n\n" + "\n".join(chunks)

    invocation_note = {
        "human": (
            "Invocation boundary: this capability is `human`-invoked. "
            "The harness should not expose autonomous model invocation "
            "when the adapter cannot preserve that boundary."
        ),
        "agent": (
            "Invocation boundary: this capability is `agent`-invoked and may be exposed to autonomous model invocation."
        ),
        "composed": (
            "Invocation boundary: this capability is `composed`. It is meaningful only as part of a composed sequence and should not be exposed as a standalone autonomous invocation."
        ),
    }.get(invocation, "")

    return f"""---
name: {package}
description: {yaml_string(export["description"])}
compatibility: {yaml_string(export["compatibility"])}
metadata:
  arsenal-capability: {yaml_string(cap["id"])}
  arsenal-version: {yaml_string(cap["version"])}
  arsenal-source-asset: {yaml_string(source_asset_id)}
  arsenal-source: {yaml_string(source_rel.as_posix())}
  arsenal-distribution: "agent-skills"
  arsenal-generated: "true"
  arsenal-lifecycle: {yaml_string(cap["lifecycle"])}
  arsenal-evaluation: {yaml_string(cap["evaluation"]["status"])}
  arsenal-invocation: {yaml_string(invocation)}
---

# {cap["display_name"]}

{cap["purpose"]}

{discovery_block}
## Canonical behavior

Read the bundled reference(s) listed below in full and execute them as the authoritative workflow for this capability.

This `SKILL.md` is a generated discovery and packaging adapter. It does not replace the canonical Arsenal workflow. If generated adapter text and any bundled reference ever disagree, the bundled reference controls.

Do not hand-edit this package. Regenerate it with `python3 scripts/arsenal_compile.py build`.

## Bundled resources

The following files are bundled with this package and are loaded on demand by the runtime. Always-loaded instructions content (if any) is embedded directly in this body; everything else is read on demand.

{resource_lines}

{instructions_section}
## Capability contract

- Capability: `{cap["id"]}`
- Version: `{cap["version"]}`
- Lifecycle: `{cap["lifecycle"]}`
- Evaluation: `{cap["evaluation"]["status"]}`
- Primary asset: `{source_asset_id}`
- Mutation class: `{cap["mutation"]["class"]}`

## Authority boundary

- Required authority: {required}
- Optional authority: {optional}
- Forbidden authority: {forbidden}
- Allowed execution surfaces: {allowed}
- Prohibited execution surfaces: {prohibited}

Compilation never grants authority beyond this contract. Runtime execution must continue to honor the canonical capability and workflow boundaries.

{invocation_note}

## Expected outputs

{output_lines}

## Provenance

See [`arsenal-manifest.json`](arsenal-manifest.json) for exact source digests, qualification state, authority, and compiler/export provenance.
"""


def digest_file_map(files: dict[str, bytes]) -> str:
    rows = [{"path": path, "sha256": sha256_bytes(files[path])} for path in sorted(files)]
    return sha256_bytes(canonical_json(rows))


def derive_resources(cap: dict[str, Any]) -> list[dict[str, str]]:
    """Return the canonical list of resources for a capability.

    When the capability declares ``implementation.resources`` the declared
    list is authoritative. When absent, derive a single reference/on-demand
    resource from the primary asset for backward compatibility.
    """
    declared = cap.get("implementation", {}).get("resources")
    if declared:
        return list(declared)
    primary = cap["implementation"]["primary_asset"]
    return [{"asset_id": primary, "role": "reference", "load": "on-demand"}]


def resource_target_path(role: str, source_rel: Path) -> Path:
    base_dir = ROLE_DIR.get(role, "references")
    safe_name = source_rel.name
    return Path(base_dir) / safe_name


def build_agent_skill(export: dict[str, Any], root: Path) -> tuple[dict[str, bytes], dict[str, Any]]:
    cap_record = export["_cap_record"]
    cap = cap_record["capability"]
    source_path: Path = export["_source_path"]
    source_rel = source_path.relative_to(root)

    resources = derive_resources(cap)
    primary_asset_id = cap["implementation"]["primary_asset"]
    assets = export["_all_assets"]

    bundled: dict[str, bytes] = {}
    embedded_instructions: list[tuple[str, bytes]] = []
    declared_paths: set[tuple[str, str]] = set()  # (asset_id, target_str)
    target_to_assets: dict[str, list[str]] = {}
    resource_map: dict[str, dict[str, str]] = {}

    for entry in resources:
        asset_id = entry["asset_id"]
        role = entry["role"]
        load = entry["load"]
        if asset_id not in assets:
            raise AssertionError(
                f"resource asset {asset_id!r} is not registered in the asset registry"
            )
        asset_path = safe_relative_path(assets[asset_id]["path"], field="resource path")
        abs_path = root / asset_path
        if not abs_path.is_file():
            raise AssertionError(
                f"resource asset {asset_id!r} path {asset_path.as_posix()} does not exist"
            )
        target_rel = resource_target_path(role, asset_path)
        target_str = target_rel.as_posix()
        # Track which assets map to which packaging paths. Two assets with
        # the same role and source basename would collide; surface that
        # explicitly instead of silently overwriting one.
        target_to_assets.setdefault(target_str, []).append(asset_id)
        if len(target_to_assets[target_str]) > 1:
            existing = ", ".join(target_to_assets[target_str])
            raise AssertionError(
                f"packaging path collision at {target_str!r}: assets {existing} share the "
                f"role=reference basename; rename the underlying files or assign distinct roles"
            )
        declared_paths.add((asset_id, target_str))
        content = abs_path.read_bytes()
        bundled[target_str] = content
        if asset_id in resource_map:
            raise AssertionError(
                f"asset_id {asset_id!r} declared as a resource multiple times"
            )
        resource_map[asset_id] = {"path": target_str, "role": role, "load": load}
        if role == "instructions" and load == "always":
            embedded_instructions.append((asset_id, content))

    # Always-loaded instructions content must respect documented size policy.
    total_always = sum(len(c) for _, c in embedded_instructions)
    if total_always > INSTRUCTIONS_ALWAYS_LOADED_SOFT_LIMIT_BYTES:
        raise AssertionError(
            f"always-loaded instructions content exceeds documented soft limit "
            f"({total_always} > {INSTRUCTIONS_ALWAYS_LOADED_SOFT_LIMIT_BYTES} bytes); "
            f"promote to role=reference or split the resource"
        )

    # Per-resource always-loaded policy: each individual always-loaded
    # resource must fit the documented soft limit. Aggregate is checked
    # above; per-resource protects against one giant instructions asset
    # silently inflating the entrypoint body.
    for asset_id, content in embedded_instructions:
        if len(content) > INSTRUCTIONS_ALWAYS_LOADED_SOFT_LIMIT_BYTES:
            raise AssertionError(
                f"always-loaded resource {asset_id!r} exceeds documented soft limit "
                f"({len(content)} > {INSTRUCTIONS_ALWAYS_LOADED_SOFT_LIMIT_BYTES} bytes); "
                f"promote to role=reference or split the resource"
            )

    # Record per-resource digests in the manifest so qualification can
    # measure actual packaged bytes rather than trust metadata.
    resource_digests = [
        {"asset_id": asset_id, "path": info["path"], "sha256": sha256_bytes(bundled[info["path"]])}
        for asset_id, info in sorted(resource_map.items())
    ]

    generated: dict[str, bytes] = {
        "SKILL.md": render_agent_skill(export, source_rel, bundled, embedded_instructions, resource_map).encode("utf-8"),
    }
    generated.update(bundled)

    content_digest = digest_file_map(generated)

    # Compute per-resource always-loaded totals from packaged bytes.
    always_loaded_bytes_per_resource = {
        asset_id: len(content) for asset_id, content in embedded_instructions
    }
    always_loaded_bytes_total = sum(always_loaded_bytes_per_resource.values())

    manifest = {
        "schema_version": "1.0.0",
        "compiler": {
            "version": COMPILER_VERSION,
            "target": export["target"],
            "adapter_version": export["adapter_version"],
        },
        "capability": {
            "id": cap["id"],
            "version": cap["version"],
            "display_name": cap["display_name"],
            "lifecycle": cap["lifecycle"],
            "evaluation": cap["evaluation"],
        },
        "authority": cap["authority"],
        "mutation": cap["mutation"],
        "execution": cap["execution"],
        "invocation": cap["invocation"],
        "resources": resources,
        "resource_digests": resource_digests,
        "always_loaded_policy": {
            "soft_limit_bytes": INSTRUCTIONS_ALWAYS_LOADED_SOFT_LIMIT_BYTES,
            "per_resource_bytes": always_loaded_bytes_per_resource,
            "total_bytes": always_loaded_bytes_total,
        },
        "source": {
            "capability_path": cap_record["path"].relative_to(root).as_posix(),
            "capability_sha256": sha256_bytes(cap_record["path"].read_bytes()),
            "primary_asset_id": primary_asset_id,
            "primary_asset_path": source_rel.as_posix(),
            "primary_asset_sha256": sha256_bytes(source_path.read_bytes()),
        },
        # Adapter qualification is a separate evidence claim from capability
        # lifecycle. The compiler owns this stub (status=unassessed) and
        # records only the identifier of the suite that should be used to
        # evaluate it. Truth lives in the receipt produced by
        # scripts/arsenal_bench.py qualify.
        "distribution_qualification": {
            "status": "unassessed",
            "target": export["target"],
            "adapter_version": export["adapter_version"],
            "suite_id": derive_default_suite_id(cap["id"]),
            "evidence_paths": [],
        },
        "package": {
            "name": export["package_name"],
            "content_sha256": content_digest,
            "files": [
                {"path": path, "sha256": sha256_bytes(generated[path])}
                for path in sorted(generated)
            ],
        },
    }
    generated["arsenal-manifest.json"] = canonical_json(manifest)
    return generated, manifest


def derive_default_suite_id(capability_id: str) -> str:
    """Deterministic mapping from capability_id to default qualification suite.

    The compiler only records the suite identifier it expects the bench to
    evaluate against; actual qualification truth is owned by receipts.
    """
    return f"suite.distribution-qualification-{capability_id.removeprefix('capability.')}-v0"


def build_outputs(root: Path, output_root: Path, plan_path: Path) -> tuple[dict[str, Any], list[Path]]:
    plan = load_json(plan_path)
    exports = validate_plan_data(plan, root)
    lock_caps: dict[str, dict[str, Any]] = {}
    written: list[Path] = []

    for export in exports:
        if export["target"] != "agent-skills":
            raise AssertionError(f"target not implemented: {export['target']}")
        files, manifest = build_agent_skill(export, root)
        out_dir = output_root / export["_output_rel"]
        if out_dir.exists():
            shutil.rmtree(out_dir)
        for rel, data in files.items():
            path = out_dir / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            written.append(path)

        cap_record = export["_cap_record"]
        cap = cap_record["capability"]
        source_path: Path = export["_source_path"]
        source_rel = source_path.relative_to(root)
        package_digest = digest_file_map(files)

        locked = lock_caps.setdefault(
            cap["id"],
            {
                "id": cap["id"],
                "version": cap["version"],
                "lifecycle": cap["lifecycle"],
                "evaluation": cap["evaluation"],
                "capability_path": cap_record["path"].relative_to(root).as_posix(),
                "capability_sha256": sha256_bytes(cap_record["path"].read_bytes()),
                "primary_asset": {
                    "id": cap["implementation"]["primary_asset"],
                    "path": source_rel.as_posix(),
                    "sha256": sha256_bytes(source_path.read_bytes()),
                },
                "exports": [],
            },
        )
        locked["exports"].append(
            {
                "target": export["target"],
                "adapter_version": export["adapter_version"],
                "package_name": export["package_name"],
                "path": export["_output_rel"].as_posix(),
                "manifest_path": (export["_output_rel"] / "arsenal-manifest.json").as_posix(),
                "package_sha256": package_digest,
            }
        )

    for item in lock_caps.values():
        item["exports"].sort(key=lambda x: (x["target"], x["package_name"]))

    lock = {
        "schema_version": LOCK_SCHEMA_VERSION,
        "compiler_version": COMPILER_VERSION,
        "plan_sha256": sha256_bytes(plan_path.read_bytes()),
        "capabilities": [lock_caps[key] for key in sorted(lock_caps)],
    }
    return lock, written


def write_build(root: Path, plan_path: Path) -> None:
    lock, written = build_outputs(root, root, plan_path)
    LOCK_PATH.write_bytes(canonical_json(lock))
    print(f"Arsenal compiler build: PASS ({len(lock['capabilities'])} capabilities; {len(written)} generated files)")
    print(f"lockfile: {LOCK_PATH.relative_to(root)}")


def compare_trees(expected: Path, actual: Path) -> list[str]:
    def collect(base: Path) -> dict[str, bytes]:
        if not base.exists():
            return {}
        return {
            p.relative_to(base).as_posix(): p.read_bytes()
            for p in sorted(base.rglob("*"))
            if p.is_file()
        }

    left = collect(expected)
    right = collect(actual)
    problems: list[str] = []
    for path in sorted(set(left) | set(right)):
        if path not in left:
            problems.append(f"unexpected generated file: {path}")
        elif path not in right:
            problems.append(f"missing generated file: {path}")
        elif left[path] != right[path]:
            problems.append(f"generated file drift: {path}")
    return problems


def verify_build(root: Path, plan_path: Path) -> None:
    plan = load_json(plan_path)
    exports = validate_plan_data(plan, root)
    with tempfile.TemporaryDirectory(prefix="arsenal-compile-") as tmp:
        tmp_root = Path(tmp)
        lock, _ = build_outputs(root, tmp_root, plan_path)
        problems: list[str] = []

        for export in exports:
            expected = tmp_root / export["_output_rel"]
            actual = root / export["_output_rel"]
            for issue in compare_trees(expected, actual):
                problems.append(f"{export['capability_id']} -> {export['target']}: {issue}")

        if not LOCK_PATH.is_file():
            problems.append("missing .arsenal.lock")
        elif LOCK_PATH.read_bytes() != canonical_json(lock):
            problems.append(".arsenal.lock drifted from canonical compiler inputs")

        if problems:
            raise AssertionError("\n".join(problems))

    # Cross-check: any checked-in qualification receipt must bind to the
    # exact distribution the compiler currently produces. A drift in
    # capability fragment, manifest, or package content invalidates the
    # receipt and `verify` must fail.
    qualification_problems = _verify_qualification_bindings(root, exports)
    if qualification_problems:
        raise AssertionError("qualification binding drift:\n" + "\n".join(qualification_problems))


def _verify_qualification_bindings(root: Path, exports: list[dict]) -> list[str]:
    """Check every checked-in receipt against current compiler outputs.

    Returns a list of drift problems. Empty list means all receipts
    bind to the exact distribution the compiler currently produces.
    """
    problems: list[str] = []
    qualifications_dir = root / "evaluation" / "qualifications"
    if not qualifications_dir.is_dir():
        return problems
    for receipt_path in sorted(qualifications_dir.glob("*.json")):
        try:
            receipt = load_json(receipt_path)
        except (OSError, json.JSONDecodeError) as exc:
            problems.append(f"{receipt_path.relative_to(root)}: invalid JSON: {exc}")
            continue
        binding = receipt.get("binding")
        if not isinstance(binding, dict):
            problems.append(f"{receipt_path.relative_to(root)}: receipt missing binding block")
            continue
        distribution_path = binding.get("distribution_path")
        if not isinstance(distribution_path, str):
            problems.append(f"{receipt_path.relative_to(root)}: binding.distribution_path missing")
            continue
        dist_path = root / distribution_path
        if not dist_path.is_dir():
            problems.append(
                f"{receipt_path.relative_to(root)}: binding.distribution_path {distribution_path!r} does not exist"
            )
            continue
        manifest_path = dist_path / "arsenal-manifest.json"
        if not manifest_path.is_file():
            problems.append(
                f"{receipt_path.relative_to(root)}: missing arsenal-manifest.json at {distribution_path}"
            )
            continue
        actual_manifest_sha = sha256_bytes(manifest_path.read_bytes())
        if binding.get("manifest_sha256") and binding["manifest_sha256"] != actual_manifest_sha:
            problems.append(
                f"{receipt_path.relative_to(root)}: manifest_sha256 drift; "
                f"expected {binding['manifest_sha256']}, got {actual_manifest_sha}"
            )
        try:
            manifest = load_json(manifest_path)
        except (OSError, json.JSONDecodeError) as exc:
            problems.append(f"{receipt_path.relative_to(root)}: invalid manifest JSON: {exc}")
            continue
        actual_package_sha = manifest.get("package", {}).get("content_sha256")
        if binding.get("package_content_sha256") and binding["package_content_sha256"] != actual_package_sha:
            problems.append(
                f"{receipt_path.relative_to(root)}: package_content_sha256 drift; "
                f"expected {binding['package_content_sha256']}, got {actual_package_sha}"
            )
        cap_rel = manifest.get("source", {}).get("capability_path")
        if isinstance(cap_rel, str):
            cap_path = root / cap_rel
            if cap_path.is_file():
                actual_cap_sha = sha256_bytes(cap_path.read_bytes())
                if binding.get("capability_sha256") and binding["capability_sha256"] != actual_cap_sha:
                    problems.append(
                        f"{receipt_path.relative_to(root)}: capability_sha256 drift; "
                        f"expected {binding['capability_sha256']}, got {actual_cap_sha}"
                    )
    return problems

    print(f"Arsenal compiler verification: PASS ({len(exports)} exports)")
    for export in exports:
        print(f"  {export['capability_id']} -> {export['target']} -> {export['_output_rel'].as_posix()}")


def explain(root: Path, plan_path: Path) -> None:
    plan = load_json(plan_path)
    exports = validate_plan_data(plan, root)
    for export in exports:
        cap = export["_cap_record"]["capability"]
        source = export["_source_path"].relative_to(root).as_posix()
        print(f"{cap['id']} {cap['version']}")
        print(f"  lifecycle/evaluation: {cap['lifecycle']} / {cap['evaluation']['status']}")
        print(f"  primary asset: {cap['implementation']['primary_asset']} -> {source}")
        print(f"  export: {export['target']} {export['adapter_version']} -> {export['_output_rel'].as_posix()}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("validate", "build", "verify", "explain"))
    parser.add_argument("--plan", default=str(PLAN_PATH), help="export plan path")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    plan_path = Path(args.plan)
    if not plan_path.is_absolute():
        plan_path = (ROOT / plan_path).resolve()
    if args.command == "validate":
        exports = validate_plan_data(load_json(plan_path), ROOT)
        print(f"Arsenal compiler contract: PASS ({len(exports)} exports; targets={','.join(sorted(SUPPORTED_TARGETS))})")
    elif args.command == "build":
        write_build(ROOT, plan_path)
    elif args.command == "verify":
        verify_build(ROOT, plan_path)
    else:
        explain(ROOT, plan_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
