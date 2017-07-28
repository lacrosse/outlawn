defmodule OutlawnWeb.API.OrderController do
  use OutlawnWeb, :controller

  alias Outlawn.Market
  alias Outlawn.Market.Book

  def index(conn, %{"book_id" => book_id}) do
    with book_tuple <- book_id |> book_id_to_tuple(),
         {:ok, book_pid} <- book_tuple |> Market.find_book() do
      user = conn.assigns[:current_user]

      orders = Book.orders_by_trader(book_pid, user.id)

      conn
      |> render("index.json", orders: orders)
    else
      _ ->
        conn
        |> render("error.json", :no_book)
    end
  end

  defp book_id_to_tuple("ETHBTC"), do: {:eth, :btc}
end
