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
  #
  # The bounded MiniMax M3 provider transport (Finch) is supervised
  # unconditionally with the single pool sized for the bounded MiniMax
  # adapter. The adapter uses a single endpoint and never retries, so a
  # single connection per pool is sufficient. Disable in tests where
  # the deterministic transport seam is used instead.
  #
  # HTTP/1 is explicitly pinned because the bounded-receive pattern
  # (Finch.stream_while/5 returning {:halt, acc} on oversize) depends on
  # HTTP/1's connection-level back-pressure to terminate the provider's
  # stream. On HTTP/2, the same return value cancels the stream but does
  # NOT close the connection, leaving the bounded-receive property
  # unproven. Protocol hardening is documented in the M11 E4 audit.
  defp children do
    base =
      case Application.get_env(:kiln, :state_path) do
        nil -> []
        path -> [{Kiln.Store, path: path, name: Kiln.Store.Connection}]
      end

    base ++
      [
        {Finch,
         name: Kiln.MinimaxFinch,
         pools: %{
           default: [
             size: 1,
             protocols: [:http1]
           ]
         }}
      ]
  end
end
