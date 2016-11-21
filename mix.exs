defmodule Schemata.Mixfile do
  use Mix.Project

  def project do
    [app: :schemata,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: Coverex.Task],
     preferred_cli_env: [espec: :test, spec: :test],
     dialyzer: [
       plt_add_deps: true,
       plt_add_apps: [:ssl],
       flags: [
         "--fullpath",
         "-Wunmatched_returns",
         "-Werror_handling",
         "-Wrace_conditions",
         "-Wunderspecs",
         "-Wunknown"
       ]
     ],
     aliases: aliases,
     deps: deps]
  end

  def application do
    dev_apps = Mix.env == :dev && [:reprise] || []
    [
      description: 'Elixir library for interacting with Cassandra',
      applications: dev_apps ++ [:logger, :timex, :cqerl, :happy, :inflex],
      mod: {Schemata.App, []},
      env: [
        drop_nulls: true,
        clusters: [],

        load_migrations_on_startup: true,
        migrations_keyspace: "schemata",
        migrations_table: "migrations",
        migrations_dir: "db/migrations",

        load_schema_on_startup: true,
        schema_file: "db/schema.exs"
      ]
    ]
  end

  defp aliases do
    [spec: "espec --cover"]
  end

  defp deps do
    [
      {:dialyxir, github: "jeremyjh/dialyxir", branch: "develop", only: :dev},
      {:dogma,    "~> 0.1", only: :dev},
      {:credo,    "~> 0.4", only: :dev},
      {:ex_guard, "~> 1.1", only: :dev},
      {:reprise,  "~> 0.5", only: :dev},
      {:espec,    "~> 1.0", only: :test},
      {:coverex,  "~> 1.4", only: :test},
      {:timex,    "~> 3.0"},
      {:inflex,   "~> 1.7"},
      {:happy,    "~> 1.3"},

      {:cqerl, [
        github: "hippware/cqerl",
        branch: "working-2.0",
        manager: :rebar3
      ]},

      # erlando's app file is b0rked so we need to override the dep here.
      {:erlando, ~r//, [
        github: "rabbitmq/erlando",
        branch: "master",
        override: true
      ]}
    ]
  end
end
