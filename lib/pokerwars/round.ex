defmodule Pokerwars.Round do
    alias Pokerwars.Game
    alias Pokerwars.Deck
    alias Pokerwars.Round
    alias Pokerwars.Ranker
    
    @rounds [:pre_flop, :flop, :turn, :river, :showdown]

    defstruct round: :pre_flop

    defp next?(game) do
        ## check that all players have met the big blind and have checked, or limit chk
        IO.puts "checking if we have any open bets before switching to the next round"
       amounts = Enum.map(game.players, fn(x) ->
        x.amount
       end
       )
       bets = Enum.reject(amounts, fn(x) -> x == game.bet end)
        case Enum.count(bets) < 1 and game.current_player == Enum.count(game.players) - 1 do
          true ->  next(game)
          false -> {:ok, game }
        end
      end
    
      defp next(%Game{status: :running, round: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
      do
        deck = Deck.shuffle(game.deck)
        {result, deck} = Deck.take(deck, 3, true)
    
        {:ok, %{game | status: :running, round: :flop, current_player: 0, board: result, deck: deck}}
      end
    
      defp next(%Game{status: :running, round: :flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
      do
        {card, deck} = Deck.deal(game.deck, true)
    
        stay_amt = game.rules.big_blind
    
        {:ok, %{game | bet: stay_amt,  status: :running, round: :turn, current_player: 0, board: [card] ++ board, deck: deck}}
      end
    
      defp next(%Game{status: :running, round: :turn, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
      do
        {card, deck} = Deck.deal(game.deck, true)
        hole = [card] ++ board  
    
        stay_amt = game.rules.big_blind
    
        {:ok, %{game | bet: stay_amt,  round: :river, current_player: 0, board: hole, deck: deck}}
      end
    
      defp next(%Game{status: :running, round: :river, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
      do
    
        
        {:ok, %{game |   current_player: 0, round: :showdown }}
      end
    
      defp next(%Game{status: :running, round: :showdown, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
      do
    
        winner = Ranker.decide_winners(players)
        
        {:ok, %{game |  winner: winner , round: :game_over, status: :game_over }}
      end
end