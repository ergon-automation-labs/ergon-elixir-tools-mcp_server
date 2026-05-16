import Config

config :logger,
  backends: [:console]

config :logger, :console, device: :standard_error

# Suppress infrastructure startup logs to stdout (critical for MCP protocol)
config :inets, :httpc_verbose, false
config :kernel, :error_logger_format_depth, 1

if config_env() == :dev do
  config :logger, level: :debug
end

if config_env() == :test do
  config :logger, level: :warn
end

if config_env() == :prod do
  config :logger, level: :info
end
