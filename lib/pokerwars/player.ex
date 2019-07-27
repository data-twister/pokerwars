defmodule Pokerwars.Player do
  defstruct hash: nil, name: '', hand: [], stack: 0, amount: 0, action: nil
  alias Pokerwars.Player
  require Logger

  def create(name, stack \\ 0) do
    hash = hash_id()
    IO.puts("player " <> hash <> " was created ")
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
    IO.puts(player.name <> "s hand cleared")
    %{player | hand: []}
  end

  def add_card_to_hand(%Player{hand: hand} = player, card) do
    IO.puts(to_string(card.rank) <> " was added to " <> player.name <> "s hand")
    %{player | hand: hand ++ [card]}
  end

  def find(%Player{} = player, game) do
    IO.puts(" searching for player hash: " <> player.hash)
    Enum.find(game.players, fn x -> x.hash == player.hash end)
  end

  def find(hash, game) do
    IO.puts(" searching for player hash: " <> hash)
    Enum.find(game.players, fn x -> x.hash == hash end)
  end

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

  def can_bet?(%Player{} = player, game, amount) do
    case player.stack > game.bet and amount > game.bet - 1 and amount < player.stack do
      true -> true
      false -> false
    end
  end

  defp current?(p, game) do
    index = Enum.find_index(game.players, fn x -> x.hash == p.hash end)

    index == game.current_player
  end

  defp current(game) do
    Enum.at(game.players, game.current_player)
  end
end
