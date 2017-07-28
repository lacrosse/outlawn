defmodule Outlawn.Market.BookSupervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def create_book(inst) do
    Supervisor.start_child(__MODULE__, [inst])
  end

  def init(:ok) do
    book_spec =
      Outlawn.Market.Book
      |> Supervisor.child_spec(start: {Outlawn.Market.Book, :start_link, []})
    Supervisor.init([book_spec], strategy: :simple_one_for_one)
  end
end
