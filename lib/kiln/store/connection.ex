defmodule Kiln.Store.Connection do
  @moduledoc """
  Owns the single supervised Exqlite connection for `$KILN_HOME/state.sqlite3`.

  The connection is one writer with pool size one, opened with the durability
  settings accepted in ADR-0022 and the P0-W21 SQLite boundary: WAL journaling,
  `synchronous=FULL`, foreign keys on, a two-second busy timeout, and immediate
  write transactions.

  `start_link/1` starts the connection. `verify/1` reads every accepted setting
  back from the live connection and reports the exact bundled SQLite version, so
  startup can prove the pragmas took effect rather than assume it. This module
  owns SQL and connection settings; it is not a domain process and holds no
  domain state.
  """

  alias Exqlite.{Query, Result}
  alias Kiln.Store.Error

  # Lowest bundled SQLite version that contains the WAL-reset corruption fix.
  @minimum_sqlite {3, 51, 3}

  @busy_timeout_ms 2000
  @wal_autocheckpoint_pages 1000

  @typedoc "A started DBConnection process for the state store."
  @type conn :: DBConnection.conn()

  @typedoc "Verified live-connection facts."
  @type info :: %{
          sqlite_version: String.t(),
          journal_mode: String.t(),
          synchronous: integer(),
          foreign_keys: integer(),
          busy_timeout: integer(),
          quick_check: String.t()
        }

  @doc "The accepted connection settings, for documentation and tests."
  @spec settings() :: map()
  def settings do
    %{
      journal_mode: :wal,
      synchronous: :full,
      foreign_keys: :on,
      busy_timeout_ms: @busy_timeout_ms,
      default_transaction_mode: :immediate,
      wal_autocheckpoint_pages: @wal_autocheckpoint_pages,
      pool_size: 1
    }
  end

  @doc """
  Start the supervised connection at `path`.

  Options:

    * `:path` (required) - absolute path to `state.sqlite3` on a local volume.
    * `:name` (optional) - registered name for the connection process.

  The database and its `-wal`/`-shm` files are created when absent. The busy
  timeout is applied through an explicit pragma in `after_connect` so it stays
  readable; Exqlite's own `:busy_timeout` option installs a C-level handler that
  `PRAGMA busy_timeout` reports as zero, which cannot be verified.
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts) do
    path = Keyword.fetch!(opts, :path)

    connect_opts =
      [
        database: path,
        journal_mode: :wal,
        synchronous: :full,
        foreign_keys: :on,
        default_transaction_mode: :immediate,
        wal_auto_check_point: @wal_autocheckpoint_pages,
        pool_size: 1,
        after_connect: &__MODULE__.__after_connect__/1
      ]
      |> maybe_put(:name, Keyword.get(opts, :name))

    DBConnection.start_link(Exqlite.Connection, connect_opts)
  end

  @doc false
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc false
  # Runs on every physical connection. Sets the readable busy-timeout pragma
  # after Exqlite's own connect settings have been applied.
  def __after_connect__(conn) do
    DBConnection.execute!(
      conn,
      %Query{statement: "PRAGMA busy_timeout = #{@busy_timeout_ms}"},
      []
    )

    :ok
  end

  @doc """
  Read every accepted setting back from `conn` and report the SQLite version.

  Returns `{:ok, info}` only when WAL, `synchronous=FULL`, foreign keys, and the
  two-second busy timeout are all in effect, the bundled SQLite version is at
  least #{Enum.join(Tuple.to_list(@minimum_sqlite), ".")}, and `quick_check`
  reports `ok`. Otherwise it returns a classified `Kiln.Store.Error`.
  """
  @spec verify(conn()) :: {:ok, info()} | {:error, Error.t()}
  def verify(conn) do
    with {:ok, version} <- one(conn, "SELECT sqlite_version()"),
         :ok <- check_version(version),
         {:ok, journal_mode} <- one(conn, "PRAGMA journal_mode"),
         {:ok, synchronous} <- one(conn, "PRAGMA synchronous"),
         {:ok, foreign_keys} <- one(conn, "PRAGMA foreign_keys"),
         {:ok, busy_timeout} <- one(conn, "PRAGMA busy_timeout"),
         {:ok, quick_check} <- one(conn, "PRAGMA quick_check"),
         :ok <- expect(:journal_mode, journal_mode, "wal"),
         :ok <- expect(:synchronous, synchronous, 2),
         :ok <- expect(:foreign_keys, foreign_keys, 1),
         :ok <- expect(:busy_timeout, busy_timeout, @busy_timeout_ms),
         :ok <- check_integrity(quick_check) do
      {:ok,
       %{
         sqlite_version: version,
         journal_mode: journal_mode,
         synchronous: synchronous,
         foreign_keys: foreign_keys,
         busy_timeout: busy_timeout,
         quick_check: quick_check
       }}
    end
  end

  @doc "Run `sql` and return its rows, raising on driver failure."
  @spec query!(conn(), String.t(), list()) :: [list()]
  def query!(conn, sql, params \\ []) do
    %Result{rows: rows} = DBConnection.execute!(conn, %Query{statement: sql}, params)
    rows
  end

  defp one(conn, sql) do
    case query!(conn, sql) do
      [[value]] ->
        {:ok, value}

      other ->
        {:error,
         Error.new(:unknown, :unexpected_pragma_shape, "unexpected result for #{sql}", %{
           rows: inspect(other)
         })}
    end
  end

  defp expect(_setting, actual, actual), do: :ok

  defp expect(setting, actual, expected) do
    {:error,
     Error.new(:integrity, :pragma_unverified, "#{setting} not in the accepted state", %{
       setting: setting,
       expected: expected,
       actual: actual
     })}
  end

  defp check_version(version) do
    if parse_version(version) >= @minimum_sqlite do
      :ok
    else
      {:error,
       Error.new(
         :integrity,
         :sqlite_too_old,
         "bundled SQLite is older than the accepted baseline",
         %{
           actual: version,
           minimum: Enum.join(Tuple.to_list(@minimum_sqlite), ".")
         }
       )}
    end
  end

  defp check_integrity("ok"), do: :ok

  defp check_integrity(result) do
    {:error,
     Error.new(:integrity, :quick_check_failed, "quick_check did not report ok", %{result: result})}
  end

  defp parse_version(version) do
    version
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
