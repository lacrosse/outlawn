defmodule Outlawn.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :encrypted_password, :string

    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:username, :password, :password_confirmation])
    |> validate_required([:username, :password, :password_confirmation])
    |> validate_confirmation(:password)
    |> validate_length(:username, min: 4)
    |> validate_length(:password, min: 8)
    |> encrypt_password()
  end

  defp encrypt_password(changeset) do
    encrypted =
      changeset
      |> get_change(:password)
      |> Comeonin.Bcrypt.hashpwsalt()

    changeset
    |> change(encrypted_password: encrypted)
  end
end
