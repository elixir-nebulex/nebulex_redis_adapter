# Nebulex.Adapters.Redis 🧱⚡
> Nebulex adapter for Redis (including [Redis Cluster][redis_cluster] support).

![CI](http://github.com/elixir-nebulex/nebulex_redis_adapter/workflows/CI/badge.svg)
[![Codecov](http://codecov.io/gh/elixir-nebulex/nebulex_redis_adapter/graph/badge.svg)](http://codecov.io/gh/elixir-nebulex/nebulex_redis_adapter/graph/badge.svg)
[![Hex.pm](http://img.shields.io/hexpm/v/nebulex_redis_adapter.svg)](http://hex.pm/packages/nebulex_redis_adapter)
[![Documentation](http://img.shields.io/badge/Documentation-ff69b4)](http://hexdocs.pm/nebulex_redis_adapter)

[redis_cluster]: http://redis.io/topics/cluster-tutorial
[redix]: http://github.com/whatyouhide/redix

## 📖 About

This adapter uses [Redix][redix] - a Redis driver for Elixir.

The adapter supports different configuration modes, which are explained in the
following sections.

---

> [!NOTE]
>
> This README refers to the main branch of `nebulex_redis_adapter`,
> not the latest released version on Hex. Please reference the
> [official documentation][docs-lsr] for the latest stable release.

[docs-lsr]: http://hexdocs.pm/nebulex_redis_adapter/NebulexRedisAdapter.html

---

## 🚀 Installation

Add `:nebulex_redis_adapter` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:nebulex_redis_adapter, "~> 3.0.0-rc.1"},
    {:crc, "~> 0.10"},        #=> Needed when using `:redis_cluster` mode
    {:ex_hash_ring, "~> 6.0"} #=> Needed when using `:client_side_cluster` mode
  ]
end
```

The adapter dependencies are optional to provide more flexibility and load only
the needed ones. For example:

* `:crc` - Required when using the adapter in `:redis_cluster` mode.
  See [Redis Cluster][redis_cluster].
* `:ex_hash_ring` - Required when using the adapter in
  `:client_side_cluster` mode.

Then run `mix deps.get` to fetch the dependencies.

## 💻 Usage

After installing, you can define your cache to use the Redis adapter as follows:

```elixir
defmodule MyApp.RedisCache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis
end
```

The Redis configuration is set in your application environment, usually
defined in your `config/config.exs`:

```elixir
config :my_app, MyApp.RedisCache,
  conn_opts: [
    # Redix options
    host: "127.0.0.1",
    port: 6379
  ]
```

Since this adapter is implemented using `Redix`, it inherits the same
options, including regular Redis options and connection options. For
more information about the options, please check out the
`Nebulex.Adapters.Redis` module and also [Redix][redix].

See the [online documentation][docs] and [Redis cache example][redis_example]
for more information.

[docs]: http://hexdocs.pm/nebulex_redis_adapter/3.0.0-rc.1/Nebulex.Adapters.Redis.html
[redis_example]: http://github.com/elixir-nebulex/nebulex_examples/tree/master/redis_cache

## 🌐 Distributed Caching

There are different ways to support distributed caching when using
**Nebulex.Adapters.Redis**.

### 🏗️ Redis Cluster

[Redis Cluster][redis_cluster] is a built-in feature in Redis since version 3,
and it may be the most convenient and recommended way to set up Redis in a
cluster and have distributed cache storage out-of-the-box. This adapter provides
the `:redis_cluster` mode to set up **Redis Cluster** from the client-side
automatically and use it transparently.

First, ensure you have **Redis Cluster** configured and running.

Then you can define your cache which will use **Redis Cluster**:

```elixir
defmodule MyApp.RedisClusterCache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis
end
```

The configuration:

```elixir
config :my_app, MyApp.RedisClusterCache,
  # Enable redis_cluster mode
  mode: :redis_cluster,

  # For :redis_cluster mode this option must be provided
  redis_cluster: [
    # Configuration endpoints
    # This is where the client will connect and send the "CLUSTER SHARDS"
    # (Redis >= 7) or "CLUSTER SLOTS" (Redis < 7) command to get the cluster
    # information and set it up on the client side.
    configuration_endpoints: [
      endpoint1_conn_opts: [
        host: "127.0.0.1",
        port: 6379,
        # Add the password if 'requirepass' is enabled
        password: "password"
      ]
    ]
  ]
```

The pool of connections to the different master nodes is automatically
configured by the adapter once it gets the cluster slots information.

> This could be the easiest and recommended way for distributed caching
  using Redis and **Nebulex.Adapters.Redis**.

### 🔗 Client-side Cluster

**Nebulex.Adapters.Redis** also provides a simple client-side cluster
implementation based on a sharding distribution model.

Define your cache normally:

```elixir
defmodule MyApp.ClusteredCache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis
end
```

The configuration:

```elixir
config :my_app, MyApp.ClusteredCache,
  # Enable client-side cluster mode
  mode: :client_side_cluster,

  # For :client_side_cluster mode this option must be provided
  client_side_cluster: [
    # Nodes config (each node has its own options)
    nodes: [
      node1: [
        # Node pool size
        pool_size: 10,

        # Redix options to establish the pool of connections against this node
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
      ]
      # Maybe more nodes...
    ]
  ]
```

### 🌉 Using a Redis Proxy

Another option is to use a proxy, such as [Envoy proxy][envoy] or
[Twemproxy][twemproxy], on top of Redis. In this case, the proxy handles the
distribution work, and from the adapter's side (**Nebulex.Adapters.Redis**),
it would only require configuration. Instead of connecting the adapter to the
Redis nodes, you connect it to the proxy nodes. This means in the config,
you set up the pool with the host and port pointing to the proxy.

[envoy]: http://www.envoyproxy.io/
[twemproxy]: http://github.com/twitter/twemproxy

## 🔧 Using the Adapter as a Redis Client

Since the Redis adapter works on top of `Redix` and provides features like
connection pools, "Redis Cluster", etc., it can also work as a Redis client.
The Redis API is quite extensive, and there are many useful commands you may
want to run, leveraging the Redis adapter features. Therefore, the adapter
provides additional functions to do so.

```elixir
iex> conn = MyCache.fetch_conn!()
iex> Redix.command!(conn, ["LPUSH", "mylist", "world"])
1
iex> Redix.command!(conn, ["LPUSH", "mylist", "hello"])
2
iex> Redix.command!(conn, ["LRANGE", "mylist", "0", "-1"])
["hello", "world"]

iex> conn = MyCache.fetch_conn!(key: "mylist")
iex> Redix.pipeline!(conn, [
...>   ["LPUSH", "mylist", "world"],
...>   ["LPUSH", "mylist", "hello"],
...>   ["LRANGE", "mylist", "0", "-1"]
...> ])
[1, 2, ["hello", "world"]]
```

> [!NOTE]
>
> The `:name` may be needed when using dynamic caches, and the `:key` is
> required when using the `:redis_cluster` or `:client_side_cluster` mode.

## 🧪 Testing

To run the **Nebulex.Adapters.Redis** tests, you will need to have Redis running
locally. **Nebulex.Adapters.Redis** requires a complex setup for running tests
(since it needs several instances running for standalone, cluster, and Redis
Cluster modes). For this reason, there is a [docker-compose.yml](docker-compose.yml)
file in the repo so you can use [Docker][docker] and [docker-compose][docker_compose]
to spin up all the necessary Redis instances with just one command. Make sure
you have Docker installed and then just run:

```bash
$ docker-compose up
```

[docker]: http://www.docker.com/
[docker_compose]: http://docs.docker.com/compose/

Since `Nebulex.Adapters.Redis` uses the support modules and shared tests
from `Nebulex` and by default its test folder is not included in the Hex
dependency, the following steps are required for running the tests.

First, make sure you set the environment variable `NEBULEX_PATH`
to `nebulex`:

```bash
export NEBULEX_PATH=nebulex
```

Second, make sure you fetch the `:nebulex` dependency directly from GitHub
by running:

```bash
mix nbx.setup
```

Third, fetch the dependencies:

```bash
mix deps.get
```

Finally, you can run the tests:

```bash
mix test
```

Running tests with coverage:

```bash
mix coveralls.html
```

You will find the coverage report within `cover/excoveralls.html`.

## 📊 Benchmarks

Benchmarks were added using [benchee](http://github.com/PragTob/benchee);
to learn more, see the [benchmarks](./benchmarks) directory.

To run the benchmarks:

```bash
mix run benchmarks/benchmark.exs
```

> Benchmarks use default Redis options (`host: "127.0.0.1", port: 6379`).

## 🤝 Contributing

Contributions to Nebulex are very welcome and appreciated!

Use the [issue tracker](http://github.com/elixir-nebulex/nebulex_redis_adapter/issues)
for bug reports or feature requests. Open a
[pull request](http://github.com/elixir-nebulex/nebulex_redis_adapter/pulls)
when you are ready to contribute.

When submitting a pull request, you should not update the [CHANGELOG.md](CHANGELOG.md),
and also make sure you test your changes thoroughly, including unit tests
alongside new or changed code.

Before submitting a PR, it is highly recommended to run `mix test.ci` and ensure
all checks run successfully.

## 📄 Copyright and License

Copyright (c) 2018, Carlos Bolaños.

Nebulex.Adapters.Redis source code is licensed under the [MIT License](LICENSE).
