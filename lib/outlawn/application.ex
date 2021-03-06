defmodule Outlawn.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Outlawn.Repo, []),
      supervisor(Outlawn.Market.Supervisor, []),
      supervisor(OutlawnWeb.Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: Outlawn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    OutlawnWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
