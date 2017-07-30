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

    book
    |> Market.Book.place_order(:sell, {Decimal.new("0.08"), 1, seller.id})

    {:ok, {o_id, _, _, _}, _} =
      book
      |> Market.Book.place_order(:buy, {Decimal.new("0.08"), 2, buyer.id})

    conn =
      conn
      |> put_req_header("x-clearance", token)
      |> get(book_order_path(conn, :index, "ETHBTC"))

    assert json_response(conn, 200) == %{
      "orders" => %{
        "bids" => [%{"id" => o_id, "price" => "0.08", "amount" => 1}],
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

    {:ok, {id_1, _, _, _}, _} =
      book
      |> Market.Book.place_order(:buy, {Decimal.new("0.015"), 3, buyer.id})

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

    assert %{
      "order" => %{
        "id" => id_2,
        "price" => "0.016",
        "amount" => 4
      }
    } = json_response(conn, 200)
    assert id_2 |> String.length() > 0
    assert book |> Market.Book.asks() == []
    assert book |> Market.Book.bids() == [
      {id_2, Decimal.new("0.016"), 4, buyer.id},
      {id_1, Decimal.new("0.015"), 3, buyer.id},
    ]
  end

  test "removes an order", %{conn: conn} do
    buyer =
      %User{}
      |> User.changeset(%{username: "chuck", password: "bobbyaxelrod", password_confirmation: "bobbyaxelrod"})
      |> Repo.insert!()

    seller =
      %User{}
      |> User.changeset(%{username: "wendy", password: "dollarbill", password_confirmation: "dollarbill"})
      |> Repo.insert!()

    token =
      buyer
      |> Access.issue_token(:full)

    {:ok, book} = Market.create_book({:eth, :xmr})

    book
    |> Market.Book.place_order(:sell, {Decimal.new("8.4"), 7, seller.id})

    {:ok, {order_id, _, _, _}, _} =
      book
      |> Market.Book.place_order(:buy, {Decimal.new("8.5"), 100, buyer.id})

    conn =
      conn
      |> put_req_header("x-clearance", token)
      |> delete(book_order_path(conn, :delete, "ETHXMR", order_id))

    assert json_response(conn, 200) == %{
      "order" => %{
        "id" => order_id,
        "price" => "8.5",
        "amount" => 93
      }
    }
  end
end
