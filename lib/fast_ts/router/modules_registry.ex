defmodule FastTS.Router.ModulesRegistry do
  @moduledoc """
  Router modules Registry

  Simple Agent that keeps track of the Registered Router modules
  """

  @doc """
  Router agent: Keeps and serves the list of router modules.
  """
  def start_link do
    {:ok, _} = Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc """
  Retrieve the list of register router modules.
  """
  def list do
    Agent.get(__MODULE__, fn modules -> modules end)
  end

  @doc """
  Register a module as FastTS router.
  """
  def register(module) do
    Agent.update(__MODULE__, fn modules -> modules ++ [module] end)
  end

  def stop do
    Agent.stop(__MODULE__)
  end
end
