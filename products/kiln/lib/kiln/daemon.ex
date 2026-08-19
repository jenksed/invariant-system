defmodule Kiln.Daemon do
  @moduledoc """
  WP-07 + WP-09: bounded Kiln daemon supervisor.

  Wraps a `Plug.Cowboy` listener in an OTP supervisor for clean bounded
  lifecycle. Restart policy: `:permanent` (bounded daemon must survive
  transient crashes; bounded restart budget via `:max_restarts`).

  WP-09 Lane 2: the listener uses a Cowboy dispatch table that routes
  `/ws` to `Kiln.Activity.WebSocket` and all other paths to the HTTP
  `Kiln.Service` plug. Bearer authentication is performed twice (HTTP
  via the Plug's `authenticate/1`, WS via `Kiln.Activity.WebSocket.
  init/2` — both call into the same `Kiln.Service.verify_token/1`).
  """

  use Supervisor

  alias Plug.Cowboy

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
      # WP-09 Lane 2: the listener uses a Cowboy dispatch table that
      # routes /ws to Kiln.Activity.WebSocket and all other paths to
      # the HTTP Kiln.Service plug via Plug.Cowboy.Translator.
      #
      # Plug.Cowboy 2.9.0+ REQUIRES `:plug` in the child spec even when
      # `:dispatch` is supplied manually (see
      # deps/plug_cowboy/lib/plug/cowboy.ex:265-272 child_spec/1). With
      # a manual :dispatch, the plug value is NOT initialized nor
      # dispatched to (deps/plug_cowboy/lib/plug/cowboy.ex:25-27
      # `:dispatch` moduledoc); the dispatch table fully owns routing.
      # We supply Kiln.Service so the child spec is structurally
      # well-formed; the dispatch table overrides what the plug would
      # otherwise have served.
      {Cowboy,
       scheme: :http,
       plug: Kiln.Service,
       options: [
         port: port,
         dispatch: dispatch_table()
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 3, max_seconds: 5)
  end

  # Build the Cowboy route list (NOT the pre-compiled dispatch).
  #
  # `/ws` is handled by the WebSocket handler module; everything else
  # falls through to the Plug via `Plug.Cowboy.Translator`. The Plug
  # itself no longer responds to `/ws` — `Kiln.Service.handle_websocket/1`
  # was simplified in WP-09 Lane 2 to authenticate and hand off;
  # Cowboy routes the upgrade to the WebSocket handler before the Plug
  # sees the request.
  #
  # IMPORTANT: return the raw route list, NOT the result of
  # `:cowboy_router.compile/1`. Plug.Cowboy's `to_args/5`
  # (deps/plug_cowboy/lib/plug/cowboy.ex:370) unconditionally calls
  # `:cowboy_router.compile/1` on whatever `:dispatch` value it
  # receives. Pre-compiling here causes a double-compile and the
  # compiled 2-tuple fed back into `compile_paths/2` raises the
  # `<<"ws">>` catch-all error at deps/cowboy/src/cowboy_router.erl:92.
  defp dispatch_table do
    [
      {:_,
       [
         {"/ws", Kiln.Activity.WebSocket, []},
         {:_, {Plug.Cowboy.Translator, {Kiln.Service, []}}, []}
       ]}
    ]
  end
end
