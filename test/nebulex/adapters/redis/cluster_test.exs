defmodule Nebulex.Adapters.Redis.ClusterTest do
  use ExUnit.Case, async: false

  @moduletag :redis_cluster
  @moduletag capture_log: true

  use Mimic

  # Inherited tests
  use Nebulex.Adapters.Redis.CacheTest

  # Inherited tests from Nebulex
  use Nebulex.CacheTestCase,
    except: [
      Nebulex.Cache.KVExpirationTest,
      Nebulex.Cache.KVPropTest,
      Nebulex.Cache.TransactionTest,
      Nebulex.Cache.QueryableTest,
      Nebulex.Cache.QueryableExpirationTest,
      Nebulex.Cache.ObservableTest
    ]

  import Nebulex.CacheCase
  import Nebulex.Utils, only: [wrap_error: 2]

  alias Nebulex.Adapters.Redis.Cluster
  alias Nebulex.Adapters.Redis.Cluster.Keyslot
  alias Nebulex.Adapters.Redis.TestCache.RedisCluster, as: Cache
  alias Nebulex.Adapters.Redis.TestCache.RedisClusterConnError
  alias Nebulex.Telemetry

  setup do
    {:ok, pid} = Cache.start_link()
    _ = Cache.delete_all!()

    on_exit(fn -> safe_stop(pid) end)

    {:ok, cache: Cache, name: Cache}
  end

  describe "cluster setup" do
    test "error: missing :redis_cluster option" do
      defmodule RedisClusterWithInvalidOpts do
        @moduledoc false
        use Nebulex.Cache,
          otp_app: :nebulex_redis_adapter,
          adapter: Nebulex.Adapters.Redis
      end

      _ = Process.flag(:trap_exit, true)

      assert {:error, {%NimbleOptions.ValidationError{message: msg}, _}} =
               RedisClusterWithInvalidOpts.start_link(mode: :redis_cluster)

      assert Regex.match?(~r/invalid value for :redis_cluster option: expected non-empty/, msg)
    end

    test "error: invalid :redis_cluster options", %{cache: cache} do
      _ = Process.flag(:trap_exit, true)

      assert {:error, {%NimbleOptions.ValidationError{message: msg}, _}} =
               cache.start_link(name: :redis_cluster_invalid_opts1, redis_cluster: [])

      assert Regex.match?(~r/invalid value for :redis_cluster option: expected non-empty/, msg)
    end

    test "error: invalid :keyslot option", %{cache: cache} do
      _ = Process.flag(:trap_exit, true)

      assert {:error, {%NimbleOptions.ValidationError{message: msg}, _}} =
               cache.start_link(
                 name: :redis_cluster_invalid_opts2,
                 redis_cluster: [configuration_endpoints: [x: []], keyslot: RedisClusterConnError]
               )

      assert msg =~ "invalid value for :keyslot option: expected"
    end

    test "error: connection with config endpoint cannot be established" do
      [_start, stop] = telemetry_events(RedisClusterConnError)

      with_telemetry_handler(__MODULE__, [stop], fn ->
        {:ok, _pid} = RedisClusterConnError.start_link()

        # 1st failed attempt
        assert_receive {^stop, %{duration: _}, %{status: :error}}, 5000

        # Command fails because the cluster is in error status
        assert_raise Nebulex.Error,
                     ~r/could not run the command because Redis Cluster is in error status/,
                     fn ->
                       RedisClusterConnError.get!("foo")
                     end

        # 2dn failed attempt
        assert_receive {^stop, %{duration: _}, %{status: :error}}, 5000
      end)
    end

    test "error: redis cluster is shutdown" do
      _ = Process.flag(:trap_exit, true)

      [start, stop] = events = telemetry_events(RedisClusterConnError)

      with_telemetry_handler(__MODULE__, events, fn ->
        {:ok, _} =
          RedisClusterConnError.start_link(
            redis_cluster: [
              configuration_endpoints: [
                endpoint1_conn_opts: [
                  host: "127.0.0.1",
                  port: 6380,
                  password: "password"
                ]
              ],
              override_master_host: true
            ]
          )

        assert_receive {^start, _, %{pid: pid}}, 5000
        assert_receive {^stop, %{duration: _}, %{status: :ok}}, 5000

        :ok = GenServer.stop(pid)

        assert_raise Nebulex.Error, ~r"Redis Cluster is in shutdown status", fn ->
          RedisClusterConnError.fetch!("foo", lock_retries: 2)
        end
      end)
    end

    test "error: command failed after reconfiguring cluster" do
      [start, stop] = events = telemetry_events(RedisClusterConnError)

      with_telemetry_handler(__MODULE__, events, fn ->
        {:ok, _} =
          RedisClusterConnError.start_link(
            redis_cluster: [
              configuration_endpoints: [
                endpoint1_conn_opts: [
                  url: "redis://127.0.0.1:6380",
                  password: "password"
                ]
              ],
              override_master_host: true
            ]
          )

        assert_receive {^start, _, %{pid: pid}}, 5000

        # Setup mocks - testing Redis version < 7 (["CLUSTER", "SLOTS"])
        Redix
        |> expect(:command, fn _, _ -> {:error, %Redix.Error{}} end)
        |> expect(:command, fn _, _ -> {:ok, [[0, 16_384, ["127.0.0.1", 6380]]]} end)
        |> allow(self(), pid)

        assert_receive {^stop, %{duration: _}, %{status: :ok}}, 5000

        # Setup mocks
        Nebulex.Adapters.Redis.Cluster
        |> expect(:fetch_conn, fn _, _, _ ->
          wrap_error Nebulex.Error, reason: :redis_connection_error
        end)

        refute RedisClusterConnError.get!("foo")

        assert_receive {^stop, %{duration: _}, %{status: :ok}}, 5000
      end)
    end
  end

  describe "hash_slot (default CRC16)" do
    test "ok: returns the expected slot" do
      assert Cluster.hash_slot("123456789") == {:"$hash_slot", 12_739}
    end
  end

  describe "keys with hash tags" do
    test "compute_key/1" do
      assert Keyslot.compute_key("{foo}.bar") == "foo"
      assert Keyslot.compute_key("foo{bar}foo") == "bar"
      assert Keyslot.compute_key("foo.{bar}") == "bar"
      assert Keyslot.compute_key("foo.{bar}foo") == "bar"
      assert Keyslot.compute_key("foo.{}bar") == "foo.{}bar"
      assert Keyslot.compute_key("foo.{bar") == "foo.{bar"
      assert Keyslot.compute_key("foo.}bar") == "foo.}bar"
      assert Keyslot.compute_key("foo.{hello}bar{world}!") == "hello"
      assert Keyslot.compute_key("foo.bar") == "foo.bar"
    end

    test "hash_slot/2" do
      for i <- 0..10 do
        assert Cluster.hash_slot("{foo}.#{i}") ==
                 Cluster.hash_slot("{foo}.#{i + 1}")

        assert Cluster.hash_slot("foo.{bar}.#{i}") ==
                 Cluster.hash_slot("foo.{bar}.#{i + 1}")
      end

      assert Cluster.hash_slot("foo.{bar.1") != Cluster.hash_slot("foo.{bar.2")
    end

    test "put and get operations", %{cache: cache} do
      assert cache.put_all!(%{"foo{bar}.1" => "bar1", "foo{bar}.2" => "bar2"}) == :ok

      assert cache.get_all!(in: ["foo{bar}.1", "foo{bar}.2"]) |> Map.new() == %{
               "foo{bar}.1" => "bar1",
               "foo{bar}.2" => "bar2"
             }
    end

    test "put and get operations with tupled keys", %{cache: cache} do
      assert cache.put_all!(%{
               {__MODULE__, "key1"} => "bar1",
               {__MODULE__, "key2"} => "bar2"
             }) == :ok

      assert cache.get_all!(in: [{__MODULE__, "key1"}, {__MODULE__, "key2"}])
             |> Map.new() == %{
               {__MODULE__, "key1"} => "bar1",
               {__MODULE__, "key2"} => "bar2"
             }

      assert cache.put_all!(%{
               {__MODULE__, {Nested, "key1"}} => "bar1",
               {__MODULE__, {Nested, "key2"}} => "bar2"
             }) == :ok

      assert cache.get_all!(
               in: [
                 {__MODULE__, {Nested, "key1"}},
                 {__MODULE__, {Nested, "key2"}}
               ]
             )
             |> Map.new() == %{
               {__MODULE__, {Nested, "key1"}} => "bar1",
               {__MODULE__, {Nested, "key2"}} => "bar2"
             }
    end
  end

  describe "MOVED" do
    test "error: raises an exception in the 2nd attempt after reconfiguring the cluster", %{
      cache: cache
    } do
      _ = Process.flag(:trap_exit, true)

      # Setup mocks
      Nebulex.Adapters.Redis.Cluster.Keyslot
      |> stub(:hash_slot, &:erlang.phash2/2)

      # put is executed with a Redis command
      assert_raise Nebulex.Error, ~r/\*\* \(Redix.Error\) MOVED/, fn ->
        cache.put!("1234567890", "hello")
      end

      # take is executed with a Redis transaction pipeline
      assert_raise Nebulex.Error, ~r/\*\* \(Redix.Error\) MOVED/, fn ->
        cache.take!("1234567890")
      end
    end

    test "ok: command is successful after configuring the cluster", %{cache: cache} do
      [_start, stop] = events = telemetry_events(cache)

      with_telemetry_handler(__MODULE__, events, fn ->
        # Setup mocks
        Nebulex.Adapters.Redis.Cluster.Keyslot
        |> expect(:hash_slot, fn _, _ -> 0 end)

        # Triggers MOVED error the first time, then the command succeeds
        :ok = cache.put!("MOVED", "MOVED")

        # Cluster is re-configured
        assert_receive {^stop, %{duration: _}, %{status: :ok}}, 5000

        # Command was executed successfully
        assert cache.get!("MOVED") == "MOVED"
      end)
    end
  end

  describe "put_new_all" do
    test "error: key alredy exists", %{cache: cache} do
      assert cache.put_new_all!(v1: 1, v2: 2) == true

      Redix
      |> stub(:command, fn _, _, _ -> {:ok, 0} end)

      assert cache.put_new_all!(v1: 1, v3: 3) == false
    end

    test "error: command failed", %{cache: cache} do
      Redix
      |> expect(:command, fn _, _, _ -> {:error, %Redix.ConnectionError{reason: :timeout}} end)

      assert_raise Nebulex.Error, ~r/timeout/, fn ->
        cache.put_new_all!(v1: 1, v3: 3)
      end
    end
  end

  ## Private functions

  defp telemetry_events(cache) do
    prefix = Telemetry.default_prefix(cache) ++ [:redis_cluster, :setup]

    [prefix ++ [:start], prefix ++ [:stop]]
  end
end
