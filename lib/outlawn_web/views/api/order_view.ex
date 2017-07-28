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

  def render("executed.json", %{executed: executed}) when is_list(executed) do
    %{status: "ok"}
  end

  def one({price, amount, _}) do
    %{
      price: price,
      amount: amount
    }
  end
end
