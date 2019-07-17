defmodule Pokerwars.Game do
  alias Pokerwars.{Deck, Player}

  require Logger

  @moduledoc """
  This module represents a game being played
  rules: ante: the min incement amount one must bid per round also known as min raise, limit: the type of game no_limit or limit, button is the dealer, blinds start at players[button] + 1
  """


  defstruct  hash: nil, players: [], status: :waiting_for_players, round: :waiting_for_players, deck: nil, bet: 0, pot: 0, rules: %{small_blind: 10, big_blind: 20, ante: 5, min_players: 2, max_players: 8, limit: nil}, board: [], current_player: 0,  winner: nil, available_actions: [:fold, :bet, :check]

  def new(deck \\ Deck.in_order) do
    hash = hash_id()

    Logger.info "game " <> hash <> " was created "

    %__MODULE__{ deck: deck, hash: hash }
  end

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

  def apply_action(game, action) do
    round(game.round, game, action)
  end

  defp round(:waiting_for_players, game, action) do
    with {:ok, game} <- waiting_for_players(action, game),
         {:ok, game} <- next_status(game)
    do
      {:ok, game}
    else
      err -> err
    end
  end

  defp round(:ready_to_start, game, action) do
    game_action(action, game)
  end

  defp round(:pre_flop, game, action) do
    game_action(action, game)
  end

  defp round(:flop, game, action) do
    game_action(action, game)
  end

  defp round(:turn, game, action) do
    game_action(action, game)
  end

  defp round(:river, game, action) do
    game_action(action, game)
  end

  defp round(:showdown, game, action) do
    game_action(action, game)
  end

  defp round(:game_over, game, action) do
    game_action(action, game)
  end

  defp next_status(%__MODULE__{status: :waiting_for_players, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
 when length(players) == min_players do
    {:ok, %{game | status: :ready_to_start, round: :ready_to_start}}
  end

  defp next_status(game), do: {:ok, game}

  defp next_round(%__MODULE__{status: :running, round: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, ante: ante, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
  do
    deck = Deck.shuffle(game.deck)
    {result, deck} = Deck.take(deck, 3, true)

    stay_amt = game.rules.big_blind

    {:ok, %{game | bet: stay_amt,  status: :running, round: :flop, current_player: 0, board: result, deck: deck}}
  end

  defp next_round(%__MODULE__{status: :running, round: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, ante: ante, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
  do
    {card, deck} = Deck.deal(game.deck, true)

    stay_amt = game.rules.big_blind

    {:ok, %{game | bet: stay_amt,  status: :running, round: :turn, current_player: 0, board: [card] ++ board, deck: deck}}
  end

  defp next_round(%__MODULE__{status: :running, round: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, ante: ante, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
  do
    {card, deck} = Deck.deal(game.deck, true)
    hole = [card] ++ board  

    stay_amt = game.rules.big_blind

    {:ok, %{game | bet: stay_amt,  round: :river, current_player: 0, board: hole, deck: deck}}
  end

  defp next_round(%__MODULE__{status: :running, round: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, ante: ante, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
  do

    stay_amt = game.rules.big_blind
    
    {:ok, %{game |  bet: stay_amt, current_player: 0, round: :showdown }}
  end

  defp next_round(%__MODULE__{status: :running, round: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players, ante: ante, limit: limit}, available_actions: available_actions, bet: bet, board: board, current_player: current_player, deck: deck, hash: hash, pot: pot, winner: winner} = game)
  do

    winner = Ranker.decide_winners(players)
    
    {:ok, %{game |  winner: winner , round: :game_over, status: :game_over }}
  end



  defp waiting_for_players({:join, player}, %{players: players, status: status, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  when length(players) < max_players  do
    
case Enum.member?([:waiting_for_players, :ready_to_start],status) && player.stack > game.rules.big_blind do
  true ->  Logger.info(player.name <> " has joined the game")
  {:ok, %{game | players: game.players ++ [player]}}
  false -> 
    Logger.info(player.name <> " does not have enough chips to join the game")
    {:ok, game}
end
 end
   
  defp waiting_for_players(_, game), do: {:invalid_action, game}


  defp game_action({:start_game}, game) do

    game = deal_hands(game)
    game = take_blinds(game)

    player_count = Enum.count(game.players)

   current_player = case player_count > 2 do
    true -> 2
    false -> 0
    end

    game = %{game | status: :running, round: :pre_flop, current_player: current_player }

    {:ok, game}
  end

  defp game_action({:join, player}, game) do
    waiting_for_players({:join, player}, game)
  end

  defp game_action({:bet, player, amount}, game) do
    game =  case current_player?(player, game) do
      true-> take_bet(game, {player, amount}, :bet)
      false -> game
    end

    current_player = game.current_player

    case current_player < Enum.count(game.players) - 1 do
    true ->  {:ok, %{game | current_player: current_player + 1}}
    false -> next_round(game)
    end

  end

  defp game_action({:raise, player, amount}, game) do
    game =  case current_player?(player, game) do
      true-> raised_amt = game.bet + amount
      take_bet(game, {player, raised_amt}, :raise)
      false -> game
  end
 

  current_player = game.current_player

  case current_player < Enum.count(game.players) - 1 do
  true ->  {:ok, %{game | current_player: current_player + 1}}
  false -> next_round(game)
  end

  end

  defp current_player?(p,game) do

    index = Enum.find_index(game.players, fn x -> x.hash == p.hash end)
 
   index == game.current_player

  end

  defp game_action({:check, player}, game) do

    game =  case current_player?(player, game) do
true->
    current_player = game.current_player

    case current_player < Enum.count(game.players)  do
    true -> 
    case game.bet < player.stack + 1 do
      true -> game = take_bet(game, {player, game.bet}, :check)
        {:ok, %{game | current_player: current_player + 1, available_actions: [:fold, :raise, :check]}}
        false -> Logger.error "Player does not have enough chips"
          {:ok, %{game | current_player: current_player, available_actions: [:fold]}}
    end
    false -> 
      IO.puts "switching rounds"
    next_round(game)
    end

  false -> IO.puts "not the current player"
  {:ok, game }
  end
end

  defp game_action({:fold, player}, game) do

    game =  case current_player?(player, game) do
      true->
         game = case game.current_player > 0 do
           true -> %{game | current_player: game.current_player - 1}
            false -> game
         end

          new_players =  Enum.reject(game.players, fn(p) -> p.hash == player.hash end)

          IO.puts player.name <> " folded"

          game = case Enum.count(new_players) < 2 do
            true ->  [winner] = new_players
             %{game | status: :game_over, round: :game_over, players: new_players, winner: winner}
            false ->  %{game | players: new_players}
          end
          false -> game
          end

    
    {:ok, game}
  end

  defp deal_hands(game) do
    game
    |> clear_game
    |> deal_cards_to_each_player
    |> deal_cards_to_each_player
  end

  defp take_blinds(game) do
    players = game.players
    rules = game.rules
    pot = game.pot

    [ first_player, second_player | other_players ] = players


    first_player = %{first_player | stack: first_player.stack - rules.small_blind, call: :bet, amount: rules.small_blind}
    second_player = %{second_player | stack: second_player.stack - rules.big_blind, call: :bet, amount: rules.big_blind}

    new_players = [first_player, second_player | other_players]

    amount_taken = rules.small_blind + rules.big_blind

    Logger.info "blinds were taken"

    %{game | players: new_players, pot: pot + amount_taken, bet: game.rules.big_blind}
  end


  defp take_bet(game, {player, amount}, call \\ :check) do
    pot = game.pot
    bet? =  Enum.map(game.players, fn(p) ->
      case p.hash == player.hash and player.stack > game.bet do 
       true -> true
       false -> false
      end
    end)

    [can_bet?] = Enum.filter(bet?, fn(x) -> x == true end)

    players =  case can_bet? do
      true ->
    Enum.map(game.players, fn(p) ->
       case p.hash == player.hash and p.stack > game.bet do 
        true ->  %{player | stack: p.stack - amount, amount: amount, call: call, hand: p.hand} 
        false -> p
       end
     end)
      false -> game.players
  end

  case can_bet? do
    true ->   Logger.info "bet was taken"
      %{game | pot: pot + amount, bet: amount, players: players}
    false -> %{game | players: players}
  end
   
  end

  defp clear_game(game) do
    players = Enum.map(game.players, &Player.clear_hand/1)
    deck = Deck.in_order
    %{game | deck: deck, players: players}
  end

  defp deal_cards_to_each_player(%{players: players, deck: deck} = game) do
    {new_deck, new_players} = deal_cards_from_deck(deck, players)

    %{game | players: new_players, deck: new_deck}
  end

  defp deal_card_to_player(deck, player) do
    {card, deck} = Deck.deal(deck)
    player = Player.add_card_to_hand(player, card)
    {deck, player}
  end

  defp deal_cards_from_deck(deck, []) do
    {deck, []}
  end

  defp deal_cards_from_deck(deck, [player | others]) do
    {deck_after_deal, updated_player} = deal_card_to_player(deck, player)
    {updated_deck, updated_others} = deal_cards_from_deck(deck_after_deal, others)

    {updated_deck, [updated_player | updated_others]}
  end

  defimpl String.Chars, for: Pokerwars.Game do
    def to_string(game) do
      deck = game.deck || %Pokerwars.Deck{}
      card_count = length(deck.cards)
      player_count = length(game.players)
      available_actions = Enum.join(game.available_actions, " ")
  
       Enum.join [
        "%Pokerwars.Game{\n",
        "  status: #{game.status}\n",
        "  hash: #{game.hash}\n",
        "  blinds: #{game.rules.small_blind} , #{game.rules.big_blind}\n",
        "  round: #{game.round}\n",
        "  bet: #{game.bet}\n",
        "  pot: #{game.pot}\n",
        "  deck: #{card_count}\n",
        "  players: #{player_count}\n",
        "  winner: #{game.winner}\n",
        "  current_player: #{game.current_player}\n",
        "  available_actions: #{available_actions}\n",
        "}"
      ]
    end
end
end
