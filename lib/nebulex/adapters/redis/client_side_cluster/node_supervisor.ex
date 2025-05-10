defmodule Nebulex.Adapters.Redis.ClientSideCluster.NodeSupervisor do
  @moduledoc false
  use Supervisor

  alias ExHashRing.{Configuration, Ring}
  alias Nebulex.Adapters.Redis.ClientSideCluster.PoolSupervisor

  ## API

  @doc false
  def start_link({adapter_meta, opts}) do
    Supervisor.start_link(__MODULE__, {adapter_meta, opts})
  end

  ## Supervisor Callbacks

  @impl true
  def init({adapter_meta, opts}) do
    %{name: name, registry: registry, pool_size: pool_size, ring: ring} = adapter_meta

    children =
      opts
      |> Keyword.fetch!(:nodes)
      |> Enum.map(fn {node_name, node_opts} ->
        node_name = to_string(node_name)

        {replicas, node_opts} =
          Keyword.pop_lazy(node_opts, :ch_ring_replicas, fn ->
            Configuration.get_replicas()
          end)

        {:ok, _} = Ring.add_node(ring, node_name, replicas)

        node_opts =
          node_opts
          |> Keyword.put(:name, name)
          |> Keyword.put(:registry, registry)
          |> Keyword.put(:node, node_name)
          |> Keyword.put_new(:pool_size, pool_size)

        Supervisor.child_spec({PoolSupervisor, node_opts}, id: {name, node_name}, type: :supervisor)
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
