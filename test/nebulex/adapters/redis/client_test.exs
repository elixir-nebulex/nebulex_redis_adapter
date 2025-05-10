defmodule Nebulex.Adapters.Redis.ClientTest do
  use ExUnit.Case, async: true
  use Mimic

  import Nebulex.CacheCase, only: [safe_stop: 1]

  alias Nebulex.Adapters.Redis.Client

  @adapter_meta %{mode: :standalone, name: :test, registry: :test, pool_size: 1}

  describe "command/3" do
    test "error: raises an exception" do
      Nebulex.Adapters.Redis.Pool
      |> expect(:fetch_conn, fn _, _, _ -> {:ok, self()} end)

      Redix
      |> expect(:command, fn _, _, _ -> {:error, %Redix.Error{}} end)

      assert {:error, %Redix.Error{}} = Client.command(@adapter_meta, [["PING"]])
    end
  end

  describe "transaction_pipeline/3" do
    test "error: raises an exception" do
      Nebulex.Adapters.Redis.Pool
      |> expect(:fetch_conn, fn _, _, _ -> {:ok, self()} end)

      Redix
      |> expect(:pipeline, fn _, _, _ -> {:ok, [%Redix.Error{}]} end)

      assert {:error, %Redix.Error{}} = Client.transaction_pipeline(@adapter_meta, [["PING"]])
    end
  end

  describe "fetch_conn/3" do
    setup do
      {:ok, pid} = Registry.start_link(keys: :unique, name: __MODULE__.Registry)

      on_exit(fn -> safe_stop(pid) end)

      {:ok, pid: pid}
    end

    test "error: no connections available" do
      assert Client.fetch_conn(%{@adapter_meta | registry: __MODULE__.Registry}, :key, 1) ==
               {:error,
                %Nebulex.Error{
                  __exception__: true,
                  metadata: [],
                  module: Nebulex.Adapters.Redis.ErrorFormatter,
                  reason: :redis_connection_error
                }}
    end
  end
end
