defmodule FastTS.Router.Modules do
  use Supervisor

  require Logger
  alias FastTS.Router

  @moduledoc """
  Router modules Supervisor

  This module is responsible for starting and supervising the components
  that manage the Router Modules provided by the end user (See FastTS.Router).

  This includes keeping track of registered Router Modules (Router.ModulesRegistry),
  loading and starting the Pipelines of declared in the Router Modules (Router.ModulesLoader).
  """

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    child_specs
    |> supervise(strategy: :one_for_one)
  end

  defp child_specs do
    [ 
      # Modules Registry:
      # Keeps track of the router modules that were registered
      worker(Router.ModulesRegistry, []),
      # Modules Loader:
      # Transient process that loads the Router Modules
      worker(Router.ModulesLoader, [], restart: :transient),
    ]
  end

  @doc """
  Register a router module
  """
  def register_router(module) do
    Logger.info "Registering Router module: #{inspect module}"
    Router.ModulesRegistry.register(module)
  end


  @doc """
  Retrieves the list of all Router modules
  """
  def list do
    Router.ModulesRegistry.list
  end

  @doc """
  Retrieves the list of all pipelines of all router modules.

  ex:
      [ "Basic pipeline": [stateless: #Function<4.54730107/1 in FastTS.Stream.under/1>,
          stateless: #Function<6.54730107/1 in FastTS.Stream.stdout/0>],
        "Second pipeline": [stateful: #Function<5.54730107/2 in FastTS.Stream.rate/1>,
          stateless: #Function<0.54730107/1 in FastTS.Stream.email/1>,
          stateless: #Function<6.54730107/1 in FastTS.Stream.stdout/0>]]
  """
  def pipelines do
    Router.ModulesRegistry.list
    |> Enum.map(&module_streams/1)
    |> Enum.concat
  end

  # Apply the `streams` function of the module, which returns
  # a list of pipeline streams
  defp module_streams(module) do
    apply(module, :streams, [])
  end

end
