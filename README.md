# Bot Army MCP Server

MCP (Model Context Protocol) server for Claude Code to access and control Bot Army.

## Overview

Gives Claude Code (or any MCP client) real-time visibility and control of the Bot Army system:
- Query codebase knowledge graphs (Graphify)
- Check system state (bot health, task counts)
- Create/manage GTD tasks and projects
- Trigger bot operations indirectly via task/project changes

## Running the Server

### For Claude Code Integration

Start the server:
```bash
cd /Users/abby/code/surfaces/elixir/bot_army_mcp_server
make run
```

It listens on stdin/stdout for MCP protocol (JSON-RPC).

### Configuration

The server connects to Bot Army NATS on the default port (4223 dev / 4222 prod).

Set `NATS_SERVERS` environment variable to override:
```bash
NATS_SERVERS=nats://localhost:4222 make run
```

## Tools Available (10 total)

### Task Operations (6)
- **task_create** - Create new task with title, description, context, priority
- **task_list** - List tasks with pagination
- **task_get** - Get specific task by ID
- **task_update** - Update task fields
- **task_complete** - Mark task done
- **task_search** - Search tasks with filters

### Project Operations (2)
- **project_create** - Create new project
- **project_list** - List all projects

### System Query (2)
- **graph_query** - Query Graphify codebase knowledge graph for a repo path
- **world_snapshot** - Get current system state (bots, health, tasks)

## Example Requests

### Create a task
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "task_create",
  "params": {
    "title": "Fix gtd_bot deployment",
    "context": "next",
    "priority": "high"
  }
}
```

### Query system health
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "world_snapshot",
  "params": {}
}
```

### Check codebase graph
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "graph_query",
  "params": {
    "repo_path": "/Users/abby/code/elixir_bots"
  }
}
```

## Integration with Claude Code

Once the server is running, Claude Code can:

1. **Check system state before making changes** — `world_snapshot` shows which bots are running, health status
2. **Query codebase context** — `graph_query` provides knowledge graph for code understanding
3. **Create tasks for work discovered during development** — `task_create` during code review
4. **Track work in GTD** — Link code changes to tasks via `task_update`
5. **Verify deployments** — Check bot status post-deploy via `world_snapshot`

## Development

```bash
# Run tests
make test

# Run in dev mode (debug logs)
make dev

# Clean build
make clean
```

## Architecture

- **StdioHandler** — Reads JSON-RPC from stdin, routes to tools
- **Tools** — Defines all 10 tools and execution logic
- **Bridge requests** — Translates tool calls to NATS `bridge.*` subjects
- **NATS integration** — Uses BotArmyRuntime to connect to NATS

All tool calls go through the Bot Army bridge, which enforces validation and injects tenant/user context automatically.

## Troubleshooting

**Server won't start:**
- Ensure NATS is running: `lsof -i :4223` (dev) or `lsof -i :4222` (prod)
- Check NATS_SERVERS env var matches your setup

**Bridge requests timing out:**
- Verify bridge is running: `ps aux | grep bridge`
- Check NATS connectivity: `nats sub bridge.task.list` in another terminal

**No response from tools:**
- Check server logs: `MIX_ENV=dev mix run --no-halt`
- Verify NATS subject names match your bridge version

## Next Steps

- Wire into Claude Code settings.json for automatic MCP connection
- Add more system query tools (logs, deployments, etc.)
- Implement outbound MCP calls (Slack, GitHub integrations)
- Session threading for multi-turn conversation memory
