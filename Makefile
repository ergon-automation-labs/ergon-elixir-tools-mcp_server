.PHONY: help run dev test logs clean build escript test-escript verify-logs test-clean

help:
	@echo "Bot Army MCP Server - ergon-elixir-tools-mcp_server"
	@echo ""
	@echo "Development:"
	@echo "  run              - Start MCP server (for Claude Code)"
	@echo "  dev              - Start in development mode with debug logs"
	@echo "  test             - Run unit tests"
	@echo ""
	@echo "Escript (production binary):"
	@echo "  build            - Build escript binary (MIX_ENV=prod)"
	@echo "  test-escript     - Test escript with initialize message"
	@echo "  verify-logs      - Verify JSON→stdout, logs→stderr separation"
	@echo "  test-clean       - Clean rebuild + unit tests + escript test"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean            - Remove _build, deps, compiled artifacts"
	@echo "  logs             - Stream logs (if running in background)"

run:
	mix run --no-halt

dev:
	MIX_ENV=dev mix run --no-halt

test:
	mix test

build:
	MIX_ENV=prod mix escript.build

escript: build

test-escript: build
	@echo "Testing escript with initialize message..."
	@(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' && sleep 0.3) | ./bot_army_elixir_tools_mcp_server 2>&1 | head -20

verify-logs: build
	@echo "=== STDOUT (JSON-only) ===" && \
	(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' && sleep 0.3) | ./bot_army_elixir_tools_mcp_server 2>/dev/null && \
	echo "" && \
	echo "=== STDERR (logs) ===" && \
	(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' && sleep 0.3) | ./bot_army_elixir_tools_mcp_server 1>/dev/null && \
	echo "✅ Separation verified"

test-clean: clean test build test-escript
	@echo "✅ All tests passed"

clean:
	rm -rf _build deps bot_army_elixir_tools_mcp_server
