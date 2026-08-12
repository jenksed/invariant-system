#!/usr/bin/env python3
"""Positive, negative, transition, determinism, and provenance tests for
``scripts/arsenal_method_record.py``.

Each test mutates one property of the canonical record in an isolated
temporary directory, runs the validator against the mutated copy, and
asserts the documented failure class. The original record is restored
after every test.

Test classes:

  * positive: the canonical record validates;
  * negative: invalid fields are rejected with the documented error;
  * transition: a record cannot claim ``qualified`` unless the
    qualification evidence is consistent with the canonical capability
    state;
  * determinism: two validator invocations produce identical exit
    codes and error messages;
  * provenance: the canonical record_digest matches the
    canonicalization rule.
"""

from __future__ import annotations

import importlib.util
import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "scripts" / "arsenal_method_record.py"
RECORDS_DIR = ROOT / "evaluation" / "method-records"
SCHEMA_PATH = RECORDS_DIR / "qualified-method-record.v0.schema.json"

sys.path.insert(0, str(ROOT / "scripts"))
spec = importlib.util.spec_from_file_location("arsenal_method_record", SCRIPT_PATH)
arm = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(arm)


def _copy_records_to(tmp: Path) -> Path:
    """Copy the records directory (schema + canonical record) into ``tmp``.

    Returns the destination records directory.
    """
    dst = tmp / "method-records"
    dst.mkdir()
    shutil.copy2(SCHEMA_PATH, dst / SCHEMA_PATH.name)
    shutil.copy2(
        RECORDS_DIR / "repository-recon.architecture-anchor.v0.yaml",
        dst / "repository-recon.architecture-anchor.v0.yaml",
    )
    return dst


def _run_validator(records_dir: Path) -> tuple[int, str]:
    """Run the validator's ``main`` against ``records_dir``.

    Returns ``(returncode, stderr)``. The validator imports ROOT-relative
    paths, so we patch ``RECORDS_DIR`` for the duration of the call.
    """
    import arsenal_method_record as arm_inner
    saved = arm_inner.RECORDS_DIR
    arm_inner.RECORDS_DIR = records_dir
    saved_argv = sys.argv
    saved_stderr = sys.stderr
    sys.argv = ["arsenal_method_record"]
    try:
        from io import StringIO
        sys.stderr = StringIO()
        rc = arm_inner.main()
        err = sys.stderr.getvalue()
    finally:
        sys.argv = saved_argv
        sys.stderr = saved_stderr
        arm_inner.RECORDS_DIR = saved
    return rc, err


def test_canonical_record_validates() -> None:
    """The committed record passes the validator with no errors."""
    rc, err = _run_validator(RECORDS_DIR)
    assert rc == 0, f"canonical record failed validation: rc={rc}, err={err!r}"
    assert "PASS" in (err or "") or err == "", f"unexpected stderr: {err!r}"
    print("PASS positive case: canonical record validates")


def test_missing_records_dir_fails() -> None:
    """When the records dir is missing, the validator exits MISSING_RECORDS_DIR."""
    import arsenal_method_record as arm_inner
    saved = arm_inner.RECORDS_DIR
    arm_inner.RECORDS_DIR = Path("/nonexistent/path/that/does/not/exist")
    saved_argv = sys.argv
    saved_stderr = sys.stderr
    sys.argv = ["arsenal_method_record"]
    from io import StringIO
    sys.stderr = StringIO()
    try:
        rc = arm_inner.main()
        err = sys.stderr.getvalue()
    finally:
        sys.argv = saved_argv
        sys.stderr = saved_stderr
        arm_inner.RECORDS_DIR = saved
    assert rc == arm.EXIT_CODE["MISSING_RECORDS_DIR"], (
        f"expected MISSING_RECORDS_DIR, got rc={rc}"
    )
    assert "missing records dir" in err
    print("PASS negative case: missing records dir")


def test_invalid_schema_identity_rejected() -> None:
    """A record carrying the wrong ``schema`` identity is rejected."""
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["schema"] = "engineering-system/something-else/v9"
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    assert rc == arm.EXIT_CODE["SCHEMA_VIOLATION"], (
        f"expected SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    )
    assert "schema" in err and "engineering-system/qualified-method-record/v0" in err
    print("PASS negative case: invalid schema identity rejected")


def test_qualified_status_requires_correct_confidence() -> None:
    """A record that claims ``status=qualified`` but uses a non-qualifying
    ``confidence`` value is rejected.
    """
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["status"] = "qualified"
        record["evaluation"]["confidence"] = "bounded"
        # Also recompute the digest using the canonicalization rule.
        record["provenance"]["record_digest"] = _canonical_digest(record)
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    # The validator emits both a schema-level (allOf.const) and a
    # contract-level message. The schema-level is the highest-priority
    # classifier match; the contract-level message must still appear.
    assert rc in (
        arm.EXIT_CODE["CONTRACT_VIOLATION"],
        arm.EXIT_CODE["SCHEMA_VIOLATION"],
    ), f"expected CONTRACT_VIOLATION/SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    assert "status=qualified" in err or "qualified-for-declared-context" in err
    print("PASS negative case: qualified status requires confidence")


def test_experimental_status_requires_observed_failures() -> None:
    """An experimental record with empty ``observed_failures`` is rejected."""
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["evaluation"]["observed_failures"] = []
        record["provenance"]["record_digest"] = _canonical_digest(record)
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    assert rc == arm.EXIT_CODE["SCHEMA_VIOLATION"], (
        f"expected SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    )
    assert "fewer items than minItems" in err or "observed_failures" in err
    print("PASS negative case: experimental status requires observed_failures")


def test_tampered_record_digest_rejected() -> None:
    """A record whose ``record_digest`` does not match the canonicalization
    is rejected as INVALID_DIGEST.
    """
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["provenance"]["record_digest"] = (
            "sha256:deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
        )
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    assert rc == arm.EXIT_CODE["INVALID_DIGEST"], (
        f"expected INVALID_DIGEST, got rc={rc}; err={err!r}"
    )
    assert "record_digest" in err
    print("PASS negative case: tampered record digest rejected")


def test_runtime_authority_claim_rejected() -> None:
    """A record that claims filesystem.write authority is rejected (the
    contract forbids runtime authority).
    """
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["qualified_for"]["exclusions"].append("filesystem.write")
        # Recompute digest.
        record["provenance"]["record_digest"] = _canonical_digest(record)
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    # The claim "filesystem.write" is now present in the record (as an
    # exclusion string) so the validator refuses it on contract grounds.
    assert rc in (arm.EXIT_CODE["CONTRACT_VIOLATION"], arm.EXIT_CODE["SCHEMA_VIOLATION"]), (
        f"expected CONTRACT_VIOLATION or SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    )
    assert "runtime authority" in err or "filesystem.write" in err
    print("PASS negative case: runtime authority claim rejected")


def test_empty_contexts_rejected() -> None:
    """An empty ``qualified_for.contexts`` is rejected for non-fixture records."""
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["qualified_for"]["contexts"] = []
        record["provenance"]["record_digest"] = _canonical_digest(record)
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    assert rc in (arm.EXIT_CODE["CONTRACT_VIOLATION"], arm.EXIT_CODE["SCHEMA_VIOLATION"]), (
        f"expected CONTRACT_VIOLATION/SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    )
    assert "contexts" in err
    print("PASS negative case: empty contexts rejected")


def test_empty_exclusions_rejected() -> None:
    """An empty ``qualified_for.exclusions`` is rejected (negative knowledge
    is first-class).
    """
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["qualified_for"]["exclusions"] = []
        record["provenance"]["record_digest"] = _canonical_digest(record)
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    assert rc in (arm.EXIT_CODE["CONTRACT_VIOLATION"], arm.EXIT_CODE["SCHEMA_VIOLATION"]), (
        f"expected CONTRACT_VIOLATION/SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    )
    assert "exclusions" in err
    print("PASS negative case: empty exclusions rejected")


def test_duplicate_method_id_rejected() -> None:
    """Two records sharing one ``method_id`` are rejected as duplicates."""
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        # Read the canonical record, give it a known method_id, write to
        # both filenames so both files share the same method_id.
        record = yaml.safe_load(
            (dst / "repository-recon.architecture-anchor.v0.yaml").read_text()
        )
        record["method_id"] = "repository-recon/duplicate-test"
        record["provenance"]["record_digest"] = _canonical_digest(record)
        # Overwrite the original file with the renamed copy and add a
        # duplicate. Both files now carry method_id = duplicate-test.
        record_text = yaml.safe_dump(record, sort_keys=True, allow_unicode=True)
        (dst / "repository-recon.architecture-anchor.v0.yaml").write_text(record_text)
        (dst / "duplicate-test.yaml").write_text(record_text)
        rc, err = _run_validator(dst)
    assert rc == arm.EXIT_CODE["DUPLICATE_METHOD_ID"], (
        f"expected DUPLICATE_METHOD_ID, got rc={rc}; err={err!r}"
    )
    assert "duplicate method_id" in err
    print("PASS negative case: duplicate method_id rejected")


def test_determinism_two_runs_agree() -> None:
    """Two consecutive validator invocations produce identical exit codes
    and identical sorted error strings.
    """
    rc1, err1 = _run_validator(RECORDS_DIR)
    rc2, err2 = _run_validator(RECORDS_DIR)
    assert rc1 == rc2 == 0, f"non-zero rc: {rc1}, {rc2}"
    # The success message is constant; ensure it is identical.
    assert err1 == err2, f"stderr drift:\nrun1={err1!r}\nrun2={err2!r}"
    print("PASS determinism case: two runs agree")


def test_provenance_canonical_record_digest_matches() -> None:
    """The committed record's ``record_digest`` matches the validator's
    canonicalization rule exactly.
    """
    import yaml
    record = yaml.safe_load(
        (RECORDS_DIR / "repository-recon.architecture-anchor.v0.yaml").read_text()
    )
    declared = record["provenance"]["record_digest"]
    assert arm._compute_record_digest(record, declared) is True, (
        "committed record_digest does not match canonicalization"
    )
    print("PASS provenance case: record digest matches canonicalization")


def test_status_field_must_be_in_enum() -> None:
    """An unknown ``status`` value is rejected."""
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["status"] = "draft"  # not in the method-record enum
        record["provenance"]["record_digest"] = _canonical_digest(record)
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    assert rc == arm.EXIT_CODE["SCHEMA_VIOLATION"], (
        f"expected SCHEMA_VIOLATION, got rc={rc}; err={err!r}"
    )
    assert "enum" in err.lower() or "not in enum" in err.lower()
    print("PASS negative case: status not in enum rejected")


def test_upstream_fixture_loads_unchanged() -> None:
    """The upstream engineering-system fixture at
    ``engineering-system/fixtures/qualified-method-record.v0.yaml`` must be
    loadable by the Arsenal validator without modification. This is the
    compatibility test: Arsenal's reproduction of the v0 contract MUST accept
    the official fixture semantics so consumers do not silently fork the
    contract.
    """
    upstream = (
        Path("/Users/jenksed/Developer/engineering-system-workspace/engineering-system")
        / "fixtures"
        / "qualified-method-record.v0.yaml"
    )
    if not upstream.is_file():
        # The compatibility target is a sibling repo (engineering-system).
        # If that workspace is not present in this checkout, skip — the
        # compatibility test is opt-in by workspace layout.
        print("SKIP compatibility case: upstream fixture not present")
        return
    with tempfile.TemporaryDirectory() as tmp:
        dst = Path(tmp) / "method-records"
        dst.mkdir()
        shutil.copy2(SCHEMA_PATH, dst / SCHEMA_PATH.name)
        shutil.copy2(upstream, dst / "qualified-method-record.v0.yaml")
        rc, err = _run_validator(dst)
    assert rc == 0, (
        f"upstream fixture failed Arsenal validation: rc={rc}, err={err!r}"
    )
    print("PASS compatibility case: upstream fixture loads unchanged")


def test_non_fixture_record_rejects_placeholder_digest() -> None:
    """A non-fixture record that uses ``record_digest: sha256:fixture-only``
    is rejected by the schema. Stricter rules for real records are preserved:
    only fixtures may carry the placeholder digest.
    """
    import yaml
    with tempfile.TemporaryDirectory() as tmp:
        dst = _copy_records_to(Path(tmp))
        path = dst / "repository-recon.architecture-anchor.v0.yaml"
        record = yaml.safe_load(path.read_text())
        record["provenance"]["record_digest"] = "sha256:fixture-only"
        path.write_text(yaml.safe_dump(record, sort_keys=True, allow_unicode=True))
        rc, err = _run_validator(dst)
    # Either the schema (fixture-only not permitted for non-fixture) or the
    # digest check rejects it; both are part of the documented invariants.
    assert rc in (
        arm.EXIT_CODE["SCHEMA_VIOLATION"],
        arm.EXIT_CODE["INVALID_DIGEST"],
    ), f"expected SCHEMA_VIOLATION/INVALID_DIGEST, got rc={rc}; err={err!r}"
    assert (
        "record_digest" in err
        or "fixture-only" in err
        or "pattern" in err.lower()
    )
    print("PASS negative case: non-fixture record rejects placeholder digest")


def _canonical_digest(record: dict) -> str:
    """Helper: compute the canonical digest for a record."""
    import hashlib, json
    placeholder = "sha256:" + ("0" * 64)
    payload = json.loads(json.dumps(record, sort_keys=True))
    payload["provenance"]["record_digest"] = placeholder
    serialized = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def main() -> int:
    test_canonical_record_validates()
    test_missing_records_dir_fails()
    test_invalid_schema_identity_rejected()
    test_qualified_status_requires_correct_confidence()
    test_experimental_status_requires_observed_failures()
    test_tampered_record_digest_rejected()
    test_runtime_authority_claim_rejected()
    test_empty_contexts_rejected()
    test_empty_exclusions_rejected()
    test_duplicate_method_id_rejected()
    test_determinism_two_runs_agree()
    test_provenance_canonical_record_digest_matches()
    test_status_field_must_be_in_enum()
    test_upstream_fixture_loads_unchanged()
    test_non_fixture_record_rejects_placeholder_digest()
    print("method-record suite: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
