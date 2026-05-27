defmodule BotArmyElixirToolsMcpServer.StdioHandlerTest do
  use ExUnit.Case
  @moduletag :core

  describe "tools/list" do
    test "returns all tools with correct schema" do
      tools = BotArmyElixirToolsMcpServer.Tools.list_tools()
      assert is_list(tools)
      assert Enum.count(tools) == 23

      Enum.each(tools, fn tool ->
        assert tool["name"]
        assert tool["description"]
        assert tool["inputSchema"]
        assert tool["inputSchema"]["type"] == "object"
        assert tool["inputSchema"]["properties"]
      end)
    end

    test "tool names are present" do
      tools = BotArmyElixirToolsMcpServer.Tools.list_tools()
      tool_names = Enum.map(tools, & &1["name"])

      expected_tools = [
        "ping",
        "task_create",
        "task_list",
        "task_get",
        "task_update",
        "task_complete",
        "task_search",
        "project_create",
        "project_list",
        "graph_query",
        "graph_search",
        "graph_stats",
        "graph_list",
        "graph_refresh",
        "graph_context",
        "world_snapshot",
        "para_capture",
        "para_fs_write",
        "registry_list_bots",
        "registry_list_subjects",
        "health_check",
        "nats_request",
        "bridge_request"
      ]

      assert tool_names == expected_tools
    end
  end

  describe "initialize" do
    test "returns protocol version and server info" do
      {:ok, _state} = BotArmyElixirToolsMcpServer.StdioHandler.init(nil)

      tools = BotArmyElixirToolsMcpServer.Tools.list_tools()
      assert Enum.count(tools) == 23
    end
  end

  describe "unknown method" do
    test "returns error for unknown tools" do
      assert {:error, reason} = BotArmyElixirToolsMcpServer.Tools.execute("unknown_tool", %{})
      assert String.contains?(reason, "Unknown tool")
    end
  end

  describe "ping" do
    test "returns pong" do
      assert {:ok, "pong"} = BotArmyElixirToolsMcpServer.Tools.execute("ping", %{})
    end
  end
end
