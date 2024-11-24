defmodule Nebulex.Adapters.Redis.Cluster.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor

  import Nebulex.Utils, only: [camelize_and_concat: 1]

  ## API

  @spec start_link({Nebulex.Adapter.adapter_meta(), keyword()}) :: Supervisor.on_start()
  def start_link({adapter_meta, opts}) do
    name = camelize_and_concat([adapter_meta.name, DynamicSupervisor])

    DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  ## Callbacks

  @impl true
  def init(opts) do
    max_children = Keyword.get(opts, :max_children, :infinity)

    DynamicSupervisor.init(strategy: :one_for_one, max_children: max_children)
  end
end
