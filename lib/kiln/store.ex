defmodule Kiln.Store do
  @moduledoc """
  Public startup boundary for the first-month SQLite state store.

  `start/1` opens the supervised connection, verifies the accepted pragmas and
  bundled SQLite version, verifies or initializes the store format metadata, and
  runs pending migrations, following the P0-W21 startup sequence. It yields one
  startup outcome and never exposes a writable store that failed a check.

  The atomic application-action transaction (append, revision, idempotency) is
  added in a later increment; this module currently owns startup only.
  """

  alias Kiln.Store.{Connection, Error, Migrations}

  @store_format "kiln-state/v1"
  @supported_formats [@store_format]

  @typedoc "A ready store and its verified facts."
  @type store :: %{
          conn: Connection.conn(),
          store_id: String.t(),
          store_format: String.t(),
          store_version: non_neg_integer(),
          sqlite_version: String.t(),
          info: Connection.info()
        }

  @typedoc "A blocking startup outcome that never exposes a writable store."
  @type blocked_state ::
          :busy | :migration_blocked | :integrity_blocked | :version_blocked | :unavailable

  @doc """
  Start and validate the store at `opts[:path]`.

  Returns:

    * `{:ready, store}` when every startup check passes;
    * `{:blocked, state, error}` for a classified startup failure that preserves
      files and exposes no writable store;
    * `{:error, reason}` when the connection process cannot start.

  Options: `:path` (required), `:store_id` and `:now` for deterministic tests,
  and `:migrations_dir` to override the migration source.
  """
  @spec start(keyword()) ::
          {:ready, store()} | {:blocked, blocked_state(), Error.t()} | {:error, term()}
  def start(opts) do
    path = Keyword.fetch!(opts, :path)

    case Connection.integrity_precheck(path) do
      :ok -> open_and_continue(path, opts)
      {:error, error} -> {:blocked, :integrity_blocked, error}
    end
  end

  defp open_and_continue(path, opts) do
    case Connection.start_link(path: path) do
      {:ok, conn} -> continue(conn, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "The accepted store format identifier."
  @spec store_format() :: String.t()
  def store_format, do: @store_format

  defp continue(conn, opts) do
    with {:ok, info} <- verify(conn),
         {:ok, meta} <- ensure_metadata(conn, opts),
         {:ok, migration} <- run_migrations(conn, opts) do
      {:ready,
       %{
         conn: conn,
         store_id: meta.store_id,
         store_format: meta.store_format,
         store_version: migration.version,
         sqlite_version: info.sqlite_version,
         info: info
       }}
    end
  end

  defp verify(conn) do
    case Connection.verify(conn) do
      {:ok, info} -> {:ok, info}
      {:error, error} -> {:blocked, :integrity_blocked, error}
    end
  end

  defp ensure_metadata(conn, opts) do
    Connection.query!(conn, """
    CREATE TABLE IF NOT EXISTS store_metadata (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      store_format TEXT NOT NULL,
      store_id TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    """)

    case Connection.query!(conn, "SELECT store_format, store_id FROM store_metadata WHERE id = 1") do
      [] -> initialize_metadata(conn, opts)
      [[store_format, store_id]] -> validate_metadata(store_format, store_id)
    end
  end

  defp initialize_metadata(conn, opts) do
    store_id = Keyword.get(opts, :store_id, generate_store_id())
    now = Keyword.get(opts, :now, utc_now())

    Connection.query!(
      conn,
      "INSERT INTO store_metadata (id, store_format, store_id, created_at) VALUES (1, ?1, ?2, ?3)",
      [@store_format, store_id, now]
    )

    {:ok, %{store_format: @store_format, store_id: store_id}}
  end

  defp validate_metadata(store_format, store_id) when store_format in @supported_formats do
    {:ok, %{store_format: store_format, store_id: store_id}}
  end

  defp validate_metadata(store_format, _store_id) do
    {:blocked, :version_blocked,
     Error.new(
       :future_version,
       :unsupported_store_format,
       "store format is not supported by this binary",
       %{
         store_format: store_format,
         supported: @supported_formats
       }
     )}
  end

  defp run_migrations(conn, opts) do
    migrate_opts =
      opts
      |> Keyword.take([:now])
      |> maybe_put(:dir, Keyword.get(opts, :migrations_dir))

    case Migrations.migrate(conn, migrate_opts) do
      {:ok, result} -> {:ok, result}
      {:error, %Error{class: :future_version} = error} -> {:blocked, :version_blocked, error}
      {:error, %Error{} = error} -> {:blocked, :migration_blocked, error}
    end
  end

  defp generate_store_id do
    "store_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp utc_now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
