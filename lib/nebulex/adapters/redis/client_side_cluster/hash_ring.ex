defmodule Nebulex.Adapters.Redis.ClientSideCluster.HashRing do
  @moduledoc false

  ## API

  if Code.ensure_loaded?(ExHashRing) do
    @doc false
    def child_spec(ring_name) do
      {ExHashRing.Ring, name: ring_name}
    end

    @doc false
    defdelegate find_node(ring, key), to: ExHashRing.Ring

    @doc false
    defdelegate add_node(ring, node_name, replicas), to: ExHashRing.Ring

    @doc false
    defdelegate get_replicas, to: ExHashRing.Configuration
  else
    @doc false
    def child_spec(_ring_name) do
      raise err_msg()
    end

    @doc false
    def find_node(_ring, _key) do
      raise err_msg()
    end

    @doc false
    def add_node(_ring, _node_name, _replicas) do
      raise err_msg()
    end

    @doc false
    def get_replicas do
      raise err_msg()
    end

    defp err_msg, do: ":ex_hash_ring dependency is required to use :client_side_cluster mode"
  end
end
