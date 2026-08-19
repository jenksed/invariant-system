defmodule Kiln.RPC.Handlers.Activity do
  @moduledoc """
  WP-09 Lane 1/2: bounded RPC handler for `activity.subscribe`.

  Returns the **initial canonical snapshot** for the subscription.
  Subsequent updates are delivered over WebSocket at `/ws`.

  This is the contract-freeze §9 `ActivitySubscribe` envelope's
  canonical-payload path. The same `subscription_id` is reused on
  the WebSocket connection so the Temper client can correlate.

  The handler is read-only: no mutation, no journal commit. It only
  reads the current canonical `session_revision` from the journal and
  packages it for the subscriber.

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
  def handle("activity.subscribe", params, _opts) when is_map(params) do
    with {:ok, subscription_id} <- require_string(params, "subscription_id"),
         {:ok, since_revision} <- coerce_integer(params["since_revision"], "since_revision", 0),
         {:ok, session_id} <- resolve_session_id(params) do
      case canonical_state(session_id) do
        {:ok, canonical_revision, unknowns, orphaned} ->
          # Register the subscription with the Hub so subsequent
          # journal commits on this Session fan out to the WS
          # connection that reuses the same `subscription_id`.
          :ok = ActivityHub.register(%{
            subscription_id: subscription_id,
            session_id: session_id,
            since_revision: since_revision
          })

          {:ok,
           %{
             "subscription_id" => subscription_id,
             "canonical_session_revision" => canonical_revision,
             "unknowns" => unknowns,
             "orphaned" => orphaned,
             "since_revision" => since_revision,
             "schema_version" => "kiln/activity/v1"
           }}

        {:error, %{code: _} = err} ->
          {:error, err}
      end
    end
  end

  def handle(_method, _params, _opts) do
    {:error, %{code: :E_UNKNOWN_METHOD}}
  end

  # -- helpers --

  defp require_string(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, %{code: :E_MISSING_FIELDS, reason: "missing required field: #{key}", fields: [key]}}
    end
  end

  defp coerce_integer(nil, _field, default), do: {:ok, default}

  defp coerce_integer(_value, field, _default) when is_integer(_value) and _value >= 0 do
    {:ok, _value}
  end

  defp coerce_integer(_, field, _default) do
    {:error, %{code: :E_INVALID_FIELD, reason: "#{field} must be a non-negative integer", field: field}}
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

  defp canonical_state(nil) do
    # No session filter — caller wants all canonical state. Return
    # the empty canonical state. Temper must explicitly subscribe
    # to a Session to receive notifications.
    {:ok, 0, [], false}
  end

  defp canonical_state(session_id) do
    case Restart.reconstruct(:activity_subscribe) do
      :empty ->
        {:error, %{code: :E_ACTIVITY_NOT_FOUND, reason: "no session in journal"}}

      {:ok, reconstruction} when is_map(reconstruction) ->
        cond do
          reconstruction[:session_id] != session_id ->
            {:error,
             %{
               code: :E_ACTIVITY_NOT_FOUND,
               reason: "session #{session_id} not present in canonical journal"
             }}

          true ->
            {:ok,
             reconstruction[:revision] || 0,
             reconstruction[:unknowns] || [],
             reconstruction[:orphaned] || false}
        end

      :multiple_sessions ->
        {:ok, 0, ["multiple_sessions_in_journal"], false}

      {:error, %{code: _} = err} ->
        {:error, err}
    end
  end
end
