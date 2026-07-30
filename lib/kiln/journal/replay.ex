defmodule Kiln.Journal.Replay do
  @moduledoc """
  Deterministic journal replay: reconstruct a Session's current projection from
  its durable `action_commits` and `journal_entries`, from zero, without trusting
  any cached projection (P1-S01-T03-R01, R02).

  T02 commits one accepted application action - one or more journal entries - in
  one atomic transaction. Replay therefore validates and applies whole action
  batches, using each `action_commits` record as the authoritative transaction
  boundary, rather than deduplicating individual rows. A truly repeated request
  writes no second journal row at commit time, so a repeated journal row is
  invalid durable state, not a benign duplicate.

  Every batch is validated before any entry applies: the commit exists, all its
  entries carry the declared action id, session id, idempotency key, and request
  digest; the row sequences are exactly the declared contiguous range; the row
  count agrees; the Session revisions are contiguous and follow the prior
  accepted revision; and each payload decodes to its accepted shape with a
  matching digest and a legal transition. The first invalid batch or entry blocks
  reconstruction and reports its exact sequence boundary (P1-S01-T03-R03, R05).
  """

  alias Kiln.Domain.Id
  alias Kiln.Journal.{Entry, Reducer}
  alias Kiln.Projections.Session
  alias Kiln.Store.{Canonical, Connection}

  @type report :: %{
          session_id: String.t() | nil,
          projection: Session.t() | nil,
          session_revision: non_neg_integer() | nil,
          first_sequence: non_neg_integer() | nil,
          last_sequence: non_neg_integer() | nil,
          action_count: non_neg_integer(),
          entry_count: non_neg_integer(),
          projection_digest: String.t() | nil,
          journal_head_digest: String.t() | nil
        }

  @type block :: %{code: atom(), boundary: non_neg_integer() | nil, detail: map()}

  @doc """
  Distinct Session identifiers from the durable journal, in first-seen order.

  A Session is a candidate if it has any `journal_entries` row or any
  `action_commits` row, so an action commit whose journal rows are missing is
  discovered and blocks on incomplete durable state instead of vanishing. The
  non-authoritative projection cache never creates a candidate.
  """
  @spec sessions(Connection.conn()) :: [String.t()]
  def sessions(conn) do
    conn
    |> Connection.query!("""
    SELECT session_id FROM (
      SELECT session_id, sequence FROM journal_entries
      UNION ALL
      SELECT session_id, first_sequence AS sequence FROM action_commits
    )
    GROUP BY session_id
    ORDER BY min(sequence)
    """)
    |> List.flatten()
  end

  @doc "Rebuild the projection for `session_id` from its action batches."
  @spec rebuild(Connection.conn(), String.t()) :: {:ok, report()} | {:error, block()}
  def rebuild(conn, session_id) do
    entries = load_entries(conn, session_id)
    commits = load_commits(conn, session_id)

    with :ok <- validate_numeric(entries, commits),
         {:ok, batches} <- build_batches(entries, commits) do
      apply_batches(session_id, batches)
    end
  end

  # Every persisted revision and sequence used in arithmetic or ordering must be
  # a non-negative integer before any calculation. The store is not STRICT, so a
  # corrupt row may hold a text or float storage class; guard it here rather than
  # let arithmetic raise (P1-S01-T03-R05).
  defp validate_numeric(entries, commits) do
    with :ok <- validate_entry_numbers(entries) do
      validate_commit_numbers(commits)
    end
  end

  defp validate_entry_numbers(entries) do
    Enum.reduce_while(entries, :ok, fn entry, :ok ->
      cond do
        not non_neg_integer?(entry.sequence) ->
          {:halt, block(:corrupt_sequence, nil, %{value: inspect(entry.sequence)})}

        not non_neg_integer?(entry.revision) ->
          {:halt, block(:corrupt_revision, entry.sequence, %{value: inspect(entry.revision)})}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp validate_commit_numbers(commits) do
    Enum.reduce_while(commits, :ok, fn commit, :ok ->
      valid? =
        non_neg_integer?(commit.expected_session_revision) and
          non_neg_integer?(commit.first_sequence) and non_neg_integer?(commit.last_sequence)

      if valid? do
        {:cont, :ok}
      else
        {:halt,
         block(:corrupt_action_bounds, sequence_or_nil(commit.first_sequence), %{
           action_id: commit.action_id
         })}
      end
    end)
  end

  defp non_neg_integer?(value), do: is_integer(value) and value >= 0

  defp sequence_or_nil(value), do: if(is_integer(value), do: value, else: nil)

  # -- loading --

  defp load_entries(conn, session_id) do
    conn
    |> Connection.query!(
      """
      SELECT sequence, entry_schema, entry_type, payload, payload_digest, payload_schema,
             session_revision, action_id, idempotency_key, request_digest
      FROM journal_entries
      WHERE session_id = ?1
      ORDER BY sequence
      """,
      [session_id]
    )
    |> Enum.map(fn [seq, entry_schema, type, payload, digest, schema, rev, action_id, idem, req] ->
      %{
        sequence: seq,
        entry_schema: entry_schema,
        type: type,
        payload_text: payload,
        payload_digest: digest,
        payload_schema: schema,
        revision: rev,
        action_id: action_id,
        idempotency_key: idem,
        request_digest: req
      }
    end)
  end

  defp load_commits(conn, session_id) do
    conn
    |> Connection.query!(
      """
      SELECT action_id, idempotency_key, request_digest, expected_session_revision,
             first_sequence, last_sequence
      FROM action_commits
      WHERE session_id = ?1
      ORDER BY first_sequence
      """,
      [session_id]
    )
    |> Enum.map(fn [action_id, idem, req, expected, first, last] ->
      %{
        action_id: action_id,
        idempotency_key: idem,
        request_digest: req,
        expected_session_revision: expected,
        first_sequence: first,
        last_sequence: last
      }
    end)
  end

  # -- batch structure --

  defp build_batches(entries, commits) do
    by_action = Map.new(commits, &{&1.action_id, &1})

    case Enum.find(entries, fn e -> not Map.has_key?(by_action, e.action_id) end) do
      %{sequence: seq} ->
        block(:missing_action_commit, seq, %{})

      nil ->
        grouped = Enum.group_by(entries, & &1.action_id)

        commits
        |> Enum.reduce_while({:ok, []}, fn commit, {:ok, acc} ->
          case validate_batch(commit, Map.get(grouped, commit.action_id, [])) do
            {:ok, batch} -> {:cont, {:ok, [batch | acc]}}
            {:error, _} = error -> {:halt, error}
          end
        end)
        |> case do
          {:ok, batches} -> {:ok, Enum.reverse(batches)}
          {:error, _} = error -> error
        end
    end
  end

  defp validate_batch(commit, []) do
    block(:missing_journal_rows, commit.first_sequence, %{action_id: commit.action_id})
  end

  defp validate_batch(commit, rows) do
    # Format first: every persisted envelope ID and request digest must match
    # the opaque shapes the domain action boundary enforces at construction.
    # `Kiln.Domain.Action.new/1` rejects malformed identifiers and digests at
    # commit time, but replay re-reads the persisted rows directly. A
    # consistent corruption in both `action_commits` and `journal_entries`
    # would otherwise pass equality and be applied as if it were committed
    # truth (P1-S01-T03-B5).
    with :ok <- validate_commit_envelope(commit),
         :ok <- validate_entries_envelope(rows) do
      validate_batch_continuity(commit, rows)
    end
  end

  defp validate_commit_envelope(commit) do
    first = commit.first_sequence

    cond do
      not Id.valid?(:action, commit.action_id) ->
        block(:invalid_action_id, first, %{value: commit.action_id})

      not Id.valid?(:idempotency, commit.idempotency_key) ->
        block(:invalid_idempotency_key, first, %{value: commit.idempotency_key})

      not valid_request_digest?(commit.request_digest) ->
        block(:invalid_request_digest, first, %{value: commit.request_digest})

      true ->
        :ok
    end
  end

  defp validate_entries_envelope(rows) do
    Enum.reduce_while(rows, :ok, fn row, :ok ->
      cond do
        not Id.valid?(:action, row.action_id) ->
          {:halt, block(:invalid_action_id, row.sequence, %{value: row.action_id})}

        not Id.valid?(:idempotency, row.idempotency_key) ->
          {:halt, block(:invalid_idempotency_key, row.sequence, %{value: row.idempotency_key})}

        not valid_request_digest?(row.request_digest) ->
          {:halt, block(:invalid_request_digest, row.sequence, %{value: row.request_digest})}

        true ->
          {:cont, :ok}
      end
    end)
  end

  defp validate_batch_continuity(commit, rows) do
    sequences = Enum.map(rows, & &1.sequence)
    revisions = Enum.map(rows, & &1.revision)
    first = commit.first_sequence
    last = commit.last_sequence

    cond do
      # Validate the declared bounds arithmetically. An untrusted range is never
      # materialized, so a corrupt last_sequence cannot allocate a huge list.
      not (is_integer(first) and is_integer(last)) or first > last ->
        block(:action_boundary_mismatch, first, %{
          declared: {first, last},
          reason: :invalid_bounds
        })

      length(rows) != last - first + 1 ->
        block(:action_boundary_mismatch, first, %{
          declared: {first, last},
          row_count: length(rows)
        })

      List.first(sequences) != first or List.last(sequences) != last ->
        block(:action_boundary_mismatch, first, %{
          declared: {first, last},
          actual: {List.first(sequences), List.last(sequences)}
        })

      not contiguous_from?(sequences, first) ->
        block(:noncontiguous_sequence, first, %{sequences: sequences})

      Enum.any?(rows, &(&1.idempotency_key != commit.idempotency_key)) ->
        block(:idempotency_key_mismatch, first, %{action_id: commit.action_id})

      Enum.any?(rows, &(&1.request_digest != commit.request_digest)) ->
        block(:request_digest_mismatch, first, %{action_id: commit.action_id})

      not contiguous_from?(revisions, List.first(revisions)) ->
        block(:revision_discontinuity, first, %{revisions: revisions})

      true ->
        {:ok,
         %{
           commit: commit,
           entries: rows,
           first_sequence: first,
           last_sequence: last,
           first_revision: List.first(revisions),
           last_revision: List.last(revisions)
         }}
    end
  end

  # The canonical request-digest shape. Anything else - including a 64-hex
  # string missing the `sha256:` prefix or a 40-hex SHA-1 - blocks.
  defp valid_request_digest?(value) when is_binary(value) do
    Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value)
  end

  defp valid_request_digest?(_value), do: false

  # Each value equals the first value plus its index. Bounded by the row count,
  # so it never materializes an untrusted range.
  defp contiguous_from?([], _first), do: false

  defp contiguous_from?(values, first) do
    values |> Enum.with_index() |> Enum.all?(fn {value, index} -> value == first + index end)
  end

  # -- application --

  defp apply_batches(session_id, batches) do
    initial = %{
      projection: nil,
      prev_revision: nil,
      prev_sequence: nil,
      actions: 0,
      entries: 0,
      first_sequence: nil,
      last_sequence: nil,
      head: []
    }

    batches
    |> Enum.reduce_while({:ok, initial}, fn batch, acc -> apply_batch(session_id, batch, acc) end)
    |> finish(session_id)
  end

  defp apply_batch(session_id, batch, {:ok, acc}) do
    with :ok <- check_batch_revision(batch, acc.prev_revision),
         :ok <- check_batch_sequence(batch, acc.prev_sequence),
         {:ok, projection, head} <-
           reduce_batch(session_id, acc.projection, batch.entries, acc.head) do
      {:cont,
       {:ok,
        %{
          acc
          | projection: projection,
            prev_revision: batch.last_revision,
            prev_sequence: batch.last_sequence,
            actions: acc.actions + 1,
            entries: acc.entries + length(batch.entries),
            first_sequence: acc.first_sequence || batch.first_sequence,
            last_sequence: batch.last_sequence,
            head: head
        }}}
    else
      {:error, _} = error -> {:halt, error}
    end
  end

  # The first accepted action creates the Session at revision 0; each later
  # action asserts the prior accepted revision and advances by one.
  defp check_batch_revision(batch, nil) do
    if batch.commit.expected_session_revision == 0 and batch.first_revision == 0 do
      :ok
    else
      revision_block(batch, 0)
    end
  end

  defp check_batch_revision(batch, prev) do
    if batch.commit.expected_session_revision == prev and batch.first_revision == prev + 1 do
      :ok
    else
      revision_block(batch, prev + 1)
    end
  end

  defp revision_block(batch, expected_first) do
    {:error,
     %{
       code: :revision_discontinuity,
       boundary: batch.first_sequence,
       detail: %{
         expected_first_revision: expected_first,
         first_revision: batch.first_revision,
         expected_session_revision: batch.commit.expected_session_revision
       }
     }}
  end

  defp check_batch_sequence(_batch, nil), do: :ok

  defp check_batch_sequence(batch, prev) do
    if batch.first_sequence > prev do
      :ok
    else
      {:error,
       %{
         code: :sequence_not_increasing,
         boundary: batch.first_sequence,
         detail: %{previous: prev, first: batch.first_sequence}
       }}
    end
  end

  defp reduce_batch(session_id, projection, entries, head) do
    Enum.reduce_while(entries, {:ok, projection, head}, fn row, {:ok, acc, acc_head} ->
      case apply_entry(session_id, acc, row) do
        {:ok, next} -> {:cont, {:ok, next, [row.payload_digest | acc_head]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, projection, head} -> {:ok, projection, head}
      {:error, _} = error -> error
    end
  end

  defp apply_entry(session_id, projection, row) do
    with :ok <- check_schemas(row),
         {:ok, payload} <- decode(row.payload_text, row.sequence),
         :ok <- verify_digest(row.payload_schema, payload, row.payload_digest, row.sequence),
         {:ok, decoded} <- decode_entry(row.type, payload, row.sequence),
         {:ok, next} <-
           reduce(projection, Map.put(decoded, :session_id, session_id), row.sequence) do
      {:ok, next}
    end
  end

  # Bind the envelope and payload schemas to the shared authority: the envelope
  # schema must be supported and the payload schema must match the entry type,
  # even if the digest was recomputed against the wrong schema.
  defp check_schemas(row) do
    cond do
      row.entry_schema != Entry.entry_schema() ->
        block(:unsupported_entry_schema, row.sequence, %{entry_schema: row.entry_schema})

      Entry.payload_schema(row.type) != row.payload_schema ->
        block(:payload_schema_mismatch, row.sequence, %{
          type: row.type,
          payload_schema: row.payload_schema
        })

      true ->
        :ok
    end
  end

  defp decode_entry(type, payload, sequence) do
    case Entry.decode(type, payload) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, %{code: code, detail: detail}} -> block(code, sequence, detail)
    end
  end

  defp reduce(projection, decoded, sequence) do
    case Reducer.reduce(projection, decoded) do
      {:ok, next} -> {:ok, next}
      {:error, %{code: code, detail: detail}} -> block(code, sequence, detail)
    end
  end

  defp finish({:ok, %{actions: 0}}, session_id) do
    {:ok, empty_report(session_id)}
  end

  defp finish({:ok, acc}, session_id) do
    projection = Session.stamp(acc.projection, acc.prev_revision, acc.last_sequence)

    {:ok,
     %{
       session_id: session_id,
       projection: projection,
       session_revision: acc.prev_revision,
       first_sequence: acc.first_sequence,
       last_sequence: acc.last_sequence,
       action_count: acc.actions,
       entry_count: acc.entries,
       projection_digest: Session.digest(projection),
       journal_head_digest: head_digest(acc.head)
     }}
  end

  defp finish({:error, _} = error, _session_id), do: error

  defp empty_report(session_id) do
    %{
      session_id: session_id,
      projection: nil,
      session_revision: nil,
      first_sequence: nil,
      last_sequence: nil,
      action_count: 0,
      entry_count: 0,
      projection_digest: nil,
      journal_head_digest: nil
    }
  end

  # A bounded diagnostic digest over the ordered validated entry digests. Not a
  # tamper-proof hash chain - only a traceable identity for the replayed prefix.
  defp head_digest([]), do: nil
  defp head_digest(reversed), do: Canonical.digest("journal_head/v1", Enum.reverse(reversed))

  # -- primitives --

  defp decode(text, sequence) do
    {:ok, JSON.decode!(text)}
  rescue
    _ -> block(:corrupt_payload, sequence, %{reason: :invalid_json})
  end

  defp verify_digest(schema, payload, expected, sequence) do
    if Canonical.digest(schema, payload) == expected do
      :ok
    else
      block(:corrupt_payload, sequence, %{reason: :digest_mismatch})
    end
  end

  defp block(code, sequence, detail) do
    {:error, %{code: code, boundary: sequence, detail: detail}}
  end
end
