defmodule Outlawn.Access.Authenticator do
  import Plug.Conn
  import Phoenix.Controller, only: [render: 3]

  def init(opts), do: opts

  def call(conn, _opts) do
    with [token] <- conn |> get_req_header("x-clearance"),
         {:ok, {id, _perms}} <- token |> Outlawn.Access.verify_token(),
         user = Outlawn.Repo.get(Outlawn.User, id),
         false <- is_nil(user) do
      conn
      |> assign(:current_user, user)
    else
      _ ->
        conn
        |> render("error.json", :unauthenticated)
        |> halt()
    end
  end
end
