defmodule Nebulex.Adapters.Redis.ClientSideCluster do
  @moduledoc """
  Client-side Cluster
  """

  import Nebulex.Adapters.Redis.Helpers
  import Nebulex.Utils, only: [camelize_and_concat: 1]

  alias __MODULE__.HashRing
  alias Nebulex.Adapters.Redis.{Options, Pool}

  @typedoc "Proxy type to the adapter meta"
  @type adapter_meta() :: Nebulex.Adapter.adapter_meta()

  @type node_entry() :: {node_name :: atom(), pool_size :: pos_integer()}
  @type nodes_config() :: [node_entry()]

  ## API

  @spec init(adapter_meta(), keyword()) :: {Supervisor.child_spec(), adapter_meta()}
  def init(%{name: name, pool_size: pool_size} = adapter_meta, opts) do
    cluster_opts = Keyword.get(opts, :client_side_cluster)

    # Ensure :client_side_cluster is provided
    if is_nil(cluster_opts) do
      raise NimbleOptions.ValidationError,
            Options.invalid_cluster_config_error(
              "invalid value for :client_side_cluster option: ",
              nil,
              :client_side_cluster
            )
    end

    nodes =
      cluster_opts
      |> Keyword.fetch!(:nodes)
      |> Map.new(&{to_string(elem(&1, 0)), Keyword.get(elem(&1, 1), :pool_size, pool_size)})

    ring_name = camelize_and_concat([name, Ring])

    adapter_meta = Map.merge(adapter_meta, %{nodes: nodes, ring: ring_name})

    children = [
      HashRing.child_spec(ring_name),
      {__MODULE__.NodeSupervisor, {adapter_meta, cluster_opts}}
    ]

    child_spec = %{
      id: {name, ClientSideClusterSupervisor},
      start: {Supervisor, :start_link, [children, [strategy: :rest_for_one]]},
      type: :supervisor
    }

    {child_spec, adapter_meta}
  end

  @spec command(
          Nebulex.Adapter.adapter_meta(),
          Redix.command(),
          keyword(),
          init_acc :: any(),
          reducer :: (any(), any() -> any())
        ) :: any()
  def command(
        %{name: name, registry: registry, nodes: nodes},
        command,
        opts,
        init_acc \\ nil,
        reducer \\ fn res, _ -> res end
      ) do
    Enum.reduce_while(nodes, {:ok, init_acc}, fn {node_name, pool_size}, {:ok, acc} ->
      registry
      |> do_command(name, node_name, pool_size, command, opts)
      |> handle_reduce_while(acc, reducer)
    end)
  end

  defp do_command(registry, name, node_name, pool_size, command, opts) do
    with {:ok, conn} <- Pool.fetch_conn(registry, {name, node_name}, pool_size) do
      Redix.command(conn, command, redis_command_opts(opts))
    end
  end

  defp handle_reduce_while({:ok, result}, acc, reducer) do
    {:cont, {:ok, reducer.(result, acc)}}
  end

  defp handle_reduce_while({:error, _} = e, _acc, _reducer) do
    {:halt, e}
  end

  @spec fetch_conn(adapter_meta(), {:"$hash_slot", any()} | any(), keyword()) ::
          {:ok, pid()} | {:error, Nebulex.Error.t()}
  def fetch_conn(adapter_meta, key, opts)

  def fetch_conn(
        %{name: name, registry: registry, nodes: nodes},
        {:"$hash_slot", node_name},
        _opts
      ) do
    pool_size = Map.fetch!(nodes, node_name)

    Pool.fetch_conn(registry, {name, node_name}, pool_size)
  end

  def fetch_conn(
        %{
          name: name,
          registry: registry,
          ring: ring,
          nodes: nodes
        },
        key,
        _opts
      ) do
    node = get_node(ring, key)
    pool_size = Map.fetch!(nodes, node)

    Pool.fetch_conn(registry, {name, node}, pool_size)
  end

  @spec group_keys_by_hash_slot(Enum.t(), atom(), atom()) :: map()
  def group_keys_by_hash_slot(enum, ring, type)

  def group_keys_by_hash_slot(enum, ring, :keys) do
    Enum.group_by(enum, &hash_slot(ring, &1))
  end

  def group_keys_by_hash_slot(enum, ring, :tuples) do
    Enum.group_by(enum, &hash_slot(ring, elem(&1, 0)))
  end

  ## Private Functions

  defp get_node(ring, key) do
    {:ok, node} = HashRing.find_node(ring, key)

    node
  end

  defp hash_slot(ring, key) do
    {:"$hash_slot", get_node(ring, key)}
  end
end
