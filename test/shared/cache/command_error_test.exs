defmodule Nebulex.Adapters.Redis.CommandErrorTest do
  import Nebulex.CacheCase

  deftests "command" do
    use Mimic

    alias Nebulex.Adapter

    test "take", %{cache: cache, name: name} do
      _ = mock_redix_transaction_pipeline(name)

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.take!("conn_error")
      end
    end

    test "has_key?", %{cache: cache} do
      _ = mock_redix_command()

      assert {:error, %Nebulex.Error{}} = cache.has_key?("conn_error")
    end

    test "ttl", %{cache: cache} do
      _ = mock_redix_command()

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.ttl!("conn_error")
      end
    end

    test "touch", %{cache: cache} do
      _ = mock_redix_command()

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.touch!("conn_error")
      end
    end

    test "expire", %{cache: cache} do
      _ = mock_redix_command()

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.expire!("conn_error", 1000)
      end
    end

    test "expire (:infinity)", %{cache: cache, name: name} do
      _ = mock_redix_transaction_pipeline(name)

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.expire!("conn_error", :infinity)
      end
    end

    test "incr", %{cache: cache} do
      _ = mock_redix_command()

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.incr!("conn_error", 1, ttl: 1000)
      end
    end

    test "get_all", %{cache: cache} do
      _ = mock_redix_command()

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.get_all!(in: [:foo, :bar])
      end
    end

    test "delete_all", %{cache: cache} do
      _ = mock_redix_command()

      assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
        cache.delete_all!(in: [:foo, :bar])
      end
    end

    test "get_all (failed fetching values)", %{cache: cache, name: name} do
      if Adapter.lookup_meta(name).mode == :client_side_cluster do
        Nebulex.Adapters.Redis.Pool
        |> stub(:fetch_conn, fn _, _, _ -> {:ok, self()} end)

        Redix
        |> expect(:command, 3, fn _, _, _ -> {:ok, ["foo", "bar"]} end)
        |> expect(:command, fn _, _, _ -> {:error, %Redix.ConnectionError{}} end)

        assert_raise Nebulex.Error, ~r/\*\* \(Redix.ConnectionError\)/, fn ->
          cache.get_all!()
        end
      end
    end

    defp mock_redix_command do
      Nebulex.Adapters.Redis.Pool
      |> expect(:fetch_conn, fn _, _, _ -> {:ok, self()} end)

      Redix
      |> stub(:command, fn _, _, _ -> {:error, %Redix.ConnectionError{}} end)
    end

    defp mock_redix_transaction_pipeline(name) do
      Nebulex.Adapters.Redis.Pool
      |> expect(:fetch_conn, fn _, _, _ -> {:ok, self()} end)

      if Adapter.lookup_meta(name).mode == :redis_cluster do
        Redix
        |> stub(:pipeline, fn _, _, _ -> {:error, %Redix.ConnectionError{}} end)
      else
        Redix
        |> stub(:transaction_pipeline, fn _, _, _ -> {:error, %Redix.ConnectionError{}} end)
      end
    end
  end
end
