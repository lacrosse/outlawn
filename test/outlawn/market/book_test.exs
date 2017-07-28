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

    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :sell, {D.new("59.01"), 10000})
    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(anton, :buy, {D.new("59.0"), 100})

    assert book |> Outlawn.Market.Book.bids() == [
      {D.new("59.0"), 100, anton}
    ]
    assert book |> Outlawn.Market.Book.asks() == [
      {D.new("59.01"), 10000, arnold}
    ]
  end

  test "executes a bid when ask is available", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :sell, {D.new("59.01"), 10000})
    {:ok, executed} =
      book
      |> Outlawn.Market.Book.place_order(anton, :buy, {D.new("59.1"), 100})

    assert executed == [{D.new("59.01"), 100, arnold}]
    assert book |> Outlawn.Market.Book.bids() == []
    assert book |> Outlawn.Market.Book.asks() == [
      {D.new("59.01"), 9900, arnold}
    ]
  end

  test "executes several bids when asks are available", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :sell, {D.new("59.5"), 100})
    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :sell, {D.new("59.02"), 100})
    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :sell, {D.new("59.01"), 100})
    {:ok, executed} =
      book
      |> Outlawn.Market.Book.place_order(anton, :buy, {D.new("59.1"), 293})

    assert executed == [
      {D.new("59.02"), 100, arnold},
      {D.new("59.01"), 100, arnold}
    ]
    assert book |> Outlawn.Market.Book.bids() == [
      {D.new("59.1"), 93, anton}
    ]
    assert book |> Outlawn.Market.Book.asks() == [
      {D.new("59.5"), 100, arnold}
    ]
  end

  test "executes several asks when bids are available", %{book: book} do
    anton = make_ref()
    arnold = make_ref()

    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :buy, {D.new("59.01"), 100})
    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :buy, {D.new("59.49"), 100})
    {:ok, []} =
      book
      |> Outlawn.Market.Book.place_order(arnold, :buy, {D.new("59.5"), 100})
    {:ok, executed} =
      book
      |> Outlawn.Market.Book.place_order(anton, :sell, {D.new("59.1"), 293})

    assert executed == [
      {D.new("59.49"), 100, arnold},
      {D.new("59.5"), 100, arnold}
    ]
    assert book |> Outlawn.Market.Book.bids() == [
      {D.new("59.01"), 100, arnold}
    ]
    assert book |> Outlawn.Market.Book.asks() == [
      {D.new("59.1"), 93, anton}
    ]
  end
end
