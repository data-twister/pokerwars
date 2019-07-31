defmodule Pokerwars.Player do
  require Logger
  alias Pokerwars.{Player, Card, Ranker}

  defstruct hash: nil, name: '', hand: [], stack: 0, amount: 0, action: nil

  def create(name, stack \\ 0) do
    hash = hash_id()
    %Player{hash: hash, name: name, stack: stack, amount: 0}
  end

  def bet(%Player{} = player, amount) do
    case player.stack > amount do
      true ->
        IO.puts(player.name <> "s bet for " <> to_string(amount) <> " was submitted ")
        %{player | amount: amount}

      false ->
        %{player | amount: 0}
    end
  end

  def clear_hand(%Player{} = player) do
    %{player | hand: []}
  end

  def add_card_to_hand(%Player{hand: hand} = player, card) do
    %{player | hand: hand ++ [card]}
  end

  def find(%Player{} = player, game) do
    Enum.find(game.players, fn x -> x.hash == player.hash end)
  end

  def find(hash, game) do
    Enum.find(game.players, fn x -> x.hash == hash end)
  end

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

  def can_bet?(%Player{} = player, game, amount) do
    case amount < player.stack do
      true -> true
      false -> false
    end
  end

  def current?(p, game) do
    index = Enum.find_index(game.players, fn x -> x.hash == p.hash end)

    index == game.current_player
  end

  def current(game) do
    Enum.at(game.players, game.current_player)
  end

  def reset(%Player{} = player) do
    %{player | amount: 0, action: nil}
  end

  def score(%Player{} = player) do
    Ranker.calculate_numeric_score(player.hand)
  end
end
