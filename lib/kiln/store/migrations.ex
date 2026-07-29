defmodule Kiln.Store.Migrations do
  @moduledoc """
  Kiln-owned forward SQL migrations for the state store.

  Migrations live under `priv/store/migrations` as `NNNN_name.sql`. Each file
  has one stable SHA-256 checksum; an applied checksum is immutable. This runner
  owns the `schema_migrations` bookkeeping table, detects a store written by a
  newer binary, rejects a modified applied migration, and applies each pending
  migration inside its own `BEGIN IMMEDIATE` transaction so a failed statement
  records no version (P1-S01-T02-R07, R08).
  """

  alias Kiln.Store.{Connection, Error}

  @typedoc "One discovered migration file."
  @type migration :: %{
          version: non_neg_integer(),
          name: String.t(),
          filename: String.t(),
          sql: String.t(),
          checksum: String.t()
        }

  @doc "Absolute path to the bundled migrations directory."
  @spec default_dir() :: String.t()
  def default_dir do
    Application.app_dir(:kiln, ["priv", "store", "migrations"])
  end

  @doc """
  Discover migration files under `dir`, ordered by version.

  Returns `{:error, ...}` when a filename is malformed or a version repeats.
  """
  @spec discover(String.t()) :: {:ok, [migration()]} | {:error, Error.t()}
  def discover(dir \\ default_dir()) do
    dir
    |> Path.join("*.sql")
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.reduce_while({:ok, []}, fn path, {:ok, acc} ->
      case parse_file(path) do
        {:ok, migration} -> {:cont, {:ok, [migration | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, migrations} -> ensure_unique_versions(Enum.reverse(migrations))
      {:error, _} = error -> error
    end
  end

  @doc """
  Bring `conn` to the latest known schema version.

  Returns `{:ok, %{version: v, applied_now: [...]}}` on success, or a classified
  `Kiln.Store.Error`:

    * `:future_version` when the store has an applied version this binary does
      not know (startup `version_blocked`);
    * `:migration` when an applied checksum differs or a migration statement
      fails (startup `migration_blocked`).

  `opts[:dir]` overrides the migrations directory; `opts[:now]` supplies the
  applied timestamp as an ISO 8601 string.
  """
  @spec migrate(Connection.conn(), keyword()) ::
          {:ok, %{version: non_neg_integer(), applied_now: [non_neg_integer()]}}
          | {:error, Error.t()}
  def migrate(conn, opts \\ []) do
    dir = Keyword.get(opts, :dir, default_dir())
    now = Keyword.get(opts, :now, utc_now())

    with :ok <- ensure_bookkeeping(conn),
         {:ok, migrations} <- discover(dir),
         applied <- applied(conn),
         :ok <- reject_future(migrations, applied),
         :ok <- reject_modified(migrations, applied) do
      apply_pending(conn, migrations, applied, now)
    end
  end

  @doc "Applied migrations as a map of version to checksum."
  @spec applied(Connection.conn()) :: %{non_neg_integer() => String.t()}
  def applied(conn) do
    conn
    |> Connection.query!("SELECT version, checksum FROM schema_migrations ORDER BY version")
    |> Map.new(fn [version, checksum] -> {version, checksum} end)
  end

  @doc "Highest applied migration version, or 0 when none are applied."
  @spec current_version(Connection.conn()) :: non_neg_integer()
  def current_version(conn) do
    conn
    |> applied()
    |> Map.keys()
    |> Enum.max(fn -> 0 end)
  end

  # -- internals --

  defp ensure_bookkeeping(conn) do
    Connection.query!(conn, """
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      checksum TEXT NOT NULL,
      applied_at TEXT NOT NULL
    )
    """)

    :ok
  end

  defp reject_future(migrations, applied) do
    known = MapSet.new(migrations, & &1.version)

    case Enum.find(Map.keys(applied), fn version -> not MapSet.member?(known, version) end) do
      nil ->
        :ok

      version ->
        {:error,
         Error.new(
           :future_version,
           :unknown_applied_migration,
           "store has a migration this binary does not know",
           %{
             applied_version: version
           }
         )}
    end
  end

  defp reject_modified(migrations, applied) do
    migrations
    |> Enum.filter(fn migration -> Map.has_key?(applied, migration.version) end)
    |> Enum.find(fn migration -> applied[migration.version] != migration.checksum end)
    |> case do
      nil ->
        :ok

      migration ->
        {:error,
         Error.new(:migration, :checksum_mismatch, "an applied migration has been modified", %{
           version: migration.version,
           filename: migration.filename
         })}
    end
  end

  defp apply_pending(conn, migrations, applied, now) do
    pending =
      Enum.reject(migrations, fn migration -> Map.has_key?(applied, migration.version) end)

    Enum.reduce_while(pending, {:ok, []}, fn migration, {:ok, done} ->
      case apply_one(conn, migration, now) do
        :ok -> {:cont, {:ok, [migration.version | done]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, applied_now} ->
        {:ok, %{version: current_version(conn), applied_now: Enum.reverse(applied_now)}}

      {:error, _} = error ->
        error
    end
  end

  defp apply_one(conn, migration, now) do
    result =
      Connection.transaction(conn, fn tx ->
        Enum.each(statements(migration.sql), fn statement ->
          Connection.query!(tx, statement)
        end)

        Connection.query!(
          tx,
          "INSERT INTO schema_migrations (version, name, checksum, applied_at) VALUES (?1, ?2, ?3, ?4)",
          [migration.version, migration.name, migration.checksum, now]
        )
      end)

    case result do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        {:error,
         Error.new(:migration, :apply_failed, "a migration statement failed", %{
           version: migration.version,
           filename: migration.filename,
           reason: inspect(reason)
         })}
    end
  rescue
    exception ->
      {:error,
       Error.new(:migration, :apply_failed, "a migration statement failed", %{
         version: migration.version,
         filename: migration.filename,
         reason: Exception.message(exception)
       })}
  end

  defp parse_file(path) do
    filename = Path.basename(path)

    case Regex.run(~r/^(\d{4})_([a-z0-9_]+)\.sql$/, filename) do
      [_, version, name] ->
        sql = File.read!(path)

        {:ok,
         %{
           version: String.to_integer(version),
           name: name,
           filename: filename,
           sql: sql,
           checksum: :crypto.hash(:sha256, sql) |> Base.encode16(case: :lower)
         }}

      _ ->
        {:error,
         Error.new(:migration, :bad_filename, "migration filename is malformed", %{
           filename: filename
         })}
    end
  end

  defp ensure_unique_versions(migrations) do
    duplicate =
      migrations
      |> Enum.frequencies_by(& &1.version)
      |> Enum.find(fn {_version, count} -> count > 1 end)

    case duplicate do
      nil ->
        {:ok, migrations}

      {version, _} ->
        {:error,
         Error.new(:migration, :duplicate_version, "two migrations share a version", %{
           version: version
         })}
    end
  end

  # Split a migration file into individual statements. Line comments are
  # stripped; statements are separated by semicolons. Migration SQL must not
  # embed semicolons inside string or identifier literals.
  defp statements(sql) do
    sql
    |> String.split("\n")
    |> Enum.map(&strip_line_comment/1)
    |> Enum.join("\n")
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp strip_line_comment(line) do
    case :binary.match(line, "--") do
      {index, _} -> binary_part(line, 0, index)
      :nomatch -> line
    end
  end

  defp utc_now do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
