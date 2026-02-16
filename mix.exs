defmodule Nebulex.Adapters.Redis.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-nebulex/nebulex_redis_adapter"
  @version "3.0.0-dev"

  def project do
    [
      app: :nebulex_redis_adapter,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      deps: deps(),

      # Docs
      name: "Nebulex.Adapters.Redis",
      docs: docs(),

      # Testing
      test_coverage: [tool: ExCoveralls],

      # Dialyzer
      dialyzer: dialyzer(),

      # Usage Rules
      usage_rules: usage_rules(),

      # Hex
      package: package(),
      description: "Nebulex adapter for Redis"
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "test.ci": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      nebulex_dep(),
      {:redix, "~> 1.5"},
      {:nimble_options, "~> 0.5 or ~> 1.0"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:crc, "~> 0.10", optional: true},
      {:ex_hash_ring, "~> 7.0", optional: true},

      # Test & Code Analysis
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:mimic, "~> 2.0", only: :test},
      {:stream_data, "~> 1.2", only: [:dev, :test]},

      # Benchmark Test
      {:benchee, "~> 1.5", only: [:dev, :test]},
      {:benchee_html, "~> 1.0", only: [:dev, :test]},

      # Usage Rules
      {:usage_rules, "~> 1.0", only: [:dev]},

      # Docs
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false}
    ]
  end

  defp nebulex_dep do
    if path = System.get_env("NEBULEX_PATH") do
      {:nebulex, path: path, override: true}
    else
      {:nebulex, github: "elixir-nebulex/nebulex", branch: "main", override: true}
    end
  end

  defp aliases do
    [
      "nbx.setup": [
        "cmd rm -rf nebulex",
        "cmd git clone --depth 1 --branch main https://github.com/elixir-nebulex/nebulex"
      ],
      "test.ci": [
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "sobelow --skip --exit Low",
        "coveralls.html",
        "dialyzer --format short"
      ],
      "ur.sync": ["usage_rules.sync"]
    ]
  end

  defp package do
    [
      name: :nebulex_redis_adapter,
      maintainers: ["Carlos Bolanos"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README* CHANGELOG* LICENSE*)
    ]
  end

  defp docs do
    [
      main: "Nebulex.Adapters.Redis",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/nebulex_redis_adapter",
      source_url: @source_url
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:nebulex],
      plt_file: {:no_warn, "priv/plts/" <> plt_file_name()},
      flags: [
        :unmatched_returns,
        :error_handling,
        :extra_return,
        :no_opaque,
        :no_return
      ]
    ]
  end

  defp plt_file_name do
    "dialyzer-#{Mix.env()}-#{System.version()}-#{System.otp_release()}.plt"
  end

  defp usage_rules do
    [
      # The file to write usage rules into (required for usage_rules syncing)
      file: "AGENTS.md",

      # rules to include directly in AGENTS.md
      usage_rules: [
        {:nebulex,
         [
           sub_rules: [
             "workflow",
             "nebulex",
             "elixir-style",
             "elixir"
           ]
         ]},
        :otp
      ],

      # Agent skills configuration
      skills: [
        # Auto-build a "use-<pkg>" skill per dependency
        deps: [:nebulex]
      ]
    ]
  end
end
