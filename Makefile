.PHONY: help run dev test logs clean

help:
	@echo "Bot Army MCP Server"
	@echo ""
	@echo "Targets:"
	@echo "  run         - Start MCP server (for Claude Code)"
	@echo "  dev         - Start in development mode with debug logs"
	@echo "  test        - Run tests"
	@echo "  logs        - Stream logs (if running in background)"
	@echo "  clean       - Remove deps and build artifacts"

run:
	mix run --no-halt

dev:
	MIX_ENV=dev mix run --no-halt

test:
	mix test

clean:
	rm -rf _build deps
