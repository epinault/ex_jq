use Mix.Config

config :logger,
       level: :debug

config :husky,
       pre_commit: "mix test",
       host_path: "../jq"