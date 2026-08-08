#!/usr/bin/env python3
"""Map an explicit local-cloud work kind to an existing Arsenal capability.

Provider detection remains delegated to the FLC-04 deterministic provider resolver.
This script intentionally does not infer natural-language task kind.
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

ROUTES = {
    "feature": {
        "primary": "workflows/floci_first_cloud_feature_delivery.md",
        "support": [
            "agent_workflows/repository_truth_audit.md",
            "agent_workflows/route_local_cloud_provider.md",
            "software_engineering/work_to_tracer_tickets.md",
            "software_engineering/tdd_vertical_slice.md",
            "software_engineering/code_review_multi_axis.md",
            "agent_workflows/independent_verification_and_receipts.md",
            "agent_workflows/session_handoff_and_continuation.md",
        ],
    },
    "iac": {
        "primary": "agent_workflows/validate_iac_with_floci.md",
        "support": [
            "agent_workflows/repository_truth_audit.md",
            "agent_workflows/route_local_cloud_provider.md",
            "agent_workflows/independent_verification_and_receipts.md",
            "agent_workflows/session_handoff_and_continuation.md",
        ],
    },
    "migration": {
        "primary": "agent_workflows/migrate_localstack_to_floci.md",
        "support": [
            "agent_workflows/repository_truth_audit.md",
            "agent_workflows/route_local_cloud_provider.md",
            "agent_workflows/independent_verification_and_receipts.md",
            "agent_workflows/session_handoff_and_continuation.md",
        ],
    },
    "bug": {
        "primary": "agent_workflows/reproduce_cloud_bug_locally.md",
        "support": [
            "software_engineering/diagnose_bug_feedback_loop.md",
            "agent_workflows/diagnose_floci_environment.md",
            "agent_workflows/audit_floci_fidelity_gap.md",
            "agent_workflows/independent_verification_and_receipts.md",
            "agent_workflows/session_handoff_and_continuation.md",
        ],
    },
    "environment": {
        "primary": "agent_workflows/diagnose_floci_environment.md",
        "support": [
            "agent_workflows/route_local_cloud_provider.md",
            "agent_workflows/audit_floci_fidelity_gap.md",
            "agent_workflows/session_handoff_and_continuation.md",
        ],
    },
    "fidelity": {
        "primary": "agent_workflows/audit_floci_fidelity_gap.md",
        "support": [
            "foundations/cloud_fidelity_ledger.md",
            "foundations/cloud_execution_boundary.md",
            "agent_workflows/independent_verification_and_receipts.md",
        ],
    },
    "review": {
        "primary": "software_engineering/code_review_multi_axis.md",
        "support": [
            "agent_workflows/route_local_cloud_provider.md",
            "engineering/development_packs/floci/FIDELITY_POLICY.md",
            "agent_workflows/independent_verification_and_receipts.md",
        ],
    },
    "provider-proof": {
        "primary": "foundations/cloud_execution_boundary.md",
        "support": [
            "agent_workflows/audit_floci_fidelity_gap.md",
            "agent_workflows/independent_verification_and_receipts.md",
            "software_engineering/human_setup_wizard.md",
        ],
        "escalation_required": True,
    },
}


def provider_result(repo: Path, provider: str | None) -> tuple[dict, int]:
    resolver = Path(__file__).with_name("resolve-provider")
    cmd = [str(resolver), str(repo), "--format", "json"]
    if provider:
        cmd.extend(["--provider", provider])
    proc = subprocess.run(cmd, text=True, capture_output=True, check=False)
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise RuntimeError(
            f"provider resolver returned invalid JSON (rc={proc.returncode}): {proc.stdout!r} {proc.stderr!r}"
        )
    return data, proc.returncode


def build_route(repo: Path, task_kind: str, provider: str | None) -> tuple[dict, int]:
    detected, rc = provider_result(repo, provider)
    if rc in (3, 4):
        return {
            "status": detected["confidence"].upper(),
            "task_kind": task_kind,
            "provider": None,
            "provider_confidence": detected["confidence"],
            "provider_pack": None,
            "provider_evidence": detected["evidence"],
            "primary": None,
            "support": [],
            "execution_boundary": "unresolved",
            "automatic_real_cloud_fallback": False,
            "requires_explicit_real_cloud_authorization": True,
        }, rc
    if rc != 0:
        raise RuntimeError(f"unexpected provider resolver exit code: {rc}")

    route = ROUTES[task_kind]
    escalation = bool(route.get("escalation_required"))
    result = {
        "status": "ESCALATION_REVIEW" if escalation else "ROUTED",
        "task_kind": task_kind,
        "provider": detected["provider"],
        "provider_confidence": detected["confidence"],
        "provider_pack": detected["pack"],
        "provider_evidence": detected["evidence"],
        "primary": route["primary"],
        "support": route["support"],
        "execution_boundary": "explicit-provider-review" if escalation else "local-first",
        "automatic_real_cloud_fallback": False,
        "requires_explicit_real_cloud_authorization": True,
    }
    return result, 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=".")
    parser.add_argument("--task-kind", required=True, choices=sorted(ROUTES))
    parser.add_argument("--provider", choices=("aws", "azure", "gcp", "oci"))
    parser.add_argument("--format", choices=("json", "text"), default="text")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        parser.error(f"repo is not a directory: {repo}")

    result, rc = build_route(repo, args.task_kind, args.provider)
    if args.format == "json":
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        if result["status"] in {"AMBIGUOUS", "UNKNOWN"}:
            print(result["status"])
        else:
            print(
                f"{result['status']}\t{result['task_kind']}\t{result['provider']}\t"
                f"{result['primary']}\t{result['provider_pack']}"
            )
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
