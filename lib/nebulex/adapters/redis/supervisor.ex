defmodule Nebulex.Adapters.Redis.Supervisor do
  @moduledoc false

  use Supervisor

  ## API

  @doc false
  def start_link({sup_name, conn_child_spec, adapter_meta}) do
    Supervisor.start_link(__MODULE__, {conn_child_spec, adapter_meta}, name: sup_name)
  end

  ## Supervisor callback

  @impl true
  def init({conn_child_spec, %{registry: registry}}) do
    children = [
      {Registry, name: registry, keys: :unique},
      conn_child_spec
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
