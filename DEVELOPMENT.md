# Bot Army MCP Server - Development

## What We Built

An Elixir/OTP MCP (Model Context Protocol) server that gives Claude Code (and other tools) real-time access to Bot Army operations.

## Architecture

### Components

1. **StdioHandler** (`lib/bot_army_elixir_tools_mcp_server/stdio_handler.ex`)
   - Reads JSON-RPC messages from stdin
   - Parses and routes to tool handlers
   - Sends responses back to stdout
   - Blocks until EOF

2. **Tools** (`lib/bot_army_mcp_server/tools.ex`)
   - Defines 10 MCP tools (schemas + execution)
   - Routes tool calls to bridge request handlers
   - Translates responses back to MCP format

3. **Bridge Integration**
   - Uses `BotArmyRuntime.NATS.request/3` to call `bridge.*` subjects
   - 5s timeout for most tools
   - 10s timeout for graph queries

### Tools (10 total)

**Task Operations (6):**
- task_create, task_list, task_get, task_update, task_complete, task_search

**Project Operations (2):**
- project_create, project_list

**System Query (2):**
- graph_query (codebase knowledge graph)
- world_snapshot (bot health, tasks, registry)

## Running Locally

### Option 1: Via Mix (Development)

```bash
cd /Users/abby/code/surfaces/elixir/tools/bot_army_elixir_tools_mcp_server
make run
```

### Option 2: Via Escript (Claude Code Integration)

The server builds as a standalone escript (self-contained binary):

```bash
cd /Users/abby/code/surfaces/elixir/tools/bot_army_elixir_tools_mcp_server
mix escript.build                    # Generates ./bot_army_elixir_tools_mcp_server (~6.3MB)
./bot_army_elixir_tools_mcp_server   # Runs standalone, no mix/Elixir needed
```

The escript is configured in `.mcp.json` (monorepo root) for Claude Code to spawn on-demand. Claude Code will automatically invoke it when you use any of the 10 MCP tools.

### Testing

The server listens on stdin/stdout (MCP protocol). To test manually:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | ./bot_army_elixir_tools_mcp_server
```

All tool calls are logged with structured JSON including execution duration and status.

## Building & Rebuilding

When you change code in this server, rebuild the escript:

```bash
cd /Users/abby/code/surfaces/elixir/tools/bot_army_elixir_tools_mcp_server
mix escript.build
```

Claude Code will pick up the new binary on the next MCP server spawn.

## Updating the MCP Server (No Deployment Required)

**The MCP server runs locally on your machine, not on Air.** It doesn't need Salt deployment.

When you make changes:

1. Modify code in `lib/bot_army_elixir_tools_mcp_server/`
2. Rebuild: `MIX_ENV=prod mix escript.build`
3. Claude Code reads the new binary from `.mcp.json` path on next use

No version bumps, no commits, no `make deploy-*` needed — just rebuild and Claude Code picks it up immediately.

## Testing

```bash
# Quick compile check
mix compile

# Run all tests (when we add them)
mix test

# Run with dev logs
make dev
```

## Claude Code Integration

The server is wired into Claude Code via `.mcp.json` (monorepo root):

```json
{
  "mcpServers": {
    "bot-army": {
      "command": "/Users/abby/code/surfaces/elixir/tools/bot_army_elixir_tools_mcp_server/bot_army_elixir_tools_mcp_server"
    }
  }
}
```

Claude Code enables it with `enableAllProjectMcpServers: true` in `~/.claude/settings.json`.

**What this means:**
- When you use any of the 10 tools in Claude Code, it spawns this escript
- All requests/responses flow via JSON-RPC (MCP protocol)
- Every tool call is logged with duration + status (structured JSON)
- Timeouts protect against hangs (5s default, 10s for graph_query)
- The bridge validates all calls and injects tenant/user context

## Next Steps

1. **Test with actual NATS** - Ensure bridge calls work
2. **Add .mise config** or instructions for running via Claude Code
3. **Implement in Claude Code settings** - Wire MCP server as a tool source
4. **Add session state** - Multi-turn conversation memory (Phase 3)
5. **Add more query tools** - Logs, deployment status, etc.

## Design Decisions

**Elixir/OTP vs TypeScript:**
- OTP provides supervision, resilience
- Integrated with bot ecosystem
- Session state easier to manage (GenServer)
- Better for long-lived processes

**Stdio vs Network Socket:**
- Stdio is MCP standard for IDE integration
- Simpler, no port management
- Natural for subprocess spawning

**Bridge vs Direct NATS:**
- Bridge enforces validation, tenants, user context
- Already available, tested
- No need to reimplement NATS integration

## Known Issues / TODOs

- [ ] Error handling for NATS failures (timeouts, no responder)
- [ ] Graceful shutdown on EOF
- [ ] Performance testing with large responses
- [ ] Wire into Claude Code settings.json
- [ ] Add per-request logging/correlation IDs
