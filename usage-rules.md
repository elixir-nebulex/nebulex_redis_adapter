<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- nebulex:THIRD_PARTY_LICENSES-start -->
## nebulex:THIRD_PARTY_LICENSES usage
# Third-Party Licenses

This directory contains usage rules sourced from the following open-source projects.

---

## UsageRules

**Source**: https://github.com/ash-project/usage_rules

**Files affected**: `elixir.md` (lines 1-69)

**License**: MIT License

```
MIT License

Copyright (c) 2025 usage_rules contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## Phoenix Framework

**Source**: https://github.com/phoenixframework/phoenix

**Files affected**: `elixir.md` (lines 71-184)

**License**: MIT License

```
MIT License

Copyright (c) 2014 Chris McCord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

<!-- nebulex:THIRD_PARTY_LICENSES-end -->
<!-- nebulex:elixir-start -->
## nebulex:elixir usage
<!--
The following rules are sourced from [UsageRules](https://github.com/ash-project/usage_rules),
with modifications and additions.

SPDX-FileCopyrightText: 2025 usage_rules contributors <https://github.com/ash-project/usage_rules/graphs.contributors>

SPDX-License-Identifier: MIT
-->
# Elixir Core Usage Rules

## Pattern Matching

- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies
- `%{}` matches ANY map, not just empty maps. Use `map_size(map) == 0` guard to check for truly empty maps

## Error Handling

- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`
- Bang functions (`!`) that explicitly raise exceptions on failure are acceptable (e.g., `File.read!/1`, `String.to_integer!/1`)
- Avoid rescuing exceptions unless for a very specific case (e.g., cleaning up resources, logging critical errors)

## Common Mistakes to Avoid

- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design

- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures

- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing

- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!--
The following rules are sourced from [Phoenix Framework](https://github.com/phoenixframework/phoenix),
with modifications and additions.

Copyright (c) 2014 Chris McCord, licensed under the MIT License.
-->
## Elixir guidelines

- Elixir lists **do not support index based access via the access syntax**

  **Never do this (invalid)**:

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Instead, **always** use `Enum.at`, pattern matching, or `List` for index based list access, ie:

      i = 0
      mylist = ["blue", "green"]
      Enum.at(mylist, i)

- Elixir variables are immutable, but can be rebound, so for block expressions like `if`, `case`, `cond`, etc
  you *must* bind the result of the expression to a variable if you want to use it and you CANNOT rebind the result inside the expression, ie:

      # INVALID: we are rebinding inside the `if` and the result never gets assigned
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID: we rebind the result of the `if` to a new variable
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file as it can cause cyclic dependencies and compilation errors
- **Never** use map access syntax (`changeset[:field]`) on structs as they do not implement the Access behaviour by default. For regular structs, you **must** access the fields directly, such as `my_struct.field` or use higher level APIs that are available on the struct if they exist, `Ecto.Changeset.get_field/2` for changesets
- Elixir's standard library has everything necessary for date and time manipulation. Familiarize yourself with the common `Time`, `Date`, `DateTime`, and `Calendar` interfaces by accessing their documentation as necessary. **Never** install additional dependencies unless asked or for date/time parsing (which you can use the `date_time_parser` package)
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Predicate function names should not start with `is_` and should end in a question mark. Names like `is_thing` should be reserved for guards
- Elixir's builtin OTP primitives like `DynamicSupervisor` and `Registry`, require names in the child spec, such as `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then you can use `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. The majority of times you will want to pass `timeout: :infinity` as option

- The `in` operator in guards requires a compile-time known value on the right side (literal list or range)

  **Never do this (invalid)**: using a variable which is unknown at compile time

      def t(x, y) when x in y, do: {x, y}

  This will raise `ArgumentError: invalid right argument for operator "in", it expects a compile-time proper list or compile-time range on the right side when used in guard expressions`

  **Valid**: use a known value for the list or range

      def t(x, y) when x in [1, 2, 3], do: {x, y}
      def t(x, y) when x in 1..10, do: {x, y}

- In tests, avoid using `assert` with pattern matching when the expected value is fully known. Use direct equality comparison instead for clearer test failures

  **Avoid**:

      assert {:ok, ^value} = testing()
      assert {:error, :not_found} = fetch()

  **Prefer**:

      assert testing() == {:ok, value}
      assert fetch() == {:error, :not_found}

  **Exception**: Pattern matching is acceptable when you only want to assert part of a complex structure

      # OK: asserting only specific fields of a large struct/map
      assert {:ok, %{id: ^id}} = get_order()

- In tests, avoid duplicating test data across multiple tests. Use constants, fixture files, or private fixture functions instead

  **Avoid**: Duplicating test data

      test "validates user email" do
        assert valid_email?("user@example.com")
      end

      test "creates user" do
        assert create_user("user@example.com")
      end

  **Prefer**: Use module attributes for constants or fixture functions

      @valid_email "user@example.com"

      test "validates user email" do
        assert valid_email?(@valid_email)
      end

      test "creates user" do
        assert create_user(@valid_email)
      end

  For complex data structures, create fixture functions:

      defp user_fixture(attrs \\ %{}) do
        %User{
          name: "John Doe",
          email: "john@example.com",
          age: 30
        }
        |> Map.merge(attrs)
      end

## Mix guidelines

- Read the docs and options before using tasks (by using `mix help task_name`)
- To debug test failures, run tests in a specific file with `mix test test/my_test.exs` or run all previously failed tests with `mix test --failed`
- `mix deps.clean --all` is **almost never needed**. **Avoid** using it unless you have good reason

<!-- nebulex:elixir-end -->
<!-- nebulex:nebulex-start -->
## nebulex:nebulex usage
# Nebulex Project-Specific Usage Rules

## Project Overview

Nebulex is a fast, flexible, and extensible caching library for Elixir that provides:
- Multiple cache adapters (local, distributed, multilevel, partitioned)
- Declarative decorator-based caching inspired by Spring Cache Abstraction
- OTP design patterns and fault tolerance
- Telemetry instrumentation
- Support for TTL, eviction policies, transactions, and more

## Architecture Patterns

### Cache Definition

- Caches MUST be defined using `use Nebulex.Cache` with `:otp_app` and `:adapter` options
- Caches should be started in the application supervision tree, not manually
- Use descriptive cache module names that indicate their purpose (e.g., `MyApp.LocalCache`, `MyApp.UserCache`)

**Example**:

```elixir
defmodule MyApp.Cache do
  use Nebulex.Cache,
    otp_app: :my_app,
    adapter: Nebulex.Adapters.Local
end
```

### Adapter Pattern

- All adapters MUST implement the `Nebulex.Adapter` behaviour
- Adapters MUST implement `c:init/1` returning `{:ok, child_spec, adapter_meta}`
- Adapter functions MUST return `{:ok, value}` or `{:error, reason}` tuples
- Use `wrap_error/2` from `Nebulex.Utils` to wrap errors consistently
- Implement optional behaviours as needed: `Nebulex.Adapter.KV`, `Nebulex.Adapter.Queryable`, etc.
- Leverage `use Nebulex.Adapter.Transaction` and similar modules for default implementations

### Command Pattern

- Use `defcommand/2` macro from `Nebulex.Adapter` to build public command wrappers
- Use `defcommandp/2` for private command wrappers
- Command functions automatically handle telemetry, metadata, and error wrapping
- The first parameter to commands should always be `name` (the cache name or PID)
- The last parameter should always be `opts` (keyword list)

**Example**:

```elixir
defcommand fetch(name, key, opts)
defcommandp do_put(name, key, value, on_write, ttl, keep_ttl?, opts), command: :put
```

## Return Value Conventions

### Tuple Returns

- Read operations that can fail MUST return `{:ok, value}` or `{:error, %Nebulex.KeyError{}}` for missing keys
- Write operations MUST return `{:ok, true}` for success or `{:ok, false}` for conditional failures (e.g., `put_new`)
- Delete operations MUST return `:ok` regardless of whether the key existed
- NEVER return bare `:error` atoms; always use `{:error, reason}` tuples

### Bang Functions

- Provide bang versions (`!`) of functions that unwrap `{:ok, value}` or raise exceptions
- Bang functions MUST use `unwrap_or_raise/1` from `Nebulex.Utils`
- Functions that return `:ok` should have bang versions that also return `:ok`
- Functions that return `{:ok, boolean}` should have bang versions that return the boolean

**Example**:

```elixir
def fetch!(name, key, opts) do
  unwrap_or_raise fetch(name, key, opts)
end

def put!(name, key, value, opts) do
  _ = unwrap_or_raise do_put(name, key, value, :put, opts)
  :ok
end
```

## Options and Validation

### Options Handling

- Use `Nebulex.Cache.Options` module for option validation
- Call `Options.validate_runtime_shared_opts!/1` to validate runtime options
- Use `Options.pop_and_validate_timeout!/2` for TTL and timeout options
- Use `Options.pop_and_validate_boolean!/2` for boolean options
- Use `Options.pop_and_validate_integer!/2` for integer options
- Validate options as early as possible, preferably at the beginning of the function

**Example**:

```elixir
def put(name, key, value, opts) do
  {ttl, opts} = Options.pop_and_validate_timeout!(opts, :ttl)
  {keep_ttl?, opts} = Options.pop_and_validate_boolean!(opts, :keep_ttl, false)

  do_put(name, key, value, :put, ttl, keep_ttl?, opts)
end
```

### Shared Options

- All cache functions should accept `:telemetry`, `:telemetry_event`, and `:telemetry_metadata` options
- Support lifecycle hooks: `:before` and `:after_return` for adapter-specific hooks
- Document adapter-specific options clearly in the module documentation

## Decorators

### Decorator Usage

- Use `use Nebulex.Caching` to enable decorator support in a module
- Configure default cache via `use Nebulex.Caching, cache: MyCache`
- Always use decorators on functions, not on function heads with multiple clauses
- Prefer module captures over anonymous functions for better performance: `match: &__MODULE__.match_fun/1`
- Avoid capturing large data structures in decorator lambdas

**Invalid**:

```elixir
@decorate cacheable(key: id)
def get_user(nil), do: nil

def get_user(id) do
  # logic
end
```

**Valid**:

```elixir
@decorate cacheable(key: id)
def get_user(id) do
  do_get_user(id)
end

defp do_get_user(nil), do: nil
defp do_get_user(id) do
  # logic
end
```

### Decorator Options

- Use `:key` option to specify explicit cache keys; avoid relying solely on default key generation
- Use `:references` for implementing cache key references and memory-efficient caching
- Use `:match` option to conditionally cache values (e.g., `match: &match_fun/1`)
- Use `:on_error` option to control error handling (`:raise` or `:nothing`)
- Specify TTL via `:opts` option: `opts: [ttl: :timer.hours(1)]`

### `cacheable` Decorator

- Use `@decorate cacheable` for read-through caching patterns
- Combine with `:references` option when the same value needs multiple cache keys
- Use `:match` function with references to ensure consistency (e.g., validating email matches)

**Example**:

```elixir
@decorate cacheable(key: id)
def get_user(id) do
  Repo.get(User, id)
end

@decorate cacheable(key: email, references: &(&1 && &1.id), match: &match_email(&1, email))
def get_user_by_email(email) do
  Repo.get_by(User, email: email)
end

defp match_email(%{email: email}, email), do: true
defp match_email(_, _), do: false
```

### `cache_put` Decorator

- Use `@decorate cache_put` for write-through caching patterns
- Always use `:match` option to conditionally update cache (e.g., only on `{:ok, value}`)
- Avoid using `cache_put` and `cacheable` on the same function

**Example**:

```elixir
@decorate cache_put(key: user.id, match: &match_ok/1)
def update_user(user, attrs) do
  user
  |> User.changeset(attrs)
  |> Repo.update()
end

defp match_ok({:ok, user}), do: {true, user}
defp match_ok({:error, _}), do: false
```

### `cache_evict` Decorator

- Use `@decorate cache_evict` for cache invalidation
- Use `key: {:in, keys}` to evict multiple keys at once
- Use `:all_entries` option to clear the entire cache
- Use `:before_invocation` option to evict before function execution
- Use `:query` option for complex eviction patterns based on match specifications

**Example**:

```elixir
@decorate cache_evict(key: {:in, [user.id, user.email]})
def delete_user(user) do
  Repo.delete(user)
end

@decorate cache_evict(all_entries: true)
def clear_all_users do
  Repo.delete_all(User)
end

@decorate cache_evict(query: &__MODULE__.query_for_tag/1)
def delete_by_tag(tag) do
  # Delete logic
end

def query_for_tag(%{args: [tag]}) do
  [{:entry, :"$1", %{tag: :"$2"}, :_, :_}, [{:"=:=", :"$2", tag}], [true]]
end
```

## Testing Patterns

### Test Structure

- Use `deftests do` macro for shared test suites that can run across multiple adapters
- Structure tests with `describe` blocks grouping related functionality
- Use context fixtures with `%{cache: cache}` for test setup
- Test both successful and error scenarios for each function

**Example**:

```elixir
defmodule MyAdapterTest do
  import Nebulex.CacheCase

  deftests do
    describe "put/3" do
      test "puts the given entry into the cache", %{cache: cache} do
        assert cache.put(:key, :value) == :ok
        assert cache.fetch!(:key) == :value
      end

      test "raises when invalid option is given", %{cache: cache} do
        assert_raise NimbleOptions.ValidationError, fn ->
          cache.put(:key, :value, ttl: "invalid")
        end
      end
    end
  end
end
```

### Test Assertions

- Use `assert cache.function() == expected_value` for exact equality
- Use `assert_raise ErrorType, ~r"message pattern"` for exception testing
- Test edge cases: `nil`, boolean values (`true`, `false`), empty collections
- Test both normal and bang (`!`) versions of functions
- Avoid pattern matching in assertions when the full value is known (use direct equality)

**Invalid**:

```elixir
assert {:ok, value} = cache.fetch(:key)
```

**Valid**:

```elixir
assert cache.fetch(:key) == {:ok, expected_value}
```

## Telemetry

### Telemetry Events

- Emit telemetry events for all cache commands when `:telemetry` option is `true`
- Use `:telemetry_prefix` option to customize event names (defaults to `[:cache_name, :cache]`)
- Provide comprehensive metadata: `:adapter_meta`, `:command`, `:args`, `:result`
- Support custom `:telemetry_event` and `:telemetry_metadata` options per command

### Telemetry Best Practices

- Use `Nebulex.Telemetry.span/3` for span events (start, stop, exception)
- Include measurements like `:duration` and `:system_time`
- Document all telemetry events in module documentation with measurement and metadata keys
- Provide example telemetry handlers in documentation

## Error Handling

### Error Types

- Use `Nebulex.Error` for general cache errors
- Use `Nebulex.KeyError` for missing key errors
- Use `Nebulex.CacheNotFoundError` for dynamic cache lookup failures
- Wrap adapter-specific errors using `wrap_error/2` from `Nebulex.Utils`

### Error Wrapping

- Adapter functions should wrap errors consistently using `wrap_error/2`
- Include relevant context in error metadata (`:key`, `:command`, `:reason`)
- Preserve original error information in the `:reason` field

**Example**:

```elixir
def fetch(_adapter_meta, key, opts) do
  case do_fetch(key) do
    {:ok, value} -> {:ok, value}
    {:error, :not_found} -> wrap_error Nebulex.KeyError, key: key
    {:error, reason} -> wrap_error Nebulex.Error, reason: reason, command: :fetch, key: key
  end
end
```

## Performance Considerations

### Key Generation

- Provide explicit keys in decorators when possible; avoid relying on default key generation
- For complex keys, use module captures: `key: &MyModule.generate_key/1`
- Keep captured data in decorator lambdas small; fetch large configs inside functions

### Reference Keys

- Use cache key references (`:references` option) to avoid storing duplicate values
- Store references in a local cache and values in a remote cache (e.g., Redis) for optimization
- Set TTL for references to prevent dangling keys
- Use external references with `keyref(key, cache: AnotherCache)` for cross-cache references

### Optimization

- Use `Stream` for large result sets instead of loading all data at once
- Leverage `Task.async_stream/3` for concurrent cache operations when appropriate
- Set appropriate TTL values to balance freshness and performance
- Use `put_all/2` for batch operations instead of multiple `put/3` calls

## Documentation Standards

### Module Documentation

- Start with a clear `@moduledoc` explaining the purpose and main features
- Include usage examples in module documentation
- Document all compile-time options
- Document all runtime shared options
- Provide telemetry event documentation with measurements and metadata
- The maximum text length is 80 characters, and you should aim to adhere to this
  limit. However, there are special cases where exceeding it is acceptable. For
  example, you may exceed the limit for a link (e.g., ["my link"](http://github.com/elixir-nebulex))
  or a code snippet that only exceeds the limit by a few characters (e.g., 1 or 2).
  If a code snippet exceeds the 80-character limit by more than 1 or 2 haracters,
  format it using the Elixir formatter.
- When you make a change to the documentation, use `mix docs` to validate it.

### Function Documentation

- Use `@doc` for all public functions
- Include `@typedoc` for all custom types
- Provide examples in function documentation using doctests when applicable
- Document all options with descriptions and default values
- Group related functions using `@doc group: "Group Name"`
- The maximum text length is 80 characters, and you should aim to adhere to this
  limit. However, there are special cases where exceeding it is acceptable. For
  example, you may exceed the limit for a link (e.g., ["my link"](http://github.com/elixir-nebulex))
  or a code snippet that only exceeds the limit by a few characters (e.g., 1 or 2).
  If a code snippet exceeds the 80-character limit by more than 1 or 2 haracters,
  format it using the Elixir formatter.
- When you make a change to the documentation, use `mix docs` to validate it.

### Code Comments

- Avoid obvious comments; code should be self-explanatory
- Use comments for complex algorithms or non-obvious business logic
- Mark internal functions with `@doc false` or `@moduledoc false`
- Use `# Inline common instructions` followed by `@compile {:inline, function_name: arity}`
- The maximum text length is 80 characters, use multiple lines if the comment
  exceeds the limit.

## Naming Conventions

### Modules

- Adapter modules: `Nebulex.Adapters.*` (e.g., `Nebulex.Adapters.Local`)
- Cache modules: `<App>.Cache` or `<App>.<Context>Cache` (e.g., `MyApp.Cache`, `MyApp.UserCache`)
- Behaviour modules: `Nebulex.Adapter.<Feature>` (e.g., `Nebulex.Adapter.KV`)

### Functions

- Use descriptive function names: `fetch/2`, `put/3`, `delete/2`, `has_key?/1`
- Bang versions: `fetch!/2`, `put!/3`, `delete!/2`
- Private helpers: prefix with `do_` (e.g., `do_fetch/3`, `do_put/7`)
- Predicate functions: suffix with `?` (e.g., `has_key?/1`, `expired?/2`)

### Variables

- Cache instance: `cache`
- Adapter metadata: `adapter_meta`
- Options: `opts`
- Keys: `key` or `keys`
- Values: `value` or `values`
- TTL: `ttl`

## Code Organization

### File Structure

- Main cache API: `lib/nebulex/cache.ex`
- Adapter behaviour: `lib/nebulex/adapter.ex`
- Adapter implementations: `lib/nebulex/adapters/<adapter_name>.ex`
- Cache features: `lib/nebulex/cache/<feature>.ex`
- Decorators: `lib/nebulex/caching/decorators.ex`
- Mix tasks: `lib/mix/tasks/<task_name>.ex`

### Module Grouping

- Keep related functionality together (e.g., all KV operations in `Nebulex.Cache.KV`)
- Use nested modules for options, helpers, and internal implementation details
- Separate public API from internal implementation

## Common Pitfalls to Avoid

- **Do NOT** use decorators on multi-clause functions without proper wrapper functions
- **Do NOT** forget to validate options at the beginning of functions
- **Do NOT** return inconsistent error types; always use tuples or raise exceptions via bang functions
- **Do NOT** capture large data structures in decorator lambdas
- **Do NOT** forget to handle `nil`, boolean, and edge case values in tests
- **Do NOT** use `cache_put` and `cacheable` decorators on the same function
- **Do NOT** forget to evict cache references when using `:references` option; use TTL or explicit eviction
- **Do NOT** implement adapter callbacks without proper error wrapping
- **Do NOT** skip telemetry support in adapter implementations
- **Do NOT** use pattern matching in test assertions when the full value is known

## Backward Compatibility

- Maintain backward compatibility when adding new options (use default values)
- Deprecate old APIs before removal; provide migration path in documentation
- Follow semantic versioning strictly: major version for breaking changes
- Test against multiple Elixir and OTP versions in CI

## Dependencies

- Keep dependencies minimal and well-justified
- Prefer standard library solutions over external dependencies
- Use optional dependencies for non-core features
- Document all dependencies in README with their purpose

<!-- nebulex:nebulex-end -->
<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies
- `%{}` matches ANY map, not just empty maps. Use `map_size(map) == 0` guard to check for truly empty maps

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark.
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, use `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- usage-rules-end -->
