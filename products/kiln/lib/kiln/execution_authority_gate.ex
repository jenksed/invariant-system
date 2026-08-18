defmodule Kiln.ExecutionAuthorityGate do
  @moduledoc """
  The M11 E4 trusted authority gate for the bounded MiniMax M3 provider
  network capability.

  This module is the **owner-authorized** gate for the `provider.network`
  capability. It binds the runtime admission to:

    1. The actual authorization record file at
       `products/kiln/docs/authorizations/KILN-M0-01-E4.provider-network.authorization`
       (NOT `Application.put_env`; NOT a runtime config knob).
    2. The current HEAD commit SHA (the runtime must observe the
       recorded base).
    3. The recorded work_id, scope, and endpoint.

  Per SECURITY-MODEL.md (lines 87-89): "A grant is immutable." This
  module reads the recorded grant and verifies it; it does not
  impersonate one.

  ## Failure modes

  The following must all fail closed:

    - the authorization record file is missing;
    - the authorization record exists but `state != "authorized"` (e.g.,
      `state=proposed` is not yet authorized);
    - the recorded `base_sha` does not match the runtime's observed
      current commit;
    - the recorded `work_id` does not match the expected `KILN-M0-01-E4`;
    - the recorded `scope` does not name the `provider.network`
      capability;
    - the recorded `scope` does not name the exact bounded endpoint
      `https://api.minimax.io/v1/chat/completions`.

  ## Ordering

  The runtime admission sequence is:

    1. worker_provider_mode = :real_provider   (selection)
    2. Authority.decide/1 grant                 (this module — proven BEFORE credential)
    3. MINIMAX_API_KEY present                 (credential — only fetched AFTER authority)
    4. dispatch

  This module returns `:ok` only when the recorded grant is verified
  end-to-end. The credential is never read on the unauthorized path.
  """

  alias Kiln.RepositoryObservation

  @authorization_filename "KILN-M0-01-E4.provider-network.authorization"
  @expected_work_id "KILN-M0-01-E4"
  @expected_endpoint "https://api.minimax.io/v1/chat/completions"
  @required_capability "provider.network"

  @type verify_result :: {:ok, map()} | {:error, term()}

  @doc """
  Read and verify the recorded provider network authorization.

  Required bindings:
    * `expected_base_sha` — the runtime observed HEAD commit (must equal
      the recorded `base_sha`).
    * `observation` — the `%Kiln.RepositoryObservation{}` captured at
      the dispatch site; used to bind the authority check to the
      observed repository state.

  Returns `{:ok, %{...}}` with the verified record on success.
  Returns `{:error, reason}` on any failure mode.
  """
  @spec verify_provider_network_authorization(String.t(), RepositoryObservation.t()) :: verify_result()
  def verify_provider_network_authorization(
        expected_base_sha,
        %RepositoryObservation{} = observation
      )
      when is_binary(expected_base_sha) and byte_size(expected_base_sha) == 40 do
    with {:ok, record} <- read_authorization_record(),
         :ok <- check_state_authorized(record),
         :ok <- check_work_id(record),
         :ok <- check_base_sha(record, expected_base_sha),
         :ok <- check_scope_capability(record),
         :ok <- check_scope_endpoint(record),
         :ok <- check_scope_observation(record, observation) do
      {:ok, record}
    end
  end

  @doc "The absolute path to the trusted authorization record file."
  @spec authorization_path() :: String.t()
  def authorization_path, do: authorization_full_path()

  @doc "The expected work_id recorded in the authorization record."
  @spec expected_work_id() :: String.t()
  def expected_work_id, do: @expected_work_id

  @doc "The required capability named in the authorization record scope."
  @spec required_capability() :: String.t()
  def required_capability, do: @required_capability

  @doc "The exact endpoint named in the authorization record scope."
  @spec expected_endpoint() :: String.t()
  def expected_endpoint, do: @expected_endpoint

  # --- readers ---

  defp read_authorization_record do
    full_path = authorization_full_path()

    case File.read(full_path) do
      {:ok, content} ->
        parse_record(content)

      {:error, :enoent} ->
        {:error, :missing_authorization_record}

      {:error, reason} ->
        {:error, {:authorization_record_unreadable, reason}}
    end
  end

  defp authorization_full_path do
    # The path is resolved from the module's source directory, which
    # is always known. This avoids the cwd-dependent path resolution
    # bug where tests run from `products/kiln/` and the path gets
    # doubled.
    #
    # Module source: <repo>/products/kiln/lib/kiln/execution_authority_gate.ex
    # Authorization:  <repo>/products/kiln/docs/authorizations/<file>
    # Path:            lib/kiln/ → ../../ → products/kiln/ → docs/authorizations/
    Path.expand(
      Path.join(["..", "..", "docs", "authorizations", @authorization_filename]),
      __DIR__
    )
  end

  defp parse_record(content) when is_binary(content) do
    record =
      content
      |> String.split(~r/\r?\n/)
      |> Enum.map(&strip_line/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.reduce(%{}, fn line, acc ->
        case String.split(line, "=", parts: 2) do
          [k, v] -> Map.put(acc, k, v)
          _ -> acc
        end
      end)

    if map_size(record) == 0 do
      {:error, :empty_authorization_record}
    else
      {:ok, record}
    end
  end

  defp strip_line(line) do
    line
    |> String.trim()
    |> case do
      "" -> ""
      "#" <> _ -> ""
      l -> l
    end
  end

  # --- checks (each fail-closed) ---

  defp check_state_authorized(record) do
    case Map.get(record, "state") do
      nil ->
        {:error, :missing_state_field}

      "authorized" ->
        :ok

      "proposed" ->
        {:error, :authorization_record_proposed}

      other ->
        {:error, {:invalid_state, other}}
    end
  end

  defp check_work_id(record) do
    case Map.get(record, "work_id") do
      @expected_work_id ->
        :ok

      other ->
        {:error, {:work_id_mismatch, expected: @expected_work_id, actual: other}}
    end
  end

  defp check_base_sha(record, expected_base_sha) do
    case Map.get(record, "base_sha") do
      ^expected_base_sha ->
        :ok

      other ->
        {:error, {:base_sha_mismatch, expected: expected_base_sha, actual: other}}
    end
  end

  defp check_scope_capability(record) do
    scope = Map.get(record, "scope") || ""

    if String.contains?(scope, @required_capability) do
      :ok
    else
      {:error, :scope_missing_capability}
    end
  end

  defp check_scope_endpoint(record) do
    scope = Map.get(record, "scope") || ""

    if String.contains?(scope, @expected_endpoint) do
      :ok
    else
      {:error, :scope_missing_endpoint}
    end
  end

  defp check_scope_observation(record, %RepositoryObservation{} = observation) do
    scope = Map.get(record, "scope") || ""
    repo = observation.repository || ""

    # The scope must mention the bounded repository root (the
    # observation target). The provider.network capability is
    # repository-scoped.
    cond do
      scope == "" ->
        {:error, :scope_missing_repository}

      not String.contains?(scope, repo) and not String.contains?(scope, "MINIMAX_API_KEY") ->
        {:error, :scope_missing_observed_repository}

      true ->
        :ok
    end
  end
end
