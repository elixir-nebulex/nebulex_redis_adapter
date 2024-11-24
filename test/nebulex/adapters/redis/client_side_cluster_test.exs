defmodule Nebulex.Adapters.Redis.ClientSideClusterTest do
  use ExUnit.Case, async: true
  @moduletag capture_log: true

  # Inherited tests
  use Nebulex.Adapters.Redis.CacheTest

  use Nebulex.CacheTestCase,
    except: [Nebulex.Cache.KVPropTest, Nebulex.Cache.TransactionTest, Nebulex.Cache.ObservableTest]

  import Nebulex.CacheCase

  alias Nebulex.Adapters.Redis.TestCache.ClientSideCluster, as: Cache

  setup do
    {:ok, pid} = Cache.start_link()
    _ = Cache.delete_all()

    on_exit(fn -> safe_stop(pid) end)

    {:ok, cache: Cache, name: Cache}
  end

  describe "cluster setup" do
    test "error: missing :client_side_cluster option" do
      defmodule ClientClusterWithInvalidOpts do
        @moduledoc false
        use Nebulex.Cache,
          otp_app: :nebulex_redis_adapter,
          adapter: Nebulex.Adapters.Redis
      end

      _ = Process.flag(:trap_exit, true)

      assert {:error, {%NimbleOptions.ValidationError{message: msg}, _}} =
               ClientClusterWithInvalidOpts.start_link(mode: :client_side_cluster)

      assert Regex.match?(~r/invalid value for :client_side_cluster option: expected/, msg)
    end
  end
end
