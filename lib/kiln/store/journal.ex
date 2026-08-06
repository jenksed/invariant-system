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
  alias Kiln.Journal.{Entry, Reducer, Replay}
  alias Kiln.Projections.Session
  alias Kiln.Projections.Store, as: ProjectionStore
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
  Look up an existing commit by `idempotency_key` alone, returning the stored
  application result verbatim when the supplied `request_digest` matches and
  the stored result is internally consistent.

  The caller uses this to short-circuit a transition validation when a prior
  commit already accepted the same request. The journal's own `commit/4`
  performs the same lookup inside its `BEGIN IMMEDIATE` transaction; this
  pre-lookup exists so the workflow can defer its `Run` state transition check
  until it knows whether the request will replay.

  Returns:

    * `{:ok, stored_result}` — an existing commit with a matching digest;
      `stored_result` is the JSON-decoded application result map.
    * `:none` — no commit exists for the supplied key.
    * `{:error, %Error{code: :idempotency_conflict}}` — an existing commit
      has a different request digest.
    * `{:error, %Error{code: :corrupt_result}}` — an existing commit's stored
      result fails its recorded result_digest.
  """
  @spec lookup_commit(Connection.conn(), String.t(), String.t()) ::
          {:ok, map()} | :none | {:error, Error.t()}
  def lookup_commit(conn, idempotency_key, request_digest) do
    case Connection.query!(
           conn,
           "SELECT request_digest, result_schema, result, result_digest FROM action_commits WHERE idempotency_key = ?1",
           [idempotency_key]
         ) do
      [] ->
        :none

      [[stored_digest, result_schema, result, stored_result_digest]] ->
        cond do
          stored_digest != request_digest ->
            {:error,
             Error.new(
               :idempotency_conflict,
               :idempotency_conflict,
               "idempotency key reused with a different request",
               %{
                 idempotency_key: idempotency_key,
                 stored_request_digest: stored_digest,
                 submitted_request_digest: request_digest
               }
             )}

          not valid_stored_result?(result_schema, result, stored_result_digest) ->
            {:error,
             Error.new(:integrity, :corrupt_result, "stored idempotency result is corrupt", %{
               idempotency_key: idempotency_key
             })}

          true ->
            case safe_decode(result) do
              {:ok, decoded} -> {:ok, decoded}
              :error -> :none
            end
        end
    end
  end

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
            # A duplicate replay must validate the stored action boundary
            # against the authoritative journal before returning the prior
            # result, so a deleted or corrupt journal cannot masquerade as
            # accepted recorded truth (R04). The replay uses the stored
            # session_id (carried in `stored`), so a retry's freshly
            # generated session identifier cannot collide with the original.
            replay_boundary_valid?(tx, stored)

          {:conflict, _} ->
            DBConnection.rollback(tx, {:idempotency_conflict})

          {:corrupt_result, error} ->
            DBConnection.rollback(tx, {:corrupt_result, error})

          :none ->
            commit_new(tx, action, entries, result_map, result_schema, now, opts)
        end
      end)

    case outcome do
      {:ok, {:committed, data}} -> {:ok, data}
      {:ok, {:replayed, stored}} -> {:ok, replayed_result(stored)}
      {:error, {:idempotency_conflict}} -> {:error, conflict_error(action)}
      {:error, {:invalid_entry, error}} -> {:error, error}
      {:error, {:corrupt_result, error}} -> {:error, error}
      {:error, {:cache_corrupt, error}} -> {:error, error}
      {:error, {:cache_invalid_metadata, error}} -> {:error, error}
      {:error, {:journal_invalid, error}} -> {:error, error}
      {:error, {:stale, current}} -> {:error, stale_error(action, current)}
      {:error, reason} -> {:error, transaction_error(reason)}
    end
  rescue
    exception -> {:error, transaction_error(Exception.message(exception))}
  end

  # Decode every proposed entry with the shared journal decoder before insertion,
  # but only for a new action, so an entry that cannot replay cannot commit while
  # a duplicate still replays. Nothing is inserted on an invalid entry.
  defp commit_new(tx, action, entries, result_map, result_schema, now, opts) do
    case validate_entries(entries) do
      :ok -> do_commit(tx, action, entries, result_map, result_schema, now, opts)
      {:error, error} -> DBConnection.rollback(tx, {:invalid_entry, error})
    end
  end

  defp validate_entries([]) do
    {:error,
     Error.new(:unknown, :empty_entry_batch, "an action must append at least one entry", %{})}
  end

  defp validate_entries(entries) do
    Enum.reduce_while(entries, :ok, fn entry, :ok ->
      case validate_entry(entry) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  # Make malformed caller input total: the entry must be a map with a string
  # type, a payload_schema that matches the shared authority, and a map payload
  # that decodes.
  defp validate_entry(entry) when is_map(entry) do
    type = Map.get(entry, :type)
    payload_schema = Map.get(entry, :payload_schema)
    payload = Map.get(entry, :payload)

    cond do
      not is_binary(type) ->
        {:error, malformed_entry(:missing_type, %{})}

      not is_binary(payload_schema) ->
        {:error, malformed_entry(:missing_payload_schema, %{type: type})}

      not is_map(payload) ->
        {:error, malformed_entry(:payload_not_a_map, %{type: type})}

      Entry.payload_schema(type) != payload_schema ->
        {:error,
         malformed_entry(:payload_schema_mismatch, %{type: type, payload_schema: payload_schema})}

      true ->
        decode_entry(type, payload)
    end
  end

  defp validate_entry(_entry), do: {:error, malformed_entry(:entry_not_a_map, %{})}

  defp decode_entry(type, payload) do
    case Entry.decode(type, payload) do
      {:ok, _decoded} -> :ok
      {:error, %{code: code, detail: detail}} -> {:error, invalid_entry_error(type, code, detail)}
    end
  end

  defp malformed_entry(reason, detail) do
    Error.new(
      :unknown,
      :invalid_entry,
      "malformed journal entry",
      Map.put(detail, :reason, reason)
    )
  end

  defp invalid_entry_error(type, code, detail) do
    Error.new(:unknown, :invalid_entry, "journal entry failed shared decoding", %{
      type: type,
      decode_code: code,
      decode_detail: detail
    })
  end

  # -- transaction body --

  defp do_commit(tx, action, entries, result_map, result_schema, now, opts) do
    {base_next, current_projection} = revision_base!(tx, action)

    {appended, first_sequence, last_sequence} =
      append_entries(tx, action, entries, base_next, now)

    new_revision = base_next + length(entries) - 1

    case build_projection(current_projection, appended, new_revision, last_sequence) do
      {:ok, projection} ->
        upsert_projection(tx, action.session_id, projection, now)

        # Stamp the freshly computed revision and projection digest into
        # the stored application result so an idempotent replay returns
        # both verbatim instead of the placeholder values. The result_map
        # keys are atom-keyed; the canonical encoder accepts both atom
        # and string keys, so the same JSON is produced regardless.
        result_with_truth =
          result_map
          |> Map.put(:session_revision, new_revision)
          |> Map.put(:projection_digest, Session.digest(projection))

        write_action_commit(
          tx,
          action,
          first_sequence,
          last_sequence,
          result_with_truth,
          result_schema,
          now
        )

        maybe_fault!(opts)

        {:committed,
         %{
           status: :committed,
           session_revision: new_revision,
           last_sequence: last_sequence,
           projection: projection,
           result: result_with_truth
         }}

      {:error, %{code: code, detail: detail}} ->
        DBConnection.rollback(
          tx,
          {:invalid_entry, invalid_entry_error("<reduce>", code, detail)}
        )
    end
  end

  # Idempotency lookup is performed by `idempotency_key` alone (the JSON
  # `action_commits` table enforces global uniqueness on
  # `idempotency_key`). The stored `session_id` is returned so the caller can
  # perform the replay-boundary validation against the original session
  # rather than the retry's freshly generated one. The retry's `session_id`
  # is not part of the lookup key, so a `start_session` retry that has not
  # yet resolved the original `session_id` can still find the prior commit
  # (P1-S01-T06).
  defp existing_commit(tx, action) do
    case Connection.query!(
           tx,
           "SELECT session_id, request_digest, result_schema, result, result_digest FROM action_commits WHERE idempotency_key = ?1",
           [action.idempotency_key]
         ) do
      [] ->
        :none

      [[stored_session_id, digest, result_schema, result, result_digest]] ->
        cond do
          digest != action.request_digest ->
            {:conflict, digest}

          not valid_stored_result?(result_schema, result, result_digest) ->
            {:corrupt_result,
             Error.new(:integrity, :corrupt_result, "stored idempotency result is corrupt", %{
               session_id: stored_session_id,
               idempotency_key: action.idempotency_key
             })}

          true ->
            {:replay,
             %{
               session_id: stored_session_id,
               result_schema: result_schema,
               result: result
             }}
        end
    end
  end

  # The stored idempotency result is the cached answer, not the source of truth.
  # Validate the authoritative Session journal before returning it, so a duplicate
  # request cannot succeed after its journal rows have been deleted or corrupted.
  # This runs inside the same `BEGIN IMMEDIATE` transaction as the replay lookup
  # so a concurrent tamper cannot interleave between the two reads. The
  # replay-boundary check uses the stored `session_id` so the retry's
  # freshly generated session identifier cannot collide with the original.
  defp replay_boundary_valid?(tx, stored) do
    case Replay.rebuild(tx, stored.session_id) do
      {:ok, _report} ->
        {:replayed, stored}

      {:error, block} ->
        DBConnection.rollback(
          tx,
          {:journal_invalid,
           Error.new(
             :integrity,
             :journal_invalid,
             "duplicate replay found the stored action boundary invalid",
             %{
               session_id: stored.session_id,
               block: block
             }
           )}
        )
    end
  end

  # A stored idempotency result must decode and match its recorded digest before
  # it is replayed, so corrupt durable result data cannot crash or mislead.
  defp valid_stored_result?(result_schema, result, result_digest) do
    case safe_decode(result) do
      {:ok, decoded} -> Canonical.digest(result_schema, decoded) == result_digest
      :error -> false
    end
  end

  # The journal is authoritative. Replay it first to derive the current
  # projection and revision, then classify the optional cache as a secondary
  # check. The cache can never produce a stale-revision error or short-circuit
  # the rebuild; if the journal is empty a missing cache is still a valid first
  # start, and a tampered cache cannot masquerade as authoritative state.
  defp revision_base!(tx, action) do
    case Replay.rebuild(tx, action.session_id) do
      {:error, block} ->
        DBConnection.rollback(
          tx,
          {:journal_invalid,
           Error.new(
             :integrity,
             :journal_invalid,
             "journal rebuild failed before the cache could be classified",
             %{session_id: action.session_id, block: block}
           )}
        )

      {:ok, report} ->
        check_revision_against_rebuild!(tx, action, report)
    end
  end

  defp check_revision_against_rebuild!(tx, action, report) do
    authoritative_revision = report.session_revision
    authoritative_projection = report.projection

    cond do
      is_nil(authoritative_revision) and action.expected_session_revision == 0 ->
        # Empty journal: the next accepted revision is 0.
        classify_cache!(tx, action.session_id, 0, nil)

      is_nil(authoritative_revision) ->
        DBConnection.rollback(tx, {:stale, nil})

      action.expected_session_revision != authoritative_revision ->
        DBConnection.rollback(tx, {:stale, authoritative_revision})

      true ->
        classify_cache!(
          tx,
          action.session_id,
          authoritative_revision + 1,
          authoritative_projection
        )
    end
  end

  # The cache is optional. A missing row is fine — the rebuild is authoritative.
  # A present row must be internally valid and digest-match the rebuild.
  defp classify_cache!(tx, session_id, base_next, authoritative_projection) do
    case load_cache_record(tx, session_id) do
      nil ->
        {base_next, authoritative_projection}

      :malformed ->
        DBConnection.rollback(
          tx,
          {:cache_corrupt,
           Error.new(:integrity, :cache_corrupt, "cached projection is corrupt", %{
             session_id: session_id
           })}
        )

      record ->
        case ProjectionStore.validate_cache_metadata(record) do
          :ok ->
            rebuilt_digest =
              if is_map(authoritative_projection),
                do: Session.digest(authoritative_projection),
                else: nil

            if is_nil(rebuilt_digest) or Session.digest(record.projection) == rebuilt_digest do
              {base_next, authoritative_projection}
            else
              DBConnection.rollback(
                tx,
                {:cache_invalid_metadata,
                 Error.new(
                   :integrity,
                   :cache_invalid_metadata,
                   "cached projection does not match the journal rebuild",
                   %{session_id: session_id, reason: :projection_does_not_match_journal}
                 )}
              )
            end

          {:error, reason} ->
            DBConnection.rollback(
              tx,
              {:cache_invalid_metadata,
               Error.new(
                 :integrity,
                 :cache_invalid_metadata,
                 "cached projection metadata or invariants are invalid",
                 %{session_id: session_id, reason: reason}
               )}
            )
        end
    end
  end

  defp load_cache_record(tx, session_id) do
    case Connection.query!(
           tx,
           "SELECT projection_schema, session_revision, last_sequence, projection, projection_digest FROM session_projections WHERE session_id = ?1",
           [session_id]
         ) do
      [] ->
        nil

      [[schema, revision, last_sequence, projection_text, digest]] ->
        case safe_decode(projection_text) do
          {:ok, projection} ->
            %{
              schema: schema,
              session_revision: revision,
              last_sequence: last_sequence,
              projection: projection,
              digest: digest
            }

          :error ->
            :malformed
        end
    end
  end

  defp safe_decode(text) do
    {:ok, JSON.decode!(text)}
  rescue
    _ -> :error
  end

  defp append_entries(tx, action, entries, base_next, now) do
    {appended, sequences} =
      entries
      |> Enum.with_index()
      |> Enum.map_reduce([], fn {entry, index}, seqs ->
        revision = base_next + index
        sequence = insert_entry(tx, action, entry, revision, now)

        reduced_entry =
          entry
          |> Map.put(:session_revision, revision)
          |> Map.put(:session_id, action.session_id)

        {reduced_entry, [sequence | seqs]}
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
    case Reducer.reduce_all(current, appended) do
      {:ok, reduced} -> {:ok, Session.stamp(reduced, new_revision, last_sequence)}
      {:error, _} = error -> error
    end
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
