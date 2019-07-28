defmodule Pokerwars.Game do
  alias Pokerwars.{Deck, Player, Ranker, Round, Status}

  require Logger

  @moduledoc """
  This module represents a game being played
  rules:  limit: the type of game none or fixed or pot

  A fixed limit Texas Hold'em betting round ends when two conditions are met:

  All players have had a chance to act.
  All players who haven't folded have bet the same amount of money for the round.
  """

  defstruct hash: nil,
            players: [],
            status: :waiting_for_players,
            round: nil,
            deck: nil,
            bet: 0,
            pot: 0,
            rules: %{
              small_blind: 10,
              big_blind: 20,
              min_players: 2,
              max_players: 10,
              limit: :fixed
            },
            board: [],
            current_player: 0,
            winner: nil,
            available_actions: [:fold, :call, :raise]

  defp hash_id(number \\ 20) do
    Base.encode64(:crypto.strong_rand_bytes(number))
  end

  @doc """
  create a new game
  """
  def new(
        rules \\ %{small_blind: 10, big_blind: 20, min_players: 2, max_players: 10, limit: :fixed},
        deck \\ Deck.in_order()
      ) do
    hash = hash_id()

    # Logger.info "game " <> hash <> " was created "
    IO.puts("game " <> hash <> " was created ")

    %__MODULE__{rules: rules, deck: deck, hash: hash}
  end

  @doc """
  applies the specified action to the game
  """
  def apply_action(game, action) do
    init(game, action)
  end

  defp init(:waiting_for_players, game, action) do
    with {:ok, game} <- Status.waiting_for_players(action, game),
         {:ok, game} <- Status.next(game) do
      {:ok, game}
    else
      err ->
        err
        {:error, err}
    end
  end

  defp init(game, action) do
    game_action(action, game)
  end

  defp continue(game) do
    case next_round?(game) do
      true -> 
       {_, game } = Round.next(game)
     #  game = reset_amounts(game)
       {:ok, game}
      false -> next_player(game)
    end
  end

  @doc """
  Player join Action, player joins the game 
  """
  defp game_action({:start_game}, game) do
    game =
      game
      |> clear_game
      |> shuffle_cards
      |> shuffle_cards
      |> deal_hands
      |> take_blinds


    game = %{
      game
      | round: :pre_flop
    }

    {:ok, game}
  end

  defp game_action({:join, player}, game) do
    init(:waiting_for_players, game, {:join, player})
  end

  @doc """
  Player raise Action, player chooses to raise the bet by x amount 
  """
  defp game_action({:raise, player, amount}, game) do
    case Player.current?(player, game) do
      true ->
        game = take_bet(game, {player, amount}, :raise)

        continue(game)

      false ->
        {:error, "it is not " <> player.name <> "s turn"}
    end
  end

  @doc """
  Player call Action, player chooses to call the bet 
  """
  defp game_action({:call, player}, game) do
    case Player.current?(player, game) do
      true ->
        game = take_bet(game, {player, game.bet}, :call)

        continue(game)

      false ->
        {:error, "it is not " <> player.name <> "s turn"}
    end
  end

  ##todo calc fun for whos turn it is
   ## fold, get the current player, chk if he is the last, if so we subtrack 1 from the current player

  @doc """
  Player fold Action, player chooses to fold his hand and is removed from player list
  """
  defp game_action({:fold, player}, game) do
    case Player.current?(player, game) do
      true ->

        players = Enum.reject(game.players, fn p -> p.hash == player.hash end)

        IO.puts(player.name <> " folded")

       current_player =  case game.current_player > Enum.count(players) - 2 do
          true -> game.current_player - 1
          false -> game.current_player
        end

        game = %{game | players: players, current_player: current_player}

        {_, game} = continue(game)

        Ranker.check_for_winner(game)

      false ->
        # IO.puts "Error: it is not " <> player.name <> "s turn"
        {:error, "it is not " <> player.name <> "s turn"}
    end
  end

  @doc """
  Player Check Action, player chooses to skip his turn without betting
  """
  defp game_action({:check, player}, game) do
    case Player.current?(player, game) do
      true ->
        continue(game)

      false ->
        # IO.puts("not the current player")
        {:error, "it is not " <> player.name <> "s turn"}
    end
  end

  @doc """
  Show the available_actions for the current game_state
  """
  defp available_actions(game) do
    player = Player.current(game)

    case player.amount > game.bet do
      true -> [:check, :fold, :raise]
      false -> [:fold, :raise]
    end
  end

  defp shuffle_cards(game) do
    deck = Deck.shuffle(game.deck)

    game = %{
      game
      | deck: deck,
        status: :running
    }
  end

  defp deal_hands(game) do
    game
    |> deal_cards_to_each_player
    |> deal_cards_to_each_player
  end

  defp take_blinds(game) do

    [first_player, second_player | other_players] = game.players

    game = take_bet(game, {first_player, game.rules.small_blind}, :blinds)

    {_, game} = next_player(game)

    game = take_bet(game, {second_player, game.rules.big_blind}, :blinds)

    {_, game} = next_player(game)

game
  end

  @doc """
  Game take_bet Action, this function is responsible for taking coin from the players stack and placing it in the pot
  """
  defp take_bet(game, {player, amount}, action \\ :call) do
    pot = game.pot

    current_player = Player.find(player.hash, game)

    amount =
      case action do
        :raise -> game.bet + amount
        _ -> amount
      end

    amount_to_take =
      case action do
        :raise -> game.bet + amount
        _ ->  amount - current_player.amount
      end

    is_betting? = Player.can_bet?(current_player, game, amount_to_take)

    players =
      case is_betting? do
        true ->
          Enum.map(game.players, fn p ->
            case p.hash == player.hash  do
              true ->  
              %{player | stack: p.stack - amount_to_take, amount: amount, action: action, hand: p.hand}

              false ->
                p
            end
          end)

        false ->
          game.players
      end

    case is_betting? do
      true ->
        IO.puts(player.name <> "s bet for " <> to_string(amount) <> " was placed in the pot")
        %{game | pot: pot + amount, bet: amount, players: players}

      false ->
        IO.puts(player.name <> "s bet for " <> to_string(amount) <> " was denied")
        %{game | players: players}
    end
  end

  defp clear_game(game) do
    players = Enum.map(game.players, &Player.clear_hand/1)
    deck = Deck.in_order()
    %{game | deck: deck, players: players}
  end

  defp reset_amounts(game) do
    players = Enum.map(game.players, &Player.reset/1)
    %{game | players: players}
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

  def next_player(game) do
    case game.current_player < Enum.count(game.players) - 1 do
      true ->
        game = %{game | current_player: game.current_player + 1}

        available_actions = available_actions(game)

        game = %{game | available_actions: available_actions}

        {:ok, game}

      false ->
             game = %{game | current_player: 0}

             available_actions = available_actions(game)

             game = %{game | available_actions: available_actions}

            {:ok, game}
       
    end
  end

  def next_round?(game) do
    ## check that all players have met the big blind and have checked, or limit chk
    IO.puts("checking if we have any open bets and we are on the last player of the round")

    amounts =
      Enum.map(game.players, fn x ->
        x.amount
      end)

    bets = Enum.reject(amounts, fn x -> x == game.bet end)

    bet_count = Enum.count(bets)

    IO.inspect(bets, label: "open bets")
    IO.inspect(game.current_player, label: "game.current_player")
    IO.inspect(Enum.count(game.players), label: "game.current_player.count")

    case bet_count < 1 and game.current_player > Enum.count(game.players) - 2 do
      true ->
        IO.puts(" We are eligible to go to the next round")
        true

      false ->
        IO.puts(" We are not eligible to go to the next round")
        false
    end
  end

  defimpl String.Chars, for: Pokerwars.Game do
    def to_string(game) do
      deck = game.deck || %Pokerwars.Deck{}
      card_count = length(deck.cards)
      player_count = length(game.players)
      available_actions = Enum.join(game.available_actions, " ")

      Enum.join([
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
      ])
    end
  end
end
