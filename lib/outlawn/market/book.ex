# Contains a single instrument: bids and asks, history, matching.
defmodule Outlawn.Market.Book do
  use GenServer, restart: :temporary

  def start_link(inst) do
    GenServer.start_link(__MODULE__, %{inst: inst, asks: [], bids: []})
  end

  def asks(book), do: book |> GenServer.call(:asks)
  def bids(book), do: book |> GenServer.call(:bids)

  def lowest_ask(book) do
    book |> GenServer.call(:lowest_ask)
  end

  def highest_bid(book) do
    book |> GenServer.call(:highest_bid)
  end

  def place_order(book, trader, action, lot) do
    book |> GenServer.call({:place_order, trader, action, lot})
  end

  # Server

  def init(state), do: {:ok, state}

  def handle_call(:asks, _from, %{asks: a} = s), do: {:reply, a, s}
  def handle_call(:bids, _from, %{bids: b} = s), do: {:reply, b, s}
  def handle_call(:lowest_ask, _from, %{asks: a} = s), do: {:reply, first_or_none(a), s}
  def handle_call(:highest_bid, _from, %{bids: b} = s), do: {:reply, first_or_none(b), s}
  def handle_call({:place_order, trader, action, lot}, _from, state) do
    {executed_orders, new_state} =
      state
      |> match_and_queue_order(trader, action, lot)

    {:reply, {:ok, executed_orders}, new_state}
  end

  defp match_and_queue_order(%{asks: asks, bids: bids} = state, trader, action, {price, amount}) do
    asks_tuple = {:asks, asks}
    bids_tuple = {:bids, bids}

    {{to_take_symbol, to_take}, {to_make_symbol, to_make}} =
      case action do
        :buy -> {asks_tuple, bids_tuple}
        :sell -> {bids_tuple, asks_tuple}
      end

    {taken, remaining_order, executed} =
      to_take
      |> match_order(action, {price, amount, trader})
    made =
      to_make
      |> queue_order(action, remaining_order)
    new_state =
      state
      |> Map.merge(%{to_take_symbol => taken, to_make_symbol => made})

    {executed, new_state}
  end

  defp match_order(list, action, order, executed \\ [])
  defp match_order([], _, order, executed), do: {[], order, executed}
  defp match_order(list, _, {_, 0, _}, executed), do: {list, nil, executed}
  defp match_order(
    [{market_price, market_amount, market_trader}|market_tail] = market,
    action,
    {taker_price, taker_amount, taker_trader} = taker_order,
    executed
  ) do
    comparison_symbol = action_to_take_comparison(action)

    case Decimal.cmp(market_price, taker_price) do
      ^comparison_symbol ->
        {market, taker_order, executed}
      _ ->
        cond do
          market_amount == taker_amount ->
            transaction = {market_price, market_amount, market_trader}
            {market_tail, nil, [transaction|executed]}
          market_amount > taker_amount ->
            transaction = {market_price, taker_amount, market_trader}
            market_order_remainder = {market_price, market_amount - taker_amount, market_trader}
            {[market_order_remainder|market_tail], nil, [transaction|executed]}
          market_amount < taker_amount ->
            transaction = {market_price, market_amount, market_trader}
            taker_order_remainder = {taker_price, taker_amount - market_amount, taker_trader}
            match_order(market_tail, action, taker_order_remainder, [transaction|executed])
        end
    end
  end

  defp queue_order(market, action, order) do
    {lead, tail} = queue_order(market, action, order, [])
    Enum.reduce(lead, tail, fn x, acc -> [x|acc] end)
  end
  defp queue_order(market, _, nil, lead), do: {lead, market}
  defp queue_order([], _, order, lead) do
    {lead, [order]}
  end
  defp queue_order([{m_price, _, _} = m_order|tail] = market, action, {t_price, _, _} = t_order, lead) do
    comparison_symbol = action_to_make_comparison(action)

    case Decimal.cmp(m_price, t_price) do
      ^comparison_symbol ->
        {lead, [t_order|market]}
      _ ->
        queue_order(tail, :buy, t_order, [m_order|lead])
    end
  end

  defp action_to_take_comparison(:buy), do: :gt
  defp action_to_take_comparison(:sell), do: :lt

  defp action_to_make_comparison(:buy), do: :lt
  defp action_to_make_comparison(:sell), do: :gt

  defp first_or_none([item|_]), do: item
  defp first_or_none(_), do: :none
end
