defmodule Pokerwars.Player do
  defstruct hash: nil, name: '', hand: [], stack: 0
  alias Pokerwars.Player

  def create(name, stack \\ 0) do

    hash = hash_id()

    %Player{hash: hash, name: name, stack: stack}
  end

  def clear_hand(%Player{} = player) do
    %{player | hand: []}
  end

  def add_card_to_hand(%Player{hand: hand} = player, card) do
    %{player | hand: hand ++ [card]}
  end

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

end
