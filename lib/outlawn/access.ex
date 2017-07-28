defmodule Outlawn.Access do
  alias Outlawn.User

  @algorithm Application.fetch_env!(:outlawn, __MODULE__)[:algorithm]
  @jwk Application.fetch_env!(:outlawn, __MODULE__)[:jwk]

  def issue_token(%User{id: u_id}, :full) do
    with body = %{u_id: u_id, perms: "full"},
         {_, token} = @jwk |> JOSE.JWT.sign(body) |> JOSE.JWS.compact(),
         do: token
  end

  def verify_token(token) when is_binary(token) do
    case @jwk |> JOSE.JWT.verify_strict([@algorithm], token) do
      {true, %JOSE.JWT{fields: fields}, _} ->
        %{"u_id" => u_id, "perms" => perms} = fields
        {:ok, {u_id, perms}}
      {false, _, _} ->
        :error
    end
  end
end
