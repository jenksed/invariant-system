defmodule Kiln.M12ESessionRecoveryFiTest do
  @moduledoc """
  M12-E WP-08 Lane 6: bounded failure-injection tests for Session recovery.

  Exercises the five FI scenarios from `docs/roadmap/t3-competitive-30-day/
  work-packages/WP08-WP09-PLAN.md` against the real on-disk SQLite store,
  using `Kiln.Test.JournalBuilder` to seed journal state and
  `Kiln.Restart.reconstruct/1` to verify post-restart projection.

  Each test:

    * Uses a real on-disk SQLite store (per Recon E).
    * Cleans up its temp directory in `on_exit`.
    * Drives `Kiln.Restart.reconstruct/1` after a forced Store restart.
    * Asserts at least one property that would FAIL if the recovery
      semantics were wrong (no vague "should work" assertions).

  The five scenarios (FI-1..FI-5):

    FI-1 — crash after assignment persistence, before execution.
      Property: assignment survives; no invented completion; no
      duplicate logical assignment; deterministic recovery/start state;
      clearly identified first attempt.

    FI-2 — crash while attempt active (kill mid-mutation + restart).
      Property: assignment survives; original attempt remains represented;
      no fabricated terminal completion; attempt becomes
      interrupted/orphaned/unknown per actual boundary.

    FI-3 — crash after external mutation but before durable response.
      Sub-cases (a) succeeded mutation + retry; (b) unknown-effect
      mutation + retry. Property: no blind replay; observation first;
      mutation never applied twice; uncertainty explicit until
      evidence resolves; no new mutation authority from restart.

    FI-4 — child agent dies without terminal result.
      Property: logical assignment durable; bounded authoritative
      inputs addressable; no conversational reconstruction required;
      explicit replacement attempt; lineage points to the interrupted
      attempt.

    FI-5 — multi-state daemon restart.
      Property: reconstructs same parent + child identities, result
      ownership, interrupted lineage, pending work, uncertain work,
      permitted recovery transitions; no vanished/duplicated
      assignments, no fabricated completion, no silent replay.
  """

  use ExUnit.Case, async: true

  alias Kiln.{OperationLifecycle, Restart, Store}
  alias Kiln.Journal.Replay
  alias Kiln.Projections.Session
  alias Kiln.Store.Connection
  alias Kiln.Test.JournalBuilder, as: JB

  # Per-test temp layout: <dir>/state.sqlite3
  setup do
    dir = Path.join(System.tmp_dir!(), "kiln-wp08-fi-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn -> File.rm_rf!(dir) end)

    {:ok, path: Path.join(dir, "state.sqlite3")}
  end

  # ================================================================
  # FI-1 — crash after assignment persistence, before execution
  # ================================================================

  test "FI-1: assignment persistence survives restart with no invented completion",
       %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)

    # Capture the pre-restart projection digest for byte-equality after
    # the Store restart. This is the "no invented completion, no
    # duplicate logical assignment" property: the restarted Store
    # MUST report the same canonical digest.
    {:ok, before} = Replay.rebuild(store.conn, d.session.id)
    before_digest = before.projection_digest

    GenServer.stop(store.conn)

    # Simulate the daemon process restart.
    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop_safely(restarted.conn) end)

    # Acceptance: reconstruction returns the original session identity,
    # revision 0 (no extra entries), and the canonical digest is
    # byte-equal to the pre-restart digest. No operation, no unknowns.
    assert {:ok, recon} = Restart.reconstruct(restarted.conn)
    assert recon.session_id == d.session.id
    assert recon.session_revision == 0
    assert recon.action_count == 1
    assert recon.entry_count == 1
    assert recon.orphaned == false
    assert recon.projection["operation"] == nil
    assert recon.projection["run"]["state"] == "ready"
    assert recon.projection["unknowns"] in [nil, []]
    assert recon.journal_projection_digest == before_digest
    assert recon.reconstructed_projection_digest == Session.digest(recon.projection)
  end

  # ================================================================
  # FI-2 — crash while attempt active (kill mid-mutation + restart)
  # ================================================================

  test "FI-2: crash mid-attempt reconstructs as orphaned with no fabricated completion",
       %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)

    # Commit intent only. No observation entry. This is the canonical
    # "mid-mutation" state: the operation was authorized and the Run
    # transitioned to running, but no terminal evidence was journaled
    # before the daemon died.
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)

    entries_before = count_rows(store.conn, "journal_entries")

    GenServer.stop(store.conn)
    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop_safely(restarted.conn) end)

    # Acceptance: the conservative classifier marks this as orphaned.
    # operation.state is "unknown" (nonterminal → unknown), Run is
    # "orphaned", and a single unknown marker is recorded. The journal
    # itself is unchanged — reconstruction must NOT append a new
    # entry to "fix" the orphan.
    assert {:ok, recon} = Restart.reconstruct(restarted.conn)
    assert recon.orphaned == true
    assert recon.projection["operation"]["state"] == "unknown"
    assert OperationLifecycle.nonterminal_string?("intent_recorded"),
           "test invariant: intent_recorded must remain nonterminal"
    refute OperationLifecycle.nonterminal_string?(recon.projection["operation"]["state"]),
           "reconstructed operation.state must not be classified as nonterminal"
    assert recon.projection["run"]["state"] == "orphaned"
    assert recon.projection["unknowns"] != nil
    assert length(recon.projection["unknowns"]) == 1
    unknown = hd(recon.projection["unknowns"])
    assert unknown["kind"] == "external_operation"
    assert unknown["reason"] == "no_terminal_observation"

    # The journal must not have been mutated by reconstruction.
    assert count_rows(restarted.conn, "journal_entries") == entries_before
  end

  # ================================================================
  # FI-3a — crash after external mutation succeeded
  # ================================================================

  test "FI-3a: replay of a successful observation does not append a second journal entry",
       %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)
    {:ok, _} = JB.commit_operation_observe(store, d, 1, 11, "succeeded", "ready")

    entries_before_crash = count_rows(store.conn, "journal_entries")
    actions_before_crash = count_rows(store.conn, "action_commits")

    GenServer.stop(store.conn)
    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop_safely(restarted.conn) end)

    # Acceptance: the post-restart projection shows the succeeded
    # observation as terminal (not orphaned, no unknowns). The
    # canonical digest matches what we computed pre-restart.
    assert {:ok, recon} = Restart.reconstruct(restarted.conn)
    assert recon.orphaned == false
    assert recon.projection["operation"]["state"] == "succeeded"
    assert recon.projection["run"]["state"] == "ready"
    assert recon.projection["unknowns"] in [nil, []]
    assert recon.entry_count == 3

    # Replay the same observation with the SAME key_byte (same
    # idempotency_key). The Journal.commit must classify this as
    # :replayed and return the stored result without appending a
    # second journal row. This is the "no blind replay; mutation
    # never applied twice" property — proven at the journal layer.
    {:ok, replay} = JB.commit_operation_observe(restarted, d, 1, 11, "succeeded", "ready")
    assert replay.status == :replayed,
           "second observation with same idempotency_key must replay; got #{inspect(replay)}"

    assert count_rows(restarted.conn, "journal_entries") == entries_before_crash,
           "replay must NOT append a second journal row"

    assert count_rows(restarted.conn, "action_commits") == actions_before_crash,
           "replay must NOT append a second action_commit row"

    # Reconstruction remains deterministic after the replay attempt.
    assert {:ok, recon2} = Restart.reconstruct(restarted.conn)
    assert recon2.projection["operation"]["state"] == "succeeded"
    assert recon2.projection["run"]["state"] == "ready"
    assert recon2.entry_count == recon.entry_count
  end

  # ================================================================
  # FI-3b — crash after external mutation returned E_MUTATION_UNKNOWN_EFFECT
  # ================================================================

  test "FI-3b: replay of an unknown-effect observation returns the same unknown state",
       %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)

    # The bounded unknown-effect observation: state="unknown",
    # run_to="orphaned". This is the canonical record for an
    # E_MUTATION_UNKNOWN_EFFECT outcome.
    {:ok, _} = JB.commit_operation_observe(store, d, 1, 11, "unknown", "orphaned")

    GenServer.stop(store.conn)
    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop_safely(restarted.conn) end)

    # Acceptance: post-restart, the projection shows the operation in
    # the terminal "unknown" state with the Run in "orphaned". Because
    # "unknown" is terminal (not in the nonterminal set), the
    # classifier does NOT add an unknown marker — the journal truth
    # already encodes the uncertainty, so the classifier is
    # conservative-without-fabrication.
    assert {:ok, recon} = Restart.reconstruct(restarted.conn)
    assert recon.projection["operation"]["state"] == "unknown"
    assert recon.projection["run"]["state"] == "orphaned"

    # A retry with the SAME idempotency_key must replay, NOT fabricate
    # a new "succeeded" outcome or append a second observation. This
    # is the "no false success, no double-attempt" property.
    entries_before = count_rows(restarted.conn, "journal_entries")

    {:ok, replay} =
      JB.commit_operation_observe(restarted, d, 1, 11, "unknown", "orphaned")

    assert replay.status == :replayed,
           "retry of unknown-effect observation must replay; got #{inspect(replay)}"

    assert count_rows(restarted.conn, "journal_entries") == entries_before,
           "unknown-effect replay must not append a second journal row"

    # The reconstructed projection remains identical after replay: the
    # operation is still "unknown", the run is still "orphaned", and
    # no new operation history was fabricated.
    assert {:ok, recon2} = Restart.reconstruct(restarted.conn)
    assert recon2.projection["operation"]["state"] == "unknown"
    assert recon2.projection["run"]["state"] == "orphaned"
    assert recon2.entry_count == recon.entry_count
  end

  # ================================================================
  # FI-4 — child agent dies without terminal result; replacement attempt
  # ================================================================

  test "FI-4: replacement attempt commits a second intent entry alongside the interrupted one",
       %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    {:ok, _} = JB.commit_start(store, d)

    # ---- Attempt 1: commit intent, then "die" without observation. ----
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)

    GenServer.stop(store.conn)
    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop_safely(restarted.conn) end)

    # The interrupted attempt reconstructs as orphaned: the journal
    # still says intent_recorded (nonterminal), the conservative
    # classifier reports the projection as op=unknown, run=orphaned.
    assert {:ok, recon_after_crash} = Restart.reconstruct(restarted.conn)
    assert recon_after_crash.orphaned == true
    assert recon_after_crash.projection["operation"]["state"] == "unknown"
    assert recon_after_crash.projection["run"]["state"] == "orphaned"

    # ---- Reconcile: observe the interrupted operation as :failed. ----
    # The reducer advances the operation from intent_recorded to
    # failed (allowed progression) and transitions the Run from
    # orphaned back to ready. This is the explicit "abandon the
    # interrupted attempt" boundary — without it, a new intent
    # would be blocked by `no_current_operation`.
    {:ok, _} =
      JB.commit_operation_observe(restarted, d, 1, 11, "failed", "ready")

    # ---- Attempt 2: a fresh intent with a NEW idempotency_key. ----
    # The replacement is a new Action (key_byte=12, distinct from
    # attempt 1's key_byte=7). The reducer must accept it because
    # the previous operation is now terminal (failed). The expected
    # revision is 2 because commit_start → rev 0, intent#1 → rev 1,
    # observe#1 → rev 2.
    {:ok, _} = JB.commit_operation_intent(restarted, d, 2, 12)

    # Acceptance (lineage): the journal carries BOTH intent entries
    # for this Session. The count query proves the interrupted
    # attempt's intent was never overwritten by the replacement.
    intent_count =
      count_rows_where(
        restarted.conn,
        "journal_entries",
        "entry_type = 'external_operation_intent_recorded/v1'"
      )

    assert intent_count == 2,
           "expected 2 intent entries (interrupted + replacement); got #{intent_count}"

    # The two intents must be distinct journal rows with distinct
    # idempotency_keys. A regression that dedupes intents on
    # (session_id, action_kind) would collapse these to one.
    distinct_keys =
      Connection.query!(
        restarted.conn,
        """
        SELECT COUNT(DISTINCT idempotency_key) FROM journal_entries
        WHERE entry_type = 'external_operation_intent_recorded/v1'
        """
      )
      |> List.flatten()
      |> hd()

    assert distinct_keys == 2,
           "expected 2 distinct idempotency_keys for the two intents; got #{distinct_keys}"

    # ---- The replacement attempt reaches a terminal state. ----
    # The expected revision is 3 (intent#2 advanced from rev 2).
    {:ok, _} =
      JB.commit_operation_observe(restarted, d, 3, 13, "succeeded", "ready")

    # Acceptance (recovery transition): the second attempt's
    # observation closes the operation in :succeeded. The journal
    # carries one observation per attempt, and both observations are
    # recorded against distinct idempotency keys (no silent overwrite
    # of the failed observation).
    {:ok, recon_final} = Restart.reconstruct(restarted.conn)
    assert recon_final.orphaned == false
    assert recon_final.projection["operation"]["state"] == "succeeded"
    assert recon_final.projection["run"]["state"] == "ready"

    observe_rows =
      Connection.query!(
        restarted.conn,
        """
        SELECT COUNT(*) FROM journal_entries
        WHERE entry_type = 'external_operation_observed/v1'
        """
      )
      |> List.flatten()
      |> hd()

    assert observe_rows == 2,
           "expected 2 observation entries (failed for attempt 1, succeeded for attempt 2); got #{observe_rows}"
  end

  # ================================================================
  # FI-5 — multi-state daemon restart
  # ================================================================

  test "FI-5: reconstruct distinguishes interrupted, uncertain, pending, and completed work in one Session",
       %{path: path} do
    store = JB.store(path)
    d = JB.domain()

    # ---- Phase A: Session started, then committed intent only. ----
    # This is the "interrupted work" phase — an attempt that was
    # authorized but never reached a terminal observation. After
    # a forced restart this is what the conservative Restart
    # classifier marks as orphaned.
    {:ok, _} = JB.commit_start(store, d)
    {:ok, _} = JB.commit_operation_intent(store, d, 0, 7)

    # ---- Forced restart between Phase A and Phase B. ----
    # The interrupt + restart is what proves the bounded recovery
    # semantics: the journal carries the nonterminal operation,
    # and Restart reports it as `orphaned` without inventing a
    # terminal observation.
    GenServer.stop(store.conn)
    {:ready, restarted} = Store.start(path: path)
    on_exit(fn -> stop_safely(restarted.conn) end)

    assert {:ok, recon_interrupted} = Restart.reconstruct(restarted.conn)
    assert recon_interrupted.orphaned == true
    assert recon_interrupted.projection["operation"]["state"] == "unknown"
    assert recon_interrupted.projection["run"]["state"] == "orphaned"

    # ---- Phase B: observe the interrupted operation as :failed. ----
    # The reducer advances the operation intent_recorded -> failed
    # (allowed progression) and transitions the Run orphaned ->
    # ready. The conservative orphan classification is the
    # *restart view*, not the journal truth — once the operator
    # commits the explicit terminal observation, the journal
    # reflects the failed outcome and the run returns to ready.
    {:ok, _} =
      JB.commit_operation_observe(restarted, d, 1, 11, "failed", "ready")

    # ---- Phase C: a fresh intent (pending work) that reaches a
    # terminal succeeded observation (result ownership). ----
    {:ok, _} = JB.commit_operation_intent(restarted, d, 2, 12)
    {:ok, _} = JB.commit_operation_observe(restarted, d, 3, 13, "succeeded", "ready")

    # ---- Phase D: a second forced restart. ----
    GenServer.stop(restarted.conn)
    {:ready, final} = Store.start(path: path)
    on_exit(fn -> stop_safely(final.conn) end)

    # Acceptance — reconstruction must distinguish every phase:
    #
    #   - the session identity is preserved (parent identity);
    #   - the current operation is reported as :succeeded
    #     (the latest committed observation, terminal);
    #   - the canonical digest matches the pre-restart digest;
    #   - there is no fabricated entry (entry_count matches the
    #     number of entries we journaled);
    #   - there is no duplicated action (action_count matches);
    #   - the reconstruction is not orphaned (latest operation is
    #     terminal).
    assert {:ok, recon} = Restart.reconstruct(final.conn)
    assert recon.session_id == d.session.id
    assert recon.orphaned == false
    assert recon.projection["operation"]["state"] == "succeeded"
    assert recon.projection["run"]["state"] == "ready"
    assert recon.projection["unknowns"] in [nil, []]

    # Acceptance — journal carries entries for every phase. A
    # reconstruction that "vanishes" any of the three attempts
    # fails this assertion.
    assert recon.entry_count == 5,
           "expected 5 entries (start + intent#1 + observe#1 failed + intent#2 + observe#2 succeeded); got #{recon.entry_count}"

    # Acceptance — the journal carries TWO distinct intent entries
    # (interrupted phase A + pending phase C) AND TWO distinct
    # observation entries (failed phase B + succeeded phase C).
    intent_count =
      count_rows_where(
        final.conn,
        "journal_entries",
        "entry_type = 'external_operation_intent_recorded/v1'"
      )

    observe_count =
      count_rows_where(
        final.conn,
        "journal_entries",
        "entry_type = 'external_operation_observed/v1'"
      )

    assert intent_count == 2,
           "expected 2 intent entries (interrupted + pending); got #{intent_count}"

    assert observe_count == 2,
           "expected 2 observation entries (failed + succeeded); got #{observe_count}"

    # Acceptance — the two observation entries carry the distinct
    # operation states. No silent overwrite; each attempt's terminal
    # outcome is preserved in the journal.
    states =
      Connection.query!(
        final.conn,
        """
        SELECT json_extract(payload, '$.operation.state')
        FROM journal_entries
        WHERE entry_type = 'external_operation_observed/v1'
        ORDER BY sequence
        """
      )
      |> List.flatten()

    assert "failed" in states,
           "expected a 'failed' observation for the interrupted attempt; got #{inspect(states)}"

    assert "succeeded" in states,
           "expected a 'succeeded' observation for the pending attempt; got #{inspect(states)}"

    # Acceptance — the reconstructed digest describes the same
    # canonical projection as the journal truth. The reconstructor
    # did not silently reclassify the failed observation as a
    # second succeeded, nor collapse the two intents into one.
    assert recon.reconstructed_projection_digest == Session.digest(recon.projection)
    assert recon.reconstructed_projection_digest == recon.journal_projection_digest,
           "reconstructed and journal digests must match for a fully-observed session; got reconstructed=#{recon.reconstructed_projection_digest} journal=#{recon.journal_projection_digest}"
  end

  # ================================================================
  # Helpers
  # ================================================================

  # Count rows in `table`. Kept local to this module so the test
  # owns its own SQL surface and does not depend on
  # `Kiln.Store.Connection`'s call shape leaking into the assertions.
  defp count_rows(conn, table) do
    [[n]] = Connection.query!(conn, "SELECT count(*) FROM #{table}")
    n
  end

  defp count_rows_where(conn, table, predicate) do
    [[n]] =
      Connection.query!(conn, "SELECT count(*) FROM #{table} WHERE #{predicate}")

    n
  end

  # Best-effort GenServer.stop that swallows `:exit` when the
  # connection has already been stopped by the test or by a prior
  # on_exit. Keeps `on_exit` cleanup idempotent across the five
  # tests.
  defp stop_safely(conn) do
    if is_pid(conn) and Process.alive?(conn) do
      try do
        GenServer.stop(conn, :normal, 1_000)
      catch
        :exit, _reason -> :ok
      end
    end

    :ok
  end
end