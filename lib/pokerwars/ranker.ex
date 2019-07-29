defmodule Pokerwars.Ranker do
  alias Pokerwars.Helpers
  alias Pokerwars.Player

  def decide_winners(hands) do
    Helpers.maxes_by(hands, &calculate_numeric_score/1)
  end

  def calculate_numeric_score(hand) do
    score = Pokerwars.Hand.score(hand)

    score.value +
      tie_breaking_modifier(score.tie_breaking_ranks)
  end

  defp tie_breaking_modifier(ranks) do
    _tie_breaking_modifier(ranks, 1, 0)
  end

  defp _tie_breaking_modifier([], _, result), do: result

  defp _tie_breaking_modifier([rank | others], index, result) do
    result = result + rank * :math.pow(100, index * -1)
    _tie_breaking_modifier(others, index + 1, result)
  end

  def check_for_winner(game) do
    players = game.players

    counted = Enum.count(players)

    game =
      case counted < 2 do
        true ->
          [winner] = players
          IO.puts(winner.name <> " is the winner")
          %{game | status: :game_over, round: :game_over, winner: winner}

        false ->
            scores = Enum.map(game.players, fn(x) -> 
           {Player.score(x), x}
          end) 
          
          {_, winner } = List.first(scores)
          IO.puts(winner.name <> " is the winner")
          %{game | status: :game_over, round: :game_over, winner: winner}

      end

    {:ok, game}
  end
end
