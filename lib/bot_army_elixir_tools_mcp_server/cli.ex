defmodule BotArmyElixirToolsMcpServer.CLI do
  @moduledoc """
  CLI entry point for escript. Starts the MCP server and keeps it alive.
  """

  def main(_args) do
    # CRITICAL: Suppress all output except JSON-RPC on stdout
    # Suppress BEFORE calling setup_clean_logger to prevent any early logs
    suppress_all_logging()

    # Set up logger after suppression
    setup_clean_logger()

    log_debug("CLI.main starting")

    # Start runtime dependencies first
    {:ok, _} = Application.ensure_all_started(:bot_army_runtime)
    log_debug("bot_army_runtime started")

    # Re-suppress after runtime starts (in case it re-enabled handlers)
    suppress_all_logging()

    # Then start our MCP server application
    case BotArmyElixirToolsMcpServer.Application.start(:normal, []) do
      {:ok, _pid} ->
        log_debug("MCP Server application started successfully")
        log_debug("StdioHandler should be running now, reading stdin...")
        Process.sleep(:infinity)

      {:error, reason} ->
        log_debug("Application startup failed: #{inspect(reason)}")
        # Write error to stdout so user sees it
        IO.write("{\"error\": \"Application startup failed: #{inspect(reason)}\"}\n")
        System.halt(1)
    end
  end

  defp setup_clean_logger do
    log_file = "/tmp/bot_army_mcp_server.log"
    File.write(log_file, "MCP Server starting at #{DateTime.utc_now()}\n", [:write])

    # Disable Erlang error_logger tty immediately
    :error_logger.tty(false)

    # Pre-configure logger before applications start
    # Set to emergency level to suppress everything
    Logger.configure(level: :emergency)

    # Start logger application early
    {:ok, _} = Application.ensure_all_started(:logger)

    # Remove ALL handlers to prevent stdout/stderr contamination
    :logger.remove_handler(:default)
    :logger.remove_handler(:console)

    for {handler_id, _info} <- :logger.get_handler_config() do
      :logger.remove_handler(handler_id)
    end

    # Re-ensure emergency level after handler removal
    Logger.configure(level: :emergency)

    # Suppress all telemetry debug messages
    Application.put_env(:logger, :log_level, :emergency)
  end

  defp suppress_all_logging do
    # Aggressively suppress all logger output
    Logger.configure(level: :emergency)
    # Remove all handlers
    for {handler_id, _} <- :logger.get_handler_config() do
      :logger.remove_handler(handler_id)
    end

    # Disable error_logger
    :error_logger.tty(false)
  end

  defp log_debug(msg) do
    log_file = "/tmp/bot_army_mcp_server.log"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    File.write(log_file, "[#{timestamp}] #{msg}\n", [:append])
  end
end
