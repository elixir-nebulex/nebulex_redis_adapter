defmodule Nebulex.Adapters.Redis.ErrorFormatter do
  @moduledoc """
  Adapter error formatter.
  """

  import Nebulex.Error, only: [maybe_format_metadata: 2]

  @doc false
  def format_error(reason, metadata) do
    reason
    |> msg(metadata)
    |> format_metadata()
  end

  defp msg(:redis_connection_error, metadata) do
    {"connection not available; maybe the cache was not started or it does not exist", metadata}
  end

  defp msg({:redis_cluster_status_error, status}, metadata) do
    {"could not run the command because Redis Cluster is in #{status} status", metadata}
  end

  defp msg({:redis_cluster_setup_error, exception}, metadata) when is_exception(exception) do
    {stacktrace, metadata} = Keyword.pop(metadata, :stacktrace, [])

    msg = """
    could not setup Redis Cluster.

        #{Exception.format(:error, exception, stacktrace) |> String.replace("\n", "\n    ")}
    """

    {msg, metadata}
  end

  defp msg({:redis_cluster_setup_error, reason}, metadata) do
    {"could not setup Redis Cluster, failed with reason: #{inspect(reason)}.", metadata}
  end

  defp format_metadata({msg, metadata}) do
    maybe_format_metadata(msg, metadata)
  end
end
