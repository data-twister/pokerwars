defmodule Pokerwars.Game do
  alias Pokerwars.{Deck, Player}

  require Logger

@min_players 2
@min_players 10

  defstruct players: [], status: :waiting_for_players, current_deck: nil, original_deck: nil, bet: 0, pot: 0, rules: %{small_blind: 10, big_blind: 20, ante: 0, buy_in: 5, min_players: 2, max_players: 2}, type: "texas holdem"

  def create(deck \\ Deck.in_order) do
    %__MODULE__{ original_deck: deck }
  end

  def apply_action(game, action) do
    phase(game.status, game, action)
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
    ready_to_start(action, game)
  end

  defp next_status(%__MODULE__{status: :waiting_for_players, players: players} = game)
 when length(players) == 2 do
    {:ok, %{game | status: :ready_to_start}}
  end
  defp next_status(game), do: {:ok, game}

  defp waiting_for_players({:join, player}, %{players: players} = game)
  when length(players) < @max_players do

    ## check if player have enough stack for game if not dont let them join
     case player.stack > game.rules.buy_in do
       true ->  Logger.info(player.name <> "  has joined the game")
       {:ok, %{game | players: game.players ++ [player]}}
       false ->  Logger.error(player.name <> "  doesnt have enough stack to join")
       {:ok, %{game | players: game.players}}
     end
   
  end
  defp waiting_for_players(_, game), do: {:invalid_action, game}

  defp ready_to_start({:start_game}, game) do

    game = deal_hands(game)

    game = %{game | status: :pre_flop}

    game = take_blinds(game)
    {:ok, game}
  end

  defp ready_to_start({:join, player}, game) do
    waiting_for_players({:join, player}, game)
    {:ok, game}
  end

  defp deal_hands(game) do
    game
    |> clear_table
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

  defp take_buyin(game) do
    players = game.players
    rules = game.rules
    pot = game.pot

    new_players = Enum.filter(players, fn(p) -> p.stack - rules.buy_in > 0 end )

    amount_taken = Enum.count(new_players) * rules.buy_in

    Enum.reduce([1, 2, 3], fn(x, acc) -> x + acc end)

    %{game | players: new_players, pot: pot + amount_taken}
  end

  defp take_bet(game, {player, bet} = bet) do
    pot = game.pot
    %{game | pot: pot + bet}
  end

  defp clear_table(game) do
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
