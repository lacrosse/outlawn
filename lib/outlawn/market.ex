defmodule Outlawn.Market do
  def find_book(book), do: __MODULE__.BookRegistry.find_book(book)
  def create_book(book), do: __MODULE__.BookRegistry.create_book(book)
end
