defmodule Outlawn.RecordFactory do
  alias Outlawn.{User, Repo}

  def create_record(User, attrs) do
    attrs =
      %{password: "findherfiner", password_confirmation: "findherfiner"}
      |> Map.merge(attrs)

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end
end
