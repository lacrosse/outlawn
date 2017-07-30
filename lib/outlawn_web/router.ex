defmodule OutlawnWeb.Router do
  use OutlawnWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :protected do
    plug Outlawn.Access.Authenticator
  end

  scope "/api", OutlawnWeb.API do
    pipe_through :api

    resources "/users", UserController, only: [:create], singleton: true
  end

  scope "/api", OutlawnWeb.API do
    pipe_through [:api, :protected]

    resources "/markets", MarketController, only: [], name: :book do
      resources "/orders", OrderController, only: [:index, :create, :delete]
    end
  end
end
