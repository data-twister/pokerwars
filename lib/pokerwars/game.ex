defmodule Pokerwars.Game do

  alias Pokerwars.Game.TexasHoldem

  def create do
    TexasHoldem.create
  end

  def create(deck) do
    TexasHoldem.create(deck)
  end


  def apply_action(game, action) do
    TexasHoldem.apply_action(game, action)
  end

 defimpl String.Chars, for: Pokerwars.Game do
  def to_string(game) do
    deck = game.current_deck || %Pokerwars.Deck{}
    card_count = length(deck.cards)
    player_count = length(game.players)

     Enum.join [
      "%Pokerwars.Game{\n",
      "  status: #{game.status}\n",
      "  current_deck: #{card_count}\n",
      "  players: #{player_count}\n",
      "}"
    ]
  end
end

end
