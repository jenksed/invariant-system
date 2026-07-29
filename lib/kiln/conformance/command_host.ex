defmodule Kiln.Conformance.CommandHost do
  @moduledoc """
  Behaviour for the future OD-02 macOS process-group host helper.

  Prompt 6-A defines only the protocol boundary. It provides no helper binary,
  process launch, signal delivery, liveness probe, or Command execution.
  """

  @type launch_request :: map()
  @type launch_result :: map()
  @type signal_request :: map()
  @type probe_request :: map()
  @type probe_result :: map()
  @type reason :: map() | atom()

  @callback launch(launch_request()) :: {:ok, launch_result()} | {:error, reason()}
  @callback signal(signal_request()) :: :ok | {:error, reason()}
  @callback probe(probe_request()) :: {:ok, probe_result()} | {:error, reason()}
end
