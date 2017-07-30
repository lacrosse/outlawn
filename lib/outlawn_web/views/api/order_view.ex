defmodule OutlawnWeb.API.OrderView do
  use OutlawnWeb, :view

  def render("index.json", %{orders: %{asks: a, bids: b}}) do
    %{
      orders: %{
        asks: a |> Enum.map(&one/1),
        bids: b |> Enum.map(&one/1)
      }
    }
  end

  def render("order.json", %{order: order}) do
    %{order: one(order)}
  end

  def render("order_executed.json", %{order: order, txns: txns}) when is_list(txns) do
    %{order: one(order)}
  end

  def one({id, price, amount, _}) do
    %{
      id: id,
      price: price,
      amount: amount
    }
  end
end
