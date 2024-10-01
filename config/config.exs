import Config

config :logger,
  level: :info,
  format: "[$level][$metadata] $message\n"

import_config "#{Mix.env()}.exs"
