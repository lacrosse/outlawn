defmodule Outlawn.Accounting.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "transactions" do
    field :amount, :decimal
    field :instrument, :string

    belongs_to :order_id, Outlawn.Market.Order, type: :binary_id
    belongs_to :user_id, Outlawn.User, type: :integer

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(%__MODULE__{} = transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :instrument, :order_id, :user_id])
    |> validate_required([:amount, :instrument, :order_id, :user_id])
  end

  def double_entry_multi(inst, amount, {from, from_order}, {to, to_order}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert({inst, :src}, __MODULE__.changeset(
      %__MODULE__{}, %{
        user_id: from,
        order_id: from_order,
        instrument: inst,
        amount: amount |> Decimal.minus()
      })
    )
    |> Ecto.Multi.insert({inst, :dst}, __MODULE__.changeset(
      %__MODULE__{}, %{
        user_id: to,
        order_id: to_order,
        instrument: inst,
        amount: amount
      })
    )
  end
end
