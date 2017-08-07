defmodule Outlawn.Accounting.UserTest do
  use Outlawn.DataCase
  import Outlawn.RecordFactory

  setup do
    :ok
  end

  test "shows zero balance when no transactions" do
    user = create_record!(Outlawn.User, %{username: "triangles"})

    assert user |> Outlawn.Accounting.User.balance(:bcc) == Decimal.new(0)
  end

  test "shows non-zero balance after some transactions" do
    user = create_record!(Outlawn.User, %{username: "happy"})
    order = create_record!(Outlawn.Market.Order, user.id, %{amount: 0, to: "bcc", from: "btc", price: 1})
    create_record!(Outlawn.Accounting.Transaction, %{
      user_id: user.id,
      order_id: order.id,
      instrument: "btc",
      amount: 80
    })

    assert user |> Outlawn.Accounting.User.balance(:btc) |> Decimal.equal?(Decimal.new(80))
    assert user |> Outlawn.Accounting.User.balance(:bcc) |> Decimal.equal?(Decimal.new(0))

    user_2 = create_record!(Outlawn.User, %{username: "aquarius"})

    {:ok, book} = Outlawn.Market.create_book({:bcc, :btc})

    {:ok, _, _} =
      book
      |> Outlawn.Market.Book.place_order({Decimal.new("0.08"), -1000, user_2.id})

    {:ok, _, _} =
      book
      |> Outlawn.Market.Book.place_order({Decimal.new("0.1"), 1000, user.id})

    assert user |> Outlawn.Accounting.User.balance(:btc) |> Decimal.equal?(Decimal.new(0))
    assert user |> Outlawn.Accounting.User.balance(:bcc) |> Decimal.equal?(Decimal.new(1000))

    {:ok, _, _} =
      book
      |> Outlawn.Market.Book.place_order({Decimal.new("0.1"), -1000, user.id})

    {:ok, _, _} =
      book
      |> Outlawn.Market.Book.place_order({Decimal.new("0.11"), 1000, user_2.id})

    assert user |> Outlawn.Accounting.User.balance(:btc) |> Decimal.equal?(Decimal.new(100))
    assert user |> Outlawn.Accounting.User.balance(:bcc) |> Decimal.equal?(Decimal.new(0))
  end
end
