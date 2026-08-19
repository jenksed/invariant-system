defmodule Kiln.Activity.Hub do
  @moduledoc """
  WP-09 Lane 2: bounded activity publication + subscription hub.

  Architecture:
  * Single named GenServer (`Kiln.Activity.Hub`).
  * Subscribers register via `register/1` and receive notifications
    by direct `send/2` to the registered pid (the WebSocket handler
    passes its own pid so the Hub does not own the transport).
  * Publishers call `publish/1` from journal-commit sites AFTER the
    commit returns `{:ok, _}` — no speculative notifications.
  * The Hub holds NO authoritative state. It is a bounded fan-out;
    missed notifications are recovered via canonical `session.query`
    on reconnect (contract freeze §8).

  Notification envelope (contract freeze §7):

      %{
        type: "activity.notification",
        subscription_id: "sub_<32hex>",
        revision: <integer>,
        emitted_at: "2026-08-19T13:30:00Z",
        subject: %{kind: "session" | "run" | "operation", id: "..."},
        event_kind: "state_changed",
        canonical_session_revision: <integer>
      }

  Monotonicity rule (contract freeze §7):
  * `revision` is derived from authoritative `session_revision` after
    journal replay. NOT event count, NOT timestamp, NOT daemon uptime.
  * Subscribers MUST discard any notification whose `revision` is
    older than their last observed `canonical_session_revision`.

  Identity rules (contract freeze §3):
  * `client_id` and `subscription_id` are correlation handles only.
  * Neither is ever persisted into the journal or used for
    authorization.
  """

  use GenServer

  @name __MODULE__

  # -- public API --

  @doc "Start the bounded Hub under the application supervisor."
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, @name))
  end

  @doc """
  Register a subscription.

  Required:
    subscription_id — opaque handle minted by the caller
    pid             — pid to send notifications to
    session_id      — filter (or nil for all)
    since_revision  — initial revision hint

  Returns `:ok` or `{:error, :already_registered}`.
  """
  @spec register(%{
          required(:subscription_id) => String.t(),
          required(:pid) => pid(),
          required(:session_id) => String.t() | nil,
          required(:since_revision) => non_neg_integer()
        }) :: :ok | {:error, atom()}
  def register(%{subscription_id: sub_id} = sub) do
    GenServer.call(@name, {:register, sub_id, Map.from_struct(sub)})
  end

  @doc "Unregister a subscription. Idempotent."
  @spec unregister(String.t()) :: :ok
  def unregister(subscription_id) do
    GenServer.call(@name, {:unregister, subscription_id})
  end

  @doc """
  Publish a canonical state-change event to all matching subscribers.

  Required:
    session_id      — ses_<32hex>
    revision        — monotonic, derived from authoritative journal
    subject         — %{kind: "session" | "run" | "operation", id: "..."}
    canonical_session_revision — integer (current authoritative revision)

  The Hub never invents or mutates any field. It only fans out the
  caller-supplied envelope after a successful journal commit.
  """
  @spec publish(%{
          required(:session_id) => String.t(),
          required(:revision) => non_neg_integer(),
          required(:subject) => map(),
          required(:canonical_session_revision) => non_neg_integer()
        }) :: :ok
  def publish(event) do
    GenServer.cast(@name, {:publish, event})
  end

  @doc "Return the current subscription count (test/observability only)."
  @spec count() :: non_neg_integer()
  def count do
    GenServer.call(@name, :count)
  end

  # -- GenServer callbacks --

  @impl true
  def init(:ok) do
    {:ok, %{subscriptions: %{}, monotonic_revision: 0}}
  end

  @impl true
  def handle_call({:register, sub_id, sub}, _from, state) do
    case Map.get(state.subscriptions, sub_id) do
      nil ->
        subscriptions = Map.put(state.subscriptions, sub_id, sub)
        {:reply, :ok, %{state | subscriptions: subscriptions}}

      _existing ->
        {:reply, {:error, :already_registered}, state}
    end
  end

  def handle_call({:unregister, sub_id}, _from, state) do
    subscriptions = Map.delete(state.subscriptions, sub_id)
    {:reply, :ok, %{state | subscriptions: subscriptions}}
  end

  def handle_call(:count, _from, state) do
    {:reply, map_size(state.subscriptions), state}
  end

  @impl true
  def handle_cast({:publish, event}, state) do
    session_id = event.session_id
    revision = event.revision
    next_revision = max(state.monotonic_revision, revision)

    state = %{state | monotonic_revision: next_revision}

    Enum.each(state.subscriptions, fn {_sub_id, sub} ->
      if subscription_matches?(sub, session_id) and Process.alive?(sub.pid) do
        frame = %{
          type: "activity.notification",
          subscription_id: sub.subscription_id,
          revision: revision,
          emitted_at: DateTime.utc_now() |> DateTime.to_iso8601(),
          subject: event.subject,
          event_kind: "state_changed",
          canonical_session_revision: event.canonical_session_revision
        }

        send(sub.pid, {:activity_notification, frame})
      end
    end)

    {:noreply, state}
  end

  # -- helpers --

  defp subscription_matches?(sub, session_id) do
    is_nil(sub.session_id) or sub.session_id == session_id
  end
end
