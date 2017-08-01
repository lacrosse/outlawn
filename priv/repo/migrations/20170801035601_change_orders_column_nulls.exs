defmodule Outlawn.Repo.Migrations.ChangeOrdersColumnNulls do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      modify :price, :decimal, null: false
      modify :amount, :decimal, null: false
    end
  end
end
