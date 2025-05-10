defmodule Nebulex.Adapters.Redis.InfoTest do
  import Nebulex.CacheCase

  deftests "info" do
    @redis_info_sections ~w(
      server clients memory persistence stats replication cpu commandstats
      latencystats cluster modules keyspace errorstats
    )a

    test "returns all", %{cache: cache} do
      # equivalent to cache.info(:all)
      assert {:ok, info} = cache.info()

      for section <- @redis_info_sections do
        assert Map.fetch!(info, section) |> is_map()
      end
    end

    test "returns everything", %{cache: cache} do
      assert {:ok, info} = cache.info(:everything)

      for section <- @redis_info_sections do
        assert Map.fetch!(info, section) |> is_map()
      end
    end

    test "returns default", %{cache: cache} do
      assert {:ok, info} = cache.info(:default)

      for section <- @redis_info_sections -- ~w(commandstats latencystats)a do
        assert Map.fetch!(info, section) |> is_map()
      end
    end

    test "returns multiple sections", %{cache: cache} do
      assert %{server: %{}, memory: %{}, stats: %{}} = cache.info!([:server, :memory, :stats])
    end

    test "returns a single section", %{cache: cache} do
      assert %{evicted_keys: _} = cache.info!(:stats)
    end
  end
end
