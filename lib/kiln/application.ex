defmodule Kiln.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Kiln.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  # The single store connection is supervised only when a local state path is
  # configured. Without it (tests, plain boot) no database is opened, so the
  # runtime that owns `$KILN_HOME` resolution opts the store in explicitly.
  defp children do
    case Application.get_env(:kiln, :state_path) do
      nil -> []
      path -> [{Kiln.Store, path: path, name: Kiln.Store.Connection}]
    end
  end
end
