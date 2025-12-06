defmodule Nebulex.Adapters.Redis do
  @moduledoc """
  Nebulex adapter for Redis. This adapter is implemented using `Redix`
  (a Redis driver for Elixir).

  The adapter provides three setup alternatives:

    * **Standalone** - The adapter establishes a pool of connections
      with a single Redis node. The `:standalone` is the default mode.

    * **Redis Cluster** - [Redis Cluster](https://redis.io/topics/cluster-tutorial)
      is a built-in feature in Redis since version 3, and it may be the most
      convenient and recommendable way to set up Redis in a cluster and have
      a distributed cache storage out-of-box. This adapter provides the
      `:redis_cluster` mode to set up **Redis Cluster** from the client-side
      automatically and be able to use it transparently.

    * **Built-in client-side cluster** - The `:client_side_cluster` mode
      provides a simple client-side cluster implementation based on
      sharding distribution model.

  ## Standalone

  A cache that uses Redis is defined as follows:

      defmodule MyApp.RedisCache do
        use Nebulex.Cache,
          otp_app: :nebulex,
          adapter: Nebulex.Adapters.Redis
      end

  The configuration for the cache must be in your application environment,
  usually defined in your `config/config.exs`:

      config :my_app, MyApp.RedisCache,
        conn_opts: [
          host: "127.0.0.1",
          port: 6379
        ]

  ## Redis Cluster

  A cache that uses Redis Cluster can be defined as follows:

      defmodule MyApp.RedisClusterCache do
        use Nebulex.Cache,
          otp_app: :nebulex,
          adapter: Nebulex.Adapters.Redis
      end

  As you may notice, nothing has changed, it is defined the same as the
  standalone mode. The change is in the configuration:

      config :my_app, MyApp.RedisClusterCache,
        mode: :redis_cluster,
        redis_cluster: [
          # Configuration endpoints
          # The client connects to these endpoints to fetch cluster topology
          # using "CLUSTER SHARDS" (Redis >= 7) or "CLUSTER SLOTS" (Redis < 7).
          # Multiple endpoints can be provided for redundancy. The adapter will
          # try each endpoint until it successfully retrieves the topology.
          configuration_endpoints: [
            endpoint1_conn_opts: [
              host: "127.0.0.1",
              port: 6379,
              # Add the password if 'requirepass' is enabled
              password: "password"
            ],
            endpoint2_conn_opts: [
              host: "127.0.0.1",
              port: 6380,
              password: "password"
            ]
          ],

          # Optional: Override master host addresses returned by the cluster.
          # Useful when running Redis in Docker or behind NAT where the
          # advertised addresses differ from the actual connection addresses.
          # Defaults to `false`.
          override_master_host: false
        ]

  ## Client-side Cluster

  Same as the previous modes, a cache is defined as:

      defmodule MyApp.ClusteredCache do
        use Nebulex.Cache,
          otp_app: :nebulex,
          adapter: Nebulex.Adapters.Redis
      end

  The configuration:

      config :my_app, MyApp.ClusteredCache,
        mode: :client_side_cluster,
        client_side_cluster: [
          nodes: [
            node1: [
              pool_size: 10,
              conn_opts: [
                host: "127.0.0.1",
                port: 9001
              ]
            ],
            node2: [
              pool_size: 4,
              conn_opts: [
                url: "redis://127.0.0.1:9002"
              ]
            ],
            node3: [
              conn_opts: [
                host: "127.0.0.1",
                port: 9003
              ]
            ],
            ...
          ]
        ]

  > #### Redis Proxy Alternative {: .warning}
  >
  > Consider using a proxy instead, since it may provide more and better
  > features. See the "Redis Proxy" section below for more information.

  ## Redis Proxy

  Another option for "Redis Cluster" or the built-in "Client-side cluster" is
  using a proxy such as [Envoy proxy][envoy] or [Twemproxy][twemproxy] on top
  of Redis. In this case, the proxy does the distribution work, and from the
  adapter's side (**Nebulex.Adapters.Redis**), it would be only configuration.
  Instead of connecting the adapter against the Redis nodes, we connect it
  against the proxy nodes, this means, in the configuration, we set up the
  pool with the host and port pointing to the proxy.

  [envoy]: https://www.envoyproxy.io/
  [twemproxy]: https://github.com/twitter/twemproxy

  ## Configuration options

  In addition to `Nebulex.Cache` config options, the adapter supports the
  following options:

  #{Nebulex.Adapters.Redis.Options.start_options_docs()}

  ## Shared runtime options

  Since the adapter runs on top of `Redix`, all commands accept their options
  (e.g.: `:timeout`, and `:telemetry_metadata`). See `Redix` docs for more
  information.

  ### Redis Cluster runtime options

  The following options are only for the `:redis_cluster` mode and apply to all
  commands:

    * `:lock_retries` -  When the config manager is running and setting up
      the hash slot map, all Redis commands get blocked until the cluster
      is properly configured and the hash slot map is ready to use. This
      option defines the max retry attempts to acquire the lock before
      executing the command. Defaults to `:infinity`.

  ## Query API

  The queryable API is implemented using Redis `KEYS` command for pattern
  matching and operations like `get_all`, `delete_all`, and `count_all`.

  > #### Performance Warning {: .warning}
  >
  > The `KEYS` command can cause performance issues in production environments
  > because it blocks Redis while scanning all keys in the database. Consider
  > the following:
  >
  >   * Avoid using pattern queries (`get_all("pattern*")`) in production with
  >     large datasets.
  >   * Prefer explicit key lists (`get_all(in: [key1, key2])`) when
  >     possible.
  >   * Use `stream/2` instead of `get_all/2` for large result sets to reduce
  >     memory usage.
  >
  > This adapter currently uses the `KEYS` command. A refactoring to use
  > `SCAN` (the Redis-recommended approach for production) is planned for
  > the next release.

  Keep in mind the following limitations:

    * Only keys can be queried (not values or other attributes).
    * Only strings and predefined queries are allowed as query values.
    * Pattern queries scan the entire keyspace.

  See ["KEYS" command](https://redis.io/docs/latest/commands/keys/) for
  pattern syntax details.

  ### Examples

      iex> MyApp.RedisCache.put_all(%{
      ...>   "firstname" => "Albert",
      ...>   "lastname" => "Einstein",
      ...>   "age" => 76
      ...> })
      :ok

      # returns key/value pairs by default
      iex> MyApp.RedisCache.get_all!("**name**") |> Map.new()
      %{"firstname" => "Albert", "lastname" => "Einstein"}

      iex> MyApp.RedisCache.get_all!("**name**", select: :key)
      ["firstname", "lastname"]

      iex> MyApp.RedisCache.get_all!("a??", select: :key)
      ["age"]

      iex> MyApp.RedisCache.get_all!(select: :key)
      ["age", "firstname", "lastname"]

      iex> MyApp.RedisCache.stream!("**name**", select: :key) |> Enum.to_list()
      ["firstname", "lastname"]

  ### Deleting/counting keys

      iex> MyApp.RedisCache.delete_all!(in: ["foo", "bar"])
      2
      iex> MyApp.RedisCache.count_all!(in: ["foo", "bar"])
      2

  ## Transactions

  > #### Nebulex Transaction API {: .info}
  >
  > The `Nebulex.Adapter.Transaction` behaviour (for multi-operation
  > transactions via the `transaction/3` callback) is not currently implemented
  > in this adapter, but it is planned for future releases.
  >
  > However, the adapter does use Redis transactions (MULTI/EXEC) internally
  > to ensure atomicity for operations like `take/2`, `put_all/2`, and
  > `update_counter/3`. These internal transactions are transparent to users
  > and happen automatically when needed.

  ## Using the adapter as a Redis client

  Since the Redis adapter works on top of `Redix` and provides features like
  connection pools, "Redis Cluster", etc., it may also work as a Redis client.
  The Redis API is quite extensive, and there are many useful commands we may
  want to run, leveraging the Redis adapter features. Therefore, the adapter
  provides additional functions to do so.

  ### `fetch_conn(opts \\\\ [])`

  The function accepts the following options:

  #{Nebulex.Adapters.Redis.Options.fetch_conn_options_docs()}

  Let's see some examples:

      iex> MyCache.fetch_conn!()
      ...> |> Redix.command!(["LPUSH", "mylist", "hello"])
      1
      iex> MyCache.fetch_conn!()
      ...> |> Redix.command!(["LPUSH", "mylist", "world"])
      2
      iex> MyCache.fetch_conn!()
      ...> |> Redix.command!(["LRANGE", "mylist", "0", "-1"])
      ["hello", "world"]

  When working with `:redis_cluster` or `:client_side_cluster` modes the option
  `:key` is required:

      iex> {:ok, conn} = MyCache.fetch_conn(key: "mylist")
      iex> Redix.pipeline!(conn, [
      ...>   ["LPUSH", "mylist", "hello"],
      ...>   ["LPUSH", "mylist", "world"],
      ...>   ["LRANGE", "mylist", "0", "-1"]
      ...> ])
      [1, 2, ["hello", "world"]]

  Since these functions run on top of `Redix`, they also accept their options
  (e.g.: `:timeout`, and `:telemetry_metadata`). See `Redix` docs for more
  information.

  ### Encoding/decoding functions

  The following functions are available to encode/decode Elixir terms. It is
  useful whenever you want to work with Elixir terms in addition to strings
  or other specific Redis data types.

    * `encode_key(name \\\\ __MODULE__, key)` - Encodes an Elixir term into a
      string. The argument `name` is optional and should be used in case of
      dynamic caches (Defaults to the defined cache module).
    * `encode_value(name \\\\ __MODULE__, value)` - Same as `encode_key` but
      it is specific for encoding values, in case the encoding for keys and
      values are different.
    * `decode_key(name \\\\ __MODULE__, key)` - Decodes binary into an Elixir
      term. The argument `name` is optional and should be used in case of
      dynamic caches (Defaults to the defined cache module).
    * `decode_value(name \\\\ __MODULE__, value)` - Same as `decode_key` but
      it is specific for decoding values, in case the decoding for keys and
      values are different.

  Let's see some examples:

      iex> conn = MyCache.fetch_conn!()
      iex> key = MyCache.encode_key({:key, "key"})
      iex> value = MyCache.encode_value({:value, "value"})
      iex> Redix.command!(conn, ["SET", key, value], timeout: 5000)
      "OK"
      iex> Redix.command!(conn, ["GET", key]) |> MyCache.decode_value()
      {:value, "value"}

  ### Custom Serializers

  By default, the adapter uses Erlang's term format (`:erlang.term_to_binary/2`)
  for serialization, with strings being stored as-is. You can implement a
  custom serializer by creating a module that implements the
  `Nebulex.Adapters.Redis.Serializer` behaviour.

  This is useful when you need:
  - JSON serialization for interoperability with other systems.
  - Custom compression algorithms.
  - Different encoding strategies for keys vs values.
  - Integration with external serialization libraries.

  Example custom serializer using JSON:

      defmodule MyApp.JSONSerializer do
        @behaviour Nebulex.Adapters.Redis.Serializer

        @impl true
        def encode_key(key, _opts), do: JSON.encode!(key)

        @impl true
        def encode_value(value, _opts), do: JSON.encode!(value)

        @impl true
        def decode_key(key, _opts), do: JSON.decode!(key)

        @impl true
        def decode_value(value, _opts), do: JSON.decode!(value)
      end

  Then configure your cache to use the custom serializer:

      config :my_app, MyApp.RedisCache,
        serializer: MyApp.JSONSerializer

  ## Adapter-specific telemetry events for the `:redis_cluster` mode

  Aside from the recommended Telemetry events by `Nebulex.Cache`, this adapter
  exposes the following Telemetry events for the `:redis_cluster` mode:

    * `telemetry_prefix ++ [:redis_cluster, :setup, :start]` - This event is
      specific to the `:redis_cluster` mode. Before the configuration manager
      calls Redis to set up the cluster shards, this event should be invoked.

      The `:measurements` map will include the following:

      * `:system_time` - The current system time in native units from calling:
        `System.system_time()`.

      A Telemetry `:metadata` map including the following fields:

      * `:adapter_meta` - The adapter metadata.
      * `:pid` - The configuration manager PID.

    * `telemetry_prefix ++ [:redis_cluster, :setup, :stop]` - This event is
      specific to the `:redis_cluster` mode. After the configuration manager
      set up the cluster shards, this event should be invoked.

      The `:measurements` map will include the following:

      * `:duration` - The time spent configuring the cluster. The measurement
        is given in the `:native` time unit. You can read more about it in the
        docs for `System.convert_time_unit/3`.

      A Telemetry `:metadata` map including the following fields:

      * `:adapter_meta` - The adapter metadata.
      * `:pid` - The configuration manager PID.
      * `:status` - The cluster setup status. If the cluster was configured
        successfully, the status will be set to `:ok`, otherwise, will be
        set to `:error`.
      * `:reason` - The status reason. When the status is `:ok`, the reason is
        `:succeeded`, otherwise, it is the error reason.

    * `telemetry_prefix ++ [:redis_cluster, :setup, :exception]` - This event
      is specific to the `:redis_cluster` mode. When an exception is raised
      while configuring the cluster, this event should be invoked.

      The `:measurements` map will include the following:

      * `:duration` - The time spent configuring the cluster. The measurement
        is given in the `:native` time unit. You can read more about it in the
        docs for `System.convert_time_unit/3`.

      A Telemetry `:metadata` map including the following fields:

      * `:adapter_meta` - The adapter metadata.
      * `:pid` - The configuration manager PID.
      * `:kind` - The type of the error: `:error`, `:exit`, or `:throw`.
      * `:reason` - The reason of the error.
      * `:stacktrace` - The stacktrace.

  """

  # Provide Cache Implementation
  @behaviour Nebulex.Adapter
  @behaviour Nebulex.Adapter.KV
  @behaviour Nebulex.Adapter.Queryable
  @behaviour Nebulex.Adapter.Info

  # Inherit default observable implementation
  use Nebulex.Adapter.Observable

  # Inherit default serializer implementation
  use Nebulex.Adapters.Redis.Serializer

  import Nebulex.Utils

  alias Nebulex.Adapter

  alias __MODULE__.{
    Client,
    ClientSideCluster,
    Cluster,
    Connection,
    Options
  }

  ## Nebulex.Adapter

  @impl true
  defmacro __before_compile__(_env) do
    quote do
      @doc """
      A convenience to fetch a Redis connection.
      """
      def fetch_conn(opts \\ []) do
        opts = Options.validate_fetch_conn_opts!(opts)

        {name, opts} = Keyword.pop(opts, :name, __MODULE__)
        {key, opts} = Keyword.pop(opts, :key)

        name
        |> Adapter.lookup_meta()
        |> Client.fetch_conn(key, opts)
      end

      @doc """
      Same as `fetch_conn` but raises an exception in case of error.
      """
      def fetch_conn!(opts \\ []) do
        case fetch_conn(opts) do
          {:ok, conn} -> conn
          {:error, e} -> raise e
        end
      end

      @doc """
      A convenience to encode the given `key`.
      """
      def encode_key(name \\ __MODULE__, key) do
        %{serializer: sz, encode_key_opts: enc_opts} = Adapter.lookup_meta(name)

        sz.encode_key(key, enc_opts)
      end

      @doc """
      A convenience to decode the given `key`.
      """
      def decode_key(name \\ __MODULE__, key) do
        %{serializer: sz, decode_key_opts: dec_opts} = Adapter.lookup_meta(name)

        sz.decode_key(key, dec_opts)
      end

      @doc """
      A convenience to encode the given `value`.
      """
      def encode_value(name \\ __MODULE__, value) do
        %{serializer: sz, encode_value_opts: enc_opts} = Adapter.lookup_meta(name)

        sz.encode_value(value, enc_opts)
      end

      @doc """
      A convenience to decode the given `value`.
      """
      def decode_value(name \\ __MODULE__, value) do
        %{serializer: sz, decode_value_opts: dec_opts} = Adapter.lookup_meta(name)

        sz.decode_value(value, dec_opts)
      end
    end
  end

  @impl true
  def init(opts) do
    # Common options
    {telemetry_prefix, opts} = Keyword.pop!(opts, :telemetry_prefix)
    {telemetry, opts} = Keyword.pop!(opts, :telemetry)
    {cache, opts} = Keyword.pop!(opts, :cache)

    # Validate options
    opts = Options.validate_start_opts!(opts)

    # Get the cache name (required)
    name = opts[:name] || cache

    # Adapter mode
    mode = Keyword.fetch!(opts, :mode)

    # Local registry
    registry = camelize_and_concat([name, Registry])

    # Redis serializer for encoding/decoding keys and values
    serializer_meta = assert_serializer!(opts)

    # Resolve the pool size
    pool_size = Keyword.get_lazy(opts, :pool_size, fn -> System.schedulers_online() end)

    # Init adapter metadata
    adapter_meta =
      %{
        telemetry_prefix: telemetry_prefix,
        telemetry: telemetry,
        cache_pid: self(),
        name: opts[:name] || cache,
        mode: mode,
        pool_size: pool_size,
        registry: registry,
        started_at: DateTime.utc_now()
      }
      |> Map.merge(serializer_meta)

    # Init the connections child spec according to the adapter mode
    {conn_child_spec, adapter_meta} = do_init(adapter_meta, opts)

    # Supervisor name
    sup_name = camelize_and_concat([name, Supervisor])

    # Prepare child spec
    child_spec =
      Supervisor.child_spec(
        {Nebulex.Adapters.Redis.Supervisor, {sup_name, conn_child_spec, adapter_meta}},
        id: {__MODULE__, sup_name}
      )

    {:ok, child_spec, adapter_meta}
  end

  defp assert_serializer!(opts) do
    serializer = Keyword.get(opts, :serializer, __MODULE__)
    serializer_opts = Keyword.fetch!(opts, :serializer_opts)

    %{
      serializer: serializer,
      encode_key_opts: Keyword.fetch!(serializer_opts, :encode_key),
      encode_value_opts: Keyword.fetch!(serializer_opts, :encode_value),
      decode_key_opts: Keyword.fetch!(serializer_opts, :decode_key),
      decode_value_opts: Keyword.fetch!(serializer_opts, :decode_value)
    }
  end

  defp do_init(%{mode: :standalone} = adapter_meta, opts) do
    Connection.init(adapter_meta, opts)
  end

  defp do_init(%{mode: :redis_cluster} = adapter_meta, opts) do
    Cluster.init(adapter_meta, opts)
  end

  defp do_init(%{mode: :client_side_cluster} = adapter_meta, opts) do
    ClientSideCluster.init(adapter_meta, opts)
  end

  ## Nebulex.Adapter.KV

  @impl true
  def fetch(
        %{
          serializer: serializer,
          encode_key_opts: enc_key_opts,
          decode_value_opts: dec_value_opts
        } = adapter_meta,
        key,
        opts
      ) do
    redis_k = serializer.encode_key(key, enc_key_opts)

    adapter_meta
    |> Client.command(["GET", redis_k], Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, nil} ->
        wrap_error Nebulex.KeyError, key: key, reason: :not_found

      {:ok, value} ->
        {:ok, serializer.decode_value(value, dec_value_opts)}

      {:error, _} = e ->
        e
    end
  end

  @impl true
  def put(
        %{
          serializer: serializer,
          encode_key_opts: enc_key_opts,
          encode_value_opts: enc_value_opts
        } = adapter_meta,
        key,
        value,
        on_write,
        ttl,
        keep_ttl?,
        opts
      ) do
    redis_k = serializer.encode_key(key, enc_key_opts)
    redis_v = serializer.encode_value(value, enc_value_opts)
    put_opts = put_opts(on_write, ttl, keep_ttl?)

    Client.command(
      adapter_meta,
      ["SET", redis_k, redis_v | put_opts],
      Keyword.put(opts, :key, redis_k)
    )
    |> case do
      {:ok, "OK"} -> {:ok, true}
      {:ok, nil} -> {:ok, false}
      {:error, _} = e -> e
    end
  end

  @impl true
  def put_all(
        %{
          mode: mode,
          serializer: serializer,
          encode_key_opts: enc_key_opts,
          encode_value_opts: enc_value_opts
        } = adapter_meta,
        entries,
        on_write,
        ttl,
        opts
      ) do
    entries =
      Enum.map(entries, fn {key, val} ->
        {serializer.encode_key(key, enc_key_opts), serializer.encode_value(val, enc_value_opts)}
      end)

    case mode do
      :standalone ->
        do_put_all(adapter_meta, nil, entries, on_write, ttl, opts)

      _else ->
        cluster_put_all(adapter_meta, entries, on_write, ttl, opts)
    end
  end

  defp cluster_put_all(adapter_meta, entries, on_write, ttl, opts) do
    keys = Enum.map(entries, &elem(&1, 0))

    case execute(adapter_meta, %{op: :count_all, query: {:in, keys}}, []) do
      {:ok, 0} ->
        entries
        |> group_keys_by_hash_slot(adapter_meta, :tuples)
        |> Enum.reduce_while({:ok, true}, fn {hash_slot, group}, acc ->
          adapter_meta
          |> do_put_all(hash_slot, group, on_write, ttl, opts)
          |> handle_put_all_response(acc)
        end)

      {:ok, _} ->
        {:ok, false}

      error ->
        error
    end
  end

  defp do_put_all(adapter_meta, hash_slot, entries, on_write, ttl, opts) do
    cmd =
      case on_write do
        :put -> "MSET"
        :put_new -> "MSETNX"
      end

    {mset, expire} =
      Enum.reduce(entries, {[cmd], []}, fn {key, val}, {acc1, acc2} ->
        acc2 =
          if is_integer(ttl),
            do: [["PEXPIRE", key, ttl] | acc2],
            else: acc2

        {[val, key | acc1], acc2}
      end)

    with {:ok, [result | _]} <-
           Client.transaction_pipeline(
             adapter_meta,
             [Enum.reverse(mset) | expire],
             Keyword.put(opts, :key, hash_slot)
           ) do
      case result do
        "OK" -> {:ok, true}
        1 -> {:ok, true}
        0 -> {:ok, false}
      end
    end
  end

  defp handle_put_all_response({:ok, true}, acc) do
    {:cont, acc}
  end

  defp handle_put_all_response(other, _acc) do
    {:halt, other}
  end

  @impl true
  def delete(adapter_meta, key, opts) do
    redis_k = enc_key(adapter_meta, key)

    with {:ok, _} <-
           Client.command(adapter_meta, ["DEL", redis_k], Keyword.put(opts, :key, redis_k)) do
      :ok
    end
  end

  @impl true
  def take(%{serializer: serializer, decode_value_opts: dec_val_opts} = adapter_meta, key, opts) do
    redis_k = enc_key(adapter_meta, key)

    adapter_meta
    |> Client.transaction_pipeline(
      [["GET", redis_k], ["DEL", redis_k]],
      Keyword.put(opts, :key, redis_k)
    )
    |> case do
      {:ok, [nil | _]} ->
        wrap_error Nebulex.KeyError, key: key, reason: :not_found

      {:ok, [result | _]} ->
        {:ok, serializer.decode_value(result, dec_val_opts)}

      {:error, _} = e ->
        e
    end
  end

  @impl true
  def has_key?(adapter_meta, key, opts) do
    redis_k = enc_key(adapter_meta, key)

    adapter_meta
    |> Client.command(["EXISTS", redis_k], Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, 1} -> {:ok, true}
      {:ok, 0} -> {:ok, false}
      {:error, _} = e -> e
    end
  end

  @impl true
  def ttl(adapter_meta, key, opts) do
    redis_k = enc_key(adapter_meta, key)

    adapter_meta
    |> Client.command(["PTTL", redis_k], Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, -1} ->
        {:ok, :infinity}

      {:ok, -2} ->
        wrap_error Nebulex.KeyError, key: key, reason: :not_found

      {:ok, ttl} ->
        {:ok, ttl * 1000}

      {:error, _} = e ->
        e
    end
  end

  @impl true
  def expire(adapter_meta, key, ttl, opts) do
    do_expire(adapter_meta, enc_key(adapter_meta, key), ttl, opts)
  end

  defp do_expire(adapter_meta, redis_k, :infinity, opts) do
    commands = [["PTTL", redis_k], ["PERSIST", redis_k]]

    adapter_meta
    |> Client.transaction_pipeline(commands, Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, [-2, 0]} -> {:ok, false}
      {:ok, [_, _]} -> {:ok, true}
      {:error, _} = e -> e
    end
  end

  defp do_expire(adapter_meta, redis_k, ttl, opts) do
    adapter_meta
    |> Client.command(["PEXPIRE", redis_k, ttl], Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, 1} -> {:ok, true}
      {:ok, 0} -> {:ok, false}
      {:error, _} = e -> e
    end
  end

  @impl true
  def touch(adapter_meta, key, opts) do
    redis_k = enc_key(adapter_meta, key)

    adapter_meta
    |> Client.command(["TOUCH", redis_k], Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, 1} -> {:ok, true}
      {:ok, 0} -> {:ok, false}
      {:error, _} = e -> e
    end
  end

  @impl true
  def update_counter(adapter_meta, key, incr, default, ttl, opts) do
    do_update_counter(adapter_meta, enc_key(adapter_meta, key), incr, ttl, default, opts)
  end

  defp do_update_counter(adapter_meta, redis_k, incr, :infinity, default, opts) do
    opts = Keyword.put(opts, :key, redis_k)

    with {:ok, ^incr} when default > 0 <-
           Client.command(adapter_meta, ["INCRBY", redis_k, incr], opts) do
      # The key didn't exist, increment the default value
      Client.command(adapter_meta, ["INCRBY", redis_k, default], opts)
    end
  end

  defp do_update_counter(adapter_meta, redis_k, incr, ttl, default, opts) do
    with {:ok, default_incr} <- default_incr(adapter_meta, redis_k, default, opts),
         {:ok, [result | _]} <-
           Client.transaction_pipeline(
             adapter_meta,
             [["INCRBY", redis_k, incr + default_incr], ["PEXPIRE", redis_k, ttl]],
             Keyword.put(opts, :key, redis_k)
           ) do
      {:ok, result}
    end
  end

  defp default_incr(adapter_meta, redis_k, default, opts) do
    adapter_meta
    |> Client.command(["EXISTS", redis_k], Keyword.put(opts, :key, redis_k))
    |> case do
      {:ok, 1} -> {:ok, 0}
      {:ok, 0} -> {:ok, default}
      {:error, _} = e -> e
    end
  end

  ## Nebulex.Adapter.Queryable

  @impl true
  def execute(adapter_meta, query_meta, opts)

  def execute(_adapter_meta, %{op: :get_all, query: {:in, []}}, _opts) do
    {:ok, []}
  end

  def execute(_adapter_meta, %{op: op, query: {:in, []}}, _opts)
      when op in [:count_all, :delete_all] do
    {:ok, 0}
  end

  def execute(%{mode: mode} = adapter_meta, %{op: :count_all, query: {:q, nil}}, opts) do
    exec(mode, [adapter_meta, ["DBSIZE"], opts], [0, &Kernel.+(&2, &1)])
  end

  def execute(%{mode: mode} = adapter_meta, %{op: :delete_all, query: {:q, nil}}, opts) do
    with {:ok, _} = ok <- exec(mode, [adapter_meta, ["DBSIZE"], opts], [0, &Kernel.+(&2, &1)]),
         {:ok, _} <- exec(mode, [adapter_meta, ["FLUSHDB"], opts], []) do
      ok
    end
  end

  def execute(%{mode: :standalone} = adapter_meta, %{op: :count_all, query: {:in, keys}}, opts)
      when is_list(keys) do
    command = ["EXISTS" | Enum.map(keys, &enc_key(adapter_meta, &1))]

    Client.command(adapter_meta, command, opts)
  end

  def execute(%{mode: :standalone} = adapter_meta, %{op: :delete_all, query: {:in, keys}}, opts)
      when is_list(keys) do
    command = ["DEL" | Enum.map(keys, &enc_key(adapter_meta, &1))]

    Client.command(adapter_meta, command, opts)
  end

  def execute(
        %{mode: :standalone} = adapter_meta,
        %{op: :get_all, query: {:in, keys}, select: select},
        opts
      )
      when is_list(keys) do
    mget(adapter_meta, enc_keys(keys, adapter_meta), select, opts)
  end

  def execute(adapter_meta, %{op: :get_all, query: {:in, keys}, select: select}, opts)
      when is_list(keys) do
    keys
    |> enc_keys(adapter_meta)
    |> group_keys_by_hash_slot(adapter_meta, :keys)
    |> Enum.reduce_while({:ok, []}, fn {hash_slot, keys}, {:ok, acc} ->
      case mget(adapter_meta, keys, select, opts, hash_slot) do
        {:ok, results} -> {:cont, {:ok, results ++ acc}}
        error -> {:halt, error}
      end
    end)
  end

  def execute(adapter_meta, %{op: op, query: {:in, keys}}, opts)
      when is_list(keys) do
    redis_cmd =
      case op do
        :count_all -> "EXISTS"
        :delete_all -> "DEL"
      end

    keys
    |> enc_keys(adapter_meta)
    |> group_keys_by_hash_slot(adapter_meta, :keys)
    |> Enum.reduce_while({:ok, 0}, fn {hash_slot, keys_group}, {:ok, acc} ->
      Client.command(
        adapter_meta,
        [redis_cmd | Enum.map(keys_group, &enc_key(adapter_meta, &1))],
        Keyword.put(opts, :key, hash_slot)
      )
      |> case do
        {:ok, count} ->
          {:cont, {:ok, acc + count}}

        {:error, _} = error ->
          {:halt, error}
      end
    end)
  end

  def execute(
        %{serializer: serializer, decode_key_opts: dec_key_opts} = adapter_meta,
        %{op: :get_all, query: {:q, query}, select: :key},
        opts
      ) do
    with {:ok, encoded_keys} <- execute_query(query, adapter_meta, opts) do
      {:ok, Enum.map(encoded_keys, &serializer.decode_key(&1, dec_key_opts))}
    end
  end

  def execute(
        %{mode: :standalone} = adapter_meta,
        %{op: :get_all, query: {:q, query}, select: select},
        opts
      ) do
    with {:ok, encoded_keys} <- execute_query(query, adapter_meta, opts) do
      mget(adapter_meta, encoded_keys, select, opts)
    end
  end

  def execute(adapter_meta, %{op: :get_all, query: {:q, query}, select: select}, opts) do
    with {:ok, encoded_keys} <- execute_query(query, adapter_meta, opts) do
      encoded_keys
      |> group_keys_by_hash_slot(adapter_meta, :keys)
      |> Enum.reduce_while({:ok, []}, fn {hash_slot, keys}, {:ok, acc} ->
        case mget(adapter_meta, keys, select, opts, hash_slot) do
          {:ok, ls} -> {:cont, {:ok, ls ++ acc}}
          {:error, _} = e -> {:halt, e}
        end
      end)
    end
  end

  def execute(adapter_meta, query, opts) do
    with {:ok, keys} <- execute(adapter_meta, %{query | op: :get_all, select: :key}, opts) do
      execute(adapter_meta, %{query | query: {:in, keys}}, opts)
    end
  end

  @impl true
  def stream(adapter_meta, query, opts) do
    _ = assert_query(query)
    opts = Options.validate_stream_opts!(opts)

    Stream.resource(
      fn ->
        {on_error, opts} = Keyword.pop!(opts, :on_error)
        {_max_entries, opts} = Keyword.pop!(opts, :max_entries)

        {execute(adapter_meta, %{query | op: :get_all}, opts), on_error}
      end,
      fn
        {{:ok, []}, _on_error} ->
          {:halt, []}

        {{:ok, elems}, on_error} ->
          {elems, {{:ok, []}, on_error}}

        {{:error, _}, :nothing} ->
          {:halt, []}

        {{:error, reason}, :raise} ->
          stacktrace =
            Process.info(self(), :current_stacktrace)
            |> elem(1)
            |> tl()

          raise Nebulex.Error, reason: reason, stacktrace: stacktrace
      end,
      & &1
    )
    |> wrap_ok()
  end

  ## Nebulex.Adapter.Info

  @impl true
  def info(adapter_meta, spec, opts)

  def info(adapter_meta, section, opts) when section in [:all, :default, :everything] do
    with {:ok, info_str} <- Client.command(adapter_meta, ["INFO", section], opts) do
      {:ok, parse_info(info_str)}
    end
  end

  def info(adapter_meta, section, opts) when is_atom(section) do
    with {:ok, info} <- info(adapter_meta, [section], opts) do
      {:ok, Map.get(info, section, %{})}
    end
  end

  def info(adapter_meta, sections, opts) when is_list(sections) do
    sections = Enum.map(sections, &to_string/1)

    with {:ok, info_str} <- Client.command(adapter_meta, ["INFO" | sections], opts) do
      {:ok, parse_info(info_str)}
    end
  end

  defp parse_info(info_str) do
    info_str
    |> String.split("#", trim: true)
    |> Enum.map(&String.split(&1, ["\r\n", "\n"], trim: true))
    |> Map.new(&parse_info_items/1)
  end

  defp parse_info_items([name | items]) do
    key = atomify_key(name)

    info_map =
      Map.new(items, fn item ->
        [k, v] = String.split(item, ":", parts: 2)

        {atomify_key(k), v}
      end)

    {key, info_map}
  end

  ## Private Functions

  defp put_opts(on_write, ttl, _keep_ttl?) when is_integer(ttl) do
    put_opts(ttl: ttl, action: on_write)
  end

  defp put_opts(on_write, ttl, keep_ttl?) do
    put_opts(keep_ttl: keep_ttl?, ttl: ttl, action: on_write)
  end

  defp put_opts(keys) do
    Enum.reduce(keys, [], fn
      {:action, :put}, acc -> acc
      {:action, :put_new}, acc -> ["NX" | acc]
      {:action, :replace}, acc -> ["XX" | acc]
      {:ttl, :infinity}, acc -> acc
      {:ttl, ttl}, acc -> ["PX", "#{ttl}" | acc]
      {:keep_ttl, true}, acc -> ["KEEPTTL" | acc]
      {:keep_ttl, false}, acc -> acc
    end)
  end

  defp enc_key(%{serializer: serializer, encode_key_opts: enc_key_opts}, key) do
    serializer.encode_key(key, enc_key_opts)
  end

  defp enc_keys(keys, %{serializer: serializer, encode_key_opts: enc_key_opts}) do
    Enum.map(keys, &serializer.encode_key(&1, enc_key_opts))
  end

  defp assert_query(%{query: {:q, q}} = query) do
    %{query | query: {:q, assert_query(q)}}
  end

  defp assert_query(%{query: {:in, _}} = query) do
    query
  end

  defp assert_query(query) when is_nil(query) or is_binary(query) do
    query
  end

  defp assert_query(query) do
    raise Nebulex.QueryError, message: "invalid pattern", query: query
  end

  defp execute_query(nil, adapter_meta, opts) do
    execute_query("*", adapter_meta, opts)
  end

  defp execute_query(query, %{mode: mode} = adapter_meta, opts) do
    query = assert_query(query)

    exec(mode, [adapter_meta, ["KEYS", query], opts], [[], &Kernel.++(&1, &2)])
  end

  defp exec(:standalone, args, _extra_args) do
    apply(Client, :command, args)
  end

  defp exec(:redis_cluster, args, extra_args) do
    apply(Cluster, :command, args ++ extra_args)
  end

  defp exec(:client_side_cluster, args, extra_args) do
    apply(ClientSideCluster, :command, args ++ extra_args)
  end

  defp group_keys_by_hash_slot(enum, %{mode: :redis_cluster, keyslot: keyslot}, enum_type) do
    Cluster.group_keys_by_hash_slot(enum, keyslot, enum_type)
  end

  defp group_keys_by_hash_slot(enum, %{mode: :client_side_cluster, ring: ring}, enum_type) do
    ClientSideCluster.group_keys_by_hash_slot(enum, ring, enum_type)
  end

  defp select(key, _value, :key, _serializer, _dec_value_opts) do
    key
  end

  defp select(_key, value, :value, serializer, dec_value_opts) do
    serializer.decode_value(value, dec_value_opts)
  end

  defp select(key, value, {:key, :value}, serializer, dec_value_opts) do
    {key, serializer.decode_value(value, dec_value_opts)}
  end

  defp mget(adapter_meta, keys, select, opts, hash_slot_key \\ nil)

  defp mget(_adapter_meta, [], _select, _opts, _hash_slot_key) do
    {:ok, []}
  end

  defp mget(
         %{
           serializer: serializer,
           decode_key_opts: dec_key_opts,
           decode_value_opts: dec_value_opts
         } = adapter_meta,
         enc_keys,
         select,
         opts,
         hash_slot_key
       ) do
    with {:ok, result} <-
           Client.command(
             adapter_meta,
             ["MGET" | enc_keys],
             Keyword.put(opts, :key, hash_slot_key)
           ) do
      results =
        enc_keys
        |> Enum.map(&serializer.decode_key(&1, dec_key_opts))
        |> Enum.zip(result)
        |> Enum.reduce([], fn
          {_key, nil}, acc ->
            acc

          {key, value}, acc ->
            [select(key, value, select, serializer, dec_value_opts) | acc]
        end)

      {:ok, results}
    end
  end

  defp atomify_key(str) when is_binary(str) do
    str
    |> String.downcase()
    |> String.trim()
    |> to_atom()
  end

  defp to_atom(str) when is_binary(str) do
    String.to_existing_atom(str)
  rescue
    ArgumentError -> String.to_atom(str)
  end
end
