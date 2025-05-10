defmodule Nebulex.Adapters.Redis.StandaloneTest do
  use ExUnit.Case, async: true
  @moduletag capture_log: true

  # Inherited tests
  use Nebulex.Adapters.Redis.CacheTest
  use Nebulex.CacheTestCase, except: [Nebulex.Cache.TransactionTest]

  import Nebulex.CacheCase, only: [safe_stop: 1]

  alias Nebulex.Adapters.Redis.TestCache.Standalone, as: Cache

  setup do
    {:ok, pid} = Cache.start_link()

    _ = Cache.delete_all()

    on_exit(fn -> safe_stop(pid) end)

    {:ok, cache: Cache, name: Cache}
  end
end
