defmodule Kiln.RPC.Router do
  @moduledoc """
  M12-D WP-07: bounded per-method RPC router.

  Per Pathfinder WP-02 service boundary decision:
  - Per-method scope (orchestration:read, orchestration:operate, terminal:operate,
    review:write, access:read, access:write)
  - Adapted from T3's scope table (client-server-boundary.md)
  - Bounded dispatch to bounded Kiln machinery
  - Bounded error envelope on any failure
  """

  @scopes %{
    # Map method name → required scope
    "worker.propose" => "orchestration:operate",
    "patch.apply" => "orchestration:operate",
    "verify.run" => "orchestration:operate",
    "review.propose" => "review:write",
    "human.decide" => "orchestration:operate",
    "project.open" => "orchestration:operate",
    "project.list" => "orchestration:read",
    "activity.subscribe" => "orchestration:read",
    "terminal.attach" => "terminal:operate"
  }

  # Bounded dispatch: method → scope → handler
  def dispatch(scope, %{"method" => method, "params" => params}) do
    case authorize(method, scope) do
      :ok ->
        case invoke(method, params) do
          {:ok, result} -> {:ok, result}
          {:error, reason} -> {:error, %{code: :E_DISPATCH_FAILED, reason: reason}}
        end

      {:error, %{code: :E_SCOPE_INSUFFICIENT} = err} ->
        bounded_error = Map.put(err, :scope, scope) |> Map.put(:method, method)
        {:error, bounded_error}

      {:error, %{code: :E_UNKNOWN_METHOD} = err} ->
        {:error, err}
    end
  end

  # Malformed body (missing method/params keys) → bounded error envelope
  def dispatch(_scope, _body) do
    {:error, %{code: :E_MALFORMED_REQUEST, reason: :missing_method_or_params}}
  end

  # Bounded scope authorization
  defp authorize(method, scope) do
    required = Map.get(@scopes, method)

    case required do
      nil -> {:error, %{code: :E_UNKNOWN_METHOD, method: method}}
      ^scope -> :ok
      _ -> {:error, %{code: :E_SCOPE_INSUFFICIENT, method: method}}
    end
  end

  # Bounded method invocation (placeholder handlers — populated by WP-08+)
  defp invoke(method, params) do
    case method do
      "project.list" -> {:ok, %{projects: []}}
      "project.open" -> {:ok, %{status: "opened", path: params["path"]}}
      _ -> {:error, %{code: :E_NOT_IMPLEMENTED, method: method}}
    end
  end
end
