defmodule BotArmyElixirToolsMcpServer.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    log_to_file("Application.start called")

    children = [
      # NATS connection is already managed by bot_army_runtime
      {BotArmyElixirToolsMcpServer.StdioHandler, []}
    ]

    opts = [strategy: :one_for_one, name: BotArmyElixirToolsMcpServer.Supervisor]
    log_to_file("Starting supervisor with BotArmyRuntime.NATS.Connection")

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        log_to_file("Supervisor started: #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        log_to_file("Supervisor failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp log_to_file(msg) do
    log_file = "/tmp/bot_army_mcp_server.log"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    File.write(log_file, "[#{timestamp}] #{msg}\n", [:append])
  end
end
