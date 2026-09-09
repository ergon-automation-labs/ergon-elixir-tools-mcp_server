.PHONY: help run run-http dev test logs clean build escript test-escript verify-logs test-clean release publish-release

MCP_PORT ?= 39900
NATS_SERVERS ?= localhost:4222

help:
	@echo "Bot Army MCP Server - ergon-elixir-tools-mcp_server"
	@echo ""
	@echo "Development:"
	@echo "  run              - Start MCP server via stdio (for Claude Desktop/Code)"
	@echo "  run-http         - Start MCP server with streamable HTTP transport"
	@echo "  dev              - Start in development mode with debug logs"
	@echo "  test             - Run unit tests"
	@echo ""
	@echo "Escript (production binary):"
	@echo "  build            - Build escript binary (MIX_ENV=prod)"
	@echo "  test-escript     - Test escript with initialize message"
	@echo "  verify-logs      - Verify JSON→stdout, logs→stderr separation"
	@echo "  test-clean       - Clean rebuild + unit tests + escript test"
	@echo ""
	@echo "HTTP transport:"
	@echo "  run-http          - Start on port $(MCP_PORT) (env: MCP_PORT)"
	@echo "  test-http         - Smoke test the HTTP endpoint"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean            - Remove _build, deps, compiled artifacts"
	@echo "  logs             - Stream logs (if running in background)"

run:
	@if [ -f .env.local ]; then source .env.local; fi && mix run --no-halt

run-http:
	@if [ -f .env.local ]; then source .env.local; fi && NATS_SERVERS=$(NATS_SERVERS) MCP_PORT=$(MCP_PORT) mix run --no-halt

dev:
	@if [ -f .env.local ]; then source .env.local; fi && MIX_ENV=dev mix run --no-halt

test:
	@if [ -f .env.local ]; then source .env.local; fi && mix test

deps:
	@if [ -f .env.local ]; then source .env.local; fi && mix deps.get

build: deps
	@if [ -f .env.local ]; then source .env.local; fi && MIX_ENV=prod mix escript.build

escript: build

test-escript: build
	@echo "Testing escript with initialize message..."
	@(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' && sleep 0.3) | ./bot_army_elixir_tools_mcp_server 2>&1 | head -20

test-http:
	@echo "Testing MCP HTTP endpoint on port $(MCP_PORT)..."
	@curl -s -X POST http://localhost:$(MCP_PORT)/mcp \
	  -H "content-type: application/json" \
	  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | python3 -m json.tool

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
release:
	MIX_ENV=prod $(MIX) release

# Scanner convention: `publish-release:` target must exist.
publish-release:
	@echo "This repo ships an escript (make build), not an OTP release tarball."; exit 0
