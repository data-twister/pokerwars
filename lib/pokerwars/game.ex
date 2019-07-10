defmodule Pokerwars.Game do
  alias Pokerwars.{Deck, Player}

  require Logger


  defstruct  hash: nil, players: [], status: :waiting_for_players, phase: :waiting_for_players, current_deck: nil, original_deck: nil, bet: 0, pot: 0, rules: %{small_blind: 10, big_blind: 20, min_players: 2, max_players: 10}, hole_cards: [], current_player: 0

  def create(deck \\ Deck.in_order) do
    hash = hash_id()
    %__MODULE__{ original_deck: deck, hash: hash }
  end

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

  def apply_action(game, action) do
    phase(game.phase, game, action)
  end

  defp phase(:waiting_for_players, game, action) do
    with {:ok, game} <- waiting_for_players(action, game),
         {:ok, game} <- next_status(game)
    do
      {:ok, game}
    else
      err -> err
    end
  end

  defp phase(:ready_to_start, game, action) do
    game_action(action, game)
  end

  defp phase(:game_over, game, action) do
    game_action(action, game)
  end

  defp phase(:pre_flop, game, action) do
    game_action(action, game)
  end

  defp phase(:flop, game, action) do
    game_action(action, game)
  end

  defp phase(:turn, game, action) do
    game_action(action, game)
  end

  defp phase(:river, game, action) do
    game_action(action, game)
  end

  defp next_status(%__MODULE__{status: :waiting_for_players, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
 when length(players) == min_players do
    {:ok, %{game | status: :ready_to_start, phase: :ready_to_start}}
  end
  defp next_phase(%__MODULE__{status: :running, phase: :pre_flop, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  do
    deck = Deck.shuffle(game.original_deck)
    {result, deck} = Deck.take(deck, 3, true)

    {:ok, %{game | bet: 0,  status: :running, phase: :flop, current_player: 0, hole_cards: result, current_deck: deck}}
  end
  defp next_phase(%__MODULE__{status: :running, phase: :flop, players: players, hole_cards: hole_cards, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  do
    {card, deck} = Deck.deal(game.current_deck, true)

    {:ok, %{game | bet: 0,  status: :running, phase: :turn, current_player: 0, hole_cards: [card] ++ hole_cards, current_deck: deck}}
  end
  defp next_phase(%__MODULE__{status: :running, phase: :turn, players: players, hole_cards: hole_cards, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  do
    {card, deck} = Deck.deal(game.current_deck, true)
    hole = [card] ++ hole_cards  
    new_cards = deck

    {:ok, %{game | bet: 0,  phase: :river, current_player: 0, hole_cards: hole, current_deck: deck}}
  end
  defp next_phase(%__MODULE__{status: :running, phase: :river, players: players, hole_cards: hole_cards, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  do

    
    {:ok, %{game |  status: :game_over, phase: :game_over }}
  end
  defp next_phase(%__MODULE__{status: :game_over, phase: :game_over, players: players, hole_cards: hole_cards, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  do

    winner = Ranker.decide_winners(players)
    
    {:ok, %{game |  winner: winner }}
  end

  defp next_status(game), do: {:ok, game}

  defp waiting_for_players({:join, player}, %{players: players, status: status, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  when length(players) < max_players  do
case Enum.member?([:waiting_for_players, :ready_to_start],status) do
  true ->  Logger.info(player.name <> " has joined the game")
  {:ok, %{game | players: game.players ++ [player]}}
  false -> {:ok, game}
end
 end
   
  defp waiting_for_players(_, game), do: {:invalid_action, game}


  defp game_action({:start_game}, game) do

    game = deal_hands(game)
    game = take_blinds(game)

    game = %{game | status: :running, phase: :pre_flop}

    {:ok, game}
  end

  defp game_action({:join, player}, game) do
    waiting_for_players({:join, player}, game)
    {:ok, game}
  end

  defp game_action({:bet, player, bet}, game) do
    game =  case current_player?(player, game) do
      true-> take_bet(game, {player, bet})
      false -> game
    end

    current_player = game.current_player

    case current_player < Enum.count(game.players) - 1 do
    true ->   %{game | current_player: current_player + 1}
    false -> next_phase(game)
    end
    
    {:ok, game}
  end

  defp game_action({:raise, player, bet}, game) do
    game =  case current_player?(player, game) do
      true-> raised_amt = game.bet + bet
      take_bet(game, {player, raised_amt})
      false -> game
      {:ok, %{game | current_player: current_player + 1}}
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

    case current_player < Enum.count(game.players) -1 do
    true -> 
    case game.bet == 0 do
      true -> {:ok, %{game | current_player: current_player + 1}}
        false ->
          Logger.error("unable to check when there is an open bet, you must bet, raise or fold") 
          {:ok, %{game | current_player: current_player + 1}}
    end
    false -> 
    next_phase(game)
    end

  false -> game
  end
end

  defp game_action({:fold, player}, game) do

    new_players =  Enum.reject(game.players, fn(p) -> p.hash == player.hash end)

    game = case Enum.count(new_players) < 2 do
      true ->   %{game | status: :game_over, phase: :game_over, players: new_players}
      false ->  %{game | players: new_players}
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


    first_player = %{first_player | stack: first_player.stack - rules.small_blind}
    second_player = %{second_player | stack: second_player.stack - rules.big_blind}

    new_players = [first_player, second_player | other_players]

    amount_taken = rules.small_blind + rules.big_blind

    %{game | players: new_players, pot: pot + amount_taken}
  end


  defp take_bet(game, {player, bet}) do
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
        true ->  %{player | stack: p.stack - bet} 
        false -> p
       end
  end)
  false -> game.players
end

  case can_bet? do
    true ->  %{game | pot: pot + bet, bet: bet, players: players}
    false -> %{game | players: players}
  end
   
  end

  defp clear_game(game) do
    players = Enum.map(game.players, &Player.clear_hand/1)
    %{game | current_deck: game.original_deck, players: players}
  end

  defp deal_cards_to_each_player(%{players: players, current_deck: deck} = game) do
    {new_deck, new_players} = deal_cards_from_deck(deck, players)

    %{game | players: new_players, current_deck: new_deck}
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
      deck = game.current_deck || %Pokerwars.Deck{}
      card_count = length(deck.cards)
      player_count = length(game.players)
  
       Enum.join [
        "%Pokerwars.Game{\n",
        "  status: #{game.status}\n",
        "  phase: #{game.phase}\n",
        "  pot: #{game.pot}\n",
        "  current_deck: #{card_count}\n",
        "  players: #{player_count}\n",
        "}"
      ]
    end
end
end
