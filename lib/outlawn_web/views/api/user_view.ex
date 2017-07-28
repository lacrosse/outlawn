defmodule OutlawnWeb.API.UserView do
  use OutlawnWeb, :view

  def render("show.json", %{user: %Outlawn.User{username: username}, token: token}) do
    %{
      user: %{
        username: username,
        token: token
      }
    }
  end
end
