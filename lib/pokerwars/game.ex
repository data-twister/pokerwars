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

  @doc """
  Player join Action, player joins the game 
  """
  defp game_action({:start_game}, game) do
    game = deal_hands(game)
    game = take_blinds(game)

    player_count = Enum.count(game.players)

    current_player =
      case player_count > 2 do
        true -> 2
        false -> 0
      end

    game = %{
      game
      | status: :running,
        round: :pre_flop,
        current_player: current_player
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
        take_bet(game, {player, amount}, :raise)

        current_player = game.current_player

        case current_player < Enum.count(game.players) - 1 do
          true -> next_player(game)
          false -> next_round?(game)
        end

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

        case next_round?(game) do
          true -> Round.next(game)
          false -> next_player(game)
        end

      false ->
        {:error, "it is not " <> player.name <> "s turn"}
    end
  end

  @doc """
  Player fold Action, player chooses to fold his hand and is removed from player list
  """
  defp game_action({:fold, player}, game) do
    case Player.current?(player, game) do
      true ->
        players = Enum.reject(game.players, fn p -> p.hash == player.hash end)

        IO.puts(player.name <> " folded")

        game = %{game | players: players}

        {_, game} =
          case next_round?(game) do
            true -> Round.next(game)
            false -> next_player(game)
          end

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
        case next_round?(game) do
          true -> Round.next(game)
          false -> next_player(game)
        end

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
      | deck: deck
    }
  end

  defp deal_hands(game) do
    game
    |> clear_game
    |> shuffle_cards
    |> shuffle_cards
    |> deal_cards_to_each_player
    |> deal_cards_to_each_player
  end

  defp take_blinds(game) do
    players = game.players
    rules = game.rules
    pot = game.pot

    [first_player, second_player | other_players] = players

    first_player = %{
      first_player
      | stack: first_player.stack - rules.small_blind,
        action: :bet,
        amount: rules.small_blind
    }

    second_player = %{
      second_player
      | stack: second_player.stack - rules.big_blind,
        action: :bet,
        amount: rules.big_blind
    }

    new_players = [first_player, second_player | other_players]

    amount_taken = rules.small_blind + rules.big_blind

    IO.puts(
      "blinds of " <>
        to_string(game.rules.small_blind) <>
        "/" <>
        to_string(game.rules.big_blind) <>
        " were taken from " <> first_player.name <> " and " <> second_player.name
    )

    %{game | players: new_players, pot: pot + amount_taken, bet: game.rules.big_blind}
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

    is_betting? = Player.can_bet?(current_player, game, amount)

    players =
      case is_betting? do
        true ->
          Enum.map(game.players, fn p ->
            case p.hash == player.hash and p.stack > amount do
              true ->
                %{player | stack: p.stack - amount, amount: amount, action: action, hand: p.hand}

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
        %{game | players: players}
    end
  end

  defp clear_game(game) do
    players = Enum.map(game.players, &Player.clear_hand/1)
    deck = Deck.in_order()
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

  def next_player(game) do
    case game.current_player < Enum.count(game.players) - 1 do
      true ->
        game = %{game | current_player: game.current_player + 1}

        available_actions = available_actions(game)

        game = %{game | available_actions: available_actions}

        {:ok, game}

      false ->
        #   available_actions = available_actions(game)

        #  game = %{game | available_actions: available_actions}

        {:ok, game}
    end

    case game.current_player > Enum.count(game.players) - 1 do
      true ->
        game = %{game | current_player: 0}

        #     available_actions = available_actions(game)

        #     game = %{game | available_actions: available_actions}

        {:ok, game}

      false ->
        # available_actions = available_actions(game)

        #    game = %{game | available_actions: available_actions}

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

    case Enum.count(bets) < 1 and game.current_player == Enum.count(game.players) - 1 do
      true -> true
      false -> false
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
