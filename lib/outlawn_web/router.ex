defmodule OutlawnWeb.Router do
  use OutlawnWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", OutlawnWeb do
    pipe_through :api
  end
end
