import Config

# Suppress all logging output to stdout
config :logger,
  level: :emergency,
  backends: []

# Disable PromEx HTTP endpoint to prevent startup logs
config :bot_army_runtime,
  auto_start_services: false,
  metrics_port: 9090

# Suppress opentelemetry logging
config :opentelemetry, :logger, level: :error

# Disable logger_json formatter
config :logger_json,
  enabled: false
