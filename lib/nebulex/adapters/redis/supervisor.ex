defmodule Nebulex.Adapters.Redis.Supervisor do
  @moduledoc false

  use Supervisor

  ## API

  @doc false
  def start_link({sup_name, child_specs, adapter_meta}) do
    Supervisor.start_link(__MODULE__, {child_specs, adapter_meta}, name: sup_name)
  end

  ## Supervisor callback

  @impl true
  def init({child_specs, %{registry: registry}}) do
    children = [{Registry, name: registry, keys: :unique} | child_specs]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
