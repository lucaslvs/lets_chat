# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :lets_chat,
  ecto_repos: [LetsChat.Repo]

# Configures the endpoint
config :lets_chat, LetsChatWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wEVA+C6INL0HGY78uCFozhGj4ji8Me6ves1G4tFv0in0aPmO75+xGaj0F7c1yd6B",
  render_errors: [view: LetsChatWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LetsChat.PubSub,
  live_view: [signing_salt: "uy2PlVkQ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
