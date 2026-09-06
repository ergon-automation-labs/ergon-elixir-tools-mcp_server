defmodule BotArmyElixirToolsMcpServer.HttpHandler do
  @moduledoc """
  MCP Streamable HTTP transport handler.

  POST /mcp   — client sends JSON-RPC request, gets JSON response
  GET  /mcp   — opens SSE stream for server-initiated messages
  DELETE /mcp — terminates session
  """
  use Plug.Router

  # NOTE: no plug(Plug.Logger) — in the starter's release the Plug version's
  # Logger before_send reads :plug_route from private and raises KeyError on
  # every non-OPTIONS request, turning all responses into empty-body 500s.
  # Logging is suppressed in prod anyway.
  plug(:cors)
  plug(:dispatch)

  # POST /mcp — handle JSON-RPC request
  post "/mcp" do
    {:ok, body, conn} = read_body(conn)

    case Jason.decode(body) do
      {:ok, request} ->
        handle_jsonrpc(conn, request)

      {:error, _} ->
        send_json(conn, 400, %{
          "jsonrpc" => "2.0",
          "error" => %{"code" => -32700, "message" => "Parse error"}
        })
    end
  end

  # GET /mcp — SSE stream for server-initiated messages
  get "/mcp" do
    session_id = generate_session_id()

    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> put_resp_header("mcp-session-id", session_id)
    |> send_resp(200, "")
    |> halt()
  end

  # DELETE /mcp — terminate session
  delete "/mcp" do
    send_resp(conn, 204, "")
  end

  # Catch-all
  match _ do
    send_resp(conn, 404, "not found")
  end

  # JSON-RPC routing
  defp handle_jsonrpc(conn, %{"method" => "initialize", "id" => id}) do
    session_id = generate_session_id()

    result = %{
      "protocolVersion" => "2025-03-26",
      "capabilities" => %{
        "streamableHttp" => %{}
      },
      "serverInfo" => %{
        "name" => "bot-army-mcp",
        "version" => "0.2.2"
      }
    }

    conn
    |> put_resp_header("mcp-session-id", session_id)
    |> send_json(200, jsonrpc_result(id, result))
  end

  defp handle_jsonrpc(conn, %{"method" => "tools/list", "id" => id}) do
    tools = BotArmyElixirToolsMcpServer.Tools.list_tools()
    send_json(conn, 200, jsonrpc_result(id, %{"tools" => tools}))
  end

  defp handle_jsonrpc(conn, %{"method" => "tools/call", "params" => params, "id" => id}) do
    tool_name = params["name"]
    arguments = params["arguments"] || %{}

    case BotArmyElixirToolsMcpServer.Tools.execute(tool_name, arguments) do
      {:ok, result} ->
        sanitized = deep_sanitize(result)
        text_content = Jason.encode!(sanitized)

        response =
          jsonrpc_result(id, %{"content" => [%{"type" => "text", "text" => text_content}]})

        send_json(conn, 200, response)

      {:error, reason} ->
        send_json(conn, 200, jsonrpc_error(id, to_string(reason)))
    end
  end

  defp handle_jsonrpc(conn, %{"method" => method, "id" => id}) do
    send_json(conn, 200, jsonrpc_error(id, "Method not found: #{method}"))
  end

  # Notifications (no id) — acknowledge silently
  defp handle_jsonrpc(conn, %{"method" => _method}) do
    send_resp(conn, 202, "")
  end

  defp handle_jsonrpc(conn, _request) do
    send_json(conn, 400, %{
      "jsonrpc" => "2.0",
      "error" => %{"code" => -32600, "message" => "Invalid request"}
    })
  end

  # CORS headers for Claude Desktop cross-origin requests
  defp cors(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, mcp-session-id")
    |> put_resp_header("access-control-expose-headers", "mcp-session-id")
    |> then(fn c ->
      if c.method == "OPTIONS" do
        c |> send_resp(204, "") |> halt()
      else
        c
      end
    end)
  end

  defp send_json(conn, status, data) do
    body = Jason.encode!(data, escape: :unicode)

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, body)
    |> halt()
  end

  defp jsonrpc_result(id, result) do
    %{"jsonrpc" => "2.0", "id" => id, "result" => result}
  end

  defp jsonrpc_error(id, message) do
    %{"jsonrpc" => "2.0", "id" => id, "error" => %{"code" => -32603, "message" => message}}
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  defp deep_sanitize(value) when is_binary(value) do
    String.replace(value, ~r/[\x00-\x08\x0A\x0B\x0C\x0D-\x1F]/, "")
  end

  defp deep_sanitize(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {k, deep_sanitize(v)} end)
  end

  defp deep_sanitize(value) when is_list(value) do
    Enum.map(value, &deep_sanitize/1)
  end

  defp deep_sanitize(value), do: value
end
