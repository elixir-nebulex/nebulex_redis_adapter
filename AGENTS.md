# Project Rules

This repository is `nebulex_redis_adapter`, the Redis adapter for
[Nebulex](https://github.com/elixir-nebulex/nebulex). The shared rules come
from the `nebulex` dependency, so run `mix deps.get` first; the `@deps/…`
files do not exist in a fresh clone. The workflow below says what to read
for each kind of task; where it says `architecture.md`, read this repo's
guide (core's applies for context).

@deps/nebulex/usage-rules/workflow.md

@usage-rules/architecture.md

## Running Tests

The tests need the Redis instances from `docker-compose.yml` (standalone,
Redis Cluster, and client-side cluster). The suite also reuses the shared
test cases from the Nebulex core repository, which are not part of the Hex
package; `mix nbx.setup` clones the `main` branch into `./nebulex`, which is
what CI runs against:

```bash
docker compose up -d
mix deps.get
mix nbx.setup
NEBULEX_PATH=nebulex mix test
```

To run against another checkout, point `NEBULEX_PATH` at it. Every
`mix test` and `mix precommit` command in the shared workflow needs the
`NEBULEX_PATH=nebulex` prefix and the containers running. The
`cluster_queryable_test` tag is excluded in CI; run those tests locally with
`--include cluster_queryable_test` when you touch the Redis Cluster queries.

<!-- usage-rules-start -->
<!-- nebulex:nebulex-start -->
## nebulex:nebulex usage
[nebulex:nebulex usage rules](deps/nebulex/usage-rules/nebulex.md)
<!-- nebulex:nebulex-end -->
<!-- nebulex:elixir-style-start -->
## nebulex:elixir-style usage
[nebulex:elixir-style usage rules](deps/nebulex/usage-rules/elixir-style.md)
<!-- nebulex:elixir-style-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A config-driven dev tool for Elixir projects to manage AGENTS.md files and agent skills from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage-rules-end -->
