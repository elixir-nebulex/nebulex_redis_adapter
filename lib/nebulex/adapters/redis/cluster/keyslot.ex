defmodule Nebulex.Adapters.Redis.Cluster.Keyslot do
  @moduledoc """
  Default `Nebulex.Adapter.Keyslot` implementation.
  """

  @typedoc "Keyslot funtion type"
  @type t() :: (binary(), any() -> non_neg_integer())

  if Code.ensure_loaded?(CRC) do
    @doc false
    def hash_slot(key, range)

    def hash_slot(key, range) when is_binary(key) do
      key
      |> compute_key()
      |> compute_hash_slot(range)
    end

    def hash_slot(key, range) do
      key
      |> :erlang.phash2()
      |> to_string()
      |> compute_hash_slot(range)
    end

    defp compute_hash_slot(key, range) do
      :crc_16_xmodem
      |> CRC.crc(key)
      |> rem(range)
    end
  else
    @doc false
    def hash_slot(_key, _range) do
      raise ":crc dependency is required to use :redis_cluster mode"
    end
  end

  @doc """
  Helper function to compute the key; regardless the key contains hashtags
  or not.
  """
  @spec compute_key(binary()) :: binary()
  def compute_key(key) when is_binary(key) do
    _ignore =
      for <<c <- key>>, reduce: nil do
        nil -> if c == ?{, do: []
        acc -> if c == ?}, do: throw({:hashtag, acc}), else: [c | acc]
      end

    key
  catch
    {:hashtag, []} ->
      key

    {:hashtag, ht} ->
      ht
      |> Enum.reverse()
      |> IO.iodata_to_binary()
  end
end
