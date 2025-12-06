defmodule Nebulex.Adapters.Redis.Options do
  @moduledoc false

  import Nebulex.Utils

  alias Nebulex.Adapters.Redis.Cluster.Keyslot, as: RedisClusterKeyslot

  # Start option definitions
  start_opts = [
    mode: [
      type: {:in, [:standalone, :redis_cluster, :client_side_cluster]},
      required: false,
      default: :standalone,
      doc: """
      Defines the Redis configuration mode, which determines how the adapter
      connects to and distributes data across Redis instances.

        * `:standalone` - Single Redis instance mode. Use this for simple
          setups or development environments. Creates a pool of connections
          to one Redis server. See the ["Standalone"](#module-standalone)
          section for more options.

        * `:redis_cluster` - Native Redis Cluster mode. Use this for
          production distributed caching with automatic sharding, replication,
          and failover provided by Redis Cluster. The adapter automatically
          discovers cluster topology and routes commands to the correct shard.
          See the ["Redis Cluster"](#module-redis-cluster) section for more
          options.

        * `:client_side_cluster` - Client-side sharding mode. Use this when
          you need to distribute data across multiple independent Redis
          instances without Redis Cluster. The adapter uses consistent hashing
          to distribute keys. See the
          ["Client-side Cluster"](#module-client-side-cluster) section for
          more options.

      """
    ],
    pool_size: [
      type: :pos_integer,
      required: false,
      doc: """
      The number of connections per Redis instance or shard.

        * In `:standalone` mode: Total number of connections to the single
          Redis instance.
        * In `:redis_cluster` mode: Number of connections per shard
          (master node).
        * In `:client_side_cluster` mode: Number of connections per node
          (can be overridden per node in the node configuration).

      Defaults to `System.schedulers_online()`, which matches the number of
      available CPU cores and provides good concurrency.
      """
    ],
    serializer: [
      type: {:custom, __MODULE__, :validate_behaviour, [Nebulex.Adapters.Redis.Serializer]},
      required: false,
      doc: """
      Custom serializer module implementing the
      `Nebulex.Adapters.Redis.Serializer` behaviour.

      See the ["Custom Serializers"](#module-custom-serializers) section in
      the module documentation for examples.
      """
    ],
    serializer_opts: [
      type: :keyword_list,
      required: false,
      default: [],
      doc: """
      Options passed to the serializer module's encode/decode functions.
      These options are forwarded to your custom serializer and can be used
      to configure serialization behavior.
      """,
      keys: [
        encode_key: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options passed to `c:Nebulex.Adapters.Redis.Serializer.encode_key/2`
          when encoding cache keys before storing them in Redis.
          """
        ],
        encode_value: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options passed to `c:Nebulex.Adapters.Redis.Serializer.encode_value/2`
          when encoding cache values before storing them in Redis.
          """
        ],
        decode_key: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options passed to `c:Nebulex.Adapters.Redis.Serializer.decode_key/2`
          when decoding cache keys retrieved from Redis.
          """
        ],
        decode_value: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options passed to `c:Nebulex.Adapters.Redis.Serializer.decode_value/2`
          when decoding cache values retrieved from Redis.
          """
        ]
      ]
    ],
    conn_opts: [
      type: :keyword_list,
      required: false,
      default: [host: "127.0.0.1", port: 6379],
      doc: """
      Redis connection options for `:standalone` mode. These options are
      passed directly to `Redix` when establishing connections.

      For cluster modes, connection options are specified within
      `:redis_cluster` or `:client_side_cluster` configuration.

      See `Redix.start_link/1` for the complete list of available options.
      """
    ],
    redis_cluster: [
      type: {:custom, __MODULE__, :validate_non_empty_cluster_opts, [:redis_cluster]},
      required: false,
      doc: """
      Required only when `:mode` is set to `:redis_cluster`. A keyword list of
      options.

      See ["Redis Cluster options"](#module-redis-cluster-options)
      section below.
      """,
      subsection: """
      ### Redis Cluster options

      The available options are:
      """,
      keys: [
        configuration_endpoints: [
          type: {:custom, __MODULE__, :validate_non_empty_cluster_opts, [:redis_cluster]},
          required: true,
          doc: """
          A keyword list of Redis Cluster nodes used to discover and fetch
          the cluster topology.

          Each endpoint is identified by an atom key and configured with
          connection options (same format as `:conn_opts`). The adapter tries
          each endpoint in order until it successfully retrieves the cluster
          topology using **"CLUSTER SHARDS"** (Redis >= 7) or
          **"CLUSTER SLOTS"** (Redis < 7).

          Providing multiple endpoints improves reliability; if one node is
          unavailable, the adapter will try the next one.

          See ["Redis Cluster"](#module-redis-cluster) for configuration
          examples.
          """,
          keys: [
            *: [
              type: :keyword_list,
              doc: """
              Connection options for this endpoint. Same format as `:conn_opts`
              (`:host`, `:port`, `:password`, etc.).
              """
            ]
          ]
        ],
        override_master_host: [
          type: :boolean,
          required: false,
          default: false,
          doc: """
          Determines whether to override master host addresses returned by
          Redis Cluster with the configuration endpoint's host.

          By default (`false`), the adapter uses host addresses returned by
          **"CLUSTER SHARDS"** (Redis >= 7) or **"CLUSTER SLOTS"** (Redis < 7).
          Set to `true` when:

            * Running Redis in Docker, where advertised addresses differ from
              actual connection addresses.
            * Redis nodes are behind NAT or a load balancer.
            * The cluster advertises internal IPs unreachable from your
              application.

          When `true`, the adapter replaces cluster-advertised hosts with the
          host from the configuration endpoint that provided the topology.
          """
        ],
        keyslot: [
          type: {:fun, 2},
          required: false,
          default: &RedisClusterKeyslot.hash_slot/2,
          doc: """
          Custom function to compute the Redis Cluster hash slot for a given
          key.

          The function receives two arguments:
            1. `key` - The cache key (after serialization).
            2. `range` - The total number of hash slots (typically `16384`).

          It should return an integer between `0` and `range - 1`.

          The default implementation uses CRC16-XMODEM algorithm with support
          for hash tags (e.g., `{user}:123` and `{user}:456` map to the same
          slot). Only provide a custom function if you need different hash
          slot calculation logic.
          """
        ]
      ]
    ],
    client_side_cluster: [
      type: {:custom, __MODULE__, :validate_non_empty_cluster_opts, [:client_side_cluster]},
      required: false,
      doc: """
      Required only when `:mode` is set to `:client_side_cluster`. A keyword
      list of options.

      See ["Client-side Cluster options"](#module-client-side-cluster-options)
      section below.
      """,
      subsection: """
      ### Client-side Cluster options

      The available options are:
      """,
      keys: [
        nodes: [
          type: {:custom, __MODULE__, :validate_non_empty_cluster_opts, [:client_side_cluster]},
          required: true,
          doc: """
          A keyword list of independent Redis nodes that form the client-side
          cluster.

          Each node is identified by an atom key and configured with connection
          options. The adapter uses consistent hashing to distribute cache keys
          across these nodes. Each node can optionally override the global
          `:pool_size` setting.

          See ["Client-side Cluster"](#module-client-side-cluster) for
          configuration examples.
          """,
          keys: [
            *: [
              type: :keyword_list,
              doc: """
              Configuration options for this node. Accepts all `:conn_opts`
              options (`:host`, `:port`, `:password`, etc.) plus:

                * `:pool_size` - Override global pool size for this specific
                  node.
                * `:ch_ring_replicas` - Number of virtual nodes (replicas) in
                  the consistent hash ring. Higher values improve distribution
                  but increase memory usage.

              """
            ]
          ]
        ]
      ]
    ]
  ]

  # Command/Pipeline options
  command_opts = [
    timeout: [
      type: :timeout,
      required: false,
      default: :timer.seconds(5),
      doc: """
      Same as `Redix.pipeline/3`.
      """
    ],
    telemetry_metadata: [
      type: {:map, :any, :any},
      default: %{},
      doc: """
      Same as `Redix.pipeline/3`.
      """
    ]
  ]

  # Stream options
  stream_opts = [
    on_error: [
      type: {:in, [:nothing, :raise]},
      type_doc: "`:raise` | `:nothing`",
      required: false,
      default: :raise,
      doc: """
      Controls error handling behavior when streaming cache entries.

        * `:raise` (default) - Raises an exception immediately when an error
          occurs during stream evaluation. This ensures you're aware of any
          issues retrieving data.

        * `:nothing` - Silently skips errors and continues streaming. Use this
          when you want partial results even if some shards/nodes are
          unavailable.

      In cluster modes (`:redis_cluster` or `:client_side_cluster`), the
      adapter queries multiple Redis instances. Network errors, timeout issues,
      or Redis errors from any instance will trigger this error handler.
      """
    ]
  ]

  # Fetch connection options
  fetch_conn_opts = [
    name: [
      type: :atom,
      required: false,
      doc: """
      The name of the cache (in case you are using dynamic caches),
      otherwise it is not required (defaults to the cache module name).
      """
    ],
    key: [
      type: :any,
      required: false,
      doc: """
      A cache key used to determine which Redis instance/shard to connect to
      in cluster modes.

      Required for `:redis_cluster` and `:client_side_cluster` modes, where
      the adapter uses the key to:

        * In `:redis_cluster` mode: Calculate the hash slot to find the
          correct shard.
        * In `:client_side_cluster` mode: Use consistent hashing to select
          the appropriate node.

      When executing custom Redis commands (e.g., list operations, sorted
      sets), provide a key to ensure all operations target the same Redis
      instance. Not required for `:standalone` mode.
      """
    ]
  ]

  # Start options schema
  @start_opts_schema NimbleOptions.new!(start_opts)

  # Nebulex common option keys
  @nbx_start_opts Nebulex.Cache.Options.__compile_opts__() ++
                    Nebulex.Cache.Options.__start_opts__()

  # Stream options schema
  @stream_opts_schema NimbleOptions.new!(stream_opts ++ command_opts)

  # Stream options docs schema
  @stream_opts_docs_schema NimbleOptions.new!(stream_opts)

  # Fetch connection options schema
  @fetch_conn_opts_schema NimbleOptions.new!(fetch_conn_opts)

  ## Docs API

  # coveralls-ignore-start

  @spec start_options_docs() :: binary()
  def start_options_docs do
    NimbleOptions.docs(@start_opts_schema)
  end

  @spec stream_options_docs() :: binary()
  def stream_options_docs do
    NimbleOptions.docs(@stream_opts_docs_schema)
  end

  @spec fetch_conn_options_docs() :: binary()
  def fetch_conn_options_docs do
    NimbleOptions.docs(@fetch_conn_opts_schema)
  end

  # coveralls-ignore-stop

  ## Validation API

  @spec validate_start_opts!(keyword()) :: keyword()
  def validate_start_opts!(opts) do
    start_opts =
      opts
      |> Keyword.drop(@nbx_start_opts)
      |> NimbleOptions.validate!(@start_opts_schema)

    Keyword.merge(opts, start_opts)
  end

  @spec validate_stream_opts!(keyword()) :: keyword()
  def validate_stream_opts!(opts) do
    adapter_opts =
      opts
      |> Keyword.take([:timeout, :on_error])
      |> NimbleOptions.validate!(@stream_opts_schema)

    Keyword.merge(opts, adapter_opts)
  end

  @spec validate_fetch_conn_opts!(keyword()) :: keyword()
  def validate_fetch_conn_opts!(opts) do
    NimbleOptions.validate!(opts, @fetch_conn_opts_schema)
  end

  ## Helpers

  @doc false
  def validate_behaviour(module, behaviour) when is_atom(module) and is_atom(behaviour) do
    if behaviour in module_behaviours(module) do
      {:ok, module}
    else
      {:error, "expected #{inspect(module)} to implement the behaviour #{inspect(behaviour)}"}
    end
  end

  @doc false
  def validate_non_empty_cluster_opts(value, mode) do
    if keyword_list?(value) and value != [] do
      {:ok, value}
    else
      {:error, invalid_cluster_config_error(value, mode)}
    end
  end

  @doc false
  def invalid_cluster_config_error(prelude \\ "", value, mode)

  def invalid_cluster_config_error(prelude, value, :redis_cluster) do
    """
    #{prelude}expected non-empty keyword list, got: #{inspect(value)}

            Redis Cluster configuration example:

                config :my_app, MyApp.RedisClusterCache,
                  mode: :redis_cluster,
                  redis_cluster: [
                    configuration_endpoints: [
                      endpoint1_conn_opts: [
                        host: "127.0.0.1",
                        port: 6379,
                        password: "password"
                      ],
                      ...
                    ]
                  ]

            See the documentation for more information.
    """
  end

  def invalid_cluster_config_error(prelude, value, :client_side_cluster) do
    """
    #{prelude}expected non-empty keyword list, got: #{inspect(value)}

            Client-side Cluster configuration example:

                config :my_app, MyApp.ClientSideClusterCache,
                  mode: :client_side_cluster,
                  client_side_cluster: [
                    nodes: [
                      node1: [
                        conn_opts: [
                          host: "127.0.0.1",
                          port: 9001
                        ]
                      ],
                      ...
                    ]
                  ]

            See the documentation for more information.
    """
  end

  defp keyword_list?(value) do
    is_list(value) and Keyword.keyword?(value)
  end
end
