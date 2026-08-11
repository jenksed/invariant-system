"""Distribution target registry loader.

`distribution/compiler/targets.json` describes which targets the
distribution supports and which invocation modes each target can
preserve. This is Arsenal-owned canonical data: the targets registry
file lives in the distribution directory alongside the artifacts it
governs.

A consumer project selects which supported targets to enable via
`arsenal.project.json` -> `distribution.enabled_targets`. Selecting an
unsupported target fails closed at config load time.

The boundary between *supported* and *enabled* is intentional:
supported targets are an Arsenal distribution property; enabled
targets are a consumer deployment property. The two are distinct
ownerships.
"""

from __future__ import annotations

from pathlib import Path

from arsenal_io import load_json
from arsenal_protocol import INVOCATIONS

SUPPORTED_TARGETS_PATH = Path("distribution/compiler/targets.json")
PROJECT_CONFIG_PATH = Path("arsenal.project.json")
PROJECT_CONFIG_VERSION = "1.0.0"


def load_supported_targets(root: Path) -> dict[str, dict]:
    """Load the Arsenal-owned target registry.

    Returns a mapping of target id -> {adapter_version, invocation_support,
    package_name_pattern?, output_subdir?}. Each invocation_support
    value is one of INVOCATIONS.
    """
    if root.is_file():
        path = root
    else:
        path = root / SUPPORTED_TARGETS_PATH
    if not path.is_file():
        raise FileNotFoundError(
            f"missing Arsenal target registry: {path} -- this file is part of "
            f"the Arsenal distribution and must be checked in"
        )
    doc = load_json(path)
    if not isinstance(doc, dict):
        raise ValueError(f"{path}: target registry must be an object")
    targets = doc.get("targets")
    if not isinstance(targets, dict) or not targets:
        raise ValueError(f"{path}: target registry must define 'targets' object")
    out: dict[str, dict] = {}
    for target_id, spec in targets.items():
        if not isinstance(spec, dict):
            raise ValueError(f"{path}: target {target_id!r} must be an object")
        invocation_support = spec.get("invocation_support", [])
        if not isinstance(invocation_support, list) or not invocation_support:
            raise ValueError(
                f"{path}: target {target_id!r} must declare invocation_support as a non-empty list"
            )
        invalid = [i for i in invocation_support if i not in INVOCATIONS]
        if invalid:
            raise ValueError(
                f"{path}: target {target_id!r} declares invalid invocations {invalid}; "
                f"must be subset of {sorted(INVOCATIONS)}"
            )
        adapter_version = spec.get("adapter_version")
        if not isinstance(adapter_version, str) or not adapter_version:
            raise ValueError(f"{path}: target {target_id!r} must declare adapter_version")
        out[target_id] = {
            "adapter_version": adapter_version,
            "invocation_support": frozenset(invocation_support),
            "package_name_pattern": spec.get("package_name_pattern", "[a-z0-9]+(?:-[a-z0-9]+)*"),
            "output_subdir": spec.get("output_subdir", "agent-skills"),
        }
    return out


def load_project_config(root: Path) -> dict:
    """Load the consumer project config.

    Returns a dict with at minimum:
        {"schema_version": str, "project": {"org": str, "repo": str},
         "distribution": {"enabled_targets": [str]}}

    Missing file returns the empty config (no overrides); the caller
    decides whether that's acceptable for the operation. Malformed
    config raises.
    """
    path = root / PROJECT_CONFIG_PATH
    if not path.is_file():
        return {
            "schema_version": PROJECT_CONFIG_VERSION,
            "project": {},
            "distribution": {"enabled_targets": []},
        }
    doc = load_json(path)
    if not isinstance(doc, dict):
        raise ValueError(f"{path}: project config must be an object")
    schema_version = doc.get("schema_version")
    if schema_version != PROJECT_CONFIG_VERSION:
        raise ValueError(
            f"{path}: unsupported project config schema_version {schema_version!r}; "
            f"expected {PROJECT_CONFIG_VERSION!r}"
        )
    project = doc.get("project", {})
    if not isinstance(project, dict):
        raise ValueError(f"{path}: project must be an object")
    distribution = doc.get("distribution", {})
    if not isinstance(distribution, dict):
        raise ValueError(f"{path}: distribution must be an object")
    enabled = distribution.get("enabled_targets", [])
    if not isinstance(enabled, list):
        raise ValueError(f"{path}: distribution.enabled_targets must be a list")
    return doc


def resolve_enabled_targets(root: Path) -> dict[str, dict]:
    """Return the subset of supported targets enabled for this project.

    Raises if the project config enables a target that is not in the
    Arsenal-owned supported registry. This is the only authority for
    "what targets does this project compile for."
    """
    supported = load_supported_targets(root)
    project = load_project_config(root)
    enabled = project.get("distribution", {}).get("enabled_targets", [])
    if not enabled:
        # Default to all supported targets when the project config
        # does not opt in. This preserves existing behavior: a project
        # without arsenal.project.json compiles everything Arsenal
        # ships.
        return supported
    out: dict[str, dict] = {}
    for target_id in enabled:
        if target_id not in supported:
            raise ValueError(
                f"project config enables unsupported target {target_id!r}; "
                f"supported targets: {sorted(supported)}. Consumer configuration "
                f"cannot create unsupported targets; add the target to "
                f"distribution/compiler/targets.json in the Arsenal distribution."
            )
        out[target_id] = supported[target_id]
    return out