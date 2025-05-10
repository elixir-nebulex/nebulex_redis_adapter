defmodule Nebulex.Adapters.Redis.TestCache do
  @moduledoc false

  defmodule Common do
    @moduledoc false

    defmacro __using__(_opts) do
      quote do
        def get_and_update_fun(nil), do: {nil, 1}
        def get_and_update_fun(current) when is_integer(current), do: {current, current * 2}

        def get_and_update_bad_fun(_), do: :other
      end
    end
  end

  defmodule Standalone do
    @moduledoc false
    use Nebulex.Cache,
      otp_app: :nebulex_redis_adapter,
      adapter: Nebulex.Adapters.Redis

    use Nebulex.Adapters.Redis.TestCache.Common
  end

  defmodule RedisCluster do
    @moduledoc false
    use Nebulex.Cache,
      otp_app: :nebulex_redis_adapter,
      adapter: Nebulex.Adapters.Redis

    use Nebulex.Adapters.Redis.TestCache.Common
  end

  defmodule ClientSideCluster do
    @moduledoc false
    use Nebulex.Cache,
      otp_app: :nebulex_redis_adapter,
      adapter: Nebulex.Adapters.Redis

    use Nebulex.Adapters.Redis.TestCache.Common
  end

  defmodule RedisClusterConnError do
    @moduledoc false
    use Nebulex.Cache,
      otp_app: :nebulex_redis_adapter,
      adapter: Nebulex.Adapters.Redis
  end

  defmodule RedisClusterWithKeyslot do
    @moduledoc false
    use Nebulex.Cache,
      otp_app: :nebulex_redis_adapter,
      adapter: Nebulex.Adapters.Redis
  end
end
