defmodule Nebulex.Adapters.Redis.RedixConnTest do
  import Nebulex.CacheCase

  deftests "Redix" do
    test "command/3 ok", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "foo")

      assert Redix.command(conn, ["SET", "foo", "bar"], timeout: 5000) == {:ok, "OK"}
      assert Redix.command(conn, ["GET", "foo"]) == {:ok, "bar"}
    end

    test "command/3 encode/decode ok", %{cache: cache, name: name} do
      key = cache.encode_key({:key, "key"})
      value = cache.encode_value({:value, "value"})

      assert {:ok, conn} = cache.fetch_conn(name: name, key: key)

      assert Redix.command!(conn, ["SET", key, value], timeout: 5000) == "OK"
      assert Redix.command!(conn, ["GET", key]) |> cache.decode_value() == {:value, "value"}
    end

    test "command/3 returns an error", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "counter")

      assert {:error, %Redix.Error{}} = Redix.command(conn, ["INCRBY", "counter", "invalid"])
    end

    test "command!/3 raises an error", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "counter")

      assert_raise Redix.Error, fn ->
        Redix.command!(conn, ["INCRBY", "counter", "invalid"])
      end
    end

    test "command!/3 with LIST", %{cache: cache, name: name} do
      conn = cache.fetch_conn!(name: name, key: "mylist")

      assert Redix.command!(conn, ["LPUSH", "mylist", "world"]) == 1
      assert Redix.command!(conn, ["LPUSH", "mylist", "hello"]) == 2
      assert Redix.command!(conn, ["LRANGE", "mylist", "0", "-1"]) == ["hello", "world"]
    end

    test "pipeline/3 runs the piped commands", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "mylist")

      assert Redix.pipeline(
               conn,
               [
                 ["LPUSH", "mylist", "world"],
                 ["LPUSH", "mylist", "hello"],
                 ["LRANGE", "mylist", "0", "-1"]
               ],
               timeout: 5000,
               telemetry_metadata: %{foo: "bar"}
             ) == {:ok, [1, 2, ["hello", "world"]]}
    end

    test "pipeline/3 returns an error", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "counter")

      assert {:ok, [%Redix.Error{}]} = Redix.pipeline(conn, [["INCRBY", "counter", "invalid"]])
    end

    test "pipeline!/3 runs the piped commands", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "mylist")

      assert Redix.pipeline!(
               conn,
               [
                 ["LPUSH", "mylist", "world"],
                 ["LPUSH", "mylist", "hello"],
                 ["LRANGE", "mylist", "0", "-1"]
               ]
             ) == [1, 2, ["hello", "world"]]
    end

    test "pipeline!/3 returns an error", %{cache: cache, name: name} do
      assert {:ok, conn} = cache.fetch_conn(name: name, key: "counter")

      assert_raise Redix.Error, fn ->
        Redix.command!(conn, [["INCRBY", "counter", "invalid"]])
      end
    end
  end
end
