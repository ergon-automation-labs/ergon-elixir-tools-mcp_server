defmodule BotArmyElixirToolsMcpServer.Application do
  use Application
  require Logger

  @mcp_port_env "MCP_PORT"
  @default_mcp_port 39900

  @impl true
  def start(_type, _args) do
    log_to_file("Application.start called")

    children =
      []
      |> maybe_add_stdio()
      |> maybe_add_http()
      |> maybe_add_pulse_publisher()

    opts = [strategy: :one_for_one, name: BotArmyElixirToolsMcpServer.Supervisor]
    log_to_file("Starting supervisor")

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        log_to_file("Supervisor started: #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        log_to_file("Supervisor failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp maybe_add_stdio(children) do
    if http_only?() do
      children
    else
      # restart: :transient — in a container (no TTY), stdin gives :eof and
      # the StdioHandler exits :normal by design. With the default
      # :permanent policy that "normal" exit still counts toward
      # max_restarts → the whole app terminates with :shutdown shortly
      # after boot. :transient lets a normal exit retire the child while
      # keeping real crashes supervised.
      [
        Supervisor.child_spec(
          {BotArmyElixirToolsMcpServer.StdioHandler, []},
          restart: :transient
        )
        | children
      ]
    end
  end

  defp maybe_add_http(children) do
    if http_enabled?() do
      port = mcp_port()
      log_to_file("Starting Bandit HTTP server on port #{port}")

      [
        {Bandit, plug: BotArmyElixirToolsMcpServer.HttpHandler, port: port, ip: {0, 0, 0, 0}}
        | children
      ]
    else
      children
    end
  end

  defp http_enabled?, do: System.get_env(@mcp_port_env) != nil or http_only?()
  defp http_only?, do: System.get_env("MCP_TRANSPORT") == "http"

  # Periodic system.health heartbeat — Synapse treats system.health as stale
  # after ~90s; this bot had no publisher at all (metrics-lit-up arc gap).
  # Publishes degrade to {:error, _} without a NATS connection, so the
  # child is harmless in stdio-only/dev mode.
  defp maybe_add_pulse_publisher(children) do
    if System.get_env("MIX_ENV") == "test" do
      children
    else
      [
        {BotArmyLibraryRuntime.HealthPulsePublisher,
         [app_name: :bot_army_elixir_tools_mcp_server, service: "elixir_tools_mcp"]}
        | children
      ]
    end
  end

  defp mcp_port do
    case System.get_env(@mcp_port_env) do
      nil -> @default_mcp_port
      port_str -> String.to_integer(port_str)
    end
  end

  defp log_to_file(msg) do
    log_file = "/tmp/bot_army_mcp_server.log"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    File.write(log_file, "[#{timestamp}] #{msg}\n", [:append])
  end
end
