defmodule Nebulex.Adapters.Redis.Connection do
  @moduledoc false

  alias Nebulex.Adapters.Redis.Pool

  @typedoc "Proxy type to the adapter meta"
  @type adapter_meta() :: Nebulex.Adapter.adapter_meta()

  ## API

  @spec init(adapter_meta(), keyword()) :: {Supervisor.child_spec(), adapter_meta()}
  def init(%{name: name, registry: registry, pool_size: pool_size} = adapter_meta, opts) do
    conn_specs =
      Pool.register_names(registry, name, pool_size, fn conn_name ->
        opts
        |> Keyword.put(:name, conn_name)
        |> child_spec()
      end)

    connections_supervisor_spec = %{
      id: :connections_supervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [conn_specs, [strategy: :one_for_one]]}
    }

    {connections_supervisor_spec, adapter_meta}
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    name = Keyword.fetch!(opts, :name)

    Supervisor.child_spec({Redix, redix_args(name, opts)}, id: {Redix, name})
  end

  @spec conn_opts(keyword()) :: keyword()
  def conn_opts(opts) do
    Keyword.get(opts, :conn_opts, host: "127.0.0.1", port: 6379)
  end

  ## Private Functions

  defp redix_args(name, opts) do
    conn_opts =
      opts
      |> conn_opts()
      |> Keyword.put(:name, name)

    case Keyword.pop(conn_opts, :url) do
      {nil, conn_opts} -> conn_opts
      {url, conn_opts} -> {url, conn_opts}
    end
  end
end
