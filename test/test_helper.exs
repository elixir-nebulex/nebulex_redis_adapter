# Start Telemetry
Application.start(:telemetry)

# Nebulex dependency path
nbx_dep_path = Mix.Project.deps_paths()[:nebulex]

Code.require_file("#{nbx_dep_path}/test/support/cache_case.exs", __DIR__)

for file <- File.ls!("#{nbx_dep_path}/test/shared/cache") do
  Code.require_file("#{nbx_dep_path}/test/shared/cache/" <> file, __DIR__)
end

for file <- File.ls!("#{nbx_dep_path}/test/shared"), file != "cache" do
  Code.require_file("#{nbx_dep_path}/test/shared/" <> file, __DIR__)
end

# Load shared tests
for file <- File.ls!("test/shared/cache") do
  Code.require_file("./shared/cache/" <> file, __DIR__)
end

for file <- File.ls!("test/shared"), not File.dir?("test/shared/" <> file) do
  Code.require_file("./shared/" <> file, __DIR__)
end

# Mocks
[
  Redix,
  Nebulex.Adapters.Redis.Cluster,
  Nebulex.Adapters.Redis.Cluster.Keyslot,
  Nebulex.Adapters.Redis.Pool
]
|> Enum.each(&Mimic.copy/1)

# Disable testing expired event on observable tests
:ok = Application.put_env(:nebulex, :observable_test_expired, false)

ExUnit.start()
