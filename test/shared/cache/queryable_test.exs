defmodule Nebulex.Adapters.Redis.QueryableTest do
  import Nebulex.CacheCase

  deftests "queryable" do
    use Mimic
    import Nebulex.CacheCase

    test "get_all!/1 returns all cached keys", %{cache: cache} do
      set1 = cache_put(cache, 1..50)
      set2 = cache_put(cache, 51..100)

      for x <- 1..100 do
        assert cache.get!(x) == x
      end

      expected = set1 ++ set2
      assert expected -- cache.get_all!(select: :key) == []

      set3 = Enum.to_list(20..60)
      :ok = Enum.each(set3, &cache.delete!/1)
      expected = Enum.sort(expected -- set3)

      assert expected -- cache.get_all!(select: :key) == []
    end

    test "stream!/1 returns a stream", %{cache: cache} do
      entries = for x <- 1..10, into: %{}, do: {x, x * 2}
      assert cache.put_all(entries) == :ok

      expected = Map.keys(entries)

      assert expected -- (cache.stream!(select: :key) |> Enum.to_list()) == []

      result =
        [query: nil, select: :key]
        |> cache.stream!(max_entries: 3)
        |> Enum.to_list()

      assert expected -- result == []

      assert_raise Nebulex.QueryError, fn ->
        cache.stream!(query: :invalid_query)
        |> Enum.to_list()
      end
    end

    test "get_all!/2 and stream!/2 with key pattern", %{cache: cache} do
      keys = ["age", "firstname", "lastname"]

      cache.put_all(%{
        "firstname" => "Albert",
        "lastname" => "Einstein",
        "age" => 76
      })

      assert cache.get_all!(query: "**name**", select: :key) |> Enum.sort() == [
               "firstname",
               "lastname"
             ]

      assert cache.get_all!(query: "a??", select: :key) == ["age"]
      assert keys -- cache.get_all!(select: :key) == []

      assert ["firstname", "lastname"] --
               (cache.stream!(query: "**name**", select: :key) |> Enum.to_list()) == []

      assert cache.stream!(query: "a??", select: :key) |> Enum.to_list() == ["age"]
      assert keys -- (cache.stream!(select: :key) |> Enum.to_list()) == []

      assert cache.get_all!(query: "**name**") |> Map.new() == %{
               "firstname" => "Albert",
               "lastname" => "Einstein"
             }
    end

    test "count_all!/1 returns the cached entries count", %{cache: cache} do
      keys = ["age", "firstname", "lastname"]

      cache.put_all(%{
        "firstname" => "Albert",
        "lastname" => "Einstein",
        "age" => 76
      })

      assert cache.count_all!() >= 3
      assert cache.count_all!(query: "**name**") == 2
      assert cache.count_all!(query: "a??") == 1

      assert cache.delete_all!(query: "**name**") == 2
      assert cache.delete_all!(query: "a??") == 1

      assert cache.delete_all!(in: keys) == 0
      assert cache.count_all!(in: keys) == 0
    end

    test "delete_all!/0 deletes all cached entries", %{cache: cache} do
      :ok = cache.put_all(a: 1, b: 2, c: 3)

      assert cache.count_all!() >= 3
      assert cache.delete_all!() >= 3
      assert cache.count_all!() == 0
    end

    test "delete_all!/1 deletes the given keys [in: keys]", %{cache: cache} do
      kv = for i <- 1..10, into: %{}, do: {:erlang.phash2(i), i}

      :ok = cache.put_all(kv)

      for {k, v} <- kv do
        assert cache.get!(k) == v
      end

      keys = Map.keys(kv)

      assert cache.count_all!(in: keys) == 10
      assert cache.delete_all!(in: keys) == 10
      assert cache.count_all!(in: keys) == 0

      for {k, _} <- kv do
        refute cache.get!(k)
      end
    end

    test "stream!/2 [on_error: :raise] raises an exception", %{cache: cache} do
      Redix
      |> stub(:command, fn _, _, _ -> {:error, %Redix.ConnectionError{reason: :closed}} end)

      assert_raise Nebulex.Error, ~r"\*\* \(Redix.ConnectionError\)", fn ->
        cache.stream!() |> Enum.to_list()
      end

      assert_raise Nebulex.Error, ~r"\*\* \(Redix.ConnectionError\)", fn ->
        cache.stream!(in: [1, 2, 3]) |> Enum.to_list()
      end
    end

    test "stream!/2 [on_error: :nothing] skips command errors", %{cache: cache} do
      Redix
      |> stub(:command, fn _, _, _ -> {:error, %Redix.ConnectionError{reason: :closed}} end)

      assert cache.stream!([], on_error: :nothing) |> Enum.to_list() == []
      assert cache.stream!([in: [1, 2, 3]], on_error: :nothing) |> Enum.to_list() == []
    end
  end
end
