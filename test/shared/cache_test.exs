defmodule Knock.Nebulex.Adapters.Redis.CacheTest do
  @moduledoc """
  Shared Tests
  """

  defmacro __using__(_opts) do
    quote do
      use Knock.Nebulex.Adapters.Redis.QueryableTest
      use Knock.Nebulex.Adapters.Redis.InfoTest
      use Knock.Nebulex.Adapters.Redis.CommandErrorTest
      use Knock.Nebulex.Adapters.Redis.RedixConnTest
    end
  end
end
