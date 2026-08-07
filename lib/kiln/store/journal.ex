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
  Classify an idempotency key as `:none`, `{:replay, ...}`, `{:conflict, ...}`,
  or `{:error, %Error{}}` using the stored action boundary and the authoritative
  Session journal.

  This helper is the single authority used by both the workflow's pre-lookup
  (`lookup_commit/3`) and the in-transaction duplicate handler in `commit/4`.
  A `{:replay, ...}` outcome is returned only after the stored `session_id`'s
  journal is rebuilt and validates, so a stored application result can never
  be replayed over a deleted, corrupt, or truncated authoritative journal.

  `request_digest` is the digest the caller computed from its own request
  attributes; the stored digest is what the journal actually accepted.

  Runs in its own `BEGIN IMMEDIATE` transaction when called outside another
  transaction so the lookup and the journal replay share one consistent view.
  Inside `commit/4` the caller passes the active transaction.
  """
  @spec classify_commit(Connection.conn(), String.t(), String.t()) ::
          :none
          | {:replay, replay()}
          | {:conflict, Error.t()}
          | {:error, Error.t()}
  def classify_commit(conn, idempotency_key, request_digest) do
    Connection.transaction(conn, fn tx ->
      do_classify(tx, idempotency_key, request_digest)
    end)
    |> normalize_classify_outcome()
  rescue
    # A raised `Connection.query!` or any other exception inside the
    # classifier must not escape into the public workflow functions;
    # the same operational-error treatment `commit/4` already uses
    # applies here, so callers see one error envelope shape.
    exception ->
      {:error, transaction_error(Exception.message(exception))}
  end

  # `classify_commit` is invoked both with a fresh transaction and from within
  # `commit/4`'s transaction. `Connection.transaction/2` returns the bare value
  # when not nested, but DBConnection's nested mode returns `{:ok, value}` or
  # `{:error, reason}`. Normalize both shapes so callers see one shape. Any
  # reason that is not already a `%Kiln.Store.Error{}` is wrapped in one so
  # the public contract always returns an error envelope.
  defp normalize_classify_outcome({:ok, value}), do: value

  defp normalize_classify_outcome({:error, %Error{} = error}), do: {:error, error}

  defp normalize_classify_outcome({:error, reason}) do
    {:error,
     Error.new(
       :unknown,
       :transaction_failed,
       "the classify transaction did not commit",
       %{reason: inspect(reason)}
     )}
  end

  @typedoc "Validated stored commit returned to a successful replay caller."
  @type replay :: %{
          session_id: String.t(),
          action_id: String.t(),
          request_digest: String.t(),
          result_schema: String.t(),
          result: map(),
          boundary: Replay.action_boundary() | nil,
          rebuild_digest: String.t() | nil,
          target_projection: map() | nil
        }

  @doc """
  Look up an existing commit by `idempotency_key` alone.

  Returns:

    * `{:ok, replay}` — a stored commit whose request digest matches and whose
      authoritative Session journal validates. `replay.session_id` is the
      stored Session, never a freshly generated one. `replay.result` is the
      decoded application result.
    * `:none` — no commit exists for the supplied key.
    * `{:error, %Error{code: :idempotency_conflict}}` — the stored digest differs.
    * `{:error, %Error{code: :corrupt_result}}` — the stored result fails its
      recorded result_digest.
    * `{:error, %Error{class: :integrity, code: :journal_invalid}}` — the
      authoritative journal for the stored `session_id` is missing, corrupt,
      truncated, or inconsistent.

  The caller uses this to short-circuit a transition validation when a prior
  commit already accepted the same request. `commit/4` performs the same
  classification inside its own `BEGIN IMMEDIATE` transaction so a check/use
  race cannot interleave between the lookup and the eventual write.
  """
  @spec lookup_commit(Connection.conn(), String.t(), String.t()) ::
          {:ok, replay()} | :none | {:error, Error.t()}
  def lookup_commit(conn, idempotency_key, request_digest) do
    case classify_commit(conn, idempotency_key, request_digest) do
      :none -> :none
      {:replay, replay} -> {:ok, replay}
      {:conflict, %Error{} = error} -> {:error, error}
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  @doc """
  Commit `action` with its `entries` in one immediate transaction.

  Options: `:result` (application result map, default `%{}`), `:result_schema`,
  `:now` (ISO 8601 commit time), and `:fault` (a test-only hook that raises
  inside the transaction to prove nothing partial persists).

  The `:precondition` option names a Store-recognized precondition that runs
  inside the same `BEGIN IMMEDIATE` transaction as the commit itself. The
  Store owns the precondition vocabulary, the evaluation, and the rollback;
  it never accepts an arbitrary caller-supplied callback. Currently
  recognized:

    * `:no_existing_session` — the journal must hold zero Sessions.
      First-month single-Session contract enforcement. On failure the
      transaction rolls back and `commit/4` returns
      `{:error, %Kiln.Store.Error{class: :precondition, code: :session_already_exists}}`.
      The caller translates this into its public application error
      vocabulary; no Domain error type escapes through the Store boundary.

  An unsupported precondition atom is rejected up front with
  `{:error, %Kiln.Store.Error{class: :precondition, code: :unsupported_precondition}}`
  before any transaction opens.
  """
  @spec commit(Connection.conn(), Action.t(), [entry_input()], keyword()) ::
          {:ok, result()} | {:error, Error.t()}
  def commit(conn, %Action{} = action, entries, opts \\ []) when is_list(entries) do
    with {:ok, precondition} <- normalize_precondition(Keyword.get(opts, :precondition)) do
      now = Keyword.get(opts, :now, utc_now())
      result_map = Keyword.get(opts, :result, %{})
      result_schema = Keyword.get(opts, :result_schema, @default_result_schema)

      outcome =
        Connection.transaction(conn, fn tx ->
          case classify_in_transaction(tx, action) do
            {:replay, replay} ->
              # The classifier already validated the stored action boundary
              # against the authoritative journal, so a deleted or corrupt
              # journal cannot masquerade as accepted recorded truth (R04).
              # The replay uses the stored session_id (carried in `replay`),
              # so a retry's freshly generated session identifier cannot
              # collide with the original.
              {:replayed, replay}

            {:conflict, _} ->
              DBConnection.rollback(tx, {:idempotency_conflict})

            {:error, %Error{class: :integrity, code: :corrupt_result} = error} ->
              DBConnection.rollback(tx, {:corrupt_result, error})

            {:error, %Error{class: :integrity, code: :journal_invalid} = error} ->
              DBConnection.rollback(tx, {:journal_invalid, error})

            {:error, %Error{} = error} ->
              DBConnection.rollback(tx, {:transaction_failed, error})

            :none ->
              case evaluate_precondition(tx, precondition) do
                :ok ->
                  commit_new(tx, action, entries, result_map, result_schema, now, opts)

                {:error, error} ->
                  DBConnection.rollback(tx, {:precondition, error})
              end
          end
        end)

      case outcome do
        {:ok, {:committed, data}} -> {:ok, data}
        {:ok, {:replayed, replay}} -> {:ok, replayed_result(replay)}
        {:error, {:idempotency_conflict}} -> {:error, conflict_error(action)}
        {:error, {:invalid_entry, error}} -> {:error, error}
        {:error, {:corrupt_result, error}} -> {:error, error}
        {:error, {:cache_corrupt, error}} -> {:error, error}
        {:error, {:cache_invalid_metadata, error}} -> {:error, error}
        {:error, {:journal_invalid, error}} -> {:error, error}
        {:error, {:transaction_failed, %Error{} = error}} -> {:error, error}
        {:error, {:stale, current}} -> {:error, stale_error(action, current)}
        {:error, {:precondition, %Error{} = error}} -> {:error, error}
        {:error, reason} -> {:error, transaction_error(reason)}
      end
    end
  rescue
    exception -> {:error, transaction_error(Exception.message(exception))}
  end

  # The Store owns the precondition vocabulary. An unknown precondition
  # atom is rejected before any transaction opens so a misspelled or
  # experimental caller cannot silently disable enforcement. `nil`
  # (no precondition) is accepted and is equivalent to omitting the
  # option.
  @preconditions [nil, :no_existing_session]

  defp normalize_precondition(precondition) do
    if precondition in @preconditions do
      {:ok, precondition}
    else
      {:error,
       Error.new(
         :precondition,
         :unsupported_precondition,
         "the precondition atom is not recognized by the Store layer",
         %{precondition: inspect(precondition)}
       )}
    end
  end

  # Evaluate the precondition inside the active `BEGIN IMMEDIATE`
  # transaction. SQLite writer-lock serialization guarantees any
  # concurrent transaction has either committed (and is therefore
  # visible) or is blocked on this transaction; there is no window in
  # which a separate transaction's writes are unobservable. A
  # precondition failure raises a typed `%Kiln.Store.Error{}` so the
  # Store error contract is never violated by an arbitrary caller term.
  defp evaluate_precondition(_tx, nil), do: :ok

  defp evaluate_precondition(tx, :no_existing_session) do
    case Replay.sessions(tx) do
      [] ->
        :ok

      _existing ->
        {:error,
         Error.new(
           :precondition,
           :session_already_exists,
           "a Session already exists in the journal; the first-month contract forbids a second",
           %{}
         )}
    end
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
  # Load the stored action commit by idempotency key. Used by the
  # in-transaction classifier and the public `lookup_commit/3`.
  defp read_commit(tx, idempotency_key) do
    case Connection.query!(
           tx,
           """
           SELECT action_id, session_id, request_digest, result_schema, result, result_digest
           FROM action_commits
           WHERE idempotency_key = ?1
           """,
           [idempotency_key]
         ) do
      [] ->
        :none

      [[action_id, session_id, request_digest, result_schema, result, result_digest]] ->
        case safe_decode(result) do
          {:ok, decoded} ->
            {:found,
             %{
               action_id: action_id,
               session_id: session_id,
               request_digest: request_digest,
               result_schema: result_schema,
               result: decoded,
               result_digest: result_digest
             }}

          :error ->
            # Treat an unparseable stored result as corrupt; never silently
            # accept an undecodable replay.
            {:found,
             %{
               action_id: action_id,
               session_id: session_id,
               request_digest: request_digest,
               result_schema: result_schema,
               result: nil,
               result_digest: result_digest,
               result_unparseable: true
             }}
        end
    end
  end

  defp valid_stored_result?(%{result_unparseable: true}), do: false

  defp valid_stored_result?(commit) do
    is_map(commit.result) and
      Canonical.digest(commit.result_schema, commit.result) == commit.result_digest
  end

  defp commit_to_replay(commit, report) do
    %{
      session_id: commit.session_id,
      action_id: commit.action_id,
      request_digest: commit.request_digest,
      result_schema: commit.result_schema,
      result: commit.result,
      boundary: report.action_boundary,
      rebuild_digest: report.projection_digest,
      target_projection: report.projection
    }
  end

  # In-transaction classifier used by `commit/4`. Delegates to `do_classify/3`
  # so both the pre-lookup (`classify_commit/3`) and the in-transaction paths
  # share one classifier implementation. The `commit/4` plumbing maps the
  # canonical `{:conflict, _}` and `{:error, _}` shapes to the legacy
  # `:corrupt_result` and `{:journal_invalid, _}` rollback tuples it has
  # always emitted, so existing behavior is preserved.
  defp classify_in_transaction(tx, action) do
    do_classify(tx, action.idempotency_key, action.request_digest)
  end

  # Single classification algorithm. Runs against either a fresh
  # `Connection.transaction` (in `classify_commit/3`) or the active transaction
  # inside `commit/4`. Returns one of:
  #
  #   `:none` — no commit exists for the supplied key.
  #   `{:replay, replay}` — a stored commit whose request digest matches and
  #     whose authoritative Session journal validates. `replay.session_id` is
  #     the stored Session, never a freshly generated one.
  #   `{:conflict, %Error{}}` — the stored digest differs from the request.
  #   `{:error, %Error{}}` — the stored result fails its recorded
  #     result_digest, or the authoritative journal for the stored session_id
  #     is missing, corrupt, truncated, or inconsistent.
  defp do_classify(tx, idempotency_key, request_digest) do
    case read_commit(tx, idempotency_key) do
      :none ->
        :none

      {:found, commit} ->
        cond do
          commit.request_digest != request_digest ->
            {:conflict, idempotency_conflict_error(commit, idempotency_key, request_digest)}

          not valid_stored_result?(commit) ->
            {:error,
             Error.new(
               :integrity,
               :corrupt_result,
               "stored idempotency result is corrupt",
               %{
                 idempotency_key: idempotency_key,
                 session_id: commit.session_id
               }
             )}

          true ->
            case replay_boundary_valid?(tx, commit.session_id, commit.action_id) do
              {:ok, report} ->
                {:replay, commit_to_replay(commit, report)}

              {:error, %Error{} = error} ->
                {:error, error}
            end
        end
    end
  end

  # The stored idempotency result is the cached answer, not the source of truth.
  # Validate the authoritative Session journal before returning it, so a duplicate
  # request cannot succeed after its journal rows have been deleted or corrupted.
  # This runs inside the same `BEGIN IMMEDIATE` transaction as the replay lookup
  # so a concurrent tamper cannot interleave between the two reads. The
  # replay-boundary check uses the stored `session_id` and `action_id` so the
  # replay returns the projection and boundary *at the target action's commit
  # point*, not the Session's current head. A retry of a start action that
  # happened before a later resume or cancel must replay the start action's
  # original revision and projection digest, not the head's.
  defp replay_boundary_valid?(tx, session_id, action_id) do
    case Replay.rebuild_for_action(tx, session_id, action_id) do
      {:ok, report} ->
        {:ok, report}

      {:error, %{code: :target_action_not_found, detail: detail}} ->
        {:error,
         Error.new(
           :integrity,
           :target_action_not_found,
           "stored action_id is not present in the authoritative journal",
           Map.put(detail, :session_id, session_id)
         )}

      {:error, block} ->
        {:error,
         Error.new(
           :integrity,
           :journal_invalid,
           "duplicate replay found the stored action boundary invalid",
           %{
             session_id: session_id,
             action_id: action_id,
             block: block
           }
         )}
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

  defp replayed_result(%{
         result: decoded,
         result_schema: result_schema,
         session_id: session_id,
         boundary: boundary,
         rebuild_digest: rebuild_digest,
         target_projection: target_projection
       }) do
    %{
      status: :replayed,
      session_id: session_id,
      session_revision: nil,
      last_sequence: nil,
      projection: nil,
      result: decoded,
      result_schema: result_schema,
      boundary: boundary,
      rebuild_digest: rebuild_digest,
      target_projection: target_projection
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

  defp idempotency_conflict_error(commit, idempotency_key, request_digest) do
    Error.new(
      :idempotency_conflict,
      :idempotency_conflict,
      "idempotency key reused with a different request",
      %{
        idempotency_key: idempotency_key,
        stored_request_digest: commit.request_digest,
        submitted_request_digest: request_digest,
        stored_session_id: commit.session_id
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
