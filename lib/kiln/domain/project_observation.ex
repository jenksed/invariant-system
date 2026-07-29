defmodule Kiln.Domain.ProjectObservation do
  @moduledoc """
  Caller-supplied metadata that binds a Session to one selected Repository.

  Construction performs no filesystem or Git access.
  """

  alias Kiln.Domain.{Error, Id}

  @enforce_keys [:id, :repository_root, :repository_fingerprint, :observed_at]
  defstruct [:id, :repository_root, :repository_fingerprint, :observed_at]

  @type t :: %__MODULE__{
          id: String.t(),
          repository_root: String.t(),
          repository_fingerprint: String.t(),
          observed_at: DateTime.t()
        }

  @spec new(map(), Id.entropy_source()) :: {:ok, t()} | {:error, Error.t()}
  def new(attrs, entropy_source \\ &:crypto.strong_rand_bytes/1) when is_map(attrs) do
    with {:ok, id} <- Id.generate(:project_observation, entropy_source),
         {:ok, repository_root} <- nonempty_string(attrs, :repository_root),
         {:ok, repository_fingerprint} <- digest(attrs, :repository_fingerprint),
         {:ok, observed_at} <- datetime(attrs, :observed_at) do
      {:ok,
       %__MODULE__{
         id: id,
         repository_root: repository_root,
         repository_fingerprint: repository_fingerprint,
         observed_at: observed_at
       }}
    end
  end

  def new(_attrs, _entropy_source) do
    {:error, Error.new(:invalid_attributes, "project observation attributes must be a map")}
  end

  defp nonempty_string(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a non-empty string", field)}
    end
  end

  defp digest(attrs, field) do
    with {:ok, value} <- nonempty_string(attrs, field),
         true <- Regex.match?(~r/^sha256:[0-9a-f]{64}$/, value) do
      {:ok, value}
    else
      {:error, %Error{} = error} -> {:error, error}
      false -> {:error, Error.new(:invalid_digest, "field must be a SHA-256 digest", field)}
    end
  end

  defp datetime(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, %DateTime{} = value} -> {:ok, value}
      _ -> {:error, Error.new(:invalid_field, "field must be a DateTime", field)}
    end
  end
end
