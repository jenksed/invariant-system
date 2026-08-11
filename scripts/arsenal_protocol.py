"""Canonical Project Arsenal protocol vocabulary.

This module is the single source of truth for Arsenal's contract
vocabulary. Every domain validator, compiler check, and bench assertion
imports from here so a new authority token or substrate cannot be added
in one place and missed in another.

These values are NOT consumer configuration. They are Arsenal protocol.
`arsenal.project.json` cannot redefine them. The Capability Contract
schema (`arsenal/capability.schema.json`) and the Capability Contract
markdown (`arsenal/CAPABILITY_CONTRACT.md`) are aligned with the
vocabularies below.
"""

from __future__ import annotations

# Arsenal Capability Contract schema versions.
# Bump CAPABILITY_SCHEMA_VERSION when an incompatible change lands.
# CAPABILITY_SCHEMA_LEGACY are still accepted by capability_audit.py.
CAPABILITY_SCHEMA_VERSION = "2.2.0"
CAPABILITY_SCHEMA_LEGACY = frozenset({"2.0.0", "2.1.0"})
ASSET_SCHEMA_VERSION = "1.0.0"
LOCK_SCHEMA_VERSION = "1.0.0"
SUITE_SCHEMA_VERSION = "1.0.0"
COMPILER_VERSION = "0.1.0"

# Capability lifecycle states. A capability moves through these as
# evidence accumulates; see arsenal/CAPABILITY_CONTRACT.md.
LIFECYCLE_STATES = frozenset({"draft", "testing", "stable", "deprecated"})

# Evaluation states for capabilities. Distinct from adapter
# qualification (which is recorded separately in distribution_qualification).
EVALUATION_STATES = frozenset({"unassessed", "planned", "candidate", "qualified"})

# Distribution-qualification states. Independent of capability lifecycle.
DISTRIBUTION_QUALIFICATION_STATES = frozenset({"unassessed", "candidate", "qualified"})

# Invocation semantics a capability declares. The compiler refuses
# exports where the target adapter cannot preserve the declared
# invocation boundary.
INVOCATIONS = frozenset({"human", "agent", "composed"})

# Mutation classes for capabilities. Read-only capabilities must not
# carry write authority.
MUTATION_CLASSES = frozenset(
    {"read-only", "workspace-write", "external-write", "high-consequence"}
)

# Authority vocabulary. Closed set; values are part of Arsenal
# protocol and must not be redefined by project configuration.
AUTHORITY = frozenset(
    {
        "filesystem.read", "filesystem.write", "shell.execute",
        "network.read", "network.write", "git.read", "git.write",
        "tracker.read", "tracker.write", "secrets.read",
        "cloud.local", "cloud.remote", "production.mutate",
        "human.confirmation",
    }
)
WRITE_AUTHORITY = frozenset(
    {
        "filesystem.write", "network.write", "git.write", "tracker.write",
        "cloud.local", "cloud.remote", "production.mutate",
    }
)

# Execution substrate vocabulary. Capabilities declare preferred,
# allowed, and prohibited substrates from this closed set.
SUBSTRATES = frozenset(
    {
        "reasoning-only", "repository-read", "local-process",
        "local-container", "local-emulator", "local-cluster",
        "remote-sandbox", "shared-nonproduction", "staging",
        "production", "user-mediated",
    }
)
# Substrates that a capability must explicitly opt into because they
# carry blast radius. The substrate selector refuses to surface them
# unless the capability calls them out as preferred or allowed.
EXPLICIT_ONLY_SUBSTRATES = frozenset(
    {"remote-sandbox", "shared-nonproduction", "staging", "production"}
)

# Resource roles and load policies (Capability Contract 2.2).
RESOURCE_ROLES = frozenset(
    {"instructions", "reference", "script", "template", "fixture", "asset"}
)
RESOURCE_LOADS = frozenset({"always", "on-demand", "execute-not-read"})
# Readable roles (model reads the content) cannot be execute-only.
READABLE_ROLES = frozenset({"instructions", "reference", "template"})
# Executable roles (runtime invokes rather than reads) cannot be
# always-loaded.
EXECUTABLE_ROLES = frozenset({"script", "fixture", "asset"})

# Distribution-qualification axes. Bench cases must declare one of these.
DISTRIBUTION_AXES = frozenset(
    {"activation", "behavioral_efficacy", "boundary_preservation", "context_efficiency"}
)

# Distribution-qualification execution modes.
DISTRIBUTION_EXECUTION_MODES = frozenset(
    {"distribution-structural", "distribution-collision", "distribution-behavioral"}
)
EXECUTION_STATUS = frozenset({"designed-not-run", "executable"})
EXECUTION_MODES = frozenset({"agent-control-treatment", "local-cloud-router", "local-cloud-runtime"})

# Bench health checks for case fitness. Distinct from execution evidence.
CASE_HEALTH_CHECKS = frozenset(
    {
        "starting_state_reproducible",
        "failure_reachable",
        "success_reachable",
        "acceptance_observable",
        "expected_outcome_explicit",
        "solution_not_leaked",
        "verifier_independent",
        "no_remote_credentials",
    }
)
COMPARISONS = frozenset({"control-treatment", "ablation", "multi-arm", "contract-counterfactual"})

# Dangerous authority profile grants the Capability Graph explicitly
# refuses under read-only authority profiles.
DANGEROUS_AUTHORITY = frozenset(
    {"secrets.read", "cloud.remote", "production.mutate", "network.write"}
)

# Exit codes are stable per CLI: domain scripts must agree on these
# so callers (CI, other tools) can branch on the outcome. Each CLI
# documents its codes at the top of its main() function.
EXIT_CODE = {
    "READY": 0,
    "PASS": 0,
    "CAPABILITY_GAP": 3,
    "AUTHORITY_GAP": 4,
    "QUALIFICATION_GAP": 5,
    "SUBSTRATE_GAP": 5,
    "ESCALATION_REQUIRED": 6,
    "EVIDENCE_GAP": 7,
    "UNKNOWN": 8,
}

# Documented soft limit for always-loaded instructions content in
# generated adapter bodies. Limits are policy, not external contract.
# Per-target overrides can be added later without changing this
# canonical default.
DEFAULT_ALWAYS_LOADED_SOFT_LIMIT_BYTES = 32_768