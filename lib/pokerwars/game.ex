defmodule Pokerwars.Game do
  alias Pokerwars.{Deck, Player}

  require Logger


  defstruct  hash: nil, players: [], original_players: [], status: :waiting_for_players, phase: :waiting_for_players, current_deck: nil, original_deck: nil, bet: 0, pot: 0, rules: %{small_blind: 10, big_blind: 20, min_players: 2, max_players: 10}, type: "texas holdem"

  def create(deck \\ Deck.in_order) do
    hash = "12345test12345"
    %__MODULE__{ original_deck: deck, hash: hash }
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

  defp phase(:game_start, game, action) do
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

  defp phase(:game_over, game, action) do
    game_action(action, game)
  end

  defp next_status(%__MODULE__{status: :waiting_for_players, players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
 when length(players) == min_players do
    {:ok, %{game | status: :ready_to_start}}
  end
  defp next_status(game), do: {:ok, game}

  defp waiting_for_players({:join, player}, %{players: players, rules: %{small_blind: small_blind, big_blind: big_blind,  min_players: min_players, max_players: max_players}} = game)
  when length(players) < max_players and Enum.member?(game.status, [:waiting_for_players, :ready_to_start]) do

       Logger.info(player.name <> " has joined the game")
       {:ok, %{game | players: game.players ++ [player]}}

     end
   
  end
  defp waiting_for_players(_, game), do: {:invalid_action, game}


  defp game_action({:start_game}, game) do

    game = deal_hands(game)

    game = %{game | status: :game_start, phase: :game_start}

    {:ok, game}
  end

  defp game_action({:join, player}, game) do
    waiting_for_players({:join, player}, game)
    {:ok, game}
  end

  defp game_action({:bet, player, bet}, game) do
    game = take_bet(game, {player, bet})
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


  defp take_bet(game, {player, bet} = bet) do
    pot = game.pot
    bet? = false
    
    players = Enum.map(game.players, fn(p) ->
       when p.hash == player.hash and player.stack > game.bet do 
        bet? = true
        %{player | stack: player.stack - bet} 
       end
  end)

  case bet? do
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
end
