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
  else
    @doc false
    def child_spec(_ring_name) do
      raise ":ex_hash_ring dependency is required to use :client_side_cluster mode"
    end

    @doc false
    def find_node(_ring, _key) do
      raise ":ex_hash_ring dependency is required to use :client_side_cluster mode"
    end
  end
end
