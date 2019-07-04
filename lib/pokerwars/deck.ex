defmodule Pokerwars.Deck do
  defstruct cards: []

  alias Pokerwars.Card

  def in_order do
    cards =
      for suit <- Card.suits, rank <- Card.ranks do
        %Card{suit: suit, rank: rank}
      end

    %__MODULE__{cards: cards}
  end

  def from_cards(cards) do
    %__MODULE__{cards: cards}
  end


  def size(%__MODULE__{cards: cards}) do
    length(cards)
  end

  def take(%__MODULE__{cards: cards} = deck, num, burn? \\ false) when length(cards) >= num  do
    cards = case burn? do
      true -> case  length(cards) >= num + 1 do
        true -> tl(cards)
        false -> {:error, deck}
      end 
      false -> cards
      end
     
    {result, new_cards} = Enum.split(cards, num)
    {result, %{deck | cards: new_cards}}
  end
  def take(deck, _num), do: {:error, deck}

  def shuffle(%__MODULE__{cards: cards} = deck, shuffle_fun \\ &Enum.shuffle/1) do
    %{deck | cards: shuffle_fun.(cards)}
  end


  def deal(%__MODULE__{} = deck) do
    case take(deck, 1, true) do
      {:error, _} -> {:error, deck}
      {[card], new_deck} -> {card, new_deck}
    end
  end


end
