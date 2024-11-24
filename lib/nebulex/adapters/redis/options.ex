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
      Redis configuration mode.

        * `:standalone` - A single Redis instance. See the
          ["Standalone"](#module-standalone) section in the
          module documentation for more options.
        * `:redis_cluster` - Redis Cluster setup. See the
          ["Redis Cluster"](#module-redis-cluster) section in the
          module documentation for more options.
        * `:client_side_cluster` - See the
          ["Client-side Cluster"](#module-client-side-cluster) section in the
          module documentation for more options.

      """
    ],
    pool_size: [
      type: :pos_integer,
      required: false,
      doc: """
      The number of connections that will be started by the adapter
      (based on the `:mode`). The default value is `System.schedulers_online()`.
      """
    ],
    serializer: [
      type: {:custom, __MODULE__, :validate_behaviour, [Nebulex.Adapters.Redis.Serializer]},
      required: false,
      doc: """
      Custom serializer module implementing the `Nebulex.Adapters.Redis.Serializer`
      behaviour.
      """
    ],
    serializer_opts: [
      type: :keyword_list,
      required: false,
      default: [],
      doc: """
      Custom serializer options.
      """,
      keys: [
        encode_key: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options for encoding the key.
          """
        ],
        encode_value: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options for encoding the value.
          """
        ],
        decode_key: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options for decoding the key.
          """
        ],
        decode_value: [
          type: :keyword_list,
          required: false,
          default: [],
          doc: """
          Options for decoding the value.
          """
        ]
      ]
    ],
    conn_opts: [
      type: :keyword_list,
      required: false,
      default: [host: "127.0.0.1", port: 6379],
      doc: """
      Redis client options. See `Redix` docs for more information
      about the options.
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
          A keyword list of named endpoints where the key is an atom as
          an identifier and the value is another keyword list of options
          (same as `:conn_opts`).

          See ["Redis Cluster"](#module-redis-cluster) for more information.
          """,
          keys: [
            *: [
              type: :keyword_list,
              doc: """
              Same as `:conn_opts`.
              """
            ]
          ]
        ],
        override_master_host: [
          type: :boolean,
          required: false,
          default: false,
          doc: """
          Defines whether the given master host should be overridden with the
          configuration endpoint or not. Defaults to `false`.

          The adapter uses the host returned by the **"CLUSTER SHARDS"**
          (Redis >= 7) or **"CLUSTER SLOTS"** (Redis < 7) command. One may
          consider set it to `true` for tests when using Docker for example,
          or when Redis nodes are behind a load balancer that Redis doesn't
          know the endpoint of. See Redis docs for more information.
          """
        ],
        keyslot: [
          type: {:fun, 2},
          required: false,
          default: &RedisClusterKeyslot.hash_slot/2,
          doc: """
          A function to compute the hash slot for a given key and range.
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
          A keyword list of named nodes where the key is an atom as
          an identifier and the value is another keyword list of options
          (same as `:conn_opts`).

          See ["Client-side Cluster"](#module-client-side-cluster)
          for more information.
          """,
          keys: [
            *: [
              type: :keyword_list,
              doc: """
              Same as `:conn_opts`.

              Additionally, option `:ch_ring_replicas` is also allowed to
              indicate the number of replicas for the consistent hash ring.
              """
            ]
          ]
        ]
      ]
    ]
  ]

  # Command/Pipilene options
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
      Indicates whether to raise an exception when an error occurs or do nothing
      (skip errors).

      When the stream is evaluated, the adapter attempts to execute the `stream`
      command on the different nodes. Still, the execution could fail due to an
      RPC error or the command explicitly returns an error. If the option is set
      to `:raise`, the command will raise an exception when an error occurs on
      the stream evaluation. On the other hand, if it is set to `:nothing`, the
      error is skipped.
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
      The key is used to compute the node where the command will be executed.
      It is only required for `:redis_cluster` and `:client_side_cluster` modes.
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
