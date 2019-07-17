defmodule Pokerwars.Player do
  defstruct hash: nil, name: '', hand: [], stack: 0, amount: 0, call: nil
  alias Pokerwars.Player
  require Logger


  def create(name, stack \\ 0) do

    hash = hash_id()
    Logger.info "player " <> hash <> " was created "
    %Player{hash: hash, name: name, stack: stack, amount: 0}
  end

  def bet(%Player{} = player, amount) do

    case  player.stack > amount do
      true ->    Logger.info player.name <> "s bet submitted "
         %{player | amount: amount}
      false ->  %{player | amount: 0}
    end   

  end

  def clear_hand(%Player{} = player) do
    Logger.info player.name <> "s hand cleared"
    %{player | hand: []}
  end

  def add_card_to_hand(%Player{hand: hand} = player, card) do
    Logger.info   "card added to " <> player.name <> "s hand"
    %{player | hand: hand ++ [card]}
  end

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

end
