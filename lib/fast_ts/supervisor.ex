defmodule FastTS.Supervisor do
  use Supervisor

  require Logger

  @moduledoc """
  FastTS main supervisor

  This Supervisor is responsible for starting and supervising the main components
  of the application:

  * Pipeline Runtime Engine (Pipeline Supervisor)
  * Router Modules 
  * Riemann Server

  It also implements the bridging mechanism between Router Modules (provided by the End User)
  and the Pipeline Engine.
  
  In particular, it:

  * Ensures that the Pipeline Engine (Pipeline Supervisor) is started before the Router Modules loading
  * Provides an API (`start_pipeline!`) for starting Pipeline processes dynamically in the Pipeline Engine

  ## Supervision tree overview:

  FastTS.Supervisor: FastTS main application supervisor
   |
   |- FastTS.Stream.Pipelines.Supervisor: Pipelines supervisor
   |   |
   |   |- FastTS.Stream.Pipeline: Pipeline process (started dynamically)
   |   |
   |   |- ... 
   |
   |- FastTS.Router.Modules: Supervisor for Router Modules manager
   |   |
   |   |- FastTS.Router.ModulesRegistry: Registry of Router Modules
   |   |
   |   |- FastTS.Router.ModulesLoader: Worker process that loads Router Modules
   |
   |- FastTS.Server: Tcp Server that accepts Riemann messages
  """

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children_specs
    |> supervise(strategy: :one_for_one)
  end

  @doc """
  Start a supervised pipeline process

  ## Parameters

  * `name`: Name of the pipeline, an atom built from the description of the pipeline (See FastTS.Router.pipeline)
  * `pipeline`: List of the pipeline instructions
  """
  def start_pipeline!(name, pipeline) do
    {:ok, _pid} = FastTS.Stream.Pipelines.Supervisor.start_pipeline(name, pipeline)
    Logger.debug "pipeline #{name} started"
  end

  defp children_specs do
    [
      # Pipelines supervisor:
      # Responsible for starting and supervise Pipeline processes dynamically
      supervisor(FastTS.Stream.Pipelines.Supervisor, []),
      # Router modules manager:
      # Responsible for loading and starting Router Modules
      worker(FastTS.Router.Modules, []),
      # Riemann Message Server:
      # Responsible for accepting input Riemann messages and forwarding
      # events to the pipelines
      # TODO: Make port configurable
      worker(Task, [FastTS.Server, :accept, [5555]])
    ]
  end

end
