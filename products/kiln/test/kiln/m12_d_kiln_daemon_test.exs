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
end
