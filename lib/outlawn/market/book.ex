# Contains a single instrument: bids and asks, history, matching.
defmodule Outlawn.Market.Book do
  use GenServer, restart: :temporary

  alias Outlawn.Accounting

  def start_link(inst) do
    GenServer.start_link(__MODULE__, %{inst: inst, asks: [], bids: []})
  end

  def orders_by_trader(book, trader), do: book |> GenServer.call({:orders_by_trader, trader})

  def asks(book), do: book |> GenServer.call(:asks)
  def bids(book), do: book |> GenServer.call(:bids)

  def lowest_ask(book), do: book |> GenServer.call(:lowest_ask)
  def highest_bid(book), do: book |> GenServer.call(:highest_bid)
  def place_order(book, action, order), do: book |> GenServer.call({:place_order, action, order})
  def delete_order(book, order_id, trader), do: book |> GenServer.call({:delete_order, order_id, trader})

  # Server

  def init(state), do: {:ok, state}

  def handle_call({:orders_by_trader, trader}, _from, %{asks: a, bids: b} = s) do
    orders = %{
      asks: a |> filter_by_trader(trader),
      bids: b |> filter_by_trader(trader)
    }

    {:reply, orders, s}
  end
  def handle_call(:asks, _from, %{asks: a} = s), do: {:reply, a, s}
  def handle_call(:bids, _from, %{bids: b} = s), do: {:reply, b, s}
  def handle_call(:lowest_ask, _from, %{asks: a} = s), do: {:reply, first_or_none(a), s}
  def handle_call(:highest_bid, _from, %{bids: b} = s), do: {:reply, first_or_none(b), s}
  def handle_call({:place_order, action, order}, _from, state) do
    {remaining_order, txns, new_state} = match_and_queue_order(state, action, order)

    {:reply, {:ok, remaining_order, txns}, new_state}
  end
  def handle_call({:delete_order, order_id, trader}, _from, %{asks: asks, bids: bids} = state) do
    {val, new_state} =
      case asks |> dequeue_order(order_id, trader) do
        :none ->
          case bids |> dequeue_order(order_id, trader) do
            :none ->
              {:error, state}
            :halt ->
              {:error, state}
            {order, new_bids} ->
              {{:ok, order}, %{state | bids: new_bids}}
          end
        :halt ->
          {:error, state}
        {order, new_asks} ->
          {{:ok, order}, %{state | asks: new_asks}}
      end

    {:reply, val, new_state}
  end

  defp match_and_queue_order(%{inst: book_id, asks: asks, bids: bids} = state, action, {price, amount, trader}) do
    asks_tuple = {:asks, asks}
    bids_tuple = {:bids, bids}

    {{to_take_symbol, to_take}, {to_make_symbol, to_make}} =
      case action do
        :buy -> {asks_tuple, bids_tuple}
        :sell -> {bids_tuple, asks_tuple}
      end

    id = Ecto.UUID.generate()

    order_with_id =
      {id, price, amount, trader}

    {taken, remaining_order, txns} =
      to_take
      |> match_order(book_id, action, order_with_id)
    made =
      to_make
      |> queue_order(action, remaining_order)
    new_state =
      state
      |> Map.merge(%{to_take_symbol => taken, to_make_symbol => made})

    {remaining_order, txns, new_state}
  end

  defp match_order(list, book_id, action, order, txns \\ [])
  defp match_order([], _, _, order, txns), do: {[], order, txns}
  defp match_order(list, _, _, {_, _, 0, _}, txns), do: {list, nil, txns}
  defp match_order(
    [{m_id, m_price, m_amount, m_trader}|m_tail] = market,
    book_id,
    action,
    {t_id, t_price, t_amount, t_trader} = t_order,
    txns
  ) do
    comparison_symbol = action_to_take_comparison(action)

    case Decimal.cmp(m_price, t_price) do
      ^comparison_symbol ->
        {market, t_order, txns}
      _ ->
        cond do
          m_amount == t_amount ->
            txn = Accounting.Transaction.create(book_id, m_price, m_amount, m_trader, t_trader)
            {m_tail, nil, [txn|txns]}
          m_amount > t_amount ->
            txn = Accounting.Transaction.create(book_id, m_price, t_amount, m_trader, t_trader)
            market_order_remainder = {m_id, m_price, m_amount - t_amount, m_trader}
            {[market_order_remainder|m_tail], nil, [txn|txns]}
          m_amount < t_amount ->
            txn = Accounting.Transaction.create(book_id, m_price, m_amount, m_trader, t_trader)
            taker_order_remainder = {t_id, t_price, t_amount - m_amount, t_trader}
            match_order(m_tail, book_id, action, taker_order_remainder, [txn|txns])
        end
    end
  end

  defp queue_order(market, action, order) do
    {lead, tail} = queue_order(market, action, order, [])
    Enum.reduce(lead, tail, &[&1|&2])
  end
  defp queue_order(market, _, nil, lead), do: {lead, market}
  defp queue_order([], _, order, lead), do: {lead, [order]}
  defp queue_order([{_, m_price, _, _} = m_order|m_tail] = market, action, {_, t_price, _, _} = t_order, lead) do
    comparison_symbol = action_to_make_comparison(action)

    case Decimal.cmp(m_price, t_price) do
      ^comparison_symbol ->
        {lead, [t_order|market]}
      _ ->
        queue_order(m_tail, :buy, t_order, [m_order|lead])
    end
  end

  defp dequeue_order(market, order_id, trader) do
    case dequeue_order(market, order_id, trader, []) do
      {order, lead, tail} ->
        {order, Enum.reduce(lead, tail, &[&1|&2])}
      other ->
        other
    end
  end
  defp dequeue_order([], _, _, _), do: :none
  defp dequeue_order([{o_id, _, _, trader} = order|m_tail], o_id, trader, lead), do: {order, lead, m_tail}
  defp dequeue_order([{o_id, _, _, _}|_], o_id, _, _), do: :halt
  defp dequeue_order([m_order|m_tail], o_id, trader, lead), do: dequeue_order(m_tail, o_id, trader, [m_order|lead])

  defp action_to_take_comparison(:buy), do: :gt
  defp action_to_take_comparison(:sell), do: :lt

  defp action_to_make_comparison(:buy), do: :lt
  defp action_to_make_comparison(:sell), do: :gt

  defp first_or_none([item|_]), do: item
  defp first_or_none(_), do: :none

  defp filter_by_trader(list, trader), do: Enum.filter(list, fn {_, _, _, t} -> t == trader end)
end
