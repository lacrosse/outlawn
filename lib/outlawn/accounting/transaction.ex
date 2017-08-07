defmodule Outlawn.Accounting.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "transactions" do
    field :amount, :decimal
    field :instrument, :string

    belongs_to :order, Outlawn.Market.Order, type: :binary_id
    belongs_to :user, Outlawn.User, type: :integer

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(%__MODULE__{} = transaction, attrs) do
    transaction
    |> cast(attrs, [:amount, :instrument, :order_id, :user_id])
    |> validate_required([:amount, :instrument, :order_id, :user_id])
    |> foreign_key_constraint(:order_id)
    |> foreign_key_constraint(:user_id)
  end

  def double_entry_multi(inst, amount, {from, from_order}, {to, to_order}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert({inst, 1}, __MODULE__.changeset(
      %__MODULE__{}, %{
        user_id: from,
        order_id: from_order,
        instrument: inst |> to_string(),
        amount: amount |> Decimal.minus()
      })
    )
    |> Ecto.Multi.insert({inst, 2}, __MODULE__.changeset(
      %__MODULE__{}, %{
        user_id: to,
        order_id: to_order,
        instrument: inst |> to_string(),
        amount: amount
      })
    )
  end
end
