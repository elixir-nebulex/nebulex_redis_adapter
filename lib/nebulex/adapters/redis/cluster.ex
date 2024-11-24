defmodule Nebulex.Adapters.Redis.Cluster do
  @moduledoc """
  Redis Cluster Manager
  """

  import Nebulex.Adapters.Redis.Helpers
  import Nebulex.Utils, only: [wrap_error: 2]

  alias __MODULE__.Keyslot
  alias Nebulex.Adapters.Redis.{ErrorFormatter, Options, Pool}

  @typedoc "Proxy type to the adapter meta"
  @type adapter_meta() :: Nebulex.Adapter.adapter_meta()

  # Redis cluster hash slots size
  @redis_cluster_hash_slots 16_384

  ## API

  @spec init(adapter_meta(), keyword()) :: {Supervisor.child_spec(), adapter_meta()}
  def init(%{name: name} = adapter_meta, opts) do
    # Ensure :redis_cluster is provided
    if is_nil(Keyword.get(opts, :redis_cluster)) do
      raise NimbleOptions.ValidationError,
            Options.invalid_cluster_config_error(
              "invalid value for :redis_cluster option: ",
              nil,
              :redis_cluster
            )
    end

    # Init ETS table to store the hash slot map
    cluster_shards_tab = init_hash_slot_map_table(name)

    # Update adapter meta
    adapter_meta =
      Map.merge(adapter_meta, %{
        cluster_shards_tab: cluster_shards_tab,
        keyslot: get_keyslot(opts)
      })

    children = [
      {__MODULE__.DynamicSupervisor, {adapter_meta, opts}},
      {__MODULE__.ConfigManager, {adapter_meta, opts}}
    ]

    child_spec = %{
      id: {name, RedisClusterSupervisor},
      start: {Supervisor, :start_link, [children, [strategy: :rest_for_one]]},
      type: :supervisor
    }

    {child_spec, adapter_meta}
  end

  @spec command(
          adapter_meta(),
          Redix.command(),
          keyword(),
          init_acc :: any(),
          (any(), any() -> any())
        ) :: any()
  def command(
        %{
          name: name,
          cluster_shards_tab: cluster_shards_tab,
          registry: registry,
          pool_size: pool_size
        },
        command,
        opts,
        init_acc \\ nil,
        reducer \\ fn res, _ -> res end
      ) do
    with_retry(name, Keyword.get(opts, :lock_retries, :infinity), fn ->
      reduce_while(cluster_shards_tab, {:ok, init_acc}, fn slot_id, {:ok, acc} ->
        registry
        |> do_command(slot_id, pool_size, command, opts)
        |> handle_reduce_while(acc, reducer)
      end)
    end)
  end

  defp do_command(registry, slot_id, pool_size, command, opts) do
    with {:ok, conn} <- Pool.fetch_conn(registry, slot_id, pool_size) do
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
  def fetch_conn(
        %{
          name: name,
          keyslot: keyslot,
          cluster_shards_tab: cluster_shards_tab,
          registry: registry,
          pool_size: pool_size
        },
        key,
        opts
      ) do
    with_retry(name, Keyword.get(opts, :lock_retries, :infinity), fn ->
      init_acc = wrap_error Nebulex.Error, reason: :redis_connection_error, module: ErrorFormatter

      {:"$hash_slot", hash_slot} =
        case key do
          {:"$hash_slot", _} -> key
          _else -> hash_slot(key, keyslot)
        end

      reduce_while(cluster_shards_tab, init_acc, fn
        {start, stop} = slot_id, _acc when hash_slot >= start and hash_slot <= stop ->
          {:halt, Pool.fetch_conn(registry, slot_id, pool_size)}

        _, acc ->
          {:cont, acc}
      end)
    end)
  end

  @spec group_keys_by_hash_slot(Enum.t(), Keyslot.t(), atom()) :: map()
  def group_keys_by_hash_slot(enum, keyslot, type)

  def group_keys_by_hash_slot(enum, keyslot, :keys) do
    Enum.group_by(enum, &hash_slot(&1, keyslot))
  end

  def group_keys_by_hash_slot(enum, keyslot, :tuples) do
    Enum.group_by(enum, &hash_slot(elem(&1, 0), keyslot))
  end

  @spec hash_slot(any(), Keyslot.t()) :: {:"$hash_slot", non_neg_integer()}
  def hash_slot(key, keyslot \\ &Keyslot.hash_slot/2) do
    {:"$hash_slot", keyslot.(key, @redis_cluster_hash_slots)}
  end

  @spec get_status(atom(), atom()) :: atom()
  def get_status(name, default \\ nil) when is_atom(name) and is_atom(default) do
    name
    |> status_key()
    |> :persistent_term.get(default)
  end

  @spec put_status(atom(), atom()) :: :ok
  def put_status(name, status) when is_atom(name) and is_atom(status) do
    # An atom is a single word so this does not trigger a global GC
    name
    |> status_key()
    |> :persistent_term.put(status)
  end

  @spec del_status_key(atom()) :: :ok
  def del_status_key(name) when is_atom(name) do
    # An atom is a single word so this does not trigger a global GC
    _ignore =
      name
      |> status_key()
      |> :persistent_term.erase()

    :ok
  end

  @spec with_retry(atom(), pos_integer() | :infinity, (-> any())) :: any()
  def with_retry(name, retries, fun)
      when (is_integer(retries) and retries > 0) or retries == :infinity do
    with_retry(name, fun, retries, 1, :ok)
  end

  defp with_retry(name, fun, max_retries, retries, _last_status) when retries <= max_retries do
    case get_status(name) do
      :ok ->
        fun.()

      :locked ->
        :ok = random_sleep(retries)

        with_retry(name, fun, max_retries, retries + 1, :locked)

      :error ->
        wrap_error Nebulex.Error,
          module: ErrorFormatter,
          reason: {:redis_cluster_status_error, :error},
          cache: name

      nil ->
        :ok = random_sleep(retries)

        with_retry(name, fun, max_retries, retries + 1, :shutdown)
    end
  end

  defp with_retry(name, _fun, _max_retries, _retries, last_status) do
    wrap_error Nebulex.Error,
      module: ErrorFormatter,
      reason: {:redis_cluster_status_error, last_status},
      cache: name
  end

  ## Private Functions

  # Inline common instructions
  @compile {:inline, status_key: 1}

  defp status_key(name), do: {name, :redis_cluster_status}

  defp init_hash_slot_map_table(name) do
    :ets.new(name, [
      :ordered_set,
      :public,
      :named_table,
      read_concurrency: true
    ])
  end

  defp reduce_while(table, acc, reducer) do
    fun = fn elem, acc ->
      case reducer.(elem, acc) do
        {:cont, acc} -> acc
        {:halt, _} = halt -> throw(halt)
      end
    end

    :ets.foldl(fun, acc, table)
  catch
    {:halt, result} -> result
  end

  defp get_keyslot(opts) do
    opts
    |> Keyword.fetch!(:redis_cluster)
    |> Keyword.fetch!(:keyslot)
  end
end
