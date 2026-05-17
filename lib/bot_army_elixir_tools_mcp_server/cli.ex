defmodule BotArmyElixirToolsMcpServer.CLI do
  @moduledoc """
  CLI entry point for escript. Starts the MCP server and keeps it alive.
  """

  def main(_args) do
    # CRITICAL: Configure logger BEFORE starting applications
    # Disable old error_logger and set up clean logger with only stderr
    setup_clean_logger()

    {:ok, _} = Application.ensure_all_started(:bot_army_elixir_tools_mcp_server)
    Process.sleep(:infinity)
  end

  defp setup_clean_logger do
    # Disable Erlang error_logger tty BEFORE logger starts
    :error_logger.tty(false)

    # Start logger application early
    {:ok, _} = Application.ensure_all_started(:logger)

    # Remove ALL handlers to prevent stdout/stderr contamination
    :logger.remove_handler(:default)
    :logger.remove_handler(:console)

    for {handler_id, _info} <- :logger.get_handler_config() do
      :logger.remove_handler(handler_id)
    end

    # Configure global logger to critical level (suppress all output)
    Logger.configure(level: :critical)
  end
end
