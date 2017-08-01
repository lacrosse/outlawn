defmodule Outlawn.Market.Order do
  use Ecto.Schema
  import Ecto.Changeset
  alias Outlawn.Market.{Order, Trader}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "orders" do
    field :amount, :decimal
    field :from, :string
    field :price, :decimal
    field :to, :string

    belongs_to :trader, Trader, type: :integer

    timestamps()
  end

  @doc false
  def changeset(%Order{} = order, trader_id, attrs) do
    order
    |> cast(attrs, [:to, :from, :price, :amount])
    |> validate_required([:to, :from, :price, :amount])
    |> validate_number(:price, greater_than: 0)
    |> put_change(:trader_id, trader_id)
  end
end
