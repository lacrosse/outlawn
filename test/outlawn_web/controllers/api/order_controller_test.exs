defmodule OutlawnWeb.API.OrderControllerTest do
  use OutlawnWeb.ConnCase, async: true

  alias Outlawn.{User, Repo, Access, Market}

  test "shows trader's current orders", %{conn: conn} do
    buyer =
      %User{}
      |> User.changeset(%{username: "bessie", password: "coltrane", password_confirmation: "coltrane"})
      |> Repo.insert!()

    seller =
      %User{}
      |> User.changeset(%{username: "nature_boy", password: "coltrane", password_confirmation: "coltrane"})
      |> Repo.insert!()

    token =
      buyer
      |> Access.issue_token(:full)

    {:ok, book} = Market.create_book({:eth, :btc})

    book |> Market.Book.place_order(seller.id, :sell, {Decimal.new("0.08"), 1})
    book |> Market.Book.place_order(buyer.id, :buy, {Decimal.new("0.08"), 2})

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

  test "places an order", %{conn: conn} do
    buyer =
      %User{}
      |> User.changeset(%{username: "jordan", password: "peterson", password_confirmation: "peterson"})
      |> Repo.insert!()

    token =
      buyer
      |> Access.issue_token(:full)

    {:ok, book} = Market.create_book({:xmr, :btc})

    book
    |> Market.Book.place_order(buyer.id, :buy, {Decimal.new("0.015"), 3})

    body = %{
      order: %{
        action: "buy",
        price: "0.016",
        amount: 4
      }
    }

    conn =
      conn
      |> put_req_header("x-clearance", token)
      |> post(book_order_path(conn, :create, "XMRBTC"), body)

    assert json_response(conn, 200) == %{
      "status" => "ok"
    }
    assert book |> Market.Book.asks() == []
    assert book |> Market.Book.bids() == [
      {Decimal.new("0.016"), 4, buyer.id},
      {Decimal.new("0.015"), 3, buyer.id},
    ]
  end
end
