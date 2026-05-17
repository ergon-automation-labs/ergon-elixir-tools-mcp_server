import Config

# Logger is configured entirely in CLI (lib/bot_army_elixir_tools_mcp_server/cli.ex)
# This prevents stdout contamination from old logger configs
# Config here is only for non-logger settings

if config_env() == :dev do
  config :logger, level: :debug
end

if config_env() == :test do
  config :logger, level: :warn
end

if config_env() == :prod do
  config :logger, level: :info
end
