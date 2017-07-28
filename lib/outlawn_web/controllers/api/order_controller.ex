defmodule OutlawnWeb.API.OrderController do
  use OutlawnWeb, :controller

  alias Outlawn.Market

  def index(conn, %{"book_id" => book_id}) do
    case book_id |> book_pid() do
      {:ok, book_pid} ->
        user = conn.assigns[:current_user]
        orders = Market.Book.orders_by_trader(book_pid, user.id)

        conn
        |> render("index.json", orders: orders)
      _ ->
        conn
        |> render("error.json", :no_book)
    end
  end

  def create(conn, %{"book_id" => book_id, "order" => order_params}) do
    case book_id |> book_pid() do
      {:ok, book_pid} ->
        user = conn.assigns[:current_user]

        %{"action" => action_string, "price" => price_string, "amount" => amount} = order_params
        action =
          case action_string do
            "sell" -> :sell
            "buy" -> :buy
          end
        price = Decimal.new(price_string)

        {:ok, executed} = book_pid |> Market.Book.place_order(user.id, action, {price, amount})

        conn
        |> render("executed.json", executed: executed)
      _ ->
        conn
        |> render("error.json", :no_book)
    end
  end

  defp book_pid(book_id) do
    with {:ok, book_pid} <- book_id |> Market.find_book() do
      {:ok, book_pid}
    else
      _ -> :error
    end
  end
end
