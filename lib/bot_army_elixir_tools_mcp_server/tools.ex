defmodule BotArmyElixirToolsMcpServer.Tools do
  @moduledoc """
  Tool definitions and execution handlers for Bot Army MCP server.
  """
  require Logger

  def list_tools do
    [
      ping_tool(),
      task_create_tool(),
      task_list_tool(),
      task_get_tool(),
      task_update_tool(),
      task_complete_tool(),
      task_search_tool(),
      project_create_tool(),
      project_list_tool(),
      graph_query_tool(),
      world_snapshot_tool()
    ]
  end

  defp ping_tool do
    %{
      "name" => "ping",
      "description" => "Test connectivity - returns pong",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{},
        "required" => []
      }
    }
  end

  def execute(tool_name, params) do
    case tool_name do
      "ping" -> {:ok, "pong"}
      "task_create" -> execute_task_create(params)
      "task_list" -> execute_task_list(params)
      "task_get" -> execute_task_get(params)
      "task_update" -> execute_task_update(params)
      "task_complete" -> execute_task_complete(params)
      "task_search" -> execute_task_search(params)
      "project_create" -> execute_project_create(params)
      "project_list" -> execute_project_list(params)
      "graph_query" -> execute_graph_query(params)
      "world_snapshot" -> execute_world_snapshot(params)
      _ -> {:error, "Unknown tool: #{tool_name}"}
    end
  end

  # Tool definitions
  defp task_create_tool do
    %{
      "name" => "task_create",
      "description" => "Create a new GTD task",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "title" => %{"type" => "string", "description" => "Task title"},
          "description" => %{"type" => "string", "description" => "Task description (optional)"},
          "context" => %{
            "type" => "string",
            "enum" => ["inbox", "next", "someday", "reference", "waiting"],
            "description" => "GTD context"
          },
          "priority" => %{
            "type" => "string",
            "enum" => ["low", "normal", "high"],
            "description" => "Priority level"
          },
          "project_id" => %{"type" => "string", "description" => "Project ID (optional)"}
        },
        "required" => ["title"]
      }
    }
  end

  defp task_list_tool do
    %{
      "name" => "task_list",
      "description" => "List GTD tasks with pagination",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "limit" => %{"type" => "number", "description" => "Max tasks (default 50)"},
          "offset" => %{"type" => "number", "description" => "Pagination offset (default 0)"}
        }
      }
    }
  end

  defp task_get_tool do
    %{
      "name" => "task_get",
      "description" => "Get a specific task by ID",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "task_id" => %{"type" => "string", "description" => "Task UUID"}
        },
        "required" => ["task_id"]
      }
    }
  end

  defp task_update_tool do
    %{
      "name" => "task_update",
      "description" => "Update a task",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "task_id" => %{"type" => "string", "description" => "Task UUID"},
          "title" => %{"type" => "string"},
          "description" => %{"type" => "string"},
          "context" => %{
            "type" => "string",
            "enum" => ["inbox", "next", "someday", "reference", "waiting"]
          },
          "priority" => %{"type" => "string", "enum" => ["low", "normal", "high"]},
          "status" => %{
            "type" => "string",
            "enum" => ["active", "completed", "deleted"]
          }
        },
        "required" => ["task_id"]
      }
    }
  end

  defp task_complete_tool do
    %{
      "name" => "task_complete",
      "description" => "Mark a task as complete",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "task_id" => %{"type" => "string"}
        },
        "required" => ["task_id"]
      }
    }
  end

  defp task_search_tool do
    %{
      "name" => "task_search",
      "description" => "Search tasks",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "query" => %{"type" => "string"},
          "status" => %{"type" => "string"},
          "context" => %{"type" => "string"},
          "limit" => %{"type" => "number"}
        },
        "required" => ["query"]
      }
    }
  end

  defp project_create_tool do
    %{
      "name" => "project_create",
      "description" => "Create a new GTD project",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string"},
          "description" => %{"type" => "string"}
        },
        "required" => ["name"]
      }
    }
  end

  defp project_list_tool do
    %{
      "name" => "project_list",
      "description" => "List all GTD projects",
      "inputSchema" => %{"type" => "object", "properties" => %{}}
    }
  end

  defp graph_query_tool do
    %{
      "name" => "graph_query",
      "description" => "Query the Graphify knowledge graph for codebase context",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "repo_path" => %{"type" => "string", "description" => "Repository path"},
          "query" => %{"type" => "string", "description" => "Optional query string"}
        },
        "required" => ["repo_path"]
      }
    }
  end

  defp world_snapshot_tool do
    %{
      "name" => "world_snapshot",
      "description" => "Get current system state: bot health, registry, task summaries",
      "inputSchema" => %{"type" => "object", "properties" => %{}}
    }
  end

  # Execution handlers
  defp execute_task_create(params) do
    case bridge_request("bridge.task.create", params) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_task_list(params) do
    limit = Map.get(params, "limit", 50)
    offset = Map.get(params, "offset", 0)

    case bridge_request("bridge.task.list", %{"limit" => limit, "offset" => offset}) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_task_get(%{"task_id" => task_id}) do
    case bridge_request("bridge.task.get", %{"task_id" => task_id}) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_task_update(%{"task_id" => task_id} = params) do
    payload = Map.put(params, "task_id", task_id)

    case bridge_request("bridge.task.update", payload) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_task_complete(%{"task_id" => task_id}) do
    case bridge_request("bridge.task.complete", %{"task_id" => task_id}) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_task_search(params) do
    limit = Map.get(params, "limit", 50)

    payload = %{
      "query" => Map.get(params, "query"),
      "filters" => %{
        "status" => Map.get(params, "status"),
        "context" => Map.get(params, "context")
      },
      "limit" => limit
    }

    case bridge_request("bridge.task.search", payload) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_project_create(params) do
    payload = %{
      "name" => Map.get(params, "name"),
      "description" => Map.get(params, "description")
    }

    case bridge_request("bridge.project.create", payload) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_project_list(_params) do
    case bridge_request("bridge.project.list", %{}) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_graph_query(%{"repo_path" => repo_path} = params) do
    payload = %{
      "repo_path" => repo_path,
      "query" => Map.get(params, "query")
    }

    case bridge_request("bridge.graph.query", payload, 10_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_world_snapshot(_params) do
    log_to_file("world_snapshot: Starting bridge request")

    result =
      try do
        case bridge_request("bridge.world.snapshot", %{}, 3_000) do
          {:ok, result} ->
            log_to_file("world_snapshot: Bridge succeeded")
            {:ok, result}

          {:error, reason} ->
            log_to_file("world_snapshot: Bridge error: #{inspect(reason)}")
            {:error, "Bridge unavailable: #{reason}"}
        end
      rescue
        e ->
          log_to_file("world_snapshot: Exception: #{inspect(e)}")
          {:error, "Bridge request exception"}
      end

    log_to_file("world_snapshot: Returning #{inspect(result)}")
    result
  end

  defp log_to_file(msg) do
    log_file = "/tmp/bot_army_mcp_server.log"
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    File.write(log_file, "[#{timestamp}] Tools: #{msg}\n", [:append])
  end

  # Bridge request helper - uses BotArmyRuntime.NATS for proper connection management
  defp bridge_request(subject, payload, timeout \\ 5_000) do
    log_to_file("bridge_request: #{subject}")

    # Get the NATS connection from BotArmyRuntime
    case GenServer.call(BotArmyRuntime.NATS.Connection, :get_connection) do
      {:ok, conn} ->
        log_to_file("bridge_request: Got connection, sending request")

        case Gnat.request(conn, subject, Jason.encode!(payload), timeout: timeout) do
          {:ok, response} ->
            log_to_file("bridge_request: Got response from #{subject}")

            case Jason.decode(response.body) do
              {:ok, decoded} ->
                log_to_file("bridge_request: Decoded response")
                {:ok, decoded}

              {:error, reason} ->
                log_to_file("bridge_request: JSON decode error: #{inspect(reason)}")
                {:error, "Failed to decode response: #{to_string(reason)}"}
            end

          {:error, reason} ->
            log_to_file("bridge_request: Gnat request failed: #{inspect(reason)}")
            {:error, "Bridge request failed: #{to_string(reason)}"}
        end

      {:error, reason} ->
        log_to_file("bridge_request: No connection: #{inspect(reason)}")
        {:error, "NATS not connected: #{to_string(reason)}"}
    end
  end
end
