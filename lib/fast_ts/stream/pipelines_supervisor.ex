defmodule FastTS.Stream.Pipelines.Supervisor do
  use Supervisor

  alias FastTS.Stream

  @moduledoc """
  Pipelines Supervisor

  Used to start dynamically and monitor the pipelines.
  """

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Dynamically start a pipeline process in the supervisor

  ## Parameters

  * `name`: Name of the pipeline, an atom built from the description of the pipeline (See FastTS.Router.pipeline)
  * `pipeline`: List of the pipeline instructions
  """
  def start_pipeline(name, pipeline) do
    Supervisor.start_child(__MODULE__, [name, pipeline])
  end

  def init(:ok) do
    # Starts the supervisor using simple_one_for_one strategy:
    # At init, no workers are started. Worker are expected to be started
    # dynamically using `start_pipeline`
    children_specs
    |> supervise(strategy: :simple_one_for_one)
  end

  defp children_specs do
    [
      # Template of Pipeline Worker, uesd by simple_one_for_one strategy
      # It starts a FastTS.Stream.Pipeline process
      worker(Stream.Pipeline, [], restart: :permanent)
    ]
  end
end