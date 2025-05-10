defmodule Nebulex.Adapters.Redis.CacheTest do
  @moduledoc """
  Shared Tests
  """

  defmacro __using__(_opts) do
    quote do
      use Nebulex.Adapters.Redis.QueryableTest
      use Nebulex.Adapters.Redis.InfoTest
      use Nebulex.Adapters.Redis.CommandErrorTest
      use Nebulex.Adapters.Redis.RedixConnTest
    end
  end
end
