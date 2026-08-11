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
    """The loader resolves the schema through the registry AND enforces
    the schema's closed-shape contract on the source-model instance.

    This test now covers both: the loader must be able to load the
    schema document, AND loading must succeed for the canonical
    source model. If the loader is bypassed or the schema drifts
    from the runtime enforcement, this test fails.
    """
    model = _model()
    assert model["schema_version"] == arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST
    assert model["schema_document"]["$id"].endswith(
        f"governance-source-model-{arsenal_governance.SOURCE_MODEL_SCHEMA_VERSION_CONST}.json"
    )
    # Coherence: every key on every artifact in the loaded model is
    # in the loader's closed-shape set. If a future schema drift
    # introduces a new field, this assertion fails until both the
    # schema and ALLOWED_ARTIFACT_KEYS are updated together.
    for art in model["artifacts"]:
        extra = sorted(set(art) - arsenal_source_model.ALLOWED_ARTIFACT_KEYS)
        assert not extra, (
            f"artifact {art['id']!r} has key(s) {extra} not in "
            f"loader-allowed set {sorted(arsenal_source_model.ALLOWED_ARTIFACT_KEYS)}; "
            f"schema and loader closed-shape are out of sync"
        )
    for fact in model["facts"]:
        extra = sorted(set(fact) - arsenal_source_model.ALLOWED_FACT_KEYS)
        assert not extra, (
            f"fact {fact['id']!r} has key(s) {extra} not in "
            f"loader-allowed set {sorted(arsenal_source_model.ALLOWED_FACT_KEYS)}; "
            f"schema and loader closed-shape are out of sync"
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


def test_each_fact_has_exactly_one_owner() -> None:
    """Every fact has exactly one owning artifact. The artifact's
    state_role tells us whether the fact is normative, derived,
    historical, or narrative; the model intentionally has facts owned
    by derived artifacts (e.g. distribution.skill-snapshot) and
    historical artifacts (e.g. qualification-receipt.qualification-verdict),
    so the invariant is "one owner" -- not "one normative owner".
    """
    owners: dict[str, str] = {}
    for fact in _model()["facts"]:
        assert "owner_artifact" in fact, f"fact {fact.get('id')!r} missing owner_artifact"
        prev = owners.get(fact["id"])
        if prev is not None and prev != fact["owner_artifact"]:
            raise AssertionError(
                f"fact {fact['id']!r} has conflicting owners: {prev!r} and {fact['owner_artifact']!r}"
            )
        owners[fact["id"]] = fact["owner_artifact"]


def test_state_role_qualifies_each_fact_owner() -> None:
    """For each fact, the owning artifact's state_role tells us what
    kind of representation the fact is. A historical artifact owns
    historical facts (the value is provenance); a derived artifact
    owns derived facts (drift is a bug); only normative artifacts
    own normative facts.
    """
    artifacts_by_id = {a["id"]: a for a in _model()["artifacts"]}
    for fact in _model()["facts"]:
        owner = artifacts_by_id.get(fact["owner_artifact"])
        assert owner is not None, f"fact {fact['id']!r}: owner missing"
        # Sanity: each owner has a state_role on the closed vocabulary.
        assert owner["state_role"] in arsenal_governance.STATE_ROLES


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

    The sandbox mirrors enough of the repository that the validator's
    path-existence and pattern-resolution checks have a real surface
    to evaluate. Without this, "accepted" tests would always fail on
    missing paths even when the mutation is structurally correct.
    """
    with tempfile.TemporaryDirectory() as tmp:
        sandbox = Path(tmp) / "sandbox"
        sandbox.mkdir()
        # Mirror the subtrees the validator inspects via path and
        # path_pattern entries on the source-model artifacts.
        for sub in ("arsenal", "scripts", "distribution", "evaluation",
                    "docs", "engineering"):
            src = ROOT / sub
            if src.is_dir():
                shutil.copytree(src, sandbox / sub)
        # Top-level files referenced by the source model.
        for top in ("arsenal.project.json", ".arsenal.lock"):
            src = ROOT / top
            if src.is_file():
                shutil.copy2(src, sandbox / top)
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


def test_two_owners_for_one_fact_rejected() -> None:
    """Two facts with the same id but different owners are rejected:
    each fact has exactly one owner, period. The artifact's state_role
    qualifies what kind of fact it is; "normative" is not the qualifier.
    """
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
    assert "duplicate fact id" in err or "more than one owner" in err


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
    """The loader, not just the validator, must reject forbidden value keys.

    After the surgical repair, the closed-shape check fires first
    (the key is unknown) and the diagnostic blacklist fires only when
    the unknown-key check does not. Either message indicates a correct
    rejection; the loader is now the structural fail-closed boundary.
    """
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["supported_targets"] = ["agent-skills"]
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "value-shaped" in err or "unknown key" in err


# --- Regression suite for the pre-repair fail-closed gap ---
#
# Before the GC01 surgical repair, the loader's structural defense
# was a finite blacklist (FORBIDDEN_ARTIFACT_VALUE_KEYS). Any unknown
# key NOT in that list bypassed the anti-duplication guard. These
# tests prove the loader now rejects EVERY unknown structural key,
# regardless of whether it was anticipated.


def test_arbitrary_unknown_artifact_key_rejected() -> None:
    """An artifact entry carrying an arbitrary unanticipated key
    (e.g. ``current_status`` -- a key that does NOT appear in
    FORBIDDEN_ARTIFACT_VALUE_KEYS) must be rejected by the loader.

    This is the headline regression: it would have PASSED at head
    b7acaf2a1dc828ec25321d8fb6d8bad410bb7a05 and FAILS after the
    surgical repair that closes the structural shape.
    """
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["current_status"] = "qualified"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown" in err and "current_status" in err


def test_arbitrary_unknown_artifact_key_unanticipated_name_rejected() -> None:
    """A completely unanticipated artifact key (``banana``) is also
    rejected. The closed shape must not be a whitelist of plausible
    governance names.
    """
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["banana"] = "split"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown" in err and "banana" in err


def test_arbitrary_unknown_fact_key_rejected() -> None:
    """An unknown fact key (e.g. ``cached_value``) is rejected.

    The model is closed-shape at every record type.
    """
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["facts"][0]["cached_value"] = "whatever"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown" in err and "cached_value" in err


def test_arbitrary_unknown_fact_key_unanticipated_name_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["facts"][0]["current_value"] = "qualified"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown" in err and "current_value" in err


def test_arbitrary_unknown_top_level_key_rejected() -> None:
    """An unknown top-level key (e.g. ``operational_state``) is rejected."""
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["operational_state"] = {}
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown" in err and "operational_state" in err


def test_arbitrary_unknown_top_level_key_runtime_state_rejected() -> None:
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["runtime_state"] = {"qualified": True}
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "unknown" in err and "runtime_state" in err


def test_path_pattern_only_artifact_accepted() -> None:
    """A source model whose artifacts use ``path_pattern`` (and never
    declare ``path``) must validate. Before the schema/loader repair
    this would have failed because the artifact's required-set
    unconditionally required ``path``.
    """
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        for art in data["artifacts"]:
            if "path" in art and "path_pattern" not in art:
                art.pop("path", None)
                # Use the existing arsenal/capabilities/* family as
                # the path_pattern target -- it always exists in
                # this repo.
                art["path_pattern"] = "arsenal/capabilities/*.json"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc == 0, f"path_pattern-only artifacts must validate: {err}"


def test_path_only_artifact_accepted() -> None:
    """A source model whose artifacts use ``path`` (and never declare
    ``path_pattern``) must validate. The committed canonical source
    model is mostly this shape.
    """
    baseline = arsenal_source_model.load_source_model(ROOT)
    rc, err = _mutate_and_validate(lambda _sandbox: None)
    assert rc == 0, f"baseline path-only artifacts must validate: {err}"
    assert all("path" in a for a in baseline["artifacts"] if "path_pattern" not in a)


def test_both_path_and_path_pattern_rejected() -> None:
    """An artifact declaring BOTH ``path`` and ``path_pattern`` is
    rejected. XOR is enforced.
    """
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0]["path_pattern"] = "arsenal/capabilities/*.json"
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "path" in err and "path_pattern" in err


def test_neither_path_nor_path_pattern_rejected() -> None:
    """An artifact declaring NEITHER ``path`` nor ``path_pattern`` is rejected."""
    def mutate(sandbox: Path) -> None:
        data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
        data["artifacts"][0].pop("path", None)
        (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
    rc, err = _mutate_and_validate(mutate)
    assert rc != 0
    assert "path" in err and "path_pattern" in err


def test_loader_and_validator_agree_on_distribution_skill_pattern() -> None:
    """Before the repair, ``distribution/agent-skills/*`` resolved to
    an empty list via ``resolve_pattern`` (it matched directories, not
    files) while the validator's ``_check_paths`` accepted the same
    glob as a valid non-empty match. After the repair, the loader
    returns the directories, and the validator's path check still
    passes -- they agree.
    """
    artifact = next(
        a for a in arsenal_source_model.load_source_model(ROOT)["artifacts"]
        if a["id"] == "arsenal.distribution.skill"
    )
    assert "path_pattern" in artifact
    resolved = arsenal_source_model.resolve_pattern(artifact, ROOT)
    assert resolved, (
        f"loader resolved empty for {artifact['path_pattern']!r}; "
        f"validator would have accepted the same glob -- mismatch"
    )
    assert all(p.is_dir() for p in resolved), (
        "distribution/agent-skills/* is a directory-family pattern; "
        "loader and validator must both treat it as non-empty"
    )
    # The validator must agree: no path-existence errors for this artifact.
    errors = arsenal_source_validate.validate_source_model(ROOT)
    bad = [e for e in errors if "arsenal.distribution.skill" in e]
    assert not bad, f"validator disagreed with loader: {bad}"


def test_forbidden_artifact_value_keys_still_rejected() -> None:
    """The diagnostic-only blacklist still produces a sharp error for
    known domain-value-shaped keys (``schema_version``, ``value``,
    ``adapter_version``) when they would NOT already be caught by
    closed-shape. The closed-shape check above is the real boundary;
    this check ensures the diagnostic messages remain for keys that
    pass closed-shape but are still value-shaped.

    Note: ``schema_version`` and ``value`` ARE caught by closed-shape
    (they are not in ALLOWED_ARTIFACT_KEYS), so the message is
    "unknown key". ``adapter_version`` is also not in the allowed set.
    The test therefore asserts either message: both are correct
    rejections of a key that should never appear on an artifact.
    """
    for key in ("schema_version", "value", "adapter_version"):
        def mutate(sandbox: Path, _key=key) -> None:
            data = json.loads((sandbox / "arsenal" / "source-model.json").read_text())
            data["artifacts"][0][_key] = "9.9.9"
            (sandbox / "arsenal" / "source-model.json").write_text(json.dumps(data))
        rc, err = _mutate_and_validate(mutate)
        assert rc != 0, f"key {key!r} should be rejected"
        assert "value-shaped" in err or "unknown key" in err, (
            f"expected 'value-shaped' or 'unknown key' diagnostic for {key!r}; got: {err}"
        )


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
