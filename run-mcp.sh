#!/bin/bash
# MCP wrapper script for Claude Desktop
# Launches the bot_army MCP server with proper environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set default NATS servers (production port)
# Format: host:port (no nats:// scheme)
export NATS_SERVERS="${NATS_SERVERS:-localhost:4222}"

# Run the compiled server
exec "$SCRIPT_DIR/bot_army_elixir_tools_mcp_server"
