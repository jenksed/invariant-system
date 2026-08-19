defmodule Kiln.Daemon do
  @moduledoc """
  M12-D WP-07: bounded Kiln daemon supervisor.

  Wraps a Plug.Cowboy http listener in an OTP supervisor for clean
  bounded lifecycle. Restart policy: `:permanent` (bounded daemon must
  survive transient crashes; bounded restart budget via `:max_restarts`).
  """

  use Supervisor

  alias Kiln.Service

  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, 4000)

    Supervisor.start_link(
      __MODULE__,
      [port: port],
      name: __MODULE__
    )
  end

  @impl Supervisor
  def init(port: port) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Service, options: [port: port]}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 5)
  end
end
