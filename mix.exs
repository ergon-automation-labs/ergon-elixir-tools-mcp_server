defmodule BotArmyElixirToolsMcpServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_army_elixir_tools_mcp_server,
      version: "0.1.4",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: BotArmyElixirToolsMcpServer.CLI]
    ]
  end

  def application do
    [
      # Don't auto-start logger - CLI manages it to prevent stdout contamination
      mod: {BotArmyElixirToolsMcpServer.Application, []}
    ]
  end

  defp deps do
    [
      {:gnat, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
