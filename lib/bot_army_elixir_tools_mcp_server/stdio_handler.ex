defmodule BotArmyElixirToolsMcpServer.StdioHandler do
  @moduledoc """
  Handles JSON-RPC over stdio for MCP protocol.
  Routes requests to tool handlers.
  Uses a non-blocking approach with async input reading.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    log_debug("StdioHandler initialized")
    # Read lines from stdin in a loop
    send(self(), :read_next_line)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:read_next_line, state) do
    try do
      case IO.read(:line) do
        :eof ->
          log_debug("EOF received, stopping")
          {:stop, :normal, state}

        {:error, reason} ->
          log_debug("IO error: #{inspect(reason)}")
          {:stop, reason, state}

        line ->
          # Process the line
          line = String.trim(line)
          log_debug("Received: #{String.slice(line, 0..80)}")

          case Jason.decode(line) do
            {:ok, request} ->
              log_debug("Decoded request: #{request["method"]}")

              try do
                handle_request(request, state)
              rescue
                e ->
                  log_debug("Error handling request: #{inspect(e)}")
                  id = request["id"]
                  if id, do: send_error(id, "Internal error")
              end

              # Continue reading
              send(self(), :read_next_line)
              {:noreply, state}

            {:error, reason} ->
              log_debug("JSON error: #{inspect(reason)}")
              send_error(nil, "Invalid JSON")
              send(self(), :read_next_line)
              {:noreply, state}
          end
      end
    rescue
      e ->
        log_debug("CRITICAL: handle_info crashed: #{inspect(e)}")
        send(self(), :read_next_line)
        {:noreply, state}
    end
  end

  defp handle_request(%{"method" => "initialize", "id" => id}, _state) do
    log_debug("Handling initialize")

    response = %{
      "protocolVersion" => "2024-11-05",
      "capabilities" => %{},
      "serverInfo" => %{
        "name" => "bot-army-mcp",
        "version" => "0.1.0"
      }
    }

    send_response(id, response)
  end

  defp handle_request(%{"method" => "tools/list", "id" => id}, _state) do
    log_debug("Handling tools/list")
    tools = BotArmyElixirToolsMcpServer.Tools.list_tools()
    log_debug("Tools: #{inspect(tools, limit: 200)}")
    response = %{"tools" => tools}
    send_response(id, response)
  end

  defp handle_request(%{"method" => "tools/call", "params" => params, "id" => id}, _state) do
    tool_name = params["name"]
    arguments = params["arguments"] || %{}
    log_debug("Calling tool: #{tool_name}")

    try do
      case BotArmyElixirToolsMcpServer.Tools.execute(tool_name, arguments) do
        {:ok, result} ->
          log_debug("Tool succeeded: #{tool_name}")
          # Sanitize result to remove any problematic control characters
          sanitized_result = deep_sanitize(result)
          # Use Jason.encode! to properly escape result as JSON
          text_content = Jason.encode!(sanitized_result)
          response = %{"content" => [%{"type" => "text", "text" => text_content}]}
          send_response(id, response)

        {:error, reason} ->
          log_debug("Tool failed: #{inspect(reason)}")
          send_error(id, to_string(reason))
      end
    rescue
      e ->
        log_debug("Tool error: #{inspect(e)}")
        send_error(id, "Tool execution error")
    end
  end

  defp handle_request(%{"method" => method, "params" => params, "id" => id}, _state) do
    log_debug("Executing tool: #{method}")

    case BotArmyElixirToolsMcpServer.Tools.execute(method, params) do
      {:ok, result} ->
        # Sanitize result to remove any problematic control characters
        sanitized_result = deep_sanitize(result)
        send_response(id, sanitized_result)

      {:error, reason} ->
        send_error(id, reason)
    end
  end

  # Ignore notifications (no id field)
  defp handle_request(%{"method" => _method} = req, _state) when not is_map_key(req, "id") do
    log_debug("Notification received, no response sent")
  end

  defp handle_request(request, _state) do
    log_debug("Unknown request: #{inspect(request)}")
    id = request["id"]
    if id, do: send_error(id, "Unknown method")
  end

  defp send_response(id, result) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => result
    }

    send_json(response)
  end

  defp send_error(id, error) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{
        "code" => -32603,
        "message" => error
      }
    }

    send_json(response)
  end

  defp send_json(data) do
    try do
      json = Jason.encode!(data)
      # Log the JSON size for debugging
      log_debug("JSON output size: #{byte_size(json)} bytes")
      # Try to detect any invalid escape sequences before sending
      detect_invalid_escapes(json)

      # Additional check: verify Node.js can parse it
      if byte_size(json) > 3000 && byte_size(json) < 6000 do
        log_debug("JSON excerpt at 3867: #{inspect(String.slice(json, 3860..3880))}")
      end

      IO.write("#{json}\n")
      # Flush to ensure immediate delivery to client
      case File.write(:user, "") do
        :ok -> :ok
        _ -> :ok
      end

      :ok
    rescue
      e ->
        error_msg = Exception.message(e)
        log_debug("JSON encoding failed: #{inspect(e)}")
        log_debug("Error message: #{error_msg}")
        log_debug("Data type: #{inspect(data, limit: 100)}")

        # Send error response
        error_response = %{
          "jsonrpc" => "2.0",
          "error" => %{
            "code" => -32603,
            "message" => "JSON encoding error: #{String.slice(error_msg, 0..50)}"
          }
        }

        json = Jason.encode!(error_response)
        IO.write("#{json}\n")

        case File.write(:user, "") do
          :ok -> :ok
          _ -> :ok
        end
    end
  end

  defp detect_invalid_escapes(json_string) do
    # Find any backslash followed by invalid escape character
    case Regex.scan(~r/\\([^"\\\/bfnrtu0-9])/, json_string) do
      [] ->
        :ok

      matches ->
        # Found invalid escapes, log them
        Enum.each(matches, fn [_full, char] ->
          log_debug("Found invalid escape sequence: \\#{char}")
        end)
    end
  end

  defp deep_sanitize(value) when is_binary(value) do
    value
    |> String.replace(~r/[\x00-\x08\x0A\x0B\x0C\x0D-\x1F]/, "")
  end

  defp deep_sanitize(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {k, deep_sanitize(v)} end)
  end

  defp deep_sanitize(value) when is_list(value) do
    Enum.map(value, &deep_sanitize/1)
  end

  defp deep_sanitize(value), do: value

  defp log_debug(msg) do
    log_file = "/tmp/bot_army_mcp_server.log"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    File.write(log_file, "[#{timestamp}] StdioHandler: #{msg}\n", [:append])
  end
end
