defmodule Outlawn.Repo.Migrations.CreateIndexOnUsersUsername do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    create index(:users, ["lower(username)"], unique: true)
  end
end
