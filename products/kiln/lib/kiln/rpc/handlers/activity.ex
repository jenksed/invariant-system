defmodule Kiln.RPC.Handlers.Activity do
  @moduledoc """
  WP-09 Lane 1/2: bounded RPC handler for `activity.subscribe`.

  Returns the **initial canonical snapshot** for the subscription.
  Subsequent updates are delivered over WebSocket at `/ws`.

  The handler is read-only: no mutation, no journal commit. It reads
  the current canonical `session_revision` from the bounded journal
  and packages it for the subscriber.

  Required params:
    subscription_id — sub_<32hex>

  Optional:
    filter          — %{session_id?: ses_<32hex>}
    since_revision  — non-negative integer (default: 0)
    session_id      — ses_<32hex> (shorthand for filter.session_id)

  Scope (router.ex): orchestration:read

  Bounded error codes:
    E_MISSING_FIELDS, E_INVALID_FIELD, E_ACTIVITY_NOT_FOUND,
    E_STORE_UNAVAILABLE
  """

  alias Kiln.Activity.Hub, as: ActivityHub
  alias Kiln.Restart

  @doc "Dispatch `activity.subscribe`."
  @spec handle(String.t(), map(), keyword()) ::
          {:ok, term()} | {:error, %{required(:code) => atom()}}
  def handle("activity.subscribe", params, opts) when is_map(params) and is_list(opts) do
    _ = opts

    with {:ok, subscription_id} <- require_string(params, "subscription_id"),
         {:ok, since_revision} <- coerce_integer(params["since_revision"], "since_revision", 0),
         {:ok, session_id} <- resolve_session_id(params),
         {:ok, canonical_revision, unknowns, orphaned} <- canonical_state(session_id),
         :ok <- register_with_hub(subscription_id, session_id, since_revision) do
      {:ok,
       %{
         "subscription_id" => subscription_id,
         "canonical_session_revision" => canonical_revision,
         "unknowns" => unknowns,
         "orphaned" => orphaned,
         "since_revision" => since_revision,
         "schema_version" => "kiln/activity/v1"
       }}
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- helpers --

  defp require_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 ->
        {:ok, value}

      _ ->
        {:error,
         %{
           code: :E_MISSING_FIELDS,
           reason: "missing required field: #{key}",
           fields: [key]
         }}
    end
  end

  defp coerce_integer(nil, _field, default), do: {:ok, default}

  defp coerce_integer(value, _field, _default) when is_integer(value) and value >= 0 do
    {:ok, value}
  end

  defp coerce_integer(_, field, _default) do
    {:error,
     %{
       code: :E_INVALID_FIELD,
       reason: "#{field} must be a non-negative integer",
       field: field
     }}
  end

  defp resolve_session_id(params) do
    cond do
      is_binary(params["session_id"]) and byte_size(params["session_id"]) > 0 ->
        {:ok, params["session_id"]}

      is_map(params["filter"]) and is_binary(params["filter"]["session_id"]) and
          byte_size(params["filter"]["session_id"]) > 0 ->
        {:ok, params["filter"]["session_id"]}

      true ->
        {:ok, nil}
    end
  end

  # Register the subscription with the Hub using the calling process's
  # pid (the Plug adapter's request pid, in this RPC path). The Hub
  # uses the pid to fan out notifications via direct send/2.
  defp register_with_hub(subscription_id, session_id, since_revision) do
    pid = self()

    case ActivityHub.register(%{
           subscription_id: subscription_id,
           pid: pid,
           session_id: session_id,
           since_revision: since_revision
         }) do
      :ok -> :ok
      {:error, :already_registered} -> :ok
    end
  end

  # No session filter — caller wants all canonical state. Return
  # the empty canonical state. Temper must explicitly subscribe to a
  # Session to receive notifications.
  defp canonical_state(nil) do
    conn = Process.whereis(Kiln.Store.Connection)

    if is_nil(conn) do
      {:error, %{code: :E_STORE_UNAVAILABLE, reason: "Kiln.Store.Connection not registered"}}
    else
      case Restart.reconstruct(conn) do
        {:ok, :empty} -> {:ok, 0, [], false}
        {:ok, reconstruction} when is_map(reconstruction) -> canonical_from_reconstruction(reconstruction)
        {:error, %{code: :multiple_sessions} = err} -> {:error, Map.put(err, :reason, "multiple durable sessions in journal")}
        {:error, %{session_id: sid, block: block}} ->
          {:error, %{code: :E_JOURNAL_BLOCKED, reason: "journal blocked", session_id: sid, block: block}}
        {:error, %{code: _} = err} -> {:error, err}
      end
    end
  end

  defp canonical_state(session_id) do
    conn = Process.whereis(Kiln.Store.Connection)

    if is_nil(conn) do
      {:error, %{code: :E_STORE_UNAVAILABLE, reason: "Kiln.Store.Connection not registered"}}
    else
      case Restart.reconstruct(conn) do
        {:ok, :empty} ->
          {:error,
           %{
             code: :E_ACTIVITY_NOT_FOUND,
             reason: "no session in journal",
             session_id: session_id
           }}

        {:ok, reconstruction} when is_map(reconstruction) ->
          case Map.get(reconstruction, :session_id) do
            ^session_id ->
              canonical_from_reconstruction(reconstruction)

            other when other == session_id ->
              canonical_from_reconstruction(reconstruction)

            _ ->
              {:error,
               %{
                 code: :E_ACTIVITY_NOT_FOUND,
                 reason: "session #{session_id} not present in canonical journal",
                 session_id: session_id
               }}
          end

        {:error, %{code: :multiple_sessions} = err} ->
          {:error, Map.put(err, :reason, "multiple durable sessions in journal")}

        {:error, %{session_id: sid, block: block}} ->
          {:error,
           %{code: :E_JOURNAL_BLOCKED, reason: "journal blocked", session_id: sid, block: block}}

        {:error, %{code: _} = err} ->
          {:error, err}
      end
    end
  end

  defp canonical_from_reconstruction(reconstruction) do
    projection = Map.get(reconstruction, :projection)
    unknowns = if is_map(projection), do: Map.get(projection, "unknowns", []), else: []

    {:ok,
     Map.get(reconstruction, :session_revision, 0) || 0,
     unknowns,
     Map.get(reconstruction, :orphaned, false) || false}
  end
end
