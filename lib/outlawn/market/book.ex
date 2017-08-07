# Contains a single instrument: bids and asks, history, matching.
defmodule Outlawn.Market.Book do
  use GenServer, restart: :temporary

  alias Outlawn.{Market, Accounting}

  def start_link(inst) do
    GenServer.start_link(__MODULE__, %{inst: inst, asks: [], bids: []})
  end

  def orders_by_trader(book, trader), do: book |> GenServer.call({:orders_by_trader, trader})

  def asks(book), do: book |> GenServer.call(:asks)
  def bids(book), do: book |> GenServer.call(:bids)

  def lowest_ask(book), do: book |> GenServer.call(:lowest_ask)
  def highest_bid(book), do: book |> GenServer.call(:highest_bid)
  def place_order(book, order), do: book |> GenServer.call({:place_order, order})
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

  def handle_call({:place_order, order}, _from, state) do
    case match_and_queue_order(state, order) do
      {:ok, remaining_order, txns, new_state} ->
        {:reply, {:ok, remaining_order, txns}, new_state} |> IO.inspect
      :error ->
        {:reply, :error, state}
    end
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

  defp match_and_queue_order(
    %{inst: {to_inst, from_inst} = book_id, asks: asks, bids: bids} = state,
    {price, amount, trader}
  ) do
    asks_tuple = {:asks, asks}
    bids_tuple = {:bids, bids}

    {{to_take_symbol, to_take}, {to_make_symbol, to_make}} =
      cond do
        amount > 0 ->
          {asks_tuple, bids_tuple}
        amount < 0 ->
          {bids_tuple, asks_tuple}
      end

    order_changeset =
      %Market.Order{}
      |> Market.Order.changeset(trader, %{
        to: to_inst |> to_string(),
        from: from_inst |> to_string(),
        price: price,
        amount: amount
      })

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:order, order_changeset)
      |> Ecto.Multi.run(:book_order, fn %{order: order_record} ->
        order_with_id = {order_record.id, price, amount, trader}
        {:ok, order_with_id}
      end)
      |> Ecto.Multi.run(:taken_tuple, fn %{book_order: book_order} ->
        case match_order(book_id, to_take, book_order) do
          {:ok, market, order, txns} ->
            {:ok, {market, order, txns}}
          :error ->
            {:error, book_order}
        end
      end)
      |> Ecto.Multi.run(:made, fn %{taken_tuple: {_, remaining_order, _}} ->
        made = to_make |> queue_order(remaining_order)
        {:ok, made}
      end)

    case multi |> Outlawn.Repo.transaction() do
      {:ok, %{taken_tuple: taken_tuple, made: made}} ->
        {taken, remaining_order, txns} = taken_tuple

        new_state =
          state
          |> Map.merge(%{to_take_symbol => taken, to_make_symbol => made})

        {:ok, remaining_order, txns, new_state}
      {:error, _key, _changeset, _them_changes} ->
        :error
    end
  end

  defp match_order(list, book_id, order, txn_trails \\ [])
  defp match_order(_, [], order, txn_trails), do: {:ok, [], order, txn_trails}
  defp match_order(_, list, {_, _, 0, _}, txn_trails), do: {:ok, list, nil, txn_trails}
  defp match_order(
    {other_inst, base_inst} = book_id,
    [{m_id, m_price, m_amount, m_trader}|m_tail] = market,
    {t_id, t_price, t_amount, t_trader} = t_order,
    txn_trails
  ) do
    action = sign(t_amount)

    case Decimal.compare(t_price, m_price).sign * action do
      -1 ->
        {:ok, market, t_order, txn_trails}
      _ ->
        surplus = t_amount + m_amount
        t_remainder = {t_id, t_price, surplus, t_trader}
        m_remainder = {m_id, m_price, surplus, m_trader}

        dec_m_amount = Decimal.new(m_amount)
        dec_base_amount = dec_m_amount |> Decimal.mult(m_price)
        txns_result =
          Ecto.Multi.append(
            Accounting.Transaction.double_entry_multi(other_inst, dec_m_amount, {t_trader, t_id}, {m_trader, m_id}),
            Accounting.Transaction.double_entry_multi(base_inst, dec_base_amount, {m_trader, m_id}, {t_trader, t_id})
          )
          |> Outlawn.Repo.transaction()

        case sign(surplus * action) do
          0 ->
            case txns_result do
              {:ok, _} ->
                {:ok, m_tail, t_remainder, [{m_price, m_amount}|txn_trails]}
              {:error, _, _, _} ->
                :error
            end
          -1 ->
            case txns_result do
              {:ok, _} ->
                {:ok, [m_remainder|m_tail], nil, [{m_price, t_amount}|txn_trails]}
              {:error, _, _, _} ->
                :error
            end
          1 ->
            case txns_result do
              {:ok, _} ->
                match_order(book_id, m_tail, t_remainder, [{m_price, m_amount}|txn_trails])
              {:error, _, _, _} ->
                :error
            end
        end
    end
  end

  defp queue_order(market, order) do
    {lead, tail} = queue_order(market, order, [])
    Enum.reduce(lead, tail, &[&1|&2])
  end
  defp queue_order(market, nil, lead), do: {lead, market}
  defp queue_order([], order, lead), do: {lead, [order]}
  defp queue_order([{_, m_price, _, _} = m_order|m_tail] = market, {_, t_price, t_amount, _} = t_order, lead) do
    action = sign(t_amount)

    case Decimal.compare(t_price, m_price).sign * action do
      1 ->
        {lead, [t_order|market]}
      _ ->
        queue_order(m_tail, t_order, [m_order|lead])
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

  defp first_or_none([item|_]), do: item
  defp first_or_none(_), do: :none

  defp filter_by_trader(list, trader), do: Enum.filter(list, fn {_, _, _, t} -> t == trader end)

  @compile {:inline, sign: 1}
  defp sign(0), do: 0
  defp sign(n) when n > 0, do: 1
  defp sign(n) when n < 0, do: -1
end
