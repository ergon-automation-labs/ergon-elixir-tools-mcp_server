defmodule BotArmyElixirToolsMcpServer.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    {host, port} = parse_nats_server(System.get_env("NATS_SERVERS", "localhost:4222"))

    children = [
      {Gnat, %{name: :nats, host: host, port: port, connection_timeout: 2000}},
      {BotArmyElixirToolsMcpServer.StdioHandler, []}
    ]

    opts = [strategy: :one_for_all, name: BotArmyElixirToolsMcpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp parse_nats_server(server_str) do
    case String.split(server_str, ":") do
      [host, port_str] ->
        {String.to_charlist(host), String.to_integer(port_str)}

      [host] ->
        {String.to_charlist(host), 4222}

      _ ->
        {~c"localhost", 4222}
    end
  end
end
