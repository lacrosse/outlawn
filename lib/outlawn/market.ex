# Manages market books, one per instrument.
defmodule Outlawn.Market do
  require Logger
  use GenServer

  # Client

  def start_link(), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def find_book(inst), do: GenServer.call(__MODULE__, {:find_book, inst})
  def create_book(inst), do: GenServer.call(__MODULE__, {:create_book, inst})

  # Server

  def init(:ok) do
    {:ok, {%{}, %{}}}
  end

  def handle_call({:find_book, inst}, _from, {books, _} = state) do
    {:reply, books |> Map.fetch(inst), state}
  end

  def handle_call({:create_book, inst}, _from, {books, _} = state) do
    {val, new_state} =
      case Map.fetch(books, inst) do
        {:ok, book} -> {book, state}
        :error -> state |> do_create_book(inst)
      end

    {:reply, {:ok, val}, new_state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {books, refs}) do
    {inst, new_refs} =
      refs
      |> Map.pop(ref)
    {book, new_books} =
      books
      |> Map.pop(inst)

    log_error("#{inspect inst} (#{inspect book}) died!")

    {_, state} = do_create_book({new_books, new_refs}, inst)

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  defp do_create_book({books, refs}, inst) do
    {:ok, book} =
      inst
      |> Outlawn.Market.BookSupervisor.create_book()

    log_info("#{inspect inst} (#{inspect book}) created")

    ref =
      book
      |> Process.monitor()
    new_books =
      books
      |> Map.put(inst, book)
    new_refs =
      refs
      |> Map.put(ref, inst)

    {book, {new_books, new_refs}}
  end

  defp log_info(string), do: Logger.info("[Outlawn.Market] " <> string)
  defp log_error(string), do: Logger.error("[Outlawn.Market] " <> string)
end
