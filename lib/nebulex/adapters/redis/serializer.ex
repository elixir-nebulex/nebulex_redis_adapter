defmodule Nebulex.Adapters.Redis.Serializer do
  @moduledoc """
  A **Serializer** encodes keys and values sent to Redis,
  and decodes keys and values in the command output.

  See [Redis Strings](https://redis.io/docs/data-types/strings/).
  """

  @doc """
  Encodes `key` with the given `opts`.
  """
  @callback encode_key(key :: any(), opts :: [any()]) :: iodata()

  @doc """
  Encodes `value` with the given `opts`.
  """
  @callback encode_value(value :: any(), opts :: [any()]) :: iodata()

  @doc """
  Decodes `key` with the given `opts`.
  """
  @callback decode_key(key :: binary(), opts :: [any()]) :: any()

  @doc """
  Decodes `value` with the given `opts`.
  """
  @callback decode_value(value :: binary(), opts :: [any()]) :: any()

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Nebulex.Adapters.Redis.Serializer

      alias Nebulex.Adapters.Redis.Serializer.Serializable

      @impl true
      defdelegate encode_key(key, opts \\ []), to: Serializable, as: :encode

      @impl true
      defdelegate encode_value(value, opts \\ []), to: Serializable, as: :encode

      @impl true
      defdelegate decode_key(key, opts \\ []), to: Serializable, as: :decode

      @impl true
      defdelegate decode_value(value, opts \\ []), to: Serializable, as: :decode

      # Overridable callbacks
      defoverridable encode_key: 2, encode_value: 2, decode_key: 2, decode_value: 2
    end
  end
end
