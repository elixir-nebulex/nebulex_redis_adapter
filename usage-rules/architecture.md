# Architecture

This guide covers what the code and the module docs do not: how the modules
split responsibility and the non-negotiable rules for every change. Read the
"Non-Negotiables" section at session start; read the rest before structural
changes.

For how the adapter works and how to configure it, read the module docs:

- `Nebulex.Adapters.Redis` - the three modes, options, the Query API,
  transactions, serializers, and the cluster telemetry events.
- `Nebulex.Adapters.Redis.Serializer` - the serializer behaviour.

For the broader Nebulex context (the adapter pattern, behaviour contracts,
and shared non-negotiables), read the
[core Nebulex architecture guide][core-arch].

[core-arch]: https://hexdocs.pm/nebulex/architecture.html

---

## Purpose

`nebulex_redis_adapter` stores Nebulex cache entries in Redis through
[Redix](https://hexdocs.pm/redix). It supports a standalone Redis, Redis
Cluster, and a client-side cluster of standalone instances, behind the same
Nebulex API, so an application can use Redis as the shared layer of a
Nebulex topology (for example as the L2 of a multilevel cache).

---

## Module Boundaries

This section covers how the modules split responsibility; the file layout
is in `lib/` and `test/`.

- `Nebulex.Adapters.Redis` is the adapter entry point. It implements the
  behaviours, builds the Redis commands, and dispatches each command to the
  mode configured for the cache.
- `Client` runs commands through Redix and wraps the errors; `Pool` holds
  the Redix connections; `Connection` exposes a connection to callers that
  use the adapter as a Redis client; `Supervisor` is the adapter's tree.
- `Cluster` implements the `:redis_cluster` mode: `ConfigManager` keeps the
  cluster slot map, `Keyslot` computes hash slots (needs `:crc`), and the
  `DynamicSupervisor`/`PoolSupervisor` pair holds one pool per master.
- `ClientSideCluster` implements the `:client_side_cluster` mode: `HashRing`
  picks the node for a key (needs `:ex_hash_ring`), and `NodeSupervisor`/
  `PoolSupervisor` hold one pool per node.
- `Serializer` and the `Serializable` protocol encode keys and values;
  `Options` holds the NimbleOptions schemas; `Helpers` and `ErrorFormatter`
  are shared utilities.

---

## Non-Negotiables

These rules apply in addition to the shared non-negotiables in the core
Nebulex architecture guide.

### 1. The three modes must stay in sync

A command works the same in standalone, Redis Cluster, and client-side
cluster mode. A feature or fix applied to one mode is applied to the others,
and the tests for all three modes (`standalone_test.exs`, `cluster_test.exs`,
`client_side_cluster_test.exs`) must pass before any PR is merged. Behaviour
a mode cannot support is documented in the adapter's module docs.

### 2. Optional deps must remain optional

`:crc` is required only by the `:redis_cluster` mode and `:ex_hash_ring`
only by the `:client_side_cluster` mode. The adapter must start and work in
the other modes without them, and raise a clear error when a mode needs a
dependency that is absent.

### 3. Tests run against real Redis instances

The suite needs the instances from `docker-compose.yml`. Do not replace
them with mocks; use Mimic only for the failure paths that a real Redis
cannot produce.

### 4. Keep this document up to date

After any structural change (changing the module boundaries, adding a
mode, or adding a non-negotiable), review this document and update it if
needed. Do not copy here what the module docs already say; link to them.
A stale architecture guide is worse than no guide.

### 5. `mix precommit` must pass

```bash
NEBULEX_PATH=nebulex mix precommit
```

It includes the docs build with warnings as errors; fix the root cause of a
docs warning, do not suppress it.

### 6. Read why before changing subtle behavior

The reasons behind the subtle behavior (slot routing and the cluster
config refresh, the hash ring, serialization, and error formatting) are in
the module docs, the code comments, the CHANGELOG, and the tests. Read
them, and the history (`git log -S`), before changing that code. Do not
reverse such behavior without a test that covers the original problem.

---

## Further Reading

- [Core Nebulex Architecture](https://hexdocs.pm/nebulex/architecture.html)
- [Creating a New Adapter](https://hexdocs.pm/nebulex/creating-new-adapter.html)
- [Redix](https://hexdocs.pm/redix)
- [nebulex_redis_adapter HexDocs](https://hexdocs.pm/nebulex_redis_adapter)
