defmodule Kiln.Store.Journal do
  @moduledoc """
  The atomic application-action transaction for the state store.

  `commit/4` runs one `BEGIN IMMEDIATE` that appends journal entries, advances
  the Session revision, updates the current projection, and writes the action
  idempotency result, all or nothing (P1-S01-T02-R09, R13). It enforces the
  P0-W21 request contract:

    * duplicate idempotency key with the same request digest replays the prior
      result and writes nothing (R11);
    * duplicate key with a different digest fails `:idempotency_conflict` (R12);
    * an expected revision that is not the current revision fails `:revision`
      and makes no durable change (R10).

  The Session revision starts at 0 for the creating `session_started` entry;
  each later action asserts the current revision and appends the next one.
  """

  alias Kiln.Domain.Action
  alias Kiln.Journal.Reducer
  alias Kiln.Projections.Session
  alias Kiln.Store.{Canonical, Connection, Error, Uuid}

  @entry_schema "journal_entry/v1"
  @default_result_schema "action_result/v1"

  @type entry_input :: %{type: String.t(), payload_schema: String.t(), payload: map()}

  @type result :: %{
          status: :committed | :replayed,
          session_revision: non_neg_integer(),
          last_sequence: non_neg_integer() | nil,
          projection: Session.t() | nil,
          result: map()
        }

  @doc """
  Commit `action` with its `entries` in one immediate transaction.

  Options: `:result` (application result map, default `%{}`), `:result_schema`,
  `:now` (ISO 8601 commit time), and `:fault` (a test-only hook that raises
  inside the transaction to prove nothing partial persists).
  """
  @spec commit(Connection.conn(), Action.t(), [entry_input()], keyword()) ::
          {:ok, result()} | {:error, Error.t()}
  def commit(conn, %Action{} = action, entries, opts \\ []) when is_list(entries) do
    now = Keyword.get(opts, :now, utc_now())
    result_map = Keyword.get(opts, :result, %{})
    result_schema = Keyword.get(opts, :result_schema, @default_result_schema)

    outcome =
      Connection.transaction(conn, fn tx ->
        case existing_commit(tx, action) do
          {:replay, stored} ->
            {:replayed, stored}

          {:conflict, _} ->
            DBConnection.rollback(tx, {:idempotency_conflict})

          :none ->
            do_commit(tx, action, entries, result_map, result_schema, now, opts)
        end
      end)

    case outcome do
      {:ok, {:committed, data}} -> {:ok, data}
      {:ok, {:replayed, stored}} -> {:ok, replayed_result(stored)}
      {:error, {:idempotency_conflict}} -> {:error, conflict_error(action)}
      {:error, {:stale, current}} -> {:error, stale_error(action, current)}
      {:error, reason} -> {:error, transaction_error(reason)}
    end
  rescue
    exception -> {:error, transaction_error(Exception.message(exception))}
  end

  # -- transaction body --

  defp do_commit(tx, action, entries, result_map, result_schema, now, opts) do
    {base_next, current_projection} = revision_base!(tx, action)

    {appended, first_sequence, last_sequence} =
      append_entries(tx, action, entries, base_next, now)

    new_revision = base_next + length(entries) - 1

    projection = build_projection(current_projection, appended, new_revision, last_sequence)
    upsert_projection(tx, action.session_id, projection, now)

    write_action_commit(tx, action, first_sequence, last_sequence, result_map, result_schema, now)

    maybe_fault!(opts)

    {:committed,
     %{
       status: :committed,
       session_revision: new_revision,
       last_sequence: last_sequence,
       projection: projection,
       result: result_map
     }}
  end

  defp existing_commit(tx, action) do
    case Connection.query!(
           tx,
           "SELECT request_digest, result_schema, result FROM action_commits WHERE session_id = ?1 AND idempotency_key = ?2",
           [action.session_id, action.idempotency_key]
         ) do
      [] ->
        :none

      [[digest, result_schema, result]] ->
        if digest == action.request_digest do
          {:replay, %{result_schema: result_schema, result: result}}
        else
          {:conflict, digest}
        end
    end
  end

  # Returns {next_revision_for_first_entry, current_projection_or_nil} or aborts
  # the transaction with a stale-revision rollback.
  defp revision_base!(tx, action) do
    case Connection.query!(
           tx,
           "SELECT session_revision, projection FROM session_projections WHERE session_id = ?1",
           [action.session_id]
         ) do
      [] ->
        if action.expected_session_revision == 0 do
          {0, nil}
        else
          DBConnection.rollback(tx, {:stale, nil})
        end

      [[current, projection_json]] ->
        if action.expected_session_revision == current do
          {current + 1, JSON.decode!(projection_json)}
        else
          DBConnection.rollback(tx, {:stale, current})
        end
    end
  end

  defp append_entries(tx, action, entries, base_next, now) do
    {appended, sequences} =
      entries
      |> Enum.with_index()
      |> Enum.map_reduce([], fn {entry, index}, seqs ->
        revision = base_next + index
        sequence = insert_entry(tx, action, entry, revision, now)
        {Map.put(entry, :session_revision, revision), [sequence | seqs]}
      end)

    ordered = Enum.reverse(sequences)
    {appended, List.first(ordered), List.last(ordered)}
  end

  defp insert_entry(tx, action, entry, revision, now) do
    payload_digest = Canonical.digest(entry.payload_schema, entry.payload)

    Connection.query!(
      tx,
      """
      INSERT INTO journal_entries
        (entry_id, entry_schema, entry_type, payload_schema, session_id, session_revision,
         action_id, actor_kind, actor_id, idempotency_key, request_digest,
         causation_entry_id, correlation_id, recorded_at, payload, payload_digest)
      VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15, ?16)
      """,
      [
        Uuid.v7(),
        @entry_schema,
        entry.type,
        entry.payload_schema,
        action.session_id,
        revision,
        action.id,
        Atom.to_string(action.actor_kind),
        action.actor_id,
        action.idempotency_key,
        action.request_digest,
        nil,
        action.correlation_id,
        now,
        Canonical.encode(entry.payload),
        payload_digest
      ]
    )

    [[sequence]] = Connection.query!(tx, "SELECT last_insert_rowid()")
    sequence
  end

  defp build_projection(current, appended, new_revision, last_sequence) do
    {:ok, reduced} = Reducer.reduce_all(current, appended)
    Session.stamp(reduced, new_revision, last_sequence)
  end

  defp upsert_projection(tx, session_id, projection, now) do
    digest = Session.digest(projection)

    Connection.query!(
      tx,
      """
      INSERT INTO session_projections
        (session_id, projection_schema, session_revision, last_sequence, projection, projection_digest, updated_at)
      VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
      ON CONFLICT (session_id) DO UPDATE SET
        projection_schema = excluded.projection_schema,
        session_revision = excluded.session_revision,
        last_sequence = excluded.last_sequence,
        projection = excluded.projection,
        projection_digest = excluded.projection_digest,
        updated_at = excluded.updated_at
      """,
      [
        session_id,
        Session.schema(),
        projection["session_revision"],
        projection["last_sequence"],
        Canonical.encode(projection),
        digest,
        now
      ]
    )
  end

  defp write_action_commit(
         tx,
         action,
         first_sequence,
         last_sequence,
         result_map,
         result_schema,
         now
       ) do
    Connection.query!(
      tx,
      """
      INSERT INTO action_commits
        (action_id, session_id, idempotency_key, request_digest, expected_session_revision,
         first_sequence, last_sequence, result_schema, result, result_digest, committed_at)
      VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)
      """,
      [
        action.id,
        action.session_id,
        action.idempotency_key,
        action.request_digest,
        action.expected_session_revision,
        first_sequence,
        last_sequence,
        result_schema,
        Canonical.encode(result_map),
        Canonical.digest(result_schema, result_map),
        now
      ]
    )
  end

  defp replayed_result(%{result: result_json}) do
    %{
      status: :replayed,
      session_revision: nil,
      last_sequence: nil,
      projection: nil,
      result: JSON.decode!(result_json)
    }
  end

  defp maybe_fault!(opts) do
    case Keyword.get(opts, :fault) do
      nil -> :ok
      reason -> raise "injected store fault: #{inspect(reason)}"
    end
  end

  defp conflict_error(action) do
    Error.new(
      :idempotency_conflict,
      :idempotency_conflict,
      "idempotency key reused with a different request",
      %{
        idempotency_key: action.idempotency_key,
        session_id: action.session_id
      }
    )
  end

  defp stale_error(action, current) do
    Error.new(:revision, :stale_revision, "expected revision is not the current revision", %{
      expected: action.expected_session_revision,
      current: current
    })
  end

  defp transaction_error(reason) do
    text = inspect(reason)

    if busy?(text) do
      Error.new(:busy, :store_busy, "the writer was busy after the accepted timeout", %{
        reason: text
      })
    else
      Error.new(:unknown, :transaction_failed, "the append transaction did not commit", %{
        reason: text
      })
    end
  end

  defp busy?(text) do
    text = String.downcase(text)
    String.contains?(text, "busy") or String.contains?(text, "locked")
  end

  defp utc_now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
