defmodule Kiln.CLI.Runtime do
  @moduledoc false
  # Lifecycle helper for the foundation CLI.
  #
  # The CLI is the single first-month caller that opens a store for a single
  # foreground command. This module owns open / stop only. It does not own
  # application or persistence semantics. Callers that need session data
  # must use `Kiln.Workflow`.

  alias Kiln.Store

  @type outcome ::
          {:ok, :ready}
          | {:blocked, atom(), Kiln.Store.Error.t()}
          | {:absent}

  @type mode :: :read | :write

  @doc """
  Open the state store at `home` for one CLI command.

  * `:write` mode always opens the store. The store file is created when it
    does not exist; migrations and metadata initialization run as part of
    the startup sequence.
  * `:read` mode refuses to create a missing state DB. The store is opened
    only when the file already exists.
  """
  @spec open(Path.t(), mode()) :: outcome()
  def open(home, mode) when mode in [:read, :write] do
    state_path = Path.join(home, "state.sqlite3")

    cond do
      mode == :read and not File.regular?(state_path) -> {:absent}
      true -> start_store(state_path)
    end
  end

  @doc """
  Stop the registered `Kiln.Store.Connection` if one is alive.

  Tolerates a missing or already-stopped connection.
  """
  @spec stop() :: :ok
  def stop do
    case Process.whereis(Kiln.Store.Connection) do
      nil ->
        :ok

      pid when is_pid(pid) ->
        stop_alive(pid)
    end
  end

  defp stop_alive(pid) do
    if Process.alive?(pid) do
      GenServer.stop(pid, :normal, 5_000)
    end

    :ok
  catch
    :exit, _reason -> :ok
  end

  defp start_store(path) do
    case Store.start_link(
           path: path,
           name: Kiln.Store.Connection,
           store_id: deterministic_store_id(path)
         ) do
      {:ok, _conn} -> {:ok, :ready}
      {:error, {state, _error}} when is_atom(state) -> error_for_state(state)
      {:error, reason} -> {:blocked, :unavailable, reason}
    end
  end

  # `Store.start_link/1` returns a flattened `{:error, {state, _error}}` for
  # classified startup blocks. The CLI distinguishes the block kinds by exit
  # code (8 for migration_blocked / integrity_blocked / version_blocked /
  # unavailable, 4 for everything else), matching the T04 contract.
  defp error_for_state(:migration_blocked), do: {:blocked, :migration_blocked, nil}
  defp error_for_state(:integrity_blocked), do: {:blocked, :integrity_blocked, nil}
  defp error_for_state(:version_blocked), do: {:blocked, :version_blocked, nil}
  defp error_for_state(:unavailable), do: {:blocked, :unavailable, nil}
  defp error_for_state(state), do: {:blocked, state, nil}

  # The CLI reuses one deterministic store_id per `--kiln-home` so that two
  # CLI invocations against the same KILN_HOME observe the same store_id in
  # the metadata table. The id is derived purely from the normalised path;
  # there is no random fallback.
  defp deterministic_store_id(path) do
    "store_cli_" <> (:crypto.hash(:sha256, path) |> Base.encode16(case: :lower))
  end
end
