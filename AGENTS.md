## Local Scope First (`nebulex_redis_adapter`)

This repository is `nebulex_redis_adapter` (the Redis adapter for Nebulex),
not Nebulex core. When imported Nebulex sections reference missing
`usage-rules/*.md` paths or Nebulex-core files, treat them as upstream
guidance and prioritize this repository's local files and modules.

### Local Rule Precedence (for this repo)

When rules conflict, apply them in this order. Items 2–4 refer to the
rule files referenced via `@deps/…` at the bottom of this file; load
them as part of session bootstrap.

1. This local preface.
2. `nebulex:workflow`.
3. `nebulex:nebulex` (as framework guidance).
4. `nebulex:elixir-style` and `nebulex:elixir`.

### Local Key Files

> Keep this list current when modules are added, moved, or removed.
> A brief one-line description per file is enough.

- `lib/nebulex/adapters/redis.ex` - Main Redis adapter implementation.
- `lib/nebulex/adapters/redis/options.ex` - Adapter option definitions/docs.
- `lib/nebulex/adapters/redis/client.ex` - Redis client abstraction.
- `lib/nebulex/adapters/redis/connection.ex` - Connection management.
- `lib/nebulex/adapters/redis/pool.ex` - Connection pooling.
- `lib/nebulex/adapters/redis/supervisor.ex` - Adapter supervision tree.
- `lib/nebulex/adapters/redis/cluster.ex` - Redis Cluster mode support.
- `lib/nebulex/adapters/redis/cluster/` - Cluster internals (config manager, keyslot, pools).
- `lib/nebulex/adapters/redis/client_side_cluster.ex` - Client-side cluster mode support.
- `lib/nebulex/adapters/redis/client_side_cluster/` - Client-side cluster internals (hash ring, pools).
- `lib/nebulex/adapters/redis/serializer.ex` - Serialization behaviour.
- `lib/nebulex/adapters/redis/helpers.ex` - Shared adapter utilities.
- `lib/nebulex/adapters/redis/error_formatter.ex` - Error formatting.
- `test/nebulex/adapters/redis/standalone_test.exs` - Standalone mode tests.
- `test/nebulex/adapters/redis/cluster_test.exs` - Redis Cluster mode tests.
- `test/nebulex/adapters/redis/client_side_cluster_test.exs` - Client-side cluster tests.
- `test/nebulex/adapters/redis/client_test.exs` - Client abstraction tests.
- `test/shared/` - Shared test cases (cache, queryable, info, command errors).
- `README.md` - Public usage/configuration for this adapter.
- `CHANGELOG.md` - Adapter release history.

<!-- usage-rules-start -->
<!-- nebulex:workflow-start -->
## nebulex:workflow usage
@deps/nebulex/usage-rules/workflow.md
<!-- nebulex:workflow-end -->
<!-- nebulex:nebulex-start -->
## nebulex:nebulex usage
@deps/nebulex/usage-rules/nebulex.md
<!-- nebulex:nebulex-end -->
<!-- nebulex:elixir-style-start -->
## nebulex:elixir-style usage
@deps/nebulex/usage-rules/elixir-style.md
<!-- nebulex:elixir-style-end -->
<!-- nebulex:elixir-start -->
## nebulex:elixir usage
@deps/nebulex/usage-rules/elixir.md
<!-- nebulex:elixir-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A config-driven dev tool for Elixir projects to manage AGENTS.md files and agent skills from dependencies_

@deps/usage_rules/usage-rules.md
<!-- usage_rules-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
@deps/usage_rules/usage-rules/otp.md
<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->
