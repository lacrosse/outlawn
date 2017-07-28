use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :outlawn, OutlawnWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :outlawn, Outlawn.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "outlawn_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :outlawn, Outlawn.Access,
  algorithm: "ES512",
  jwk: %{
    "crv" => "P-521",
    "d" => "58NTavSQjQ1F3GUGLxhDE5pv4pMMkmkk8FCUYFOAxNmdmV47NmgXbHo2pEwn6npM725G4EFcGTTVd9z8ayAfHo8",
    "kty" => "EC",
    "x" => "AaMf06Wr0gMPuWHY30o4N9raNkNb7L69bSKZczkXKbrQOZZIw3-QD2Fr-Z9Q3SFqomSG0zNITYacZ9szUFp25UsU",
    "y" => "ACH5gK5n33hyVvTR1JCEJ4IiR6wFyag2dMLpCy1qlZ7IEa0o0RhB5Cg1Nxr7GL8MztqQzzlU3-NYNhttYEenDcT3"
  }

config :bcrypt_elixir,
  log_rounds: 4
