defmodule Outlawn.Market.Supervisor do
  def start_link() do
    import Supervisor.Spec

    children = [
      supervisor(Outlawn.Market.BookRegistry, []),
      supervisor(Outlawn.Market.BookSupervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
