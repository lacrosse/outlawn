defmodule Outlawn.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :amount, :decimal
      add :instrument, :string
      add :order_id, references(:orders, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :integer)

      timestamps(updated_at: false)
    end

    create index(:transactions, [:order_id])
    create index(:transactions, [:user_id])
  end
end
