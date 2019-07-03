use Mix.Config

config :logger,
  level: :debug

config :husky,
  pre_commit: "mix format",
  pre_push: "mix test"

#  host_path: "../jq",
#  escript_path: "/Users/sc/code/husky-elixir/priv/husky"
#  json_codec: Jason
