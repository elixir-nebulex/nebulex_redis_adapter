defmodule Nebulex.Adapters.Redis.Pool do
  @moduledoc false

  import Nebulex.Utils, only: [wrap_error: 2]

  alias Nebulex.Adapters.Redis.ErrorFormatter

  ## API

  @spec register_names(atom(), any(), pos_integer(), ({:via, module(), any()} -> any())) :: [any()]
  def register_names(registry, key, pool_size, fun) do
    for index <- 0..(pool_size - 1) do
      fun.({:via, Registry, {registry, {key, index}}})
    end
  end

  @spec fetch_conn(atom(), any(), pos_integer()) :: {:ok, pid()} | {:error, Nebulex.Error.t()}
  def fetch_conn(registry, key, pool_size) do
    # Ensure selecting the connection based on the caller PID
    index = :erlang.phash2(self(), pool_size)

    case Registry.lookup(registry, {key, index}) do
      [{pid, _}] -> {:ok, pid}
      [] -> wrap_error Nebulex.Error, reason: :redis_connection_error, module: ErrorFormatter
    end
  end
end
