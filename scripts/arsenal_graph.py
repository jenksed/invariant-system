#!/usr/bin/env python3
"""Validate Project Arsenal Capability Graph routes and run Capability Gap Preflight."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

# Canonical Arsenal protocol vocabulary and shared I/O primitives.
from arsenal_protocol import (
    DANGEROUS_AUTHORITY,
    EVALUATION_STATES,
    LIFECYCLE_STATES,
)
from arsenal_io import load_json, safe_relative_path, sha256_bytes

ROOT = Path(__file__).resolve().parents[1]
GRAPH_PATH = ROOT / "arsenal/graph/graph.json"
LOCK_PATH = ROOT / ".arsenal.lock"

LIFECYCLE_ORDER = {state: i for i, state in enumerate(sorted(LIFECYCLE_STATES))}
EVALUATION_ORDER = {state: i for i, state in enumerate(sorted(EVALUATION_STATES))}
SEMVER_RE = re.compile(r"^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
DANGEROUS_PROFILE_GRANTS = DANGEROUS_AUTHORITY
EXIT_CODES = {
    "READY": 0,
    "CAPABILITY_GAP": 3,
    "AUTHORITY_GAP": 4,
    "QUALIFICATION_GAP": 5,
    "UNKNOWN": 6,
}


def parse_semver(value: str) -> tuple[int, int, int]:
    match = SEMVER_RE.fullmatch(value)
    if not match:
        raise AssertionError(f"invalid semantic version: {value!r}")
    return tuple(int(group) for group in match.groups())  # type: ignore[return-value]


def load_capabilities(root: Path = ROOT) -> dict[str, dict[str, Any]]:
    capabilities: dict[str, dict[str, Any]] = {}
    for path in sorted((root / "arsenal/capabilities").glob("*.json")):
        doc = load_json(path)
        cap = doc["capability"]
        cap_id = cap["id"]
        if cap_id in capabilities:
            raise AssertionError(f"duplicate capability id: {cap_id}")
        capabilities[cap_id] = {
            "path": path,
            "document": doc,
            "capability": cap,
        }
    return capabilities


def load_assets(root: Path = ROOT) -> dict[str, dict[str, Any]]:
    files = [root / "arsenal/registry.json"] + sorted((root / "arsenal/registry.d").glob("*.json"))
    assets: dict[str, dict[str, Any]] = {}
    for path in files:
        doc = load_json(path)
        if doc.get("schema_version") != "1.0.0":
            raise AssertionError(f"unsupported asset registry schema: {path.relative_to(root)}")
        for asset in doc.get("assets", []):
            asset_id = asset["id"]
            if asset_id in assets:
                raise AssertionError(f"duplicate asset id across registry fragments: {asset_id}")
            assets[asset_id] = asset
    return assets


def load_locked_capabilities(root: Path = ROOT) -> dict[str, dict[str, Any]]:
    if not (root / ".arsenal.lock").is_file():
        return {}
    lock = load_json(root / ".arsenal.lock")
    result: dict[str, dict[str, Any]] = {}
    for item in lock.get("capabilities", []):
        cap_id = item["id"]
        if cap_id in result:
            raise AssertionError(f"duplicate capability in .arsenal.lock: {cap_id}")
        result[cap_id] = item
    return result


def validate_graph_data(
    graph: dict[str, Any],
    root: Path = ROOT,
    capabilities: dict[str, dict[str, Any]] | None = None,
) -> dict[str, Any]:
    capabilities = capabilities or load_capabilities(root)

    if graph.get("schema_version") != "1.0.0":
        raise AssertionError("graph schema_version must be 1.0.0")

    profiles = graph.get("authority_profiles")
    if not isinstance(profiles, list) or not profiles:
        raise AssertionError("graph must define authority_profiles")

    profile_map: dict[str, dict[str, Any]] = {}
    for profile in profiles:
        profile_id = profile.get("id")
        grants = profile.get("grants")
        if not isinstance(profile_id, str) or not profile_id:
            raise AssertionError("authority profile id must be non-empty")
        if profile_id in profile_map:
            raise AssertionError(f"duplicate authority profile: {profile_id}")
        if not isinstance(grants, list) or any(not isinstance(item, str) for item in grants):
            raise AssertionError(f"authority profile {profile_id} grants must be a string list")
        if len(grants) != len(set(grants)):
            raise AssertionError(f"authority profile {profile_id} contains duplicate grants")
        dangerous = sorted(set(grants) & DANGEROUS_PROFILE_GRANTS)
        if dangerous:
            raise AssertionError(
                f"authority profile {profile_id} includes ARS-04-v0 prohibited grants: {', '.join(dangerous)}"
            )
        profile_map[profile_id] = profile

    routes = graph.get("routes")
    if not isinstance(routes, list) or not routes:
        raise AssertionError("graph must define routes")

    route_map: dict[str, dict[str, Any]] = {}
    for route in routes:
        route_id = route.get("id")
        if not isinstance(route_id, str) or not route_id.startswith("route."):
            raise AssertionError(f"invalid route id: {route_id!r}")
        if route_id in route_map:
            raise AssertionError(f"duplicate route id: {route_id}")
        default_profile = route.get("default_authority_profile")
        if default_profile not in profile_map:
            raise AssertionError(f"route {route_id} references unknown authority profile: {default_profile}")

        steps = route.get("steps")
        if not isinstance(steps, list) or not steps:
            raise AssertionError(f"route {route_id} must contain steps")

        seen: set[str] = set()
        for index, step in enumerate(steps):
            cap_id = step.get("capability_id")
            if cap_id not in capabilities:
                raise AssertionError(f"route {route_id} references unknown capability: {cap_id}")
            if cap_id in seen:
                raise AssertionError(f"route {route_id} repeats capability: {cap_id}")

            after = step.get("after")
            if not isinstance(after, list) or any(not isinstance(item, str) for item in after):
                raise AssertionError(f"route {route_id} step {cap_id} after must be a string list")
            if index > 0 and not after:
                raise AssertionError(f"route {route_id} non-root step {cap_id} must declare an explicit dependency")
            for dependency in after:
                if dependency not in seen:
                    raise AssertionError(
                        f"route {route_id} step {cap_id} depends on {dependency} before it is available"
                    )

            parse_semver(step.get("minimum_version", ""))
            lifecycle = step.get("minimum_lifecycle")
            evaluation = step.get("minimum_evaluation")
            if lifecycle not in LIFECYCLE_ORDER:
                raise AssertionError(f"route {route_id} step {cap_id} has invalid lifecycle minimum: {lifecycle}")
            if evaluation not in EVALUATION_ORDER:
                raise AssertionError(f"route {route_id} step {cap_id} has invalid evaluation minimum: {evaluation}")
            seen.add(cap_id)

        route_map[route_id] = route

    return {"profiles": profile_map, "routes": route_map}


def qualification_at_least(actual: str, minimum: str, order: dict[str, int]) -> bool | None:
    if actual == "deprecated":
        return False
    if actual not in order:
        return None
    return order[actual] >= order[minimum]


def stricter_minimum(route_value: str, override: str | None, order: dict[str, int]) -> str:
    if override is None:
        return route_value
    return override if order[override] > order[route_value] else route_value


def implementation_state(
    capability: dict[str, Any], assets: dict[str, dict[str, Any]], root: Path
) -> tuple[bool, str | None, str | None]:
    primary = capability["implementation"]["primary_asset"]
    asset = assets.get(primary)
    if asset is None:
        return False, None, f"primary implementation asset is not registered: {primary}"
    try:
        rel = safe_relative_path(asset["path"], field="primary implementation path")
    except (AssertionError, KeyError) as exc:
        return False, None, str(exc)
    path = root / rel
    if not path.is_file():
        return False, rel.as_posix(), f"registered primary implementation file is missing: {rel.as_posix()}"
    return True, rel.as_posix(), None


def locked_entry_state(record: dict[str, Any], locked: dict[str, Any]) -> tuple[bool, list[str]]:
    cap = record["capability"]
    reasons: list[str] = []
    if locked.get("version") != cap["version"]:
        reasons.append(f"locked version {locked.get('version')!r} does not match canonical {cap['version']}")
    expected_digest = sha256_bytes(record["path"].read_bytes())
    if locked.get("capability_sha256") != expected_digest:
        reasons.append("locked capability digest does not match canonical capability file")
    if locked.get("lifecycle") != cap["lifecycle"]:
        reasons.append(
            f"locked lifecycle {locked.get('lifecycle')!r} does not match canonical {cap['lifecycle']}"
        )
    if locked.get("evaluation") != cap["evaluation"]:
        reasons.append("locked evaluation qualification does not match canonical capability")
    return not reasons, reasons


def preflight(
    route_id: str,
    *,
    inventory: str = "canonical",
    authority_profile: str | None = None,
    omitted: set[str] | None = None,
    minimum_lifecycle: str | None = None,
    minimum_evaluation: str | None = None,
    root: Path = ROOT,
    graph: dict[str, Any] | None = None,
) -> dict[str, Any]:
    graph = graph or load_json(root / "arsenal/graph/graph.json")
    capabilities = load_capabilities(root)
    assets = load_assets(root)
    validated = validate_graph_data(graph, root, capabilities)

    if route_id not in validated["routes"]:
        raise AssertionError(f"unknown route: {route_id}")
    if inventory not in {"canonical", "lock"}:
        raise AssertionError(f"unknown inventory mode: {inventory}")
    if minimum_lifecycle is not None and minimum_lifecycle not in LIFECYCLE_ORDER:
        raise AssertionError(f"invalid lifecycle override: {minimum_lifecycle}")
    if minimum_evaluation is not None and minimum_evaluation not in EVALUATION_ORDER:
        raise AssertionError(f"invalid evaluation override: {minimum_evaluation}")

    route = validated["routes"][route_id]
    profile_id = authority_profile or route["default_authority_profile"]
    if profile_id not in validated["profiles"]:
        raise AssertionError(f"unknown authority profile: {profile_id}")
    grants = set(validated["profiles"][profile_id]["grants"])

    locked_inventory = load_locked_capabilities(root) if inventory == "lock" else {}
    available = set(capabilities) if inventory == "canonical" else set(locked_inventory)
    available -= omitted or set()

    results: list[dict[str, Any]] = []
    statuses: set[str] = set()

    for step in route["steps"]:
        cap_id = step["capability_id"]
        record = capabilities.get(cap_id)
        if record is None:
            result = {
                "capability_id": cap_id,
                "status": "unknown",
                "reasons": ["canonical capability metadata is unavailable"],
            }
            results.append(result)
            statuses.add("unknown")
            continue

        cap = record["capability"]
        reasons: list[str] = []
        status = "covered"

        if cap_id not in available:
            status = "missing"
            reasons.append(f"capability is not present in {inventory} inventory")
        elif inventory == "lock":
            lock_ok, lock_reasons = locked_entry_state(record, locked_inventory[cap_id])
            if not lock_ok:
                status = "incompatible"
                reasons.extend(lock_reasons)

        impl_ok, impl_path, impl_reason = implementation_state(cap, assets, root)
        if not impl_ok:
            status = "missing"
            reasons.append(impl_reason or "primary implementation is unavailable")

        actual_version = cap["version"]
        try:
            version_ok = parse_semver(actual_version) >= parse_semver(step["minimum_version"])
        except AssertionError:
            version_ok = None
        if version_ok is False and status == "covered":
            status = "incompatible"
            reasons.append(
                f"capability version {actual_version} is below route minimum {step['minimum_version']}"
            )
        elif version_ok is None and status == "covered":
            status = "unknown"
            reasons.append(f"capability version cannot be interpreted safely: {actual_version!r}")

        required_authority = set(cap["authority"]["required"])
        missing_authority = sorted(required_authority - grants)
        if missing_authority and status == "covered":
            status = "unauthorized"
            reasons.append(f"authority profile lacks: {', '.join(missing_authority)}")

        lifecycle_min = stricter_minimum(
            step["minimum_lifecycle"], minimum_lifecycle, LIFECYCLE_ORDER
        )
        evaluation_min = stricter_minimum(
            step["minimum_evaluation"], minimum_evaluation, EVALUATION_ORDER
        )
        lifecycle_ok = qualification_at_least(cap["lifecycle"], lifecycle_min, LIFECYCLE_ORDER)
        evaluation_ok = qualification_at_least(
            cap["evaluation"]["status"], evaluation_min, EVALUATION_ORDER
        )
        if status == "covered" and (lifecycle_ok is False or evaluation_ok is False):
            status = "insufficient-qualification"
            if lifecycle_ok is False:
                reasons.append(
                    f"lifecycle {cap['lifecycle']} is below required {lifecycle_min}"
                )
            if evaluation_ok is False:
                reasons.append(
                    f"evaluation {cap['evaluation']['status']} is below required {evaluation_min}"
                )
        elif status == "covered" and (lifecycle_ok is None or evaluation_ok is None):
            status = "unknown"
            reasons.append("capability qualification state cannot be interpreted safely")

        result = {
            "capability_id": cap_id,
            "display_name": cap["display_name"],
            "version": actual_version,
            "status": status,
            "reasons": reasons,
            "after": step["after"],
            "implementation": {
                "primary_asset": cap["implementation"]["primary_asset"],
                "path": impl_path,
                "available": impl_ok,
            },
            "authority": {
                "required": sorted(required_authority),
                "granted": sorted(grants),
                "missing": missing_authority,
            },
            "qualification": {
                "lifecycle": cap["lifecycle"],
                "minimum_lifecycle": lifecycle_min,
                "evaluation": cap["evaluation"]["status"],
                "minimum_evaluation": evaluation_min,
            },
            "preconditions": cap["preconditions"],
            "outputs": cap["outputs"],
        }
        if inventory == "lock" and cap_id in locked_inventory:
            result["lock"] = {
                "version": locked_inventory[cap_id].get("version"),
                "capability_sha256": locked_inventory[cap_id].get("capability_sha256"),
            }
        results.append(result)
        statuses.add(status)

    if "unknown" in statuses:
        verdict = "UNKNOWN"
    elif "missing" in statuses or "incompatible" in statuses:
        verdict = "CAPABILITY_GAP"
    elif "unauthorized" in statuses:
        verdict = "AUTHORITY_GAP"
    elif "insufficient-qualification" in statuses:
        verdict = "QUALIFICATION_GAP"
    else:
        verdict = "READY"

    return {
        "schema_version": "1.0.0",
        "route": {
            "id": route["id"],
            "display_name": route["display_name"],
            "purpose": route["purpose"],
        },
        "inventory": inventory,
        "authority_profile": profile_id,
        "verdict": verdict,
        "steps": results,
    }


def render_report(report: dict[str, Any]) -> str:
    lines = [
        f"Capability Gap Preflight: {report['verdict']}",
        f"route: {report['route']['id']} — {report['route']['display_name']}",
        f"inventory: {report['inventory']}",
        f"authority profile: {report['authority_profile']}",
        "",
    ]
    for step in report["steps"]:
        display = step.get("display_name", step["capability_id"])
        lines.append(f"[{step['status']}] {step['capability_id']} — {display}")
        for reason in step.get("reasons", []):
            lines.append(f"  reason: {reason}")
        if "qualification" in step:
            q = step["qualification"]
            lines.append(
                "  qualification: "
                f"{q['lifecycle']}/{q['evaluation']} "
                f"(minimum {q['minimum_lifecycle']}/{q['minimum_evaluation']})"
            )
        if "authority" in step and step["authority"]["missing"]:
            lines.append(f"  authority missing: {', '.join(step['authority']['missing'])}")
        if "implementation" in step:
            lines.append(
                f"  implementation: {step['implementation']['primary_asset']} -> "
                f"{step['implementation']['path'] or 'unresolved'}"
            )
        if step.get("after"):
            lines.append(f"  after: {', '.join(step['after'])}")
    return "\n".join(lines)


def explain_route(route_id: str, root: Path = ROOT) -> str:
    graph = load_json(root / "arsenal/graph/graph.json")
    capabilities = load_capabilities(root)
    validated = validate_graph_data(graph, root, capabilities)
    if route_id not in validated["routes"]:
        raise AssertionError(f"unknown route: {route_id}")
    route = validated["routes"][route_id]
    lines = [
        f"{route['id']} — {route['display_name']}",
        route["purpose"],
        f"default authority: {route['default_authority_profile']}",
        "",
    ]
    for index, step in enumerate(route["steps"], 1):
        cap = capabilities[step["capability_id"]]["capability"]
        lines.append(
            f"{index}. {step['capability_id']} ({cap['display_name']}) "
            f">= {step['minimum_version']} "
            f"[{step['minimum_lifecycle']}/{step['minimum_evaluation']}]"
        )
        if step["after"]:
            lines.append(f"   after: {', '.join(step['after'])}")
        lines.append(f"   preconditions: {', '.join(item['id'] for item in cap['preconditions'])}")
        lines.append(f"   outputs: {', '.join(item['name'] for item in cap['outputs'])}")
    return "\n".join(lines)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("validate")

    explain = sub.add_parser("explain")
    explain.add_argument("--route", required=True)

    pre = sub.add_parser("preflight")
    pre.add_argument("--route", required=True)
    pre.add_argument("--inventory", choices=("canonical", "lock"), default="canonical")
    pre.add_argument("--authority-profile")
    pre.add_argument("--omit", action="append", default=[])
    pre.add_argument("--minimum-lifecycle", choices=tuple(LIFECYCLE_ORDER))
    pre.add_argument("--minimum-evaluation", choices=tuple(EVALUATION_ORDER))
    pre.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.command == "validate":
        graph = load_json(GRAPH_PATH)
        validated = validate_graph_data(graph)
        print(
            f"Capability Graph contract: PASS "
            f"({len(validated['routes'])} routes; {len(validated['profiles'])} authority profiles)"
        )
        return 0
    if args.command == "explain":
        print(explain_route(args.route))
        return 0

    report = preflight(
        args.route,
        inventory=args.inventory,
        authority_profile=args.authority_profile,
        omitted=set(args.omit),
        minimum_lifecycle=args.minimum_lifecycle,
        minimum_evaluation=args.minimum_evaluation,
    )
    print(json.dumps(report, indent=2, sort_keys=True) if args.json else render_report(report))
    return EXIT_CODES[report["verdict"]]


if __name__ == "__main__":
    raise SystemExit(main())
