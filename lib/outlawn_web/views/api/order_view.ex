defmodule OutlawnWeb.API.OrderView do
  use OutlawnWeb, :view

  def render("index.json", %{orders: %{asks: a, bids: b}}) do
    %{
      orders: %{
        asks: a |> Enum.map(&render("show.json", %{order: &1})),
        bids: b |> Enum.map(&render("show.json", %{order: &1}))
      }
    }
  end

  def render("show.json", %{order: {price, amount, _}}) do
    %{
      price: price,
      amount: amount
    }
  end
end
