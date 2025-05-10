defmodule Nebulex.Adapters.Redis.Client do
  # Redix wrapper
  @moduledoc false

  import Nebulex.Adapters.Redis.Helpers

  alias Nebulex.Adapters.Redis.{
    ClientSideCluster,
    Cluster,
    Cluster.ConfigManager,
    Pool
  }

  ## API

  @doc """
  Executes a Redis command.
  """
  @spec command(
          Nebulex.Adapter.adapter_meta(),
          Redix.command(),
          keyword()
        ) :: {:ok, any()} | {:error, any()}
  def command(adapter_meta, command, opts \\ [])

  def command(%{mode: :redis_cluster, name: name} = adapter_meta, command, opts) do
    on_moved = fn ->
      # Re-configure the cluster
      :ok = ConfigManager.setup_shards(name)

      # Retry once more
      do_command(adapter_meta, command, Keyword.put(opts, :on_moved, nil))
    end

    do_command(adapter_meta, command, Keyword.put(opts, :on_moved, on_moved))
  end

  def command(adapter_meta, command, opts) do
    do_command(adapter_meta, command, Keyword.put(opts, :on_moved, nil))
  end

  defp do_command(adapter_meta, command, opts) do
    {key, opts} = Keyword.pop(opts, :key)
    {on_moved, opts} = Keyword.pop(opts, :on_moved)

    with {:ok, conn} <- fetch_conn(adapter_meta, key, opts) do
      conn
      |> Redix.command(command, redis_command_opts(opts))
      |> handle_command_response(on_moved)
    end
  end

  @doc """
  Executes a Redis `MULTI`/`EXEC` transaction.
  """
  @spec transaction_pipeline(
          Nebulex.Adapter.adapter_meta(),
          [Redix.command()],
          keyword()
        ) :: {:ok, [any()]} | {:error, any()}
  def transaction_pipeline(adapter_meta, commands, opts \\ [])

  def transaction_pipeline(%{mode: :redis_cluster, name: name} = adapter_meta, commands, opts) do
    on_moved = fn ->
      # Re-configure the cluster
      :ok = ConfigManager.setup_shards(name)

      # Retry once more
      do_transaction_pipeline(adapter_meta, commands, Keyword.put(opts, :on_moved, nil))
    end

    do_transaction_pipeline(adapter_meta, commands, Keyword.put(opts, :on_moved, on_moved))
  end

  def transaction_pipeline(adapter_meta, commands, opts) do
    do_transaction_pipeline(adapter_meta, commands, Keyword.put(opts, :on_moved, nil))
  end

  defp do_transaction_pipeline(%{mode: mode} = adapter_meta, commands, opts) do
    {key, opts} = Keyword.pop(opts, :key)
    {on_moved, opts} = Keyword.pop(opts, :on_moved)

    with {:ok, conn} <- fetch_conn(adapter_meta, key, opts) do
      conn
      |> redix_transaction_pipeline(commands, redis_command_opts(opts), mode)
      |> handle_tx_pipeline_response(on_moved)
    end
  end

  @spec fetch_conn(Nebulex.Adapter.adapter_meta(), any(), keyword()) ::
          {:ok, pid()} | {:error, Nebulex.Error.t()}
  def fetch_conn(adapter_meta, key, opts)

  def fetch_conn(
        %{mode: :standalone, name: name, registry: registry, pool_size: pool_size},
        _key,
        _opts
      ) do
    Pool.fetch_conn(registry, name, pool_size)
  end

  def fetch_conn(%{mode: :redis_cluster, name: name} = meta, key, opts) do
    with {:error, %Nebulex.Error{reason: :redis_connection_error}} <-
           Cluster.fetch_conn(meta, key, opts) do
      # Perhars the cluster should be re-configured
      :ok = ConfigManager.setup_shards(name)

      # Retry once more
      Cluster.fetch_conn(meta, key, opts)
    end
  end

  def fetch_conn(%{mode: :client_side_cluster} = meta, key, opts) do
    ClientSideCluster.fetch_conn(meta, key, opts)
  end

  ## Private Functions

  defp handle_command_response({:error, %Redix.Error{message: "MOVED" <> _}}, on_moved)
       when is_function(on_moved) do
    on_moved.()
  end

  defp handle_command_response(other, _on_moved) do
    other
  end

  defp handle_tx_pipeline_response({:error, {error, prev_responses}}, on_moved) do
    Enum.reduce_while(prev_responses, {:error, error}, fn
      %Redix.Error{message: "MOVED" <> _}, _acc when is_function(on_moved) ->
        {:halt, on_moved.()}

      %Redix.Error{message: "MOVED" <> _} = error, _acc ->
        {:halt, {:error, error}}

      _other, acc ->
        {:cont, acc}
    end)
  end

  defp handle_tx_pipeline_response(other, _on_moved) do
    other
  end

  # A tweaked version of `Redix.transaction_pipeline/3` for handling
  # Redis Cluster errors
  defp redix_transaction_pipeline(conn, [_ | _] = commands, options, :redis_cluster)
       when is_list(options) do
    with {:ok, responses} <- Redix.pipeline(conn, [["MULTI"]] ++ commands ++ [["EXEC"]], options) do
      case Enum.split(responses, -1) do
        {prev_responses, [%Redix.Error{} = error]} -> {:error, {error, prev_responses}}
        {_prev_responses, [other]} -> {:ok, other}
      end
    end
  end

  # Forward to `Redix.transaction_pipeline/3`
  defp redix_transaction_pipeline(conn, commands, options, _mode) do
    Redix.transaction_pipeline(conn, commands, options)
  end
end
