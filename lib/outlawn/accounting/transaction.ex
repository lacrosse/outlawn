defmodule Outlawn.Accounting.Transaction do
  def create(_book_id, price, amount, _maker, _taker) do
    id = Ecto.UUID.generate()
    {id, price, amount}
  end
end
