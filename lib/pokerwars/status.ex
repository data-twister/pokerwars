defmodule Pokerwars.Status do
    alias Pokerwars.Game
    alias Pokerwars.Status

    require Logger

    def next_status(%Game{status: :waiting_for_players, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
    when length(players) == min_players do
       {:ok, %{game | status: :ready_to_start, round: :ready_to_start}}
     end
   
     def next_status(game), do: {:ok, game}


  def waiting_for_players({:join, player}, %{players: players, status: status, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  when length(players) < max_players  do
    
case Enum.member?([:waiting_for_players, :ready_to_start],status) && player.stack > game.rules.big_blind do
  true ->  #Logger.info(player.name <> " has joined the game")
  IO.puts player.name <> " has joined the game" 
  {:ok, %{game | players: game.players ++ [player]}}
  false -> 
    IO.puts(player.name <> " does not have enough chips to join the game")
    {:ok, game}
end
 end
   
  def waiting_for_players(_, game), do: {:invalid_action, game}


end