defmodule Outlawn.Market.BookTest do
  use ExUnit.Case, async: true

  require Decimal, as: D

  setup do
    {:ok, book} = start_supervised({Outlawn.Market.Book, {:usd, :rub}})
    %{book: book}
  end

  test "starts with empty order book", %{book: book} do
    assert book |> Outlawn.Market.Book.asks() == []
    assert book |> Outlawn.Market.Book.bids() == []
  end

  test "queues a bid when asks are unaffordable", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    {:ok, {id_1, _, _, _}, []} =
      book
      |> Outlawn.Market.Book.place_order(:sell, {D.new("59.01"), 10000, arnold})
    {:ok, {id_2, _, _, _}, []} =
      book
      |> Outlawn.Market.Book.place_order(:buy, {D.new("59.0"), 100, anton})

    assert book |> Outlawn.Market.Book.bids() == [
      {id_2, D.new("59.0"), 100, anton}
    ]
    assert book |> Outlawn.Market.Book.asks() == [
      {id_1, D.new("59.01"), 10000, arnold}
    ]
  end

  test "executes a bid when ask is available", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    price = D.new("59.01")

    {:ok, {id_1, _, _, _}, []} =
      book
      |> Outlawn.Market.Book.place_order(:sell, {price, 10000, arnold})
    {:ok, _, txns} =
      book
      |> Outlawn.Market.Book.place_order(:buy, {D.new("59.1"), 100, anton})

    assert [{_, ^price, 100}] = txns
    assert book |> Outlawn.Market.Book.bids() == []
    assert book |> Outlawn.Market.Book.asks() == [
      {id_1, price, 9900, arnold}
    ]
  end

  test "executes several bids when asks are available", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    {:ok, {id_1, _, _, _}, []} =
      book
      |> Outlawn.Market.Book.place_order(:sell, {D.new("59.5"), 100, arnold})
    price_2 = D.new("59.02")
    {:ok, _, []} =
      book
      |> Outlawn.Market.Book.place_order(:sell, {price_2, 100, arnold})
    price_3 = D.new("59.01")
    {:ok, _, []} =
      book
      |> Outlawn.Market.Book.place_order(:sell, {price_3, 100, arnold})
    {:ok, {id_4, _, _, _}, txns} =
      book
      |> Outlawn.Market.Book.place_order(:buy, {D.new("59.1"), 293, anton})

    assert [
      {_, ^price_2, 100},
      {_, ^price_3, 100}
    ] = txns
    assert book |> Outlawn.Market.Book.bids() == [
      {id_4, D.new("59.1"), 93, anton}
    ]
    assert book |> Outlawn.Market.Book.asks() == [
      {id_1, D.new("59.5"), 100, arnold}
    ]
  end

  test "executes several asks when bids are available", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    {:ok, {id_1, _, _, _}, []} =
      book
      |> Outlawn.Market.Book.place_order(:buy, {D.new("59.01"), 100, arnold})
    price_2 = D.new("59.49")
    {:ok, _, []} =
      book
      |> Outlawn.Market.Book.place_order(:buy, {price_2, 100, arnold})
    price_3 = D.new("59.5")
    {:ok, _, []} =
      book
      |> Outlawn.Market.Book.place_order(:buy, {price_3, 100, arnold})
    {:ok, {id_4, _, _, _}, txns} =
      book
      |> Outlawn.Market.Book.place_order(:sell, {D.new("59.1"), 293, anton})

    assert [
      {_, ^price_2, 100},
      {_, ^price_3, 100}
    ] = txns
    assert book |> Outlawn.Market.Book.bids() == [
      {id_1, D.new("59.01"), 100, arnold}
    ]
    assert book |> Outlawn.Market.Book.asks() == [
      {id_4, D.new("59.1"), 93, anton}
    ]
  end
end
