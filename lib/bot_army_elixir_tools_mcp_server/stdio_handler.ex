defmodule BotArmyElixirToolsMcpServer.StdioHandler do
  @moduledoc """
  Handles JSON-RPC over stdio for MCP protocol.
  Routes requests to tool handlers.
  """
  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    send(self(), :start_reading)
    {:ok, %{request_id: 0}}
  end

  @impl true
  def handle_info(:start_reading, state) do
    read_loop(state)
  end

  defp read_loop(state) do
    case IO.read(:line) do
      :eof ->
        {:stop, :normal, state}

      {:error, reason} ->
        {:stop, reason, state}

      line ->
        case process_line(line, state) do
          {:ok, new_state} ->
            read_loop(new_state)

          {:stop, reason, new_state} ->
            {:stop, reason, new_state}
        end
    end
  end

  defp process_line(line, state) do
    line = String.trim(line)

    case Jason.decode(line) do
      {:ok, request} ->
        handle_request(request, state)

      {:error, _reason} ->
        error_response(nil, "Invalid JSON", state)
    end
  end

  defp handle_request(%{"method" => method, "params" => params, "id" => id}, state) do
    case BotArmyElixirToolsMcpServer.Tools.execute(method, params) do
      {:ok, result} ->
        send_response(id, result, state)

      {:error, reason} ->
        send_error(id, reason, state)
    end
  end

  defp handle_request(%{"method" => "initialize", "id" => id}, state) do
    response = %{
      "protocolVersion" => "2024-11-05",
      "capabilities" => %{},
      "serverInfo" => %{
        "name" => "bot-army-mcp",
        "version" => "0.1.0"
      }
    }

    send_response(id, response, state)
  end

  defp handle_request(%{"method" => "tools/list"}, state) do
    tools = BotArmyElixirToolsMcpServer.Tools.list_tools()
    response = %{"tools" => tools}
    send_response(nil, response, state)
  end

  defp handle_request(request, state) do
    send_error(request["id"], "Unknown method: #{request["method"]}", state)
  end

  defp send_response(id, result, state) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => result
    }

    send_json(response)
    {:ok, state}
  end

  defp send_error(id, error, state) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{
        "code" => -32603,
        "message" => error
      }
    }

    send_json(response)
    {:ok, state}
  end

  defp error_response(id, error, state) do
    send_error(id, error, state)
  end

  defp send_json(data) do
    json = Jason.encode!(data)
    IO.write("#{json}\n")
  end
end
