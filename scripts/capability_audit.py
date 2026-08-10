#!/usr/bin/env python3
"""Validate Project Arsenal Capability Contract v2 fragments against repository truth."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

CAPABILITY_SCHEMA_VERSION = "2.1.0"
CAPABILITY_SCHEMA_LEGACY = "2.0.0"
ASSET_SCHEMA_VERSION = "1.0.0"

AUTHORITY = {
    "filesystem.read", "filesystem.write", "shell.execute",
    "network.read", "network.write", "git.read", "git.write",
    "tracker.read", "tracker.write", "secrets.read", "cloud.local",
    "cloud.remote", "production.mutate", "human.confirmation",
}
WRITE_AUTHORITY = {
    "filesystem.write", "network.write", "git.write", "tracker.write",
    "cloud.local", "cloud.remote", "production.mutate",
}
SUBSTRATES = {
    "reasoning-only", "repository-read", "local-process", "local-container",
    "local-emulator", "local-cluster", "remote-sandbox",
    "shared-nonproduction", "staging", "production", "user-mediated",
}
MUTATION_CLASSES = {"read-only", "workspace-write", "external-write", "high-consequence"}
LIFECYCLES = {"draft", "testing", "stable", "deprecated"}
INVOCATIONS = {"human", "agent", "composed"}
EVALUATION_STATES = {"unassessed", "planned", "candidate", "qualified"}
EVIDENCE_KINDS = {
    "report", "artifact", "command", "test", "diff", "receipt",
    "decision-record", "runtime-observation", "verdict",
}
HARNESS_MARKERS = (
    "codex", "claude", ".agents/skills", "agent skills",
    "slash command", "slash-command", "plugin packaging",
)
REQUIRED_CAPABILITIES = {
    "capability.repository-truth",
    "capability.pressure-test",
    "capability.recon",
    "capability.diagnose",
    "capability.tdd",
    "capability.review",
    "capability.verify",
    "capability.resume",
    "capability.local-cloud-feature-delivery",
}
CAPABILITY_FIELDS = {
    "id", "version", "display_name", "aliases", "purpose", "lifecycle",
    "invocation", "discovery", "inputs", "outputs", "preconditions",
    "context", "implementation", "authority", "mutation", "execution",
    "verification", "evidence_outputs", "evaluation", "provenance",
    "compatibility",
}


def _json(path: Path):
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


def load_asset_ids(root: Path) -> tuple[set[str], list[str]]:
    errors: list[str] = []
    files = [root / "arsenal" / "registry.json"]
    files.extend(sorted((root / "arsenal" / "registry.d").glob("*.json")))
    ids: set[str] = set()
    for path in files:
        try:
            doc = _json(path)
        except Exception as exc:
            errors.append(f"{path.relative_to(root)}: invalid asset registry JSON: {exc}")
            continue
        if doc.get("schema_version") != ASSET_SCHEMA_VERSION:
            errors.append(f"{path.relative_to(root)}: unsupported asset schema_version")
        for asset in doc.get("assets", []):
            asset_id = asset.get("id")
            if not isinstance(asset_id, str):
                errors.append(f"{path.relative_to(root)}: asset missing string id")
                continue
            if asset_id in ids:
                errors.append(f"{path.relative_to(root)}: duplicate asset id {asset_id}")
            ids.add(asset_id)
    return ids, errors


def load_capability_fragments(root: Path, capability_dir: Path | None = None):
    directory = capability_dir or (root / "arsenal" / "capabilities")
    if not directory.is_absolute():
        directory = root / directory
    errors: list[str] = []
    fragments: list[tuple[Path, dict]] = []
    files = sorted(directory.glob("*.json"))
    if not files:
        return [], [f"{directory}: no capability JSON fragments found"]
    for path in files:
        try:
            doc = _json(path)
        except Exception as exc:
            errors.append(f"{path}: invalid JSON: {exc}")
            continue
        if set(doc) != {"schema_version", "capability"}:
            errors.append(f"{path}: fragment must contain only schema_version and capability")
            continue
        if doc.get("schema_version") not in (CAPABILITY_SCHEMA_VERSION, CAPABILITY_SCHEMA_LEGACY):
            errors.append(f"{path}: unsupported capability schema_version {doc.get('schema_version')!r}")
            continue
        capability = doc.get("capability")
        if not isinstance(capability, dict):
            errors.append(f"{path}: capability must be an object")
            continue
        fragments.append((path, capability))
    return fragments, errors


def _unique_named(cap_id: str, field: str, items, key: str, errors: list[str]):
    if not isinstance(items, list) or not items:
        errors.append(f"{cap_id}: {field} must be a non-empty array")
        return
    seen: set[str] = set()
    for item in items:
        if not isinstance(item, dict) or not isinstance(item.get(key), str):
            errors.append(f"{cap_id}: {field} entries require string {key}")
            continue
        value = item[key]
        if value in seen:
            errors.append(f"{cap_id}: duplicate {field} {key} {value}")
        seen.add(value)


def validate_capability(cap: dict, asset_ids: set[str], errors: list[str]) -> None:
    cap_id = cap.get("id", "<missing-id>")
    missing = CAPABILITY_FIELDS - set(cap)
    extra = set(cap) - CAPABILITY_FIELDS
    if missing:
        errors.append(f"{cap_id}: missing fields {sorted(missing)}")
    if extra:
        errors.append(f"{cap_id}: unknown fields {sorted(extra)}")
    if missing:
        return

    if not isinstance(cap_id, str) or not re.fullmatch(r"capability\.[a-z][a-z0-9.-]*", cap_id):
        errors.append(f"{cap_id}: invalid capability id")
    if not isinstance(cap.get("version"), str) or not re.fullmatch(r"\d+\.\d+\.\d+", cap["version"]):
        errors.append(f"{cap_id}: version must be semantic x.y.z")
    if cap.get("lifecycle") not in LIFECYCLES:
        errors.append(f"{cap_id}: invalid lifecycle {cap.get('lifecycle')!r}")
    if cap.get("invocation") not in INVOCATIONS:
        errors.append(f"{cap_id}: invalid invocation {cap.get('invocation')!r}")
    if not isinstance(cap.get("display_name"), str) or len(cap["display_name"].strip()) < 2:
        errors.append(f"{cap_id}: display_name is required")
    if not isinstance(cap.get("aliases"), list) or any(not isinstance(x, str) for x in cap["aliases"]):
        errors.append(f"{cap_id}: aliases must be an array of strings")

    discovery = cap.get("discovery")
    if not isinstance(discovery, dict):
        errors.append(f"{cap_id}: discovery must be an object")
    else:
        use_when = discovery.get("use_when")
        if not isinstance(use_when, list) or not use_when:
            errors.append(f"{cap_id}: discovery.use_when must be a non-empty array")
        else:
            seen_texts: set[str] = set()
            for entry in use_when:
                if not isinstance(entry, dict):
                    errors.append(f"{cap_id}: discovery.use_when entries must be objects")
                    continue
                text = entry.get("text")
                kind = entry.get("kind", "positive")
                if not isinstance(text, str) or len(text.strip()) < 8:
                    errors.append(f"{cap_id}: discovery.use_when entries require text >= 8 chars")
                    continue
                if kind not in {"positive", "negative"}:
                    errors.append(f"{cap_id}: discovery.use_when kind must be positive or negative")
                if text.strip().casefold() in seen_texts:
                    errors.append(f"{cap_id}: discovery.use_when duplicate text {text!r}")
                seen_texts.add(text.strip().casefold())
                if not all(isinstance(x, str) and x.strip() for x in [text]) or text.strip() != text:
                    errors.append(f"{cap_id}: discovery.use_when text must be non-empty trimmed string")
        do_not_use_when = discovery.get("do_not_use_when", [])
        if not isinstance(do_not_use_when, list):
            errors.append(f"{cap_id}: discovery.do_not_use_when must be an array")
        else:
            for entry in do_not_use_when:
                if not isinstance(entry, dict):
                    errors.append(f"{cap_id}: discovery.do_not_use_when entries must be objects")
                    continue
                text = entry.get("text")
                kind = entry.get("kind", "negative")
                if not isinstance(text, str) or len(text.strip()) < 8:
                    errors.append(f"{cap_id}: discovery.do_not_use_when entries require text >= 8 chars")
                if kind not in {"positive", "negative"}:
                    errors.append(f"{cap_id}: discovery.do_not_use_when kind must be positive or negative")
        if isinstance(use_when, list) and isinstance(do_not_use_when, list):
            overlap = {
                entry.get("text", "").strip().casefold()
                for entry in use_when if isinstance(entry, dict)
            } & {
                entry.get("text", "").strip().casefold()
                for entry in do_not_use_when if isinstance(entry, dict)
            }
            overlap.discard("")
            if overlap:
                errors.append(f"{cap_id}: discovery.use_when and do_not_use_when overlap: {sorted(overlap)}")

    _unique_named(cap_id, "inputs", cap.get("inputs"), "name", errors)
    _unique_named(cap_id, "outputs", cap.get("outputs"), "name", errors)
    _unique_named(cap_id, "preconditions", cap.get("preconditions") or [], "id", errors) if cap.get("preconditions") else None
    _unique_named(cap_id, "evidence_outputs", cap.get("evidence_outputs"), "name", errors)

    implementation = cap.get("implementation")
    if not isinstance(implementation, dict):
        errors.append(f"{cap_id}: implementation must be an object")
    else:
        primary = implementation.get("primary_asset")
        refs = implementation.get("asset_ids")
        if not isinstance(refs, list) or not refs or any(not isinstance(x, str) for x in refs):
            errors.append(f"{cap_id}: implementation.asset_ids must be a non-empty string array")
            refs = []
        if primary not in refs:
            errors.append(f"{cap_id}: primary_asset must appear in implementation.asset_ids")
        for ref in refs:
            if ref not in asset_ids:
                errors.append(f"{cap_id}: unknown registered asset {ref} in implementation")

    provenance = cap.get("provenance")
    if not isinstance(provenance, dict) or not isinstance(provenance.get("asset_ids"), list) or not provenance["asset_ids"]:
        errors.append(f"{cap_id}: provenance.asset_ids must be a non-empty array")
    else:
        for ref in provenance["asset_ids"]:
            if ref not in asset_ids:
                errors.append(f"{cap_id}: unknown registered asset {ref} in provenance")

    authority = cap.get("authority")
    if not isinstance(authority, dict) or set(authority) != {"required", "optional", "forbidden"}:
        errors.append(f"{cap_id}: authority requires required/optional/forbidden arrays")
    else:
        sets = {}
        for name in ("required", "optional", "forbidden"):
            values = authority[name]
            if not isinstance(values, list) or any(v not in AUTHORITY for v in values):
                errors.append(f"{cap_id}: invalid authority token in {name}")
                values = [v for v in values if v in AUTHORITY] if isinstance(values, list) else []
            if len(values) != len(set(values)):
                errors.append(f"{cap_id}: duplicate authority token within {name}")
            sets[name] = set(values)
        overlap = (sets["required"] & sets["optional"]) | (sets["required"] & sets["forbidden"]) | (sets["optional"] & sets["forbidden"])
        if overlap:
            errors.append(f"{cap_id}: authority sets overlap: {sorted(overlap)}")
        mutation = cap.get("mutation", {})
        if mutation.get("class") == "read-only" and sets["required"] & WRITE_AUTHORITY:
            errors.append(f"{cap_id}: read-only capability requires write authority {sorted(sets['required'] & WRITE_AUTHORITY)}")

    mutation = cap.get("mutation")
    if not isinstance(mutation, dict) or mutation.get("class") not in MUTATION_CLASSES or not isinstance(mutation.get("reversible"), bool):
        errors.append(f"{cap_id}: invalid mutation contract")

    execution = cap.get("execution")
    if not isinstance(execution, dict) or set(execution) != {"preferred", "allowed", "prohibited"}:
        errors.append(f"{cap_id}: execution requires preferred/allowed/prohibited arrays")
    else:
        pref = set(execution["preferred"]) if isinstance(execution["preferred"], list) else set()
        allowed = set(execution["allowed"]) if isinstance(execution["allowed"], list) else set()
        prohibited = set(execution["prohibited"]) if isinstance(execution["prohibited"], list) else set()
        if not pref or not allowed or (pref | allowed | prohibited) - SUBSTRATES:
            errors.append(f"{cap_id}: invalid execution substrate")
        if not pref <= allowed:
            errors.append(f"{cap_id}: preferred execution substrate must be allowed")
        if allowed & prohibited:
            errors.append(f"{cap_id}: allowed/prohibited execution substrates overlap: {sorted(allowed & prohibited)}")

    verification = cap.get("verification")
    if not isinstance(verification, dict) or not isinstance(verification.get("requirements"), list) or not verification["requirements"]:
        errors.append(f"{cap_id}: verification.requirements must be non-empty")
    else:
        seen = set()
        for req in verification["requirements"]:
            if not isinstance(req, dict) or req.get("evidence_kind") not in EVIDENCE_KINDS or not isinstance(req.get("id"), str):
                errors.append(f"{cap_id}: invalid verification requirement")
                continue
            if req["id"] in seen:
                errors.append(f"{cap_id}: duplicate verification requirement {req['id']}")
            seen.add(req["id"])
        if not isinstance(verification.get("receipt_required"), bool):
            errors.append(f"{cap_id}: verification.receipt_required must be boolean")

    evaluation = cap.get("evaluation")
    if not isinstance(evaluation, dict) or evaluation.get("status") not in EVALUATION_STATES or not isinstance(evaluation.get("suite_asset_ids"), list):
        errors.append(f"{cap_id}: invalid evaluation contract")
    else:
        suites = evaluation["suite_asset_ids"]
        for ref in suites:
            if ref not in asset_ids:
                errors.append(f"{cap_id}: unknown registered asset {ref} in evaluation suites")
        lifecycle = cap.get("lifecycle")
        if lifecycle == "testing" and (evaluation["status"] not in {"candidate", "qualified"} or not suites):
            errors.append(f"{cap_id}: testing capability requires candidate/qualified evaluation evidence")
        if lifecycle == "stable" and (evaluation["status"] != "qualified" or not suites):
            errors.append(f"{cap_id}: stable capability requires qualified evaluation evidence")

    serialized = json.dumps(cap, sort_keys=True).lower()
    for marker in HARNESS_MARKERS:
        if marker in serialized:
            errors.append(f"{cap_id}: harness-specific marker leaked into canonical capability data: {marker}")

    # Discovery harness-neutrality: each statement text must not contain harness markers
    if isinstance(discovery, dict):
        for key in ("use_when", "do_not_use_when"):
            entries = discovery.get(key) or []
            if not isinstance(entries, list):
                continue
            for entry in entries:
                if not isinstance(entry, dict):
                    continue
                text = entry.get("text")
                if not isinstance(text, str):
                    continue
                lowered = text.lower()
                for marker in HARNESS_MARKERS:
                    if marker in lowered:
                        errors.append(f"{cap_id}: discovery.{key} leaked harness marker {marker!r}")


def validate_repository(root: Path, capability_dir: Path | None = None):
    root = root.resolve()
    asset_ids, errors = load_asset_ids(root)
    fragments, fragment_errors = load_capability_fragments(root, capability_dir)
    errors.extend(fragment_errors)

    schema_path = root / "arsenal" / "capability.schema.json"
    try:
        schema = _json(schema_path)
        if schema.get("$id") != "https://project-arsenal.dev/schema/capability-fragment-2.0.0.json":
            errors.append("arsenal/capability.schema.json: unexpected $id")
    except Exception as exc:
        errors.append(f"arsenal/capability.schema.json: invalid JSON: {exc}")

    capabilities: list[dict] = []
    ids: set[str] = set()
    public_names: dict[str, str] = {}
    for path, cap in fragments:
        cap_id = cap.get("id", f"<{path.name}>")
        if cap_id in ids:
            errors.append(f"{cap_id}: duplicate capability id")
        ids.add(cap_id)
        validate_capability(cap, asset_ids, errors)
        capabilities.append(cap)
        for public in [cap.get("display_name"), *(cap.get("aliases") or [])]:
            if not isinstance(public, str):
                continue
            key = public.strip().casefold()
            owner = public_names.get(key)
            if owner and owner != cap_id:
                errors.append(f"{cap_id}: public name/alias collision {public!r} with {owner}")
            else:
                public_names[key] = cap_id

    missing = REQUIRED_CAPABILITIES - ids
    if missing:
        errors.append(f"missing ARS-01 migration capabilities: {sorted(missing)}")

    by_id = {cap.get("id"): cap for cap in capabilities}
    pressure = by_id.get("capability.pressure-test", {})
    if not {"grill", "grilling"} <= {x.casefold() for x in pressure.get("aliases", []) if isinstance(x, str)}:
        errors.append("capability.pressure-test: Grill/Grilling compatibility aliases required")
    recon = by_id.get("capability.recon", {})
    if not {"wayfind", "wayfinding"} <= {x.casefold() for x in recon.get("aliases", []) if isinstance(x, str)}:
        errors.append("capability.recon: Wayfind/Wayfinding compatibility aliases required")
    cloud = by_id.get("capability.local-cloud-feature-delivery", {})
    cloud_auth = cloud.get("authority", {}) if isinstance(cloud, dict) else {}
    if "cloud.local" not in cloud_auth.get("required", []):
        errors.append("capability.local-cloud-feature-delivery: cloud.local must be required")
    for token in ("cloud.remote", "production.mutate"):
        if token not in cloud_auth.get("forbidden", []):
            errors.append(f"capability.local-cloud-feature-delivery: {token} must be forbidden by default")

    return capabilities, errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capability-dir", type=Path, default=None)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    capabilities, errors = validate_repository(args.root, args.capability_dir)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Capability audit failed: {len(errors)} error(s)", file=sys.stderr)
        return 1
    print(f"Capability audit passed: {len(capabilities)} capabilities, schema {CAPABILITY_SCHEMA_VERSION}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
