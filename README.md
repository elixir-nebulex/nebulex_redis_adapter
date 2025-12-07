# Nebulex.Adapters.Redis 🧱⚡
> Nebulex adapter for Redis (including [Redis Cluster][redis_cluster] support).

![CI](http://github.com/elixir-nebulex/nebulex_redis_adapter/workflows/CI/badge.svg)
[![Codecov](http://codecov.io/gh/elixir-nebulex/nebulex_redis_adapter/graph/badge.svg)](http://codecov.io/gh/elixir-nebulex/nebulex_redis_adapter/graph/badge.svg)
[![Hex.pm](http://img.shields.io/hexpm/v/nebulex_redis_adapter.svg)](http://hex.pm/packages/nebulex_redis_adapter)
[![Documentation](http://img.shields.io/badge/Documentation-ff69b4)](http://hexdocs.pm/nebulex_redis_adapter)

[redis_cluster]: http://redis.io/topics/cluster-tutorial
[redix]: http://github.com/whatyouhide/redix

## 📖 About

This adapter uses [Redix][redix], a Redis driver for Elixir, to provide a
production-ready caching solution with support for multiple deployment modes.

**Key Features:**

- **Three deployment modes:**
  - `:standalone` - Single Redis instance with connection pooling.
  - `:redis_cluster` - Native Redis Cluster with automatic sharding and failover.
  - `:client_side_cluster` - Client-side sharding across multiple Redis instances.
- **Automatic cluster topology discovery** for Redis Cluster mode.
- **Connection pooling** for high concurrency.
- **Custom serializers** for flexible data encoding.
- **Telemetry integration** for monitoring and observability.

The adapter supports different configuration modes, which are explained in the
following sections.

---

> [!NOTE]
>
> This README refers to the main branch of `nebulex_redis_adapter`,
> not the latest released version on Hex. Please reference the
> [official documentation][docs-lsr] for the latest stable release.

[docs-lsr]: http://hexdocs.pm/nebulex_redis_adapter/Nebulex.Adapters.Redis.html

---

## 🚀 Installation

Add `:nebulex_redis_adapter` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:nebulex_redis_adapter, "~> 3.0.0-rc.2"},
    {:telemetry, "~> 1.0"},   #=> For observability/telemetry support
    {:crc, "~> 0.10"},        #=> Needed when using `:redis_cluster` mode
    {:ex_hash_ring, "~> 7.0"} #=> Needed when using `:client_side_cluster` mode
  ]
end
```

The adapter dependencies are optional to provide more flexibility and load only
the needed ones. For example:

  * `:telemetry` - Add when you want to emit and consume telemetry events for
    monitoring cache operations (recommended).
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

[docs]: http://hexdocs.pm/nebulex_redis_adapter/3.0.0-rc.2/Nebulex.Adapters.Redis.html
[redis_example]: http://github.com/elixir-nebulex/nebulex_examples/tree/master/redis_cache

## 🌐 Distributed Caching

There are different ways to support distributed caching when using
**Nebulex.Adapters.Redis**.

### 🏗️ Redis Cluster

[Redis Cluster][redis_cluster] is the recommended approach for production
distributed caching. The adapter automatically discovers the cluster topology
and routes commands to the correct shards.

**Quick setup:**

```elixir
# 1. Define your cache
defmodule MyApp.RedisClusterCache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis
end

# 2. Configure in config/config.exs
config :my_app, MyApp.RedisClusterCache,
  mode: :redis_cluster,
  redis_cluster: [
    configuration_endpoints: [
      endpoint1_conn_opts: [
        host: "127.0.0.1",
        port: 6379,
        password: "password"
      ]
    ]
  ]
```

The adapter automatically:
- Connects to configuration endpoints.
- Fetches cluster topology via `CLUSTER SHARDS` (Redis 7+) or `CLUSTER SLOTS`.
- Creates connection pools for each shard.
- Handles `MOVED` errors with automatic retry.

See the [Redis Cluster documentation][redis_cluster_docs] for advanced
configuration options.

[redis_cluster_docs]: http://hexdocs.pm/nebulex_redis_adapter/Nebulex.Adapters.Redis.html#module-redis-cluster

### 🔗 Client-side Cluster

For distributing data across multiple independent Redis instances without Redis
Cluster, use client-side sharding with consistent hashing.

**Quick setup:**

```elixir
# 1. Define your cache
defmodule MyApp.ClusteredCache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Redis
end

# 2. Configure in config/config.exs
config :my_app, MyApp.ClusteredCache,
  mode: :client_side_cluster,
  client_side_cluster: [
    nodes: [
      node1: [pool_size: 10, conn_opts: [host: "127.0.0.1", port: 9001]],
      node2: [pool_size: 4, conn_opts: [host: "127.0.0.1", port: 9002]],
      node3: [conn_opts: [host: "127.0.0.1", port: 9003]]
    ]
  ]
```

The adapter uses consistent hashing to distribute keys across nodes. Each node
maintains its own connection pool.

See the [Client-side Cluster documentation][client_cluster_docs] for more
configuration options.

[client_cluster_docs]: http://hexdocs.pm/nebulex_redis_adapter/Nebulex.Adapters.Redis.html#module-client-side-cluster

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

The adapter provides `fetch_conn/1` and `fetch_conn!/1` to execute custom Redis
commands using `Redix`, while leveraging the adapter's connection pooling and
cluster routing.

```elixir
# Get a connection and execute Redis commands
iex> conn = MyCache.fetch_conn!()
iex> Redix.command!(conn, ["LPUSH", "mylist", "hello"])
1
iex> Redix.command!(conn, ["LRANGE", "mylist", "0", "-1"])
["hello"]
```

For cluster modes, provide a `:key` to ensure commands route to the correct
shard/node:

```elixir
iex> conn = MyCache.fetch_conn!(key: "mylist")
iex> Redix.pipeline!(conn, [
...>   ["LPUSH", "mylist", "world"],
...>   ["LRANGE", "mylist", "0", "-1"]
...> ])
[1, ["world"]]
```

See the [Using as Redis Client documentation][redis_client_docs] for encoding/
decoding helpers and advanced usage.

[redis_client_docs]: http://hexdocs.pm/nebulex_redis_adapter/Nebulex.Adapters.Redis.html#module-using-the-adapter-as-a-redis-client

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

Nebulex.Adapters.Redis source code is licensed under the [MIT License](LICENSE.md).
