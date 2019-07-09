defmodule Pokerwars.Card do
  defstruct suit: nil, 
            rank: nil

    @moduledoc """
    A struct representing the data to hold an individual card as well as helper
    functions for using the cards, such as displaying them.
  """


  # Ranks of numbered cars are represented by the number (2..10)
  # Jack, Queen, King, Ace represented by 11, 12, 13, 14 respectively
  # Suits can be: :hearts, :diamonds, :clubs, :spades



  require Pokerwars.Deck.Constants
  alias Pokerwars.Deck.Constants, as: Conf

  @ranks 2..14 |> Enum.to_list
  @suits [:hearts, :diamonds, :clubs, :spades]

  def ranks, do: @ranks
  def suits, do: @suits

  def print(card) do
    "#{print_face(card)}#{print_suit(card)}"
  end

  def parse(card_string) do
    card_regex = ~r/(.{1,2})([hdsc])/
    [[_,face,suit]] = Regex.scan(card_regex, card_string)
    %Pokerwars.Card{rank: parse_rank(face), suit: parse_suit(suit)}
  end

  defp parse_rank("J"), do: 11
  defp parse_rank("Q"), do: 12
  defp parse_rank("K"), do: 13
  defp parse_rank("A"), do: 14
  defp parse_rank(numeric_face) do
    {rank, _} = Integer.parse(numeric_face)
    rank
  end

  defp parse_suit("h"), do: :hearts
  defp parse_suit("d"), do: :diamonds
  defp parse_suit("s"), do: :spades
  defp parse_suit("c"), do: :clubs

  defp print_face(card) do
    r = card.rank
    cond do
      r in 2..10 -> Integer.to_string(r)
      r == 11 -> 'J'
      r == 12 -> 'Q'
      r == 13 -> 'K'
      r == 14 -> 'A'
    end
  end

  defp print_suit(card) do
    s = card.suit
    case s do
      :hearts -> "h"
      :diamonds -> "d"
      :clubs -> "c"
      :spades -> "s"
    end
  end

  @doc """
    Returns the print representation of a particular card.
    List of all cards:

        A♤ 2♤ 3♤ 4♤ 5♤ 6♤ 7♤ 8♤ 9♤ 10♤ J♤ Q♤ K♤
      A♢ 2♢ 3♢ 4♢ 5♢ 6♢ 7♢ 8♢ 9♢ 10♢ J♢ Q♢ K♢
      A♡ 2♡ 3♡ 4♡ 5♡ 6♡ 7♡ 8♡ 9♡ 10♡ J♡ Q♡ K♡
      A♧ 2♧ 3♧ 4♧ 5♧ 6♧ 7♧ 8♧ 9♧ 10♧ J♧ Q♧ K♧
  """
  def display(%__MODULE__{suit: :spades, rank: rank}) do
    "#{rank |> Atom.to_string |> String.upcase}#{Conf.spade}"
  end
  def display(%__MODULE__{suit: :diamonds, rank: rank}) do
    "#{rank |> Atom.to_string |> String.upcase}#{Conf.diamond}"
  end
  def display(%__MODULE__{suit: :hearts, rank: rank}) do
    "#{rank |> Atom.to_string |> String.upcase}#{Conf.heart}"
  end
  def display(%__MODULE__{suit: :clubs, rank: rank}) do
    "#{rank |> Atom.to_string |> String.upcase}#{Conf.club}"
  end
  def display(%__MODULE__{suit: suit, rank: rank}), do: "Unknown #{rank} of #{suit}"
end
