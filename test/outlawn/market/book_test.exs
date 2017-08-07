defmodule BookTest do
  use Outlawn.DataCase
  require Decimal, as: D
  import Outlawn.RecordFactory

  alias Outlawn.Market.Book

  setup do
    {:ok, book} = start_supervised({Book, {:usd, :rub}})

    anton = create_record!(Outlawn.User, %{ username: "anton" })
    arnold = create_record!(Outlawn.User, %{ username: "arnold" })

    %{book: book, anton: anton.id, arnold: arnold.id}
  end

  test "starts with empty order book", %{book: book} do
    assert book |> Book.asks() == []
    assert book |> Book.bids() == []
  end

  test "queues a bid when asks are unaffordable", %{book: book, anton: anton, arnold: arnold} do
    {:ok, {id_1, _, _, _}, []} =
      book
      |> Book.place_order({D.new("59.01"), -10000, arnold})
    {:ok, {id_2, _, _, _}, []} =
      book
      |> Book.place_order({D.new("59.0"), 100, anton})

    assert book |> Book.bids() == [
      {id_2, D.new("59.0"), 100, anton}
    ]
    assert book |> Book.asks() == [
      {id_1, D.new("59.01"), -10000, arnold}
    ]
  end

  test "executes a bid when ask is available", %{book: book, anton: anton, arnold: arnold} do
    price = D.new("59.01")

    {:ok, {id_1, _, _, _}, []} =
      book
      |> Book.place_order({price, -10000, arnold})
    {:ok, _, txns} =
      book
      |> Book.place_order({D.new("59.1"), 100, anton})

    assert [{^price, 100}] = txns
    assert book |> Book.bids() == []
    assert book |> Book.asks() == [
      {id_1, price, -9900, arnold}
    ]
  end

  test "executes several bids when asks are available", %{book: book, anton: anton, arnold: arnold} do
    {:ok, {id_1, _, _, _}, []} =
      book
      |> Book.place_order({D.new("59.5"), -100, arnold})
    price_2 = D.new("59.02")
    {:ok, _, []} =
      book
      |> Book.place_order({price_2, -100, arnold})
    price_3 = D.new("59.01")
    {:ok, _, []} =
      book
      |> Book.place_order({price_3, -100, arnold})
    {:ok, {id_4, _, _, _}, txns} =
      book
      |> Book.place_order({D.new("59.1"), 293, anton})

    assert [{^price_2, -100}, {^price_3, -100}] = txns
    assert book |> Book.bids() == [
      {id_4, D.new("59.1"), 93, anton}
    ]
    assert book |> Book.asks() == [
      {id_1, D.new("59.5"), -100, arnold}
    ]
  end

  test "executes several asks when bids are available", %{book: book, anton: anton, arnold: arnold} do
    {:ok, {id_1, _, _, _}, []} =
      book
      |> Book.place_order({D.new("59.01"), 100, arnold})
    price_2 = D.new("59.49")
    {:ok, _, []} =
      book
      |> Book.place_order({price_2, 100, arnold})
    price_3 = D.new("59.5")
    {:ok, _, []} =
      book
      |> Book.place_order({price_3, 100, arnold})
    {:ok, {id_4, _, _, _}, txns} =
      book
      |> Book.place_order({D.new("59.1"), -293, anton})

    assert [{^price_2, 100}, {^price_3, 100}] = txns
    assert book |> Book.bids() == [
      {id_1, D.new("59.01"), 100, arnold}
    ]
    assert book |> Book.asks() == [
      {id_4, D.new("59.1"), -93, anton}
    ]
  end
end
