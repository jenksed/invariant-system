defmodule Temper.M4WhyDispatcher do
  @moduledoc """
  M4 — async WHY request dispatcher (Gate 8).

  Tracks in-flight WHY requests by:
    - request_id
    - projection_generation
    - subject_identity
    - why_packet_version/input digest

  Stale responses are dropped.

  Architecture: Temper.M4 (M4-Q1, lane M4).
  """

  alias Kiln.Domain.SubjectIdentity
  alias Kiln.WhyPacket

  @type request_id :: String.t()
  @type generation :: pos_integer()

  @type inflight :: %{
          required(:request_id) => request_id(),
          required(:generation) => generation(),
          required(:subject) => SubjectIdentity.t() | nil,
          required(:packet_digest) => String.t() | nil,
          required(:status) => :open | :superseded | :closed
        }

  @type state :: %{
          required(:generation) => generation(),
          required(:inflight) => %{optional(request_id()) => inflight()},
          required(:panel_open) => boolean()
        }

  @doc "Initial state."
  @spec initial() :: state()
  def initial do
    %{generation: 0, inflight: %{}, panel_open: false}
  end

  @doc "Begin a new hydration generation. Bumps generation and invalidates old in-flight."
  @spec new_generation(state()) :: state()
  def new_generation(state) do
    %{state | generation: state.generation + 1, inflight: %{}}
  end

  @doc "Open the WHY panel."
  @spec open_panel(state()) :: state()
  def open_panel(state), do: %{state | panel_open: true}

  @doc "Close the WHY panel. In-flight requests are NOT auto-superseded by close; the
  caller must check the response against the panel state."
  @spec close_panel(state()) :: state()
  def close_panel(state), do: %{state | panel_open: false}

  @doc "Begin a WHY request. Returns the updated state with the request tracked."
  @spec begin_request(state(), SubjectIdentity.t() | nil, WhyPacket.t() | nil) :: {state(), inflight()}
  def begin_request(state, subject, packet) do
    request_id = "why_" <> unique_id()
    digest = packet && WhyPacket.digest(packet)

    req = %{
      request_id: request_id,
      generation: state.generation,
      subject: subject,
      packet_digest: digest,
      status: :open
    }

    state = put_in(state, [:inflight, request_id], req)
    {state, req}
  end

  @doc "Begin a second WHY request. The earlier open one is superseded."
  @spec begin_request_superseding(state(), SubjectIdentity.t() | nil, WhyPacket.t() | nil) ::
          {state(), inflight()}
  def begin_request_superseding(state, subject, packet) do
    state = %{
      state
      | inflight: Map.new(state.inflight, fn {k, v} -> {k, %{v | status: :superseded}} end)
    }

    begin_request(state, subject, packet)
  end

  @doc "Receive a response. Returns :accept if the response matches current state, :drop otherwise."
  @spec receive(state(), request_id(), map()) :: :accept | :drop
  def receive(%{panel_open: false}, _request_id, _body), do: :drop

  def receive(state, request_id, _body) do
    case Map.get(state.inflight, request_id) do
      nil ->
        :drop

      %{status: :superseded} ->
        :drop

      %{generation: gen} when gen != state.generation ->
        :drop

      _ ->
        :accept
    end
  end

  # --- private ---

  defp unique_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
