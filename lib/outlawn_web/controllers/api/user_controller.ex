defmodule OutlawnWeb.API.UserController do
  use OutlawnWeb, :controller

  alias Outlawn.User

  def create(conn, %{"user" => user_params}) do
    user_changeset =
      %User{}
      |> User.changeset(user_params)

    case Outlawn.Repo.insert(user_changeset) do
      {:ok, user} ->
        token =
          user
          |> Outlawn.Access.issue_token(:full)

        conn
        |> render("show.json", user: user, token: token)
      {:error, changeset} ->
        conn
        |> render("error.json", changeset: changeset)
    end
  end
end
