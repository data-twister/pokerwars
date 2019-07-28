defmodule Pokerwars.Status do
  alias Pokerwars.Game
  alias Pokerwars.Status

  require Logger

  def next(
        %Game{
          hash: hash,
          players: players,
          status: :waiting_for_players,
          round: round,
          deck: deck,
          bet: bet,
          pot: pot,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          board: board,
          current_player: current_player,
          winner: winner,
          available_actions: available_actions
        } = game
      )
      when length(players) == min_players do
    {:ok, %{game | status: :ready_to_start, round: :ready_to_start}}
  end

  def next(game), do: {:ok, game}

  def waiting_for_players(
        {:join, player},
        %Game{
          hash: hash,
          players: players,
          status: status,
          round: round,
          deck: deck,
          bet: bet,
          pot: pot,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          board: board,
          current_player: current_player,
          winner: winner,
          available_actions: available_actions
        } = game
      )
      when length(players) < max_players do
    case Enum.member?([:waiting_for_players, :ready_to_start], status) &&
           player.stack > game.rules.big_blind do
      # Logger.info(player.name <> " has joined the game")
      true ->
        # IO.puts(player.name <> " has joined the game")
        {:ok, %{game | players: game.players ++ [player]}}

      false ->
        # IO.puts(player.name <> " does not have enough chips to join the game")
        {:ok, game}
    end
  end

  def waiting_for_players(_, game), do: {:invalid_action, game}
end
