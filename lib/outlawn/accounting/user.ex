defmodule Outlawn.Accounting.User do
  import Ecto.Query

  alias Outlawn.Repo

  def balance(user, inst), do: balance_query(user, inst) |> Repo.one()

  defp balance_query(user, inst) when is_atom(inst), do: balance_query(user, inst |> to_string())
  defp balance_query(%Outlawn.User{id: uid}, inst) when is_binary(inst) do
    from t in Outlawn.Accounting.Transaction,
      where: t.user_id == ^uid and t.instrument == ^inst,
      select: fragment("coalesce(?, 0)", sum(t.amount))
  end
end
