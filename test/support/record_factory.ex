defmodule Outlawn.RecordFactory do
  alias Outlawn.{User, Repo, Accounting, Market}

  def create_record!(User, attrs) do
    attrs =
      %{password: "findherfiner", password_confirmation: "findherfiner"}
      |> Map.merge(attrs)

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  def create_record!(Accounting.Transaction, attrs) do
    %Accounting.Transaction{}
    |> Accounting.Transaction.changeset(attrs)
    |> Repo.insert!()
  end

  def create_record!(Market.Order, trader_id, attrs) do
    %Market.Order{}
    |> Market.Order.changeset(trader_id, attrs)
    |> Repo.insert!()
  end
end
