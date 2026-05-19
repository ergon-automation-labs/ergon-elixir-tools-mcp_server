defmodule BotArmyElixirToolsMcpServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_army_elixir_tools_mcp_server,
      version: "0.2.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: BotArmyElixirToolsMcpServer.CLI]
    ]
  end

  def application do
    [
      # Don't auto-start - CLI starts the application manually
      # This allows us to suppress logger output before the app starts
    ]
  end

  defp deps do
    runtime_path =
      System.get_env("BOT_ARMY_RUNTIME_PATH", "/Users/abby/code/elixir_bots/bot_army_runtime")

    [
      {:gnat, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:bot_army_runtime, path: runtime_path},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
