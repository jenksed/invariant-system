defmodule Kiln.Domain.Id do
  @moduledoc """
  Opaque identifiers for the first-month durable domain.

  Callers can inject an entropy function so tests never depend on randomness.
  """

  alias Kiln.Domain.Error

  @byte_count 16
  @prefixes %{
    project_observation: "pro",
    session: "ses",
    task: "tsk",
    run: "run",
    decision: "dec",
    operation: "opn",
    action: "act",
    idempotency: "idem"
  }

  @type kind ::
          :project_observation
          | :session
          | :task
          | :run
          | :decision
          | :operation
          | :action
          | :idempotency

  @type entropy_source :: (pos_integer() -> binary())

  @spec generate(kind(), entropy_source()) :: {:ok, String.t()} | {:error, Error.t()}
  def generate(kind, entropy_source \\ &:crypto.strong_rand_bytes/1)

  def generate(kind, entropy_source) when is_function(entropy_source, 1) do
    with {:ok, prefix} <- prefix(kind),
         entropy when is_binary(entropy) <- entropy_source.(@byte_count),
         :ok <- validate_entropy(entropy) do
      {:ok, prefix <> "_" <> Base.encode16(entropy, case: :lower)}
    else
      {:error, %Error{} = error} ->
        {:error, error}

      _ ->
        {:error, Error.new(:invalid_entropy, "entropy source must return 16 bytes")}
    end
  end

  def generate(_kind, _entropy_source) do
    {:error, Error.new(:invalid_entropy_source, "entropy source must be a function")}
  end

  @spec valid?(kind(), term()) :: boolean()
  def valid?(kind, value) do
    match?(:ok, validate(kind, value))
  end

  @spec validate(kind(), term()) :: :ok | {:error, Error.t()}
  def validate(kind, value) when is_binary(value) do
    with {:ok, prefix} <- prefix(kind),
         true <- Regex.match?(~r/^#{prefix}_[0-9a-f]{32}$/, value) do
      :ok
    else
      {:error, %Error{} = error} ->
        {:error, error}

      false ->
        {:error,
         Error.new(
           :invalid_identifier,
           "identifier does not match the required opaque format",
           :id,
           %{
             kind: kind
           }
         )}
    end
  end

  def validate(kind, _value) do
    case prefix(kind) do
      {:ok, _prefix} ->
        {:error,
         Error.new(:invalid_identifier, "identifier must be a string", :id, %{kind: kind})}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  @spec prefix(kind()) :: {:ok, String.t()} | {:error, Error.t()}
  def prefix(kind) do
    case Map.fetch(@prefixes, kind) do
      {:ok, prefix} ->
        {:ok, prefix}

      :error ->
        {:error,
         Error.new(:unsupported_identifier_kind, "identifier kind is not supported", :kind)}
    end
  end

  defp validate_entropy(entropy) when byte_size(entropy) == @byte_count, do: :ok

  defp validate_entropy(_entropy),
    do: {:error, Error.new(:invalid_entropy, "entropy source must return 16 bytes")}
end
