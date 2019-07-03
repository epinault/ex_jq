# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger,
  level: :info,
  metadata: [:all],
  format: "[$level][$metadata] $message\n"

import_config "#{Mix.env()}.exs"
