defmodule OutlawnWeb.API.UserControllerTest do
  use OutlawnWeb.ConnCase, async: true

  test "creates new user", %{conn: conn} do
    conn =
      conn
      |> post(user_path(conn, :create), %{
        user: %{
          username: "eastre",
          password: "cinereaL",
          password_confirmation: "cinereaL"
        }
      })

    assert %{
      "user" => %{
        "username" => "eastre",
        "token" => token
      }
    } = json_response(conn, 200)
    assert %Outlawn.User{id: id} = Outlawn.User |> Outlawn.Repo.get_by!(username: "eastre")
    assert String.length(token) > 0
    assert {:ok, {^id, "full"}} = Outlawn.Access.verify_token(token)
  end
end
