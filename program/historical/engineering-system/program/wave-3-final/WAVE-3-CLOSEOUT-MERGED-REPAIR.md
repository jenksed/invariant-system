# Wave 3 Repair Closeout — KILN-01 + KILN-02

**Date:** 2026-08-13
**Branch:** `work/p3-w01-kil-w3-work-envelope-supervision`
**Commits:**
- `1edc3a1` — KIL-01: Restart reconstructs Run Result Envelope from durable Artifact + supervision_runs
- `5d07f07` — KIL-02: ready_store/1 in CLI includes the canonical artifact_root

**Predecessor:** WAVE-3-CLOSEOUT-MERGED.md (HOLD — TARGETED REPAIR REQUIRED)

---

## KILN-02 — `ready_store/1` in `lib/kiln/cli.ex`

**Root cause:** `ready_store/0` returned `%{conn: pid}` and omitted the `artifact_root` key. `Kiln.Artifact.Store.put/2` is defined as `put(%{conn: conn, artifact_root: root} = _store, …)`, so the missing key crashed the CLI dispatch with `FunctionClauseError` once supervision reached the Artifact substrate.

**Repair:**

1. `lib/kiln/store.ex` — exposed the canonical `Kiln.Store.artifact_root_for_path/1` helper that derives the artifact root from a state file path (`Path.dirname(path) <> "/artifacts"`). The internal `artifact_root/1` private function now delegates to this public helper so the two cannot drift.
2. `lib/kiln/cli.ex` — `ready_store/1` (renamed from `/0` and now takes `Request`) returns `%{conn: pid, artifact_root: path}` derived from the same state.sqlite3 path `Runtime.open/2` started. The CLI does not invent a second artifact location convention.
3. `lib/kiln/cli.ex` — added the missing `navigation_actions("supervise")` clause that crashed `dispatch_supervise/1` with `FunctionClauseError` and removed the duplicate inline `next_actions` list.

**Files:**
- `lib/kiln/cli.ex` (modified)
- `lib/kiln/store.ex` (modified)
- `test/kiln/cli/ready_store_test.exs` (new)

**Tests:**
- `Kiln.CLI.ReadyStoreTest."real CLI mix kiln supervise reaches Artifact.Store.put/2 without FunctionClauseError"` — invokes `Kiln.CLI.run/1` over a parsed `Kiln.CLI.Request` with a real `Kiln.CLI.Runtime.open/2` backed store and asserts the supervise dispatch returns `status: :ok`, no `FunctionClauseError`.
- `Kiln.CLI.ReadyStoreTest."ready_store artifact_root matches the canonical Kiln.Store derivation"` — proves the CLI path matches the canonical helper.

**Final SHA:** `5d07f07`

**Real CLI result:** `mix kiln supervise --work-envelope … --kiln-home …` reaches `Kiln.Artifact.Store.put/2`, persists observation + authority_decision artifacts, returns `status: :ok, exit_code: 0` with a fully populated envelope.

---

## KILN-01 — `reconstruct_envelope/5` in `lib/kiln/supervision.ex`

**Root cause:** the legacy `reconstruct_envelope/5` returned placeholders (`"sha256:restored"`, `"0000000000000000000000000000000000000000"`, empty authority lists, `nil` final commit). The durable data lived in the Artifact substrate and the `supervision_runs` SQL row, but the projection never read either source.

**FIELD → DURABLE_SOURCE map:**

```
FIELD                          DURABLE SOURCE
work_id                        supervision_runs.work_id
run_id                         (call site, not reconstructed)
authority.requested            authority_decision Artifact bodies (requested_capability)
authority.granted              filtered from authority_decision (result == "granted")
authority.denied               filtered from authority_decision (result == "denied")
input_state.base_commit        supervision_runs.base_commit (NEW column, migration 0006)
input_state.workspace_state_digest
                               supervision_runs.workspace_state_digest (NEW column, migration 0006)
final_state.commit             observation Artifact body.current_commit
final_state.workspace_state_digest
                               observation Artifact body.input_state_digest
proof_obligations              supervision_runs.proof_obligation_ids (NEW column) +
                               evidence_records.criterion_id + result
Artifact ids                   supervision_run_artifacts (already)
Evidence ids                   supervision_run_evidence (already)
```

**Projection repair:**

1. Added `Kiln.Artifact.Store.read/2` — reads and integrity-verifies a committed Artifact's bytes; returns `{:ok, bytes, %{integrity_status: :verified}}` or a typed error. The supervisor is the only first-month caller; the digest is rechecked against the metadata before any bytes are returned.
2. `reconstruct_envelope/5` reads `supervision_runs` for the producer's input bindings, locates the observation Artifact by schema (`kiln.repository_observation/v1`), locates every authority_decision Artifact by schema (`kiln.authority.decision/v1`), and fetches every Evidence record by id.
3. Authority grouping: each decision is grouped by `requested_capability`; `requested`, `granted`, and `denied` sets are computed from the persistent `result` field.
4. Proof-obligation partition: requested obligation ids come from the persisted `proof_obligation_ids` JSON column; `satisfied`, `unsatisfied`, and `invalidated` come from matching the Evidence `criterion_id` + `result` for each requested id.
5. Status: derived from the persisted decisions and evidence. `:blocked` when any decision is `:denied` for an out-of-v0 capability; `:completed` when a pass Evidence satisfies every requested obligation; `:unknown` otherwise.
6. Unknowns: list every durable fact the supervisor cannot recover truthfully (missing input_state, missing obligation ids, etc.) so the operator sees the gap rather than a fabricated value.

**Placeholder values removed:**
- `"sha256:restored"` (in input_state and final_state.workspace_state_digest) — replaced by the producer's `workspace_state_digest` from the persisted SQL row.
- `"0000000000000000000000000000000000000000"` (in input_state.base_commit) — replaced by the producer's `base_commit` from the persisted SQL row.
- `nil` (in final_state.commit) — replaced by `observation.current_commit` parsed from the durable Artifact body.
- Empty authority lists — replaced by parsing every authority_decision Artifact body.
- Hardcoded `proof_obligations: %{satisfied: ["repo-state-observed"], …}` — replaced by partitioning the persisted obligation ids against the Evidence criterion_ids.
- Hardcoded `acceptance_readiness` reasons — replaced with the v0 contract reason (which was already correct).

**Files:**
- `lib/kiln/supervision.ex` (modified)
- `lib/kiln/artifact/store.ex` (modified — added `read/2`)
- `priv/store/migrations/0006_supervision_input_state.sql` (new)
- `test/kiln/supervision_restart_regression_test.exs` (new)

**Tests:**
- `Kiln.SupervisionRestartRegressionTest."restart semantic equality — durable_truth(R1) == durable_truth(R2)"` — runs a full supervision, restarts the store from disk, asserts every historical semantic field matches.
- `… "missing artifact does not invent original authority or final commit"` — removes the observation Artifact body from disk, asserts `{:error, {:incomplete_durable_facts, _}}`.
- `… "corrupt artifact does not deserialize and trust bytes without integrity"` — overwrites the observation Artifact body with garbage, asserts `{:error, {:incomplete_durable_facts, _}}`.
- `… "partial durable information exposes an unknown state rather than sentinel"` — drops the Evidence rows, asserts the supervisor returns the empty partition rather than a fabricated sentinel.
- `… "replay determinism: repeated inspect/reconstruction is stable"` — repeated inspections produce identical envelopes.

**Final SHA:** `1edc3a1`

**Restart semantic equality:** PASSED — every historical semantic field (`work_id`, `run_id`, `status`, `input_state`, `final_state`, `authority`) is equal between R1 and R2 for any new supervision.

**Negative reconstruction behavior:** PASSED — missing, corrupt, partial, and replay cases all return truthful states; no fabricated sentinel values, no decoded-and-trusted unverified bytes.

---

## Wave 3 Re-Acceptance

**Golden path (RE-PROOF A — Real CLI):**
- `parse argv → CLI.run/1 → dispatch_supervise → ready_store/1 → Kiln.Supervision.supervise/2 → Artifact.Store.put/2 → Evidence.Store.record/2 → RunResultEnvelope.build/1` — all reach the durable substrate without error.
- Returns `status: :ok, exit_code: 0` with a fully populated envelope (`authority.granted == ["git.read"]`, `authority.denied == []`, `input_state.base_commit` matches producer, `final_state.commit` matches observed HEAD).

**Restart (RE-PROOF B):**
- Capture R1 from a fresh supervision.
- Stop the live connection. Reopen the store from disk with a new `Store.start/1`.
- Recover the same Run via `Kiln.Supervision.inspect_run/2`.
- All durable semantic fields (`authority.granted`, `authority.denied`, `authority.requested`, `input_state.base_commit`, `input_state.workspace_state_digest`, `final_state.commit`, `final_state.workspace_state_digest`, `proof_obligations`) equal R1.

**Negative proof (RE-PROOF C):**
- Missing observation Artifact body: reconstruction fails with `{:incomplete_durable_facts, …}` rather than inventing authority.
- Corrupt observation Artifact body: reconstruction fails with `{:incomplete_durable_facts, …}` rather than decoding unverified bytes.
- Partial Evidence: the supervisor reports the empty proof-obligation partition; status remains `:unknown` if no obligations can be partitioned.
- Replay: two inspections of the same Run produce identical envelopes.

**Dogfood status:** Arsenal/Loadout/Temper unchanged. Wave 4 Temper implementation must NOT begin until the Wave 3 verdict reaches A or B.

**Arsenal flywheel status:** unchanged — FLYWHEEL-01 (5/16 supported, 11 reproducible misses) preserved. The repair does not move this needle; it only closes the two real defects that blocked Wave 3 acceptance.

---

## Verdict

**A. WAVE 3 LANDED**

The canonical CLI path now reaches the durable Artifact + Evidence substrate, the post-restart projection reads every durable fact truthfully, and the four independent dimensions (authority, work completion, proof, acceptance) survive process death without sentinel values. The Wave 3 architecture held; the two defects were integration and projection defects that did not require architectural change.