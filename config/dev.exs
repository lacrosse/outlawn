use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :outlawn, OutlawnWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :outlawn, Outlawn.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "outlawn_dev",
  hostname: "localhost",
  pool_size: 10

config :outlawn, Outlawn.Access,
  algorithm: "ES512",
  jwk: %{
    "crv" => "P-521",
    "d" => "MjRzOtCS-X8dp6ZbqyLuT8IdLBl-4UxljkVWbW4inYDAF8KGJ8N911syGjYXBZ_ZBdRsskq-uOCWQ0uSQ1B6r94",
    "kty" => "EC",
    "x" => "Aee9WKFmyAdcydDydA4gO9lHyi24XIwnMc-RGhJum--bgOjX-FGIGVT43aywXWCrwJ_Z01iD75xNAJidk4wz70kZ",
    "y" => "AK7vrjyvQ-AyresyhVEjVJ9b1GwGZ0ymSa3NCqi77LqtvvvVD1YUEJdxtBaW2mLNh5leokIo9VrhPPWTndvUzAfq"
  }

config :bcrypt_elixir,
  log_rounds: 4
