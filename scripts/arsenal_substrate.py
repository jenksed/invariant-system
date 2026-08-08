#!/usr/bin/env python3
"""Validate ARS-05 substrate contracts and select the lowest sufficient Reality Budget."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = ROOT / "arsenal/substrates/catalog.json"
PROOF_PATH = ROOT / "arsenal/substrates/proof-requirements.json"
GRAPH_PATH = ROOT / "arsenal/graph/graph.json"

AUTHORITY_VOCAB = {
    "filesystem.read", "filesystem.write", "shell.execute",
    "network.read", "network.write", "git.read", "git.write",
    "tracker.read", "tracker.write", "secrets.read", "cloud.local",
    "cloud.remote", "production.mutate", "human.confirmation",
}
EXECUTION_SURFACES = {
    "reasoning-only", "repository-read", "local-process",
    "local-container", "local-emulator", "local-cluster",
    "remote-sandbox", "shared-nonproduction", "staging",
    "production", "user-mediated",
}
EXPLICIT_ONLY_SURFACES = {"remote-sandbox", "shared-nonproduction", "staging", "production"}
TRAIT_RE = re.compile(r"^[a-z][a-z0-9.-]*$")
EXIT_CODES = {
    "SELECTED": 0,
    "AUTHORITY_GAP": 4,
    "SUBSTRATE_GAP": 5,
    "ESCALATION_REQUIRED": 6,
    "EVIDENCE_GAP": 7,
    "UNKNOWN": 8,
}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_capabilities(root: Path = ROOT) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for path in sorted((root / "arsenal/capabilities").glob("*.json")):
        doc = load_json(path)
        cap = doc["capability"]
        result[cap["id"]] = {"path": path, "capability": cap}
    return result


def load_authority_profiles(root: Path = ROOT) -> dict[str, set[str]]:
    graph = load_json(root / "arsenal/graph/graph.json")
    return {item["id"]: set(item["grants"]) for item in graph["authority_profiles"]}


def validate_catalog_data(catalog: dict[str, Any]) -> dict[str, Any]:
    if catalog.get("schema_version") != "1.0.0":
        raise AssertionError("substrate catalog schema_version must be 1.0.0")

    isolation_strength = catalog.get("isolation_strength")
    if not isinstance(isolation_strength, dict) or not isolation_strength:
        raise AssertionError("catalog must define isolation_strength")
    if any(not isinstance(k, str) or not isinstance(v, int) or v < 0 for k, v in isolation_strength.items()):
        raise AssertionError("isolation_strength must map strings to non-negative integers")

    repro_order = catalog.get("reproducibility_order")
    if not isinstance(repro_order, list) or repro_order != ["best-effort", "resettable", "deterministic"]:
        raise AssertionError("reproducibility_order must be best-effort < resettable < deterministic")
    repro_rank = {name: idx for idx, name in enumerate(repro_order)}

    substrates = catalog.get("substrates")
    if not isinstance(substrates, list) or not substrates:
        raise AssertionError("catalog must contain substrates")

    by_id: dict[str, dict[str, Any]] = {}
    ranks: set[int] = set()
    for item in substrates:
        substrate_id = item.get("id")
        if not isinstance(substrate_id, str) or not substrate_id.startswith("substrate."):
            raise AssertionError(f"invalid substrate id: {substrate_id!r}")
        if substrate_id in by_id:
            raise AssertionError(f"duplicate substrate id: {substrate_id}")
        rank = item.get("reality_rank")
        if not isinstance(rank, int) or rank < 0 or rank in ranks:
            raise AssertionError(f"invalid or duplicate reality_rank for {substrate_id}: {rank!r}")
        ranks.add(rank)

        surface = item.get("execution_surface")
        if surface not in EXECUTION_SURFACES:
            raise AssertionError(f"unknown execution surface for {substrate_id}: {surface!r}")
        mode = item.get("selection_mode")
        if mode not in {"automatic", "explicit-only"}:
            raise AssertionError(f"invalid selection_mode for {substrate_id}: {mode!r}")
        if surface in EXPLICIT_ONLY_SURFACES and mode != "explicit-only":
            raise AssertionError(f"high-consequence surface must be explicit-only: {substrate_id}")
        if mode == "automatic" and set(item.get("required_authority", [])) & {"cloud.remote", "production.mutate", "secrets.read"}:
            raise AssertionError(f"automatic substrate requires prohibited high-consequence authority: {substrate_id}")

        authority = item.get("required_authority")
        if not isinstance(authority, list) or len(authority) != len(set(authority)):
            raise AssertionError(f"required_authority must be a unique list for {substrate_id}")
        unknown_authority = sorted(set(authority) - AUTHORITY_VOCAB)
        if unknown_authority:
            raise AssertionError(f"unknown authority for {substrate_id}: {', '.join(unknown_authority)}")

        isolation = item.get("isolation")
        if isolation not in isolation_strength:
            raise AssertionError(f"unknown isolation for {substrate_id}: {isolation!r}")
        reproducibility = item.get("reproducibility")
        if reproducibility not in repro_rank:
            raise AssertionError(f"unknown reproducibility for {substrate_id}: {reproducibility!r}")

        traits = item.get("traits")
        if not isinstance(traits, list) or not traits or len(traits) != len(set(traits)):
            raise AssertionError(f"traits must be a non-empty unique list for {substrate_id}")
        if any(not isinstance(t, str) or not TRAIT_RE.fullmatch(t) for t in traits):
            raise AssertionError(f"invalid proof trait on {substrate_id}")

        limitations = item.get("limitations")
        if not isinstance(limitations, list) or not limitations or any(not isinstance(x, str) or len(x) < 8 for x in limitations):
            raise AssertionError(f"limitations must be explicit for {substrate_id}")

        for contract_field in ("fixture_reset", "teardown"):
            contract = item.get(contract_field)
            if not isinstance(contract, dict) or set(contract) != {"required", "strategy"}:
                raise AssertionError(f"{contract_field} contract malformed for {substrate_id}")
            if not isinstance(contract["required"], bool) or not isinstance(contract["strategy"], str) or not contract["strategy"]:
                raise AssertionError(f"{contract_field} contract malformed for {substrate_id}")

        by_id[substrate_id] = item

    if ranks != set(range(len(substrates))):
        raise AssertionError("reality_rank values must form a contiguous 0..N ladder")

    for item in substrates:
        target = item.get("escalation_to")
        if target is None:
            if item["reality_rank"] != max(ranks):
                raise AssertionError(f"only the top substrate may omit escalation_to: {item['id']}")
            continue
        if target not in by_id:
            raise AssertionError(f"unknown escalation target from {item['id']}: {target}")
        if by_id[target]["reality_rank"] <= item["reality_rank"]:
            raise AssertionError(f"escalation must increase reality rank: {item['id']} -> {target}")

    profiles = catalog.get("availability_profiles")
    if not isinstance(profiles, list) or not profiles:
        raise AssertionError("catalog must define availability_profiles")
    profile_map: dict[str, set[str]] = {}
    for profile in profiles:
        profile_id = profile.get("id")
        entries = profile.get("substrates")
        if not isinstance(profile_id, str) or not profile_id or profile_id in profile_map:
            raise AssertionError(f"invalid/duplicate availability profile: {profile_id!r}")
        if not isinstance(entries, list) or not entries or len(entries) != len(set(entries)):
            raise AssertionError(f"availability profile {profile_id} must contain unique substrates")
        unknown = sorted(set(entries) - set(by_id))
        if unknown:
            raise AssertionError(f"availability profile {profile_id} references unknown substrates: {', '.join(unknown)}")
        explicit = sorted(s for s in entries if by_id[s]["selection_mode"] == "explicit-only")
        if explicit:
            raise AssertionError(f"availability profile {profile_id} may not auto-declare explicit-only substrates: {', '.join(explicit)}")
        profile_map[profile_id] = set(entries)

    return {
        "substrates": by_id,
        "profiles": profile_map,
        "isolation_strength": isolation_strength,
        "repro_rank": repro_rank,
    }


def validate_proof_data(
    proof: dict[str, Any],
    *,
    capabilities: dict[str, dict[str, Any]],
    catalog_view: dict[str, Any],
) -> dict[tuple[str, str], dict[str, Any]]:
    if proof.get("schema_version") != "1.0.0":
        raise AssertionError("proof requirements schema_version must be 1.0.0")
    requirements = proof.get("requirements")
    if not isinstance(requirements, list) or not requirements:
        raise AssertionError("proof requirements must contain entries")

    by_key: dict[tuple[str, str], dict[str, Any]] = {}
    seen_ids: set[str] = set()
    substrate_ids = set(catalog_view["substrates"])
    for item in requirements:
        proof_id = item.get("id")
        cap_id = item.get("capability_id")
        req_id = item.get("verification_requirement_id")
        if not isinstance(proof_id, str) or not proof_id.startswith("proof.") or proof_id in seen_ids:
            raise AssertionError(f"invalid/duplicate proof id: {proof_id!r}")
        seen_ids.add(proof_id)
        if cap_id not in capabilities:
            raise AssertionError(f"proof requirement references unknown capability: {cap_id}")
        cap = capabilities[cap_id]["capability"]
        canonical_ids = {entry["id"] for entry in cap["verification"]["requirements"]}
        if req_id not in canonical_ids:
            raise AssertionError(f"proof requirement {proof_id} references unknown verification requirement: {cap_id}/{req_id}")
        key = (cap_id, req_id)
        if key in by_key:
            raise AssertionError(f"duplicate proof binding: {cap_id}/{req_id}")

        traits = item.get("required_traits")
        if not isinstance(traits, list) or not traits or len(traits) != len(set(traits)):
            raise AssertionError(f"required_traits must be a non-empty unique list: {proof_id}")
        if any(not isinstance(t, str) or not TRAIT_RE.fullmatch(t) for t in traits):
            raise AssertionError(f"invalid required trait: {proof_id}")
        leaked = sorted(t for t in traits if t.startswith("substrate.") or t in substrate_ids)
        if leaked:
            raise AssertionError(f"proof requirement must be runtime-agnostic; found substrate identity: {', '.join(leaked)}")

        min_isolation = item.get("minimum_isolation")
        if min_isolation not in catalog_view["isolation_strength"]:
            raise AssertionError(f"unknown minimum_isolation on {proof_id}: {min_isolation!r}")
        min_repro = item.get("minimum_reproducibility")
        if min_repro not in catalog_view["repro_rank"]:
            raise AssertionError(f"unknown minimum_reproducibility on {proof_id}: {min_repro!r}")
        by_key[key] = item
    return by_key


def substrate_satisfies(item: dict[str, Any], proof: dict[str, Any], catalog_view: dict[str, Any]) -> bool:
    if not set(proof["required_traits"]).issubset(set(item["traits"])):
        return False
    if catalog_view["isolation_strength"][item["isolation"]] < catalog_view["isolation_strength"][proof["minimum_isolation"]]:
        return False
    if catalog_view["repro_rank"][item["reproducibility"]] < catalog_view["repro_rank"][proof["minimum_reproducibility"]]:
        return False
    return True


def select_substrate(
    capability_id: str,
    requirement_id: str,
    *,
    authority_profile: str,
    availability_profile: str,
    extra_traits: list[str] | None = None,
    omitted_substrates: set[str] | None = None,
    root: Path = ROOT,
    catalog: dict[str, Any] | None = None,
    proof_doc: dict[str, Any] | None = None,
) -> dict[str, Any]:
    catalog_doc = catalog or load_json(root / "arsenal/substrates/catalog.json")
    catalog_view = validate_catalog_data(catalog_doc)
    capabilities = load_capabilities(root)
    proof_bindings = validate_proof_data(
        proof_doc or load_json(root / "arsenal/substrates/proof-requirements.json"),
        capabilities=capabilities,
        catalog_view=catalog_view,
    )
    profiles = load_authority_profiles(root)

    if capability_id not in capabilities:
        raise AssertionError(f"unknown capability: {capability_id}")
    key = (capability_id, requirement_id)
    if key not in proof_bindings:
        raise AssertionError(f"no ARS-05 proof requirement for {capability_id}/{requirement_id}")
    if authority_profile not in profiles:
        raise AssertionError(f"unknown authority profile: {authority_profile}")
    if availability_profile not in catalog_view["profiles"]:
        raise AssertionError(f"unknown availability profile: {availability_profile}")

    cap = capabilities[capability_id]["capability"]
    proof = dict(proof_bindings[key])
    required_traits = list(proof["required_traits"])
    for trait in extra_traits or []:
        if not TRAIT_RE.fullmatch(trait) or trait.startswith("substrate."):
            raise AssertionError(f"invalid extra proof trait: {trait!r}")
        if trait not in required_traits:
            required_traits.append(trait)
    proof["required_traits"] = required_traits

    all_substrates = sorted(catalog_view["substrates"].values(), key=lambda x: x["reality_rank"])
    evidence_candidates = [s for s in all_substrates if substrate_satisfies(s, proof, catalog_view)]
    base_report = {
        "schema_version": "1.0.0",
        "capability": {"id": cap["id"], "display_name": cap["display_name"], "version": cap["version"]},
        "verification_requirement_id": requirement_id,
        "proof_requirement": {
            "required_traits": required_traits,
            "minimum_isolation": proof["minimum_isolation"],
            "minimum_reproducibility": proof["minimum_reproducibility"],
        },
        "authority_profile": authority_profile,
        "availability_profile": availability_profile,
    }

    if not evidence_candidates:
        return {**base_report, "verdict": "EVIDENCE_GAP", "selected": None, "reason": "no known substrate can establish the required proof properties", "candidate": None}

    allowed_surfaces = set(cap["execution"]["allowed"])
    prohibited_surfaces = set(cap["execution"]["prohibited"])
    legal_candidates = [
        s for s in evidence_candidates
        if s["execution_surface"] in allowed_surfaces and s["execution_surface"] not in prohibited_surfaces
    ]
    if not legal_candidates:
        candidate = evidence_candidates[0]
        return {
            **base_report,
            "verdict": "ESCALATION_REQUIRED",
            "selected": None,
            "reason": f"lowest proof-sufficient substrate {candidate['id']} is outside the capability execution contract",
            "candidate": summarize_candidate(candidate, profiles[authority_profile], cap),
        }

    automatic = [s for s in legal_candidates if s["selection_mode"] == "automatic"]
    explicit = [s for s in legal_candidates if s["selection_mode"] == "explicit-only"]
    availability = set(catalog_view["profiles"][availability_profile]) - (omitted_substrates or set())

    available_automatic = [s for s in automatic if s["id"] in availability]
    if available_automatic:
        grants = profiles[authority_profile]
        authorized: list[dict[str, Any]] = []
        unauthorized: list[tuple[dict[str, Any], list[str]]] = []
        for item in available_automatic:
            required_authority = set(cap["authority"]["required"]) | set(item["required_authority"])
            missing = sorted(required_authority - grants)
            if missing:
                unauthorized.append((item, missing))
            else:
                authorized.append(item)
        if authorized:
            selected = authorized[0]
            return {
                **base_report,
                "verdict": "SELECTED",
                "selected": {
                    "id": selected["id"],
                    "display_name": selected["display_name"],
                    "reality_rank": selected["reality_rank"],
                    "execution_surface": selected["execution_surface"],
                    "isolation": selected["isolation"],
                    "reproducibility": selected["reproducibility"],
                    "earned_traits": sorted(set(required_traits) & set(selected["traits"])),
                    "limitations": selected["limitations"],
                    "next_escalation": selected["escalation_to"],
                },
                "reason": "lowest available, legal, authorized substrate that can establish the required proof",
                "candidate": None,
            }
        item, missing = unauthorized[0]
        return {
            **base_report,
            "verdict": "AUTHORITY_GAP",
            "selected": None,
            "reason": f"lowest available proof-sufficient substrate lacks authority: {', '.join(missing)}",
            "candidate": summarize_candidate(item, grants, cap),
        }

    if automatic:
        candidate = automatic[0]
        return {
            **base_report,
            "verdict": "SUBSTRATE_GAP",
            "selected": None,
            "reason": f"proof-sufficient automatic substrate is not declared available in profile {availability_profile}",
            "candidate": summarize_candidate(candidate, profiles[authority_profile], cap),
        }

    if explicit:
        candidate = explicit[0]
        return {
            **base_report,
            "verdict": "ESCALATION_REQUIRED",
            "selected": None,
            "reason": f"required proof begins at explicit-only substrate {candidate['id']}",
            "candidate": summarize_candidate(candidate, profiles[authority_profile], cap),
        }

    return {**base_report, "verdict": "UNKNOWN", "selected": None, "reason": "proof candidates could not be classified safely", "candidate": None}


def summarize_candidate(item: dict[str, Any], grants: set[str], cap: dict[str, Any]) -> dict[str, Any]:
    required = set(cap["authority"]["required"]) | set(item["required_authority"])
    return {
        "id": item["id"],
        "display_name": item["display_name"],
        "reality_rank": item["reality_rank"],
        "execution_surface": item["execution_surface"],
        "selection_mode": item["selection_mode"],
        "missing_authority": sorted(required - grants),
        "capability_allows_surface": item["execution_surface"] in set(cap["execution"]["allowed"]) and item["execution_surface"] not in set(cap["execution"]["prohibited"]),
        "limitations": item["limitations"],
    }


def render_report(report: dict[str, Any]) -> str:
    lines = [
        f"Reality Budget: {report['verdict']}",
        f"capability: {report['capability']['id']} — {report['capability']['display_name']}",
        f"verification requirement: {report['verification_requirement_id']}",
        f"authority profile: {report['authority_profile']}",
        f"availability profile: {report['availability_profile']}",
        "required proof traits: " + ", ".join(report["proof_requirement"]["required_traits"]),
        f"reason: {report['reason']}",
    ]
    selected = report.get("selected")
    if selected:
        lines.extend([
            "",
            f"selected: {selected['id']} — {selected['display_name']}",
            f"reality rank: {selected['reality_rank']}",
            f"execution surface: {selected['execution_surface']}",
            f"isolation/reproducibility: {selected['isolation']} / {selected['reproducibility']}",
            "earned traits: " + ", ".join(selected["earned_traits"]),
            "limitations:",
        ])
        lines.extend(f"  - {item}" for item in selected["limitations"])
        if selected.get("next_escalation"):
            lines.append(f"next declared escalation: {selected['next_escalation']}")
    candidate = report.get("candidate")
    if candidate:
        lines.extend([
            "",
            f"candidate: {candidate['id']} — {candidate['display_name']}",
            f"reality rank: {candidate['reality_rank']}",
            f"selection mode: {candidate['selection_mode']}",
            f"capability allows surface: {str(candidate['capability_allows_surface']).lower()}",
        ])
        if candidate["missing_authority"]:
            lines.append("missing authority: " + ", ".join(candidate["missing_authority"]))
    return "\n".join(lines)


def explain(capability_id: str, requirement_id: str) -> None:
    catalog = load_json(CATALOG_PATH)
    view = validate_catalog_data(catalog)
    capabilities = load_capabilities(ROOT)
    bindings = validate_proof_data(load_json(PROOF_PATH), capabilities=capabilities, catalog_view=view)
    key = (capability_id, requirement_id)
    if key not in bindings:
        raise AssertionError(f"no proof binding for {capability_id}/{requirement_id}")
    proof = bindings[key]
    print(f"{proof['id']}")
    print(f"capability: {capability_id}")
    print(f"verification requirement: {requirement_id}")
    print("required traits: " + ", ".join(proof["required_traits"]))
    print(f"minimum isolation: {proof['minimum_isolation']}")
    print(f"minimum reproducibility: {proof['minimum_reproducibility']}")
    print("\nProof-sufficient catalog substrates:")
    for item in sorted(view["substrates"].values(), key=lambda x: x["reality_rank"]):
        if substrate_satisfies(item, proof, view):
            print(f"  {item['reality_rank']:>2} {item['id']} [{item['selection_mode']}] -> {item['execution_surface']}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("validate")
    explain_parser = sub.add_parser("explain")
    explain_parser.add_argument("--capability", required=True)
    explain_parser.add_argument("--requirement", required=True)
    select_parser = sub.add_parser("select")
    select_parser.add_argument("--capability", required=True)
    select_parser.add_argument("--requirement", required=True)
    select_parser.add_argument("--authority-profile", required=True)
    select_parser.add_argument("--availability-profile", required=True)
    select_parser.add_argument("--require-trait", action="append", default=[])
    select_parser.add_argument("--omit-substrate", action="append", default=[])
    select_parser.add_argument("--json", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    if args.command == "validate":
        catalog_view = validate_catalog_data(load_json(CATALOG_PATH))
        capabilities = load_capabilities(ROOT)
        bindings = validate_proof_data(load_json(PROOF_PATH), capabilities=capabilities, catalog_view=catalog_view)
        print(
            "Execution Substrate contract: PASS "
            f"({len(catalog_view['substrates'])} substrates; "
            f"{len(catalog_view['profiles'])} availability profiles; "
            f"{len(bindings)} proof requirements)"
        )
        return 0
    if args.command == "explain":
        explain(args.capability, args.requirement)
        return 0

    report = select_substrate(
        args.capability,
        args.requirement,
        authority_profile=args.authority_profile,
        availability_profile=args.availability_profile,
        extra_traits=args.require_trait,
        omitted_substrates=set(args.omit_substrate),
    )
    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(render_report(report))
    return EXIT_CODES[report["verdict"]]


if __name__ == "__main__":
    raise SystemExit(main())
