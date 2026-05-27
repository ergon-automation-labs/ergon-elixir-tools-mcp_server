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
      graph_search_tool(),
      graph_stats_tool(),
      graph_list_tool(),
      graph_refresh_tool(),
      graph_context_tool(),
      world_snapshot_tool(),
      para_capture_tool(),
      para_fs_write_tool(),
      registry_list_bots_tool(),
      registry_list_subjects_tool(),
      health_check_tool(),
      nats_request_tool(),
      bridge_request_tool()
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
      "graph_search" -> execute_graph_search(params)
      "graph_stats" -> execute_graph_stats(params)
      "graph_list" -> execute_graph_list(params)
      "graph_refresh" -> execute_graph_refresh(params)
      "graph_context" -> execute_graph_context(params)
      "world_snapshot" -> execute_world_snapshot(params)
      "para_capture" -> execute_para_capture(params)
      "para_fs_write" -> execute_para_fs_write(params)
      "registry_list_bots" -> execute_registry_list_bots(params)
      "registry_list_subjects" -> execute_registry_list_subjects(params)
      "health_check" -> execute_health_check(params)
      "nats_request" -> execute_nats_request(params)
      "bridge_request" -> execute_bridge_request(params)
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

  defp graph_search_tool do
    %{
      "name" => "graph_search",
      "description" => "Search within a codebase graph for symbols, files, or patterns",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "repo_path" => %{"type" => "string", "description" => "Repository path"},
          "query" => %{
            "type" => "string",
            "description" => "Search query (symbol, file, or pattern)"
          },
          "type" => %{
            "type" => "string",
            "enum" => ["symbol", "file", "pattern"],
            "description" => "Type of search"
          }
        },
        "required" => ["repo_path", "query"]
      }
    }
  end

  defp graph_stats_tool do
    %{
      "name" => "graph_stats",
      "description" => "Get statistics about a codebase graph (modules, functions, complexity)",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "repo_path" => %{"type" => "string", "description" => "Repository path"}
        },
        "required" => ["repo_path"]
      }
    }
  end

  defp graph_list_tool do
    %{
      "name" => "graph_list",
      "description" => "List all available cached codebase graphs",
      "inputSchema" => %{"type" => "object", "properties" => %{}}
    }
  end

  defp graph_refresh_tool do
    %{
      "name" => "graph_refresh",
      "description" => "Refresh/regenerate the knowledge graph for a repository",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "repo_path" => %{"type" => "string", "description" => "Repository path"}
        },
        "required" => ["repo_path"]
      }
    }
  end

  defp graph_context_tool do
    %{
      "name" => "graph_context",
      "description" => "Get context around a specific symbol or file in the graph",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "repo_path" => %{"type" => "string", "description" => "Repository path"},
          "symbol" => %{"type" => "string", "description" => "Symbol or file name"},
          "depth" => %{"type" => "number", "description" => "Context depth (1-5, default 2)"}
        },
        "required" => ["repo_path", "symbol"]
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

  defp para_capture_tool do
    %{
      "name" => "para_capture",
      "description" => "Append a note to the PARA inbox via para.capture.append",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "summary" => %{"type" => "string", "description" => "Short summary / title"},
          "details" => %{
            "type" => "string",
            "description" => "Longer markdown content (optional)"
          },
          "topic" => %{
            "type" => "string",
            "description" => "Topic tag (optional, default: general)"
          },
          "task_id" => %{"type" => "string", "description" => "Optional linked GTD task ID"}
        },
        "required" => ["summary"]
      }
    }
  end

  defp para_fs_write_tool do
    %{
      "name" => "para_fs_write",
      "description" => "Write or append a file to the PARA filesystem via para.fs.write",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "relative_path" => %{
            "type" => "string",
            "description" => "Path relative to PARA root, e.g. inbox/note.md"
          },
          "content" => %{"type" => "string", "description" => "File content (markdown)"},
          "mode" => %{
            "type" => "string",
            "enum" => ["write", "append"],
            "description" => "Write mode: write (overwrite) or append"
          }
        },
        "required" => ["relative_path", "content"]
      }
    }
  end

  defp registry_list_bots_tool do
    %{
      "name" => "registry_list_bots",
      "description" => "List all registered bots with versions, health, and subjects",
      "inputSchema" => %{"type" => "object", "properties" => %{}}
    }
  end

  defp registry_list_subjects_tool do
    %{
      "name" => "registry_list_subjects",
      "description" => "List all NATS subjects and their providers",
      "inputSchema" => %{"type" => "object", "properties" => %{}}
    }
  end

  defp health_check_tool do
    %{
      "name" => "health_check",
      "description" => "Check health of a specific bot via system.health.<bot_name>",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "bot_name" => %{
            "type" => "string",
            "description" => "Bot registry name (e.g. gtd, llm, dispatcher)"
          }
        },
        "required" => ["bot_name"]
      }
    }
  end

  defp nats_request_tool do
    %{
      "name" => "nats_request",
      "description" =>
        "Send a request/reply to any NATS subject (direct bot access, not via bridge)",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "subject" => %{
            "type" => "string",
            "description" => "Full NATS subject (e.g. bot_army.gtd.task.list, system.health.llm)"
          },
          "payload" => %{
            "type" => "object",
            "description" => "JSON payload to send (default: {})"
          },
          "timeout_ms" => %{
            "type" => "number",
            "description" => "Timeout in milliseconds (default 5000)"
          }
        },
        "required" => ["subject"]
      }
    }
  end

  defp bridge_request_tool do
    %{
      "name" => "bridge_request",
      "description" => "Send a request to any bridge.* subject (operator façade only)",
      "inputSchema" => %{
        "type" => "object",
        "properties" => %{
          "subject" => %{
            "type" => "string",
            "description" => "NATS subject, must start with bridge."
          },
          "payload" => %{
            "type" => "object",
            "description" => "JSON payload to send"
          },
          "timeout_ms" => %{
            "type" => "number",
            "description" => "Timeout in milliseconds (default 5000)"
          }
        },
        "required" => ["subject"]
      }
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

  defp execute_graph_search(%{"repo_path" => repo_path, "query" => query} = params) do
    payload = %{
      "repo_path" => repo_path,
      "query" => query,
      "type" => Map.get(params, "type", "symbol")
    }

    case bridge_request("bridge.graph.search", payload, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_graph_stats(%{"repo_path" => repo_path}) do
    case bridge_request("bridge.graph.stats", %{"repo_path" => repo_path}, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_graph_list(_params) do
    case bridge_request("bridge.graph.list", %{}, 3_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_graph_refresh(%{"repo_path" => repo_path}) do
    case bridge_request("bridge.graph.refresh", %{"repo_path" => repo_path}, 30_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_graph_context(%{"repo_path" => repo_path, "symbol" => symbol} = params) do
    payload = %{
      "repo_path" => repo_path,
      "symbol" => symbol,
      "depth" => Map.get(params, "depth", 2)
    }

    case bridge_request("bridge.graph.context", payload, 10_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_world_snapshot(_params) do
    log_to_file("world_snapshot: querying registry")

    result =
      case bridge_request("bot_army.registry.bots.list", %{}, 5_000) do
        {:ok, %{"ok" => true, "data" => data}} ->
          bots = Map.get(data, "bots", [])

          summary =
            Enum.map(bots, fn b ->
              %{
                "name" => Map.get(b, "name"),
                "version" => Map.get(b, "version"),
                "last_heartbeat" => Map.get(b, "last_heartbeat"),
                "subject_count" => Map.get(b, "subject_count", 0),
                "status" => if(recent_heartbeat?(b), do: "healthy", else: "stale")
              }
            end)

          {:ok, %{"bots" => summary, "count" => length(summary)}}

        {:ok, %{"ok" => false} = error_resp} ->
          {:error, Map.get(error_resp, "error", "Registry returned error")}

        {:error, reason} ->
          log_to_file("world_snapshot: registry error: #{inspect(reason)}")
          {:error, "Registry unavailable: #{reason}"}

        _ ->
          {:error, "Unexpected response from registry"}
      end

    log_to_file("world_snapshot: Returning #{inspect(result)}")
    result
  end

  defp recent_heartbeat?(bot) do
    case Map.get(bot, "last_heartbeat") do
      nil ->
        false

      ts ->
        case DateTime.from_iso8601(ts) do
          {:ok, dt, _} -> DateTime.diff(DateTime.utc_now(), dt, :second) < 120
          _ -> false
        end
    end
  end

  defp execute_para_capture(params) do
    summary = Map.get(params, "summary")

    payload = %{
      "schema_version" => "1.0",
      "source_bot" => "claude_bridge",
      "summary" => summary,
      "details" => Map.get(params, "details", ""),
      "topic" => Map.get(params, "topic", "general"),
      "task_id" => Map.get(params, "task_id")
    }

    case bridge_request("para.capture.append", payload, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_para_fs_write(params) do
    relative_path = Map.get(params, "relative_path")
    content = Map.get(params, "content")
    mode = Map.get(params, "mode", "write")

    payload = %{
      "schema_version" => "1.0",
      "relative_path" => relative_path,
      "mode" => mode,
      "content" => content
    }

    case bridge_request("para.fs.write", payload, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_registry_list_bots(_params) do
    case bridge_request("bot_army.registry.bots.list", %{}, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_registry_list_subjects(_params) do
    case bridge_request("bot_army.registry.subjects.list", %{}, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_health_check(%{"bot_name" => bot_name}) do
    subject = "system.health.#{bot_name}"

    case bridge_request(subject, %{}, 5_000) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_nats_request(params) do
    subject = Map.get(params, "subject", "")
    payload = Map.get(params, "payload", %{})
    timeout = Map.get(params, "timeout_ms", 5_000)

    case bridge_request(subject, payload, timeout) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp execute_bridge_request(params) do
    subject = Map.get(params, "subject", "")

    if not String.starts_with?(subject, "bridge.") do
      {:error, "Subject must start with bridge. (operator façade only)"}
    else
      payload = Map.get(params, "payload", %{})
      timeout = Map.get(params, "timeout_ms", 5_000)

      case bridge_request(subject, payload, timeout) do
        {:ok, result} -> {:ok, result}
        error -> error
      end
    end
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
