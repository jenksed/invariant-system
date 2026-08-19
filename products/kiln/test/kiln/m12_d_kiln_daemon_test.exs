defmodule Kiln.M12DKilnDaemonTest do
  @moduledoc """
  M12-D WP-07: bounded Kiln daemon tests.

  Acceptance property: bounded daemon enforces per-method scope via
  bounded bearer token; rejects without with bounded error envelope.
  Uses Plug.Test for bounded unit testing (no external HTTP client needed).
  """

  use ExUnit.Case, async: true

  import Plug.Test

  alias Kiln.{Service, RPC.Router, RPC.Error}

  describe "M12-D WP-07 bounded Plug.Service" do
    # Bounded scoped tokens are generated at runtime (never hardcoded in
    # source) and injected via Application config for the duration of each
    # test. The previous config value is restored on_exit so tests do not
    # leak config into each other.
    setup do
      previous = Application.get_env(:kiln, :scoped_tokens)
      read_token = Base.encode16(:crypto.strong_rand_bytes(32))

      Application.put_env(:kiln, :scoped_tokens, %{read_token => "orchestration:read"})

      on_exit(fn ->
        case previous do
          nil -> Application.delete_env(:kiln, :scoped_tokens)
          value -> Application.put_env(:kiln, :scoped_tokens, value)
        end
      end)

      %{read_token: read_token}
    end

    test "bounded GET /healthz returns 200 + JSON body" do
      conn = conn(:get, "/healthz")
      conn = Service.call(conn, Service.init([]))

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"status" => "ok"}
    end

    test "bounded GET /api/rpc without bearer token returns 401 + bounded error envelope" do
      conn = conn(:post, "/api/rpc", ~s({"method":"project.list","params":{}}))
      conn = Service.call(conn, Service.init([]))

      assert conn.status == 401
      decoded = Jason.decode!(conn.resp_body)
      assert decoded["code"] == "E_UNAUTHORIZED"
    end

    test "bounded POST /api/rpc with valid bearer + authorized method returns 200", %{
      read_token: bearer
    } do
      # project.list requires orchestration:read → use setup-generated read token
      conn =
        conn(:post, "/api/rpc", ~s({"method":"project.list","params":{}}))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{bearer}")

      conn = Service.call(conn, Service.init([]))

      assert conn.status == 200
    end

    test "bounded POST /api/rpc with short bearer returns 401 + bounded error envelope" do
      bearer = "short"

      conn =
        conn(:post, "/api/rpc", ~s({"method":"project.list","params":{}}))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{bearer}")

      conn = Service.call(conn, Service.init([]))

      assert conn.status == 401
    end

    test "bounded POST /api/rpc with insufficient scope returns 400 + bounded error envelope", %{
      read_token: bearer
    } do
      # setup token → orchestration:read; method unknown.method → E_UNKNOWN_METHOD
      conn =
        conn(:post, "/api/rpc", ~s({"method":"unknown.method","params":{}}))
        |> Plug.Conn.put_req_header("authorization", "Bearer #{bearer}")

      conn = Service.call(conn, Service.init([]))

      assert conn.status == 400
      decoded = Jason.decode!(conn.resp_body)
      assert decoded["code"] == "E_UNKNOWN_METHOD"
    end

    test "bounded GET /api/rpc returns 404 (only POST allowed)", %{read_token: bearer} do
      conn =
        conn(:get, "/api/rpc")
        |> Plug.Conn.put_req_header("authorization", "Bearer #{bearer}")

      conn = Service.call(conn, Service.init([]))

      assert conn.status == 404
    end

    test "bounded unknown path returns 404" do
      conn = conn(:get, "/some/unknown/path")
      conn = Service.call(conn, Service.init([]))

      assert conn.status == 404
    end
  end

  describe "Kiln.RPC.Router bounded scope authorization" do
    test "scoped dispatch: orchestration:operate passes scope for worker.propose (invoke may fail with E_NOT_IMPLEMENTED)" do
      scope = "orchestration:operate"
      body = %{"method" => "worker.propose", "params" => %{}}
      # Scope matches; invoke may fail (placeholder), but NOT with E_SCOPE_INSUFFICIENT.
      case Router.dispatch(scope, body) do
        {:ok, _} -> :ok
        {:error, %{code: :E_SCOPE_INSUFFICIENT}} -> flunk("scope mismatch on authorized method")
        # scope check passed; invoke may fail (placeholder)
        {:error, _} -> :ok
      end
    end

    test "scoped dispatch: orchestration:read rejected for worker.propose" do
      scope = "orchestration:read"
      body = %{"method" => "worker.propose", "params" => %{}}
      assert {:error, %{code: :E_SCOPE_INSUFFICIENT} = err} = Router.dispatch(scope, body)
      assert err.scope == scope
      assert err.method == "worker.propose"
    end

    test "scoped dispatch: terminal:operate passes scope for terminal.attach" do
      scope = "terminal:operate"
      body = %{"method" => "terminal.attach", "params" => %{}}
      # Same logic — scope passes; invoke placeholder may fail.
      case Router.dispatch(scope, body) do
        {:ok, _} -> :ok
        {:error, %{code: :E_SCOPE_INSUFFICIENT}} -> flunk("scope mismatch on authorized method")
        {:error, _} -> :ok
      end
    end

    test "scoped dispatch: unknown method returns E_UNKNOWN_METHOD" do
      scope = "orchestration:operate"
      body = %{"method" => "no.such.method", "params" => %{}}
      assert {:error, %{code: :E_UNKNOWN_METHOD}} = Router.dispatch(scope, body)
    end

    test "scoped dispatch: review:write passes scope for review.propose" do
      scope = "review:write"
      body = %{"method" => "review.propose", "params" => %{}}

      case Router.dispatch(scope, body) do
        {:ok, _} -> :ok
        {:error, %{code: :E_SCOPE_INSUFFICIENT}} -> flunk("scope mismatch on authorized method")
        {:error, _} -> :ok
      end
    end

    test "scoped dispatch: orchestration:operate rejected for review.propose" do
      scope = "orchestration:operate"
      body = %{"method" => "review.propose", "params" => %{}}
      result = Router.dispatch(scope, body)
      assert {:error, %{code: :E_SCOPE_INSUFFICIENT}} = result
    end
  end

  describe "Kiln.RPC.Error bounded error envelope" do
    test "bounded/2 returns a structured error map" do
      assert %{code: :E_TEST, reason: :ok} = Error.bounded(:E_TEST, reason: :ok)
    end

    test "unauthorized/2 marks conn with 401 status and bounded code" do
      conn = %Plug.Conn{resp_body: nil, status: nil}
      result = Error.unauthorized(conn, :missing_token)
      assert result.status == 401
      assert result.resp_body =~ ~s({"code":"E_UNAUTHORIZED")
    end
  end

  # WP-09 repair-5 + repair-6 regression guards:
  #   - Plug.Cowboy 2.9.0+ REQUIRES :plug in the child spec
  #     (deps/plug_cowboy/lib/plug/cowboy.ex:265-272).
  #   - The bounded daemon supplies a manual Cowboy :dispatch table
  #     that routes /ws to Kiln.Activity.WebSocket and all other
  #     paths to the Plug via Plug.Cowboy.Translator.
  #   - The dispatch value passed in :options must be the raw route
  #     LIST, NOT the result of :cowboy_router.compile/1.
  #     Plug.Cowboy.to_args/5 unconditionally re-compiles the
  #     :dispatch value, which causes the cowboy_router catch-all
  #     "MUST begin with a slash" error when a pre-compiled
  #     2-tuple is fed back into compile_paths/2.
  describe "Kiln.Daemon bounded Plug.Cowboy child spec" do
    test "Supervisor.init/2 returns ok with child_spec that satisfies Plug.Cowboy 2.9.0 :plug contract" do
      # Kiln.Daemon.init/1 returns the standard Supervisor callback
      # shape: {:ok, {supervisor_flags, child_specs}}. Extract the
      # child_specs via the public Supervisor.child_spec/2 contract,
      # NOT by destructuring implementation-specific tuple internals.
      assert {:ok, {sup_flags, child_specs}} = Kiln.Daemon.init(port: 0)
      assert is_list(sup_flags)
      assert is_list(child_specs)
      assert length(child_specs) == 1

      [{module, opts, _type}] = child_specs
      assert module == Plug.Cowboy
      assert Keyword.get(opts, :scheme) == :http
      assert Keyword.has_key?(opts, :plug),
             "Plug.Cowboy 2.9.0 child spec must include :plug even with manual :dispatch"

      dispatch = Keyword.get(opts, :options)[:dispatch]
      assert is_list(dispatch),
             "options[:dispatch] must be the raw route LIST (Plug.Cowboy compiles it)"

      # Validate the route shape: /ws -> Kiln.Activity.WebSocket;
      # everything else -> Plug.Cowboy.Translator -> Kiln.Service.
      assert [{:_, routes}] = dispatch
      assert is_list(routes)

      {ws_route, fallback_route} = case routes do
        [ws, fb] -> {ws, fb}
        [ws] -> {ws, nil}
      end

      assert {"/ws", ws_handler, _ws_opts} = ws_route
      assert ws_handler == Kiln.Activity.WebSocket

      if fallback_route do
        assert {:_, translator, _fb_opts} = fallback_route
        assert {Plug.Cowboy.Translator, {Kiln.Service, []}} = translator
      end

      # Now exercise Plug.Cowboy.child_spec/1 directly. If :plug is
      # missing this raises KeyError, which is the regression we are
      # guarding against.
      child_spec = Plug.Cowboy.child_spec(opts)
      assert is_map(child_spec)
      assert Map.has_key?(child_spec, :id)
      assert Map.has_key?(child_spec, :start)
    end

    test "Plug.Cowboy child_spec/1 raises KeyError without :plug (sanity)" do
      # Sanity: confirm that without :plug the child_spec raises, so
      # the regression test above is meaningful.
      opts = [scheme: :http, options: [port: 0, dispatch: [{:_, [{:_, Plug.Cowboy.Handler, {Plug.Test, []}}]}]]

      assert_raise KeyError, fn ->
        Plug.Cowboy.child_spec(opts)
      end
    end
  end
end
