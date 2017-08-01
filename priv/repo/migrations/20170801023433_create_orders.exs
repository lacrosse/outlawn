defmodule Outlawn.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :to, :string
      add :from, :string
      add :price, :decimal
      add :amount, :decimal
      add :trader_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:orders, [:trader_id])
  end
end
