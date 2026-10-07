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

    # Start runtime dependencies first. The OTP app is :bot_army_library_runtime
    # (the repo was renamed); :bot_army_runtime no longer resolves and the
    # `{:ok, _} =` match crashed every escript boot.
    {:ok, _} = Application.ensure_all_started(:bot_army_library_runtime)
    log_debug("bot_army_library_runtime started")

    # Re-suppress after runtime starts (in case it re-enabled handlers)
    suppress_all_logging()

    # Start (or adopt) our MCP server application. An escript built with an
    # application `mod:` starts the app before main/1 runs, so a manual
    # Application.start/2 returns {:already_started, pid} and used to halt the
    # server right after the handshake. ensure_all_started is idempotent.
    case Application.ensure_all_started(:bot_army_elixir_tools_mcp_server) do
      {:ok, _apps} ->
        log_debug("MCP Server application started successfully")
        ensure_stdio_handler()
        log_debug("StdioHandler should be running now, reading stdin...")
        wait_for_shutdown()

      {:error, reason} ->
        log_debug("Application startup failed: #{inspect(reason)}")
        # Write error to stdout so user sees it
        IO.write("{\"error\": \"Application startup failed: #{inspect(reason)}\"}\n")
        System.halt(1)
    end
  end

  # In an escript the app is auto-started by its `mod:` before main/1 runs.
  # At that point the process's stdin is not attached yet, so the supervised
  # StdioHandler reads :eof and retires (restart: :transient keeps it retired).
  # By main/1 stdin is usable, so start a fresh handler here if the supervised
  # one is gone. Without this the server is deaf while looking "connected".
  defp ensure_stdio_handler do
    if Process.whereis(BotArmyElixirToolsMcpServer.StdioHandler) == nil do
      log_debug("StdioHandler not running (boot-time :eof); starting it from CLI")
      {:ok, _pid} = BotArmyElixirToolsMcpServer.StdioHandler.start_link([])
    end
  end

  # Block main/1 until the StdioHandler stops. It stops when stdin closes
  # (:eof), so the escript exits with its client instead of leaking an orphan
  # BEAM. The orphan is not just untidy: a scripted caller that closes the pipe
  # early (`... | head -1`, `grep -q`) leaves the shell waiting on a process
  # that never exits, which hangs the whole command.
  defp wait_for_shutdown do
    case Process.whereis(BotArmyElixirToolsMcpServer.StdioHandler) do
      nil ->
        log_debug("StdioHandler already stopped, exiting")
        :ok

      pid ->
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, :process, ^pid, reason} ->
            log_debug("StdioHandler stopped: #{inspect(reason)}, exiting")
            :ok
        end
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
