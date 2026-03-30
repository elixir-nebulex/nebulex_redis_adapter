defmodule Knock.Nebulex.Adapters.Redis.ClusterQueryableTest do
  use ExUnit.Case, async: false

  @moduletag :redis_cluster
  @moduletag :cluster_queryable_test
  @moduletag capture_log: true

  # Inherited tests from Nebulex
  use Knock.Nebulex.CacheTestCase,
    only: [
      Knock.Nebulex.Cache.QueryableTest,
      Knock.Nebulex.Cache.QueryableExpirationTest
    ]

  import Knock.Nebulex.CacheCase

  alias Knock.Nebulex.Adapters.Redis.TestCache.RedisCluster, as: Cache

  setup do
    {:ok, pid} = Cache.start_link()
    _ = Cache.delete_all!()

    on_exit(fn -> safe_stop(pid) end)

    {:ok, cache: Cache, name: Cache}
  end
end
