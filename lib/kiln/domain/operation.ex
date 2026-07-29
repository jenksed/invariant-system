defmodule Kiln.Domain.Operation do
  @moduledoc """
  Durable intent and observation shape for an accepted external-operation class.

  This module records no effect and dispatches nothing.
  """

  alias Kiln.Domain.{Error, Id}

  @classes [:model_invocation, :patch_application, :command_execution]
  @states [:intent_recorded, :started, :succeeded, :failed, :canceled, :unknown]
  @terminal_states [:succeeded, :failed, :canceled, :unknown]

  @enforce_keys [
    :id,
    :session_id,
    :run_id,
    :class,
    :state,
    :subject_id,
    :subject_revision,
    :idempotency_key,
    :request_digest,
    :recorded_at
  ]
  defstruct [
    :id,
    :session_id,
    :run_id,
    :class,
    :state,
    :subject_id,
    :subject_revision,
    :idempotency_key,
    :request_digest,
    :result_reference,
    :recorded_at,
    :observed_at
  ]

  @type class :: :model_invocation | :patch_application | :command_execution
  @type state :: :intent_recorded | :started | :succeeded | :failed | :canceled | :unknown

  @type t :: %__MODULE__{
          id: String.t(),
          session_id: String.t(),
          run_id: String.t(),
          class: class(),
          state: state(),
          subject_id: String.t(),
          subject_revision: non_neg_integer(),
          idempotency_key: String.t(),
          request_digest: String.t(),
          result_reference: String.t() | nil,
          recorded_at: DateTime.t(),
          observed_at: DateTime.t() | nil
        }

  @spec intent(map()) :: {:ok, t()} | {:error, Error.t()}
  def intent(attrs) when is_map(attrs) do
    with :ok <- Id.validate(:operation, Map.get(attrs, :id)),
         :ok <- Id.validate(:session, Map.get(attrs, :session_id)),
         :ok <- Id.validate(:run, Map.get(attrs, :run_id)),
         :ok <- validate_class(Map.get(attrs, :class)),
         {:ok, subject_id} <- nonempty_string(attrs, :subject_id),
         :ok <- validate_revision(Map.get(attrs, :subject_revision)),
         :ok <- Id.validate(:idempotency, Map.get(attrs, :idempotency_key)),
         {:ok, request_digest} <- digest(attrs, :request_digest),
         {:ok, recorded_at} <- datetime(attrs, :recorded_at) do
      {:ok,
       %__MODULE__{
         id: attrs.id,
         session_id: attrs.session_id,
         run_id: attrs.run_id,
         class: attrs.class,
         state: :intent_recorded,
         subject_id: subject_id,
         subject_revision: attrs.subject_revision,
         idempotency_key: attrs.idempotency_key,
         request_digest: request_digest,
         result_reference: nil,
         recorded_at: recorded_at,
         observed_at: nil
       }}
    end
  end

  def intent(_attrs),
    do: {:error, Error.new(:invalid_attributes, "operation attributes must be a map")}

  @spec observe(t(), state(), map()) :: {:ok, t()} | {:error, Error.t()}
  def observe(%__MODULE__{} = operation, state, attrs) when is_map(attrs) do
    with :ok <- validate_observation_transition(operation.state, state),
         {:ok, observed_at} <- datetime(attrs, :observed_at),
         {:ok, result_reference} <- optional_nonempty_string(attrs, :result_reference) do
      {:ok,
       %{
         operation
         | state: state,
           result_reference: result_reference,
           observed_at: observed_at
       }}
    end
  end

  def observe(%__MODULE__{}, _state, _attrs) do
    {:error, Error.new(:invalid_attributes, "operation observation attributes must be a map")}
  end

  @spec states() :: [state()]
  def states, do: @states

  @spec classes() :: [class()]
  def classes, do: @classes

  defp validate_class(class) when class in @classes, do: :ok

  defp validate_class(_class),
    do: {:error, Error.new(:invalid_operation_class, "operation class is not supported", :class)}

  defp validate_observation_transition(:intent_recorded, :started), do: :ok

  defp validate_observation_transition(:intent_recorded, state) when state in @terminal_states,
    do: :ok

  defp validate_observation_transition(:started, state) when state in @terminal_states,
    do: :ok

  defp validate_observation_transition(from, to) do
    {:error,
     Error.new(:invalid_operation_transition, "operation transition is not allowed", :state, %{
       from: from,
       to: to
     })}
  end

  defp validate_revision(value) when is_integer(value) and value >= 0, do: :ok

  defp validate_revision(_value) do
    {:error,
     Error.new(
       :invalid_revision,
       "subject revision must be a non-negative integer",
       :subject_revision
     )}
  end

  defp digest(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) ->
        if Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value) do
          {:ok, value}
        else
          {:error, Error.new(:invalid_digest, "field must be a SHA-256 digest", field)}
        end

      _ ->
        {:error, Error.new(:invalid_digest, "field must be a SHA-256 digest", field)}
    end
  end

  defp optional_nonempty_string(attrs, field) do
    case Map.get(attrs, field) do
      nil -> {:ok, nil}
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be nil or a non-empty string", field)}
    end
  end

  defp nonempty_string(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a non-empty string", field)}
    end
  end

  defp datetime(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, %DateTime{} = value} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a DateTime", field)}
    end
  end
end
