defmodule Nebulex.Adapters.Redis.ClusterCacheTest do
  use ExUnit.Case, async: false
  @moduletag :nebulex_test
  @moduletag capture_log: true

  # Inherited tests from Nebulex
  use Nebulex.CacheTestCase,
    only: [
      Nebulex.Cache.QueryableTest,
      Nebulex.Cache.QueryableExpirationTest
    ]

  import Nebulex.CacheCase

  alias Nebulex.Adapters.Redis.TestCache.RedisCluster, as: Cache

  setup do
    {:ok, pid} = Cache.start_link()
    _ = Cache.delete_all!()

    on_exit(fn -> safe_stop(pid) end)

    {:ok, cache: Cache, name: Cache}
  end
end
