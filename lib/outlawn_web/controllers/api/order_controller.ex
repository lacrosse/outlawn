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

        %{"price" => price_string, "amount" => amount} = order_params

        price = Decimal.new(price_string)

        {:ok, order, txns} =
          book_pid
          |> Market.Book.place_order({price, amount, user.id})

        conn
        |> render("order_executed.json", order: order, txns: txns)
      _ ->
        conn
        |> render("error.json", :no_book)
    end
  end

  def delete(conn, %{"book_id" => book_id, "id" => order_id}) do
    case book_id |> book_pid() do
      {:ok, book_pid} ->
        user = conn.assigns[:current_user]

        case book_pid |> Market.Book.delete_order(order_id, user.id) do
          {:ok, order} ->
            conn
            |> render("order.json", order: order)
          :error ->
            conn
            |> render("error.json", :no_order)
        end
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
