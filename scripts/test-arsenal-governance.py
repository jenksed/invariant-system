#!/usr/bin/env python3
"""Characterization and adversarial tests for the governance slice.

These tests prove the canonical governance vocabulary is closed, the
source model is not a duplicate copy of domain values, the loader and
validator fail closed on the documented invariants, and at least one
``generated + normative`` and one ``generated + historical``
classification is currently registered.

They follow the same standalone-script style as
``test-arsenal-shared.py``: each test is a plain function; the
``main()`` function walks ``globals()`` and runs them in sorted order.
"""

from __future__ import annotations

import copy
import json
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import arsenal_governance  # noqa: E402
import arsenal_schema_registry  # noqa: E402
import arsenal_source_model  # noqa: E402
import arsenal_source_validate  # noqa: E402


def _model() -> dict:
    return arsenal_source_model.load_source_model(ROOT)


def test_governance_vocabulary_is_closed() -> None:
    assert arsenal_governance.STATE_ROLES == frozenset(
        {"normative", "derived", "historical", "narrative"}
    )
    assert arsenal_governance.OWNERSHIP_LAYERS == frozenset(
        {"arsenal-protocol", "arsenal-distribution", "consumer-deployed"}
    )
    assert arsenal_governance.MATERIALIZATION_MODES == frozenset(
        {"authored", "generated"}
    )


def test_schema_registry_lists_source_model_schema() -> None:
    arsenal_schema_registry.schema_id_for(
        ROOT, arsenal_governance.SOURCE_MODEL_SCHEMA_NAME
    )


def test_source_model_loads_against_canonical_schema() -> None:
    model = _model()
    assert model["schema_version"] == arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST
    assert model["schema_document"]["$id"].endswith(
        f"governance-source-model-{arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST}.json"
    )


def test_lockfile_is_generated_normative() -> None:
    """The competence lockfile is a canonical generated-but-normative
    counter-example: produced by the compiler, but owned and accepted
    by the consumer installation.
    """
    lock = next(a for a in _model()["artifacts"] if a["id"] == "arsenal.competence-lockfile")
    assert lock["state_role"] == "normative"
    assert lock["materialization"] == "generated"
    assert lock["ownership"] == "consumer-deployed"
    # The lockfile owns PINNED facts, not canonical capability facts.
    # Its fact IDs are prefixed lockfile.pinned-* so they cannot collide
    # with capability.current-* owned by the fragment.
    forbidden = [f for f in lock["owns_facts"] if not f.startswith("lockfile.")]
    assert not forbidden, (
        f"lockfile must not own non-pinned facts: {forbidden}"
    )


def test_capability_lifecycle_owner_is_fragment_not_lockfile() -> None:
    """The current capability lifecycle is owned by the canonical
    capability fragment. The lockfile owns a PIN of the lifecycle at
    compile time. These are distinct facts and must have distinct
    owners; otherwise the lockfile would be a duplicate normative
    owner of the current lifecycle.
    """
    artifacts_by_id = {a["id"]: a for a in _model()["artifacts"]}
    fragment = artifacts_by_id["arsenal.capability-fragments"]
    lockfile = artifacts_by_id["arsenal.competence-lockfile"]
    fact_by_id = {f["id"]: f for f in _model()["facts"]}
    assert fact_by_id["capability.current-lifecycle"]["owner_artifact"] == "arsenal.capability-fragments"
    assert fact_by_id["lockfile.pinned-capability-lifecycle"]["owner_artifact"] == "arsenal.competence-lockfile"
    # Both fragments (the family artifact) and the lockfile are present.
    assert "capability.current-lifecycle" in fragment["owns_facts"]
    assert "lockfile.pinned-capability-lifecycle" in lockfile["owns_facts"]
    assert "lockfile.pinned-capability-lifecycle" not in fragment["owns_facts"]
    assert "capability.current-lifecycle" not in lockfile["owns_facts"]


def test_qualification_receipt_is_generated_historical() -> None:
    """A qualification receipt is a canonical generated-but-historical
    counter-example: it is Project Arsenal's own qualification
    evidence for its own distributed packages.
    """
    receipts = next(
        a for a in _model()["artifacts"]
        if a["id"] == "arsenal.bench.distribution-qualification-receipt"
    )
    assert receipts["state_role"] == "historical"
    assert receipts["materialization"] == "generated"
    assert receipts["ownership"] == "arsenal-distribution"
    # The receipt owns its own historical subject-binding; it does
    # NOT redefine the canonical capability identity.
    bad = [f for f in receipts["owns_facts"] if f in {"capability.identity", "capability.current-lifecycle"}]
    assert not bad, f"receipt must not own canonical capability facts: {bad}"


def test_skill_package_is_generated_derived() -> None:
    pkg = next(
        a for a in _model()["artifacts"] if a["id"] == "arsenal.distribution.skill"
    )
    assert pkg["state_role"] == "derived"
    assert pkg["materialization"] == "generated"
    assert pkg["ownership"] == "arsenal-distribution"


def test_canonical_artifact_classifications() -> None:
    """Sanity check the key load-bearing artifacts we expect to be
    registered.
    """
    ids = {a["id"] for a in _model()["artifacts"]}
    expected = {
        "arsenal.protocol",
        "arsenal.governance-vocabulary",
        "arsenal.capability-fragment-schema",
        "arsenal.competence-lock-schema",
        "arsenal.distribution.compiler.targets",
        "arsenal.distribution.schema-registry",
        "arsenal.capability-fragments",
        "arsenal.registry",
        "arsenal.project",
        "arsenal.competence-lockfile",
        "arsenal.distribution.skill",
        "arsenal.bench.case",
        "arsenal.bench.distribution-qualification",
        "arsenal.bench.local-cloud-cases",
        "arsenal.bench.distribution-qualification-receipt",
        "arsenal.knowledge.snapshot-fixture-kft-0",
        "arsenal.field-trial.kft-0-report",
        "arsenal.architecture.doctrine",
        "arsenal.roadmap.post-pr-24",
        "arsenal.governance-source-model",
        "arsenal.governance-source-model-schema",
    }
    missing = expected - ids
    assert not missing, f"expected artifacts not classified: {sorted(missing)}"


def test_canonical_capability_fragments_are_distribution_not_consumer() -> None:
    """Canonical Project Arsenal capability fragments are
    arsenal-distribution, not consumer-deployed. A consumer may
    install/use them but does not redefine them.
    """
    fragments = next(
        a for a in _model()["artifacts"] if a["id"] == "arsenal.capability-fragments"
    )
    assert fragments["ownership"] == "arsenal-distribution", (
        "capability fragments are canonical Project Arsenal content; "
        "consumers do not redefine them"
    )
    assert fragments["state_role"] == "normative"


def test_concrete_evaluation_suites_are_distribution_not_protocol() -> None:
    """The evaluation schemas are protocol; the concrete suite
    instances are arsenal-distribution.
    """
    schemas = next(
        a for a in _model()["artifacts"] if a["id"] == "arsenal.evaluation-case-schema"
    )
    cases = next(
        a for a in _model()["artifacts"] if a["id"] == "arsenal.bench.case"
    )
    dq = next(
        a for a in _model()["artifacts"]
        if a["id"] == "arsenal.bench.distribution-qualification"
    )
    assert schemas["ownership"] == "arsenal-protocol"
    assert cases["ownership"] == "arsenal-distribution"
    assert dq["ownership"] == "arsenal-distribution"


def test_source_model_schema_and_instance_have_distinct_ownership() -> None:
    """The source-model schema is protocol (defines what a valid
    source-model IS). The source-model instance is distribution
    (Project Arsenal's own classification index).
    """
    schema = next(
        a for a in _model()["artifacts"]
        if a["id"] == "arsenal.governance-source-model-schema"
    )
    instance = next(
        a for a in _model()["artifacts"]
        if a["id"] == "arsenal.governance-source-model"
    )
    assert schema["ownership"] == "arsenal-protocol"
    assert instance["ownership"] == "arsenal-distribution"
    # The instance owns facts scoped to this Project Arsenal distribution.
    instance_facts = set(instance["owns_facts"])
    assert "governance.artifact-classification.project-arsenal" in instance_facts
    assert "governance.source-assignment.project-arsenal" in instance_facts


def test_kft0_evidence_is_distribution_even_though_subject_is_external() -> None:
    """Field-trial evidence about Kiln is owned by Project Arsenal,
    not by the consumer whose repository was the trial subject.
    Ownership is about who may define/revise, not about who the
    subject is.
    """
    fixture = next(
        a for a in _model()["artifacts"]
        if a["id"] == "arsenal.knowledge.snapshot-fixture-kft-0"
    )
    report = next(
        a for a in _model()["artifacts"] if a["id"] == "arsenal.field-trial.kft-0-report"
    )
    assert fixture["ownership"] == "arsenal-distribution"
    assert fixture["state_role"] == "historical"
    assert report["ownership"] == "arsenal-distribution"
    assert report["state_role"] == "historical"


def test_roadmaps_are_distribution_narrative() -> None:
    """Project Arsenal's program roadmaps are arsenal-distribution
    narrative. A consumer does not redefine Project Arsenal's roadmap
    by configuring its installation.
    """
    for aid in ("arsenal.roadmap.post-pr-24", "arsenal.roadmap.capability-system"):
        art = next(a for a in _model()["artifacts"] if a["id"] == aid)
        assert art["ownership"] == "arsenal-distribution"
        assert art["state_role"] == "narrative"


def test_consumer_deployed_is_narrow() -> None:
    """Only arsenal.project.json and the competence lockfile are
    consumer-deployed in this distribution. Adding a third would
    require a deliberate justification; the test catches accidental
    widening.
    """
    consumer_assets = [
        a for a in _model()["artifacts"] if a["ownership"] == "consumer-deployed"
    ]
    consumer_ids = sorted(a["id"] for a in consumer_assets)
    assert consumer_ids == ["arsenal.competence-lockfile", "arsenal.project"], (
        f"unexpected consumer-deployed artifacts: {consumer_ids}; "
        f"widening the consumer-deployed layer requires explicit justification"
    )


def test_each_fact_has_exactly_one_normative_owner() -> None:
    owners: dict[str, str] = {}
    for fact in _model()["facts"]:
        assert "owner_artifact" in fact, f"fact {fact.get('id')!r} missing owner_artifact"
        prev = owners.get(fact["id"])
        if prev is not None and prev != fact["owner_artifact"]:
            raise AssertionError(
                f"fact {fact['id']!r} has conflicting owners: {prev!r} and {fact['owner_artifact']!r}"
            )
        owners[fact["id"]] = fact["owner_artifact"]


def test_consumer_config_does_not_appear_in_arsenal_project() -> None:
    """The model must classify arsenal.project.json as a single
    normative configuration artifact; it must NOT itself be derived
    or historical, and it must NOT be the normative owner of any
    governance fact.
    """
    proj = next(a for a in _model()["artifacts"] if a["id"] == "arsenal.project")
    assert proj["state_role"] == "normative"
    assert proj["ownership"] == "consumer-deployed"
    bad = [f for f in proj["owns_facts"] if f.startswith("governance.")]
    assert not bad, f"arsenal.project must not own governance facts; got {bad}"


def test_canonical_capability_identity_owner_is_fragment() -> None:
    """Canonical capability identity is owned by the fragment family,
    not by a historical receipt.
    """
    fact_by_id = {f["id"]: f for f in _model()["facts"]}
    assert fact_by_id["capability.identity"]["owner_artifact"] == "arsenal.capability-fragments"
    receipt_facts = next(
        a for a in _model()["artifacts"]
        if a["id"] == "arsenal.bench.distribution-qualification-receipt"
    )["owns_facts"]
    assert "capability.identity" not in receipt_facts, (
        "receipt must bind to capability identity, not redefine it"
    )


def test_source_model_does_not_duplicate_domain_values() -> None:
    """Anti-duplication test.

    The source model must NOT carry any of the domain values it
    references; it stores only classification and locator metadata.
    """
    bad = arsenal_source_model.FORBIDDEN_ARTIFACT_VALUE_KEYS
    for art in _model()["artifacts"]:
        leaked = sorted(set(art) & bad)
        assert not leaked, (
            f"artifact {art['id']!r} leaks domain value(s) {leaked}; "
            f"the source model must point at the source rather than copy its value"
        )


def _mutate_and_validate(mutation) -> tuple[int, str]:
    """Apply ``mutation(root)`` to a copy of the source model in a
    tmp tree, run the validator, then return ``(exit_code, stderr)``.
    """
    with tempfile.TemporaryDirectory() as tmp:
        sandbox = Path(tmp) / "sandbox"
        # We only need arsenal/source-model.json + arsenal/source-model.schema.json
        # + arsenal/schema-registry.json for the loader to succeed.
        sandbox.mkdir()
        (sandbox / "arsenal").mkdir()
        shutil.copy2(ROOT / "arsenal" / "source-model.json", sandbox / "arsenal" / "source-model.json")
        shutil.copy2(
            ROOT / "arsenal" / "source-model.schema.json",
            sandbox / "arsenal" / "source-model.schema.json",
        )
        shutil.copy2(
            ROOT / "arsenal" / "schema-registry.json",
            sandbox / "arsenal" / "schema-registry.json",
        )
        mutation(sandbox)
        errors = arsenal_source_validate.validate_source_model(sandbox)
        if errors:
            return 1, "\n".join(errors)
        return 0, ""


def test_unknown_state_role_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["state_role"] = "authoritative"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown state role" in err or "state role" in err


def test_unknown_ownership_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["ownership"] = "external"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "ownership" in err


def test_duplicate_artifact_id_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"].append(copy.deepcopy(data["artifacts"][0]))
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "duplicate artifact id" in err


def test_duplicate_fact_id_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["facts"].append(copy.deepcopy(data["facts"][0]))
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "duplicate fact id" in err


def test_two_normative_owners_for_one_fact_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["facts"].append(
            {
                "id": data["facts"][0]["id"],
                "owner_artifact": data["artifacts"][1]["id"],
                "locator": "alias",
            }
        )
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "duplicate fact id" in err or "more than one normative owner" in err


def test_owner_artifact_must_exist() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["facts"][0]["owner_artifact"] = "nonexistent.artifact"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "not a registered artifact id" in err


def test_pattern_must_be_repository_relative() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        # Inject a path_pattern that escapes the root.
        for art in data["artifacts"]:
            if "path_pattern" in art:
                art["path_pattern"] = "../escape/*.json"
                break
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "traversal" in err or "repository-relative" in err


def test_recursive_glob_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        for art in data["artifacts"]:
            if "path_pattern" in art:
                art["path_pattern"] = "arsenal/**/secrets.json"
                break
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "**" in err or "recursive" in err


def test_domain_value_copy_rejected_by_loader() -> None:
    """The loader, not just the validator, must reject forbidden value keys."""
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["supported_targets"] = ["agent-skills"]
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "value-shaped" in err or "duplicate" in err


def test_consumer_redefines_vocabulary_is_impossible() -> None:
    """The source-model loader imports its closed vocabulary from
    arsenal_governance. There is no path through which
    arsenal.project.json can override it. We prove this by checking
    that the vocabulary is a frozenset imported from the canonical
    module, and that the governance loaders never call the project
    config loader.
    """
    # The vocabulary is a module-level frozenset. Removing this
    # attribute would cause the source-model loader itself to fail.
    assert isinstance(arsenal_governance.STATE_ROLES, frozenset)
    assert isinstance(arsenal_governance.OWNERSHIP_LAYERS, frozenset)
    assert isinstance(arsenal_governance.MATERIALIZATION_MODES, frozenset)
    # The governance loaders must not call load_project_config.
    src_model = (Path(arsenal_source_model.__file__)).read_text()
    src_validate = (Path(arsenal_source_validate.__file__)).read_text()
    for forbidden in ("load_project_config", "PROJECT_CONFIG_PATH"):
        assert forbidden not in src_model, f"loader must not depend on {forbidden}"
        assert forbidden not in src_validate, f"validator must not depend on {forbidden}"


def test_canonical_drift_guard() -> None:
    """A snapshot of the model serialized twice must be byte-equal."""
    a = json.dumps(_model()["artifacts"], sort_keys=True, separators=(",", ":"))
    b = json.dumps(_model()["artifacts"], sort_keys=True, separators=(",", ":"))
    assert a == b
    # And the validator's exit code for an unmodified tree is zero.
    assert arsenal_source_validate.validate_source_model(ROOT) == []


def main() -> int:
    test_names = sorted(n for n in globals() if n.startswith("test_"))
    failures: list[tuple[str, str]] = []
    for name in test_names:
        try:
            globals()[name]()
        except AssertionError as exc:
            failures.append((name, str(exc)))
            print(f"FAIL {name}: {exc}")
        else:
            print(f"PASS {name}")
    if failures:
        print(
            f"governance suite: {len(failures)} failure(s) of {len(test_names)} test(s)",
            file=sys.stderr,
        )
        return 1
    print(f"governance suite: PASS ({len(test_names)} tests)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
