defmodule BotArmyElixirToolsMcpServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_army_elixir_tools_mcp_server,
      version: "0.3.4",
      # NOTE: mod: lives in application/0 below — the application/0 return
      # overrides the project application config, so putting mod: here has
      # no effect.
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      default_release: :elixir_tools_mcp_bot,
      releases: [
        elixir_tools_mcp_bot: [
          applications: [bot_army_elixir_tools_mcp_server: :permanent]
        ]
      ],
      escript: [main_module: BotArmyElixirToolsMcpServer.CLI]
    ]
  end

  def application do
    [
      # mod: makes `mix release` START the application. Historically this
      # repo was escript/CLI-only ("don't auto-start"), but the starter's
      # compose runs it as a release HTTP server (MCP_PORT/MCP_TRANSPORT):
      # an empty application spec made the release boot an idle skeleton
      # (beam alive, Application.start/2 never called, port 39900 deaf).
      mod: {BotArmyElixirToolsMcpServer.Application, []}
    ]
  end

  defp deps do
    runtime_path =
      System.get_env("BOT_ARMY_RUNTIME_PATH", "/Users/abby/code/bots/bot_army_library_runtime")

    [
      {:gnat, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.5"},
      {:plug, "~> 1.16"},
      {:bot_army_library_runtime, path: runtime_path},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
