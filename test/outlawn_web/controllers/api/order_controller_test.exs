defmodule OutlawnWeb.API.OrderControllerTest do
  use OutlawnWeb.ConnCase, async: true

  test "shows trader's current orders", %{conn: conn} do
    buyer =
      %Outlawn.User{}
      |> Outlawn.User.changeset(%{username: "bessie", password: "coltrane", password_confirmation: "coltrane"})
      |> Outlawn.Repo.insert!()

    seller =
      %Outlawn.User{}
      |> Outlawn.User.changeset(%{username: "nature_boy", password: "coltrane", password_confirmation: "coltrane"})
      |> Outlawn.Repo.insert!()

    token =
      buyer
      |> Outlawn.Access.issue_token(:full)

    {:ok, book} = Outlawn.Market.create_book({:eth, :btc})

    book
    |> Outlawn.Market.Book.place_order(seller.id, :sell, {Decimal.new("0.08"), 1})

    book
    |> Outlawn.Market.Book.place_order(buyer.id, :buy, {Decimal.new("0.08"), 2})

    conn =
      conn
      |> put_req_header("x-clearance", token)
      |> get(book_order_path(conn, :index, "ETHBTC"))

    assert json_response(conn, 200) == %{
      "orders" => %{
        "bids" => [%{"price" => "0.08", "amount" => 1}],
        "asks" => []
      }
    }
  end
end
