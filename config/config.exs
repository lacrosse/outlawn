# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :outlawn,
  ecto_repos: [Outlawn.Repo]

# Configures the endpoint
config :outlawn, OutlawnWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BN2bYa7bM9bhTH4KqO9Xo0D284WOMk6gPrGivu1DW1HDPUtrLmsCYi7f0pCiSX94",
  render_errors: [view: OutlawnWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Outlawn.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
