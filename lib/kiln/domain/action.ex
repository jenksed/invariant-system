defmodule Kiln.Domain.Action do
  @moduledoc """
  Validated application-action envelope for later journal transactions.

  An action contains intent and concurrency controls. It performs no operation.
  """

  alias Kiln.Domain.{Error, Id}

  @actor_kinds [:local_user, :system]
  @action_kinds [
    :start_session,
    :revise_intent,
    :transition_run,
    :request_decision,
    :answer_decision,
    :record_operation_intent,
    :observe_operation,
    :fail_session,
    :cancel_session,
    :reconcile_operation,
    :finalize_completion
  ]
  @forbidden_payload_keys MapSet.new([
                            :pid,
                            "pid",
                            :process_id,
                            "process_id",
                            :provider_request_id,
                            "provider_request_id",
                            :branch,
                            "branch",
                            :worktree,
                            "worktree",
                            :transcript,
                            "transcript",
                            :hidden_reasoning,
                            "hidden_reasoning",
                            :artifact_payload,
                            "artifact_payload"
                          ])

  @enforce_keys [
    :id,
    :session_id,
    :run_id,
    :expected_session_revision,
    :idempotency_key,
    :actor_kind,
    :actor_id,
    :kind,
    :request_digest,
    :payload,
    :requested_at
  ]
  defstruct [
    :id,
    :session_id,
    :run_id,
    :expected_session_revision,
    :idempotency_key,
    :actor_kind,
    :actor_id,
    :kind,
    :request_digest,
    :payload,
    :causation_action_id,
    :correlation_id,
    :requested_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          session_id: String.t(),
          run_id: String.t() | nil,
          expected_session_revision: non_neg_integer(),
          idempotency_key: String.t(),
          actor_kind: :local_user | :system,
          actor_id: String.t(),
          kind: atom(),
          request_digest: String.t(),
          payload: map(),
          causation_action_id: String.t() | nil,
          correlation_id: String.t() | nil,
          requested_at: DateTime.t()
        }

  @spec new(map()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs) when is_map(attrs) do
    with :ok <- Id.validate(:action, Map.get(attrs, :id)),
         :ok <- Id.validate(:session, Map.get(attrs, :session_id)),
         :ok <- validate_optional_id(:run, Map.get(attrs, :run_id)),
         :ok <- validate_revision(Map.get(attrs, :expected_session_revision)),
         :ok <- Id.validate(:idempotency, Map.get(attrs, :idempotency_key)),
         :ok <- validate_actor_kind(Map.get(attrs, :actor_kind)),
         {:ok, actor_id} <- nonempty_string(attrs, :actor_id),
         :ok <- validate_action_kind(Map.get(attrs, :kind)),
         {:ok, request_digest} <- digest(attrs, :request_digest),
         {:ok, payload} <- payload(attrs),
         :ok <- validate_optional_id(:action, Map.get(attrs, :causation_action_id)),
         {:ok, correlation_id} <- optional_nonempty_string(attrs, :correlation_id),
         {:ok, requested_at} <- datetime(attrs, :requested_at) do
      {:ok,
       %__MODULE__{
         id: attrs.id,
         session_id: attrs.session_id,
         run_id: Map.get(attrs, :run_id),
         expected_session_revision: attrs.expected_session_revision,
         idempotency_key: attrs.idempotency_key,
         actor_kind: attrs.actor_kind,
         actor_id: actor_id,
         kind: attrs.kind,
         request_digest: request_digest,
         payload: payload,
         causation_action_id: Map.get(attrs, :causation_action_id),
         correlation_id: correlation_id,
         requested_at: requested_at
       }}
    end
  end

  def new(_attrs), do: {:error, Error.new(:invalid_attributes, "action attributes must be a map")}

  @spec kinds() :: [atom()]
  def kinds, do: @action_kinds

  defp validate_revision(value) when is_integer(value) and value >= 0, do: :ok

  defp validate_revision(_value) do
    {:error,
     Error.new(
       :invalid_revision,
       "expected Session revision must be a non-negative integer",
       :expected_session_revision
     )}
  end

  defp validate_actor_kind(kind) when kind in @actor_kinds, do: :ok

  defp validate_actor_kind(_kind),
    do: {:error, Error.new(:invalid_actor, "actor kind is not permitted", :actor_kind)}

  defp validate_action_kind(kind) when kind in @action_kinds, do: :ok

  defp validate_action_kind(_kind) do
    {:error, Error.new(:invalid_action_kind, "action kind is not supported", :kind)}
  end

  defp validate_optional_id(_kind, nil), do: :ok
  defp validate_optional_id(kind, value), do: Id.validate(kind, value)

  defp payload(attrs) do
    case Map.fetch(attrs, :payload) do
      {:ok, value} when is_map(value) ->
        case validate_payload_value(value) do
          :ok -> {:ok, value}
          {:error, %Error{} = error} -> {:error, error}
        end

      _ ->
        {:error, Error.new(:invalid_payload, "payload must be a map", :payload)}
    end
  end

  defp validate_payload_value(value) when is_map(value) do
    Enum.reduce_while(value, :ok, fn {key, child}, :ok ->
      cond do
        MapSet.member?(@forbidden_payload_keys, key) ->
          {:halt,
           {:error,
            Error.new(
              :forbidden_payload_field,
              "payload contains a forbidden runtime or sensitive field",
              :payload,
              %{
                key: key
              }
            )}}

        not (is_atom(key) or is_binary(key)) ->
          {:halt,
           {:error,
            Error.new(:invalid_payload, "payload keys must be atoms or strings", :payload)}}

        true ->
          case validate_payload_value(child) do
            :ok -> {:cont, :ok}
            {:error, %Error{} = error} -> {:halt, {:error, error}}
          end
      end
    end)
  end

  defp validate_payload_value(value) when is_list(value) do
    Enum.reduce_while(value, :ok, fn child, :ok ->
      case validate_payload_value(child) do
        :ok -> {:cont, :ok}
        {:error, %Error{} = error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp validate_payload_value(value)
       when is_binary(value) or is_boolean(value) or is_integer(value) or is_float(value) or
              is_nil(value),
       do: :ok

  defp validate_payload_value(_value) do
    {:error, Error.new(:invalid_payload, "payload values must be deterministic data", :payload)}
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
