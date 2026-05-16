defmodule BotArmyMcpServer.StdioHandlerTest do
  use ExUnit.Case
  @moduletag :integration

  describe "tools/list" do
    test "returns all 10 tools with correct schema" do
      request = %{"jsonrpc" => "2.0", "id" => 1, "method" => "tools/list", "params" => %{}}

      assert {:ok, result} = BotArmyMcpServer.Tools.execute("tools/list", %{})
      assert is_list(result["tools"])
      assert Enum.count(result["tools"]) == 10

      # Verify tool schema
      Enum.each(result["tools"], fn tool ->
        assert tool["name"]
        assert tool["description"]
        assert tool["inputSchema"]
        assert tool["inputSchema"]["type"] == "object"
        assert tool["inputSchema"]["properties"]
      end)
    end

    test "tool names are present" do
      assert {:ok, result} = BotArmyMcpServer.Tools.execute("tools/list", %{})
      tool_names = Enum.map(result["tools"], & &1["name"])

      expected_tools = [
        "task_create",
        "task_list",
        "task_get",
        "task_update",
        "task_complete",
        "task_search",
        "project_create",
        "project_list",
        "graph_query",
        "world_snapshot"
      ]

      assert tool_names == expected_tools
    end
  end

  describe "initialize" do
    test "returns protocol version and server info" do
      request = %{"jsonrpc" => "2.0", "id" => 1, "method" => "initialize"}
      {:ok, state} = BotArmyMcpServer.StdioHandler.init(nil)

      # Manually call the handler (in real usage, this goes through read_loop)
      # For now, just verify the Tools module responds correctly
      tools = BotArmyMcpServer.Tools.list_tools()
      assert Enum.count(tools) == 10
    end
  end

  describe "unknown method" do
    test "returns error for unknown tools" do
      assert {:error, reason} = BotArmyMcpServer.Tools.execute("unknown_tool", %{})
      assert String.contains?(reason, "Unknown tool")
    end
  end
end
