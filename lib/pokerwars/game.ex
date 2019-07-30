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
            available_actions: [:fold, :call, :raise],
            message: nil

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
    # IO.puts("game " <> hash <> " was created ")

    %__MODULE__{rules: rules, deck: deck, hash: hash}
  end

  @doc """
  applies the specified action to the game
  """
  def apply_action(game, action) do
    {status, game} = init(game, action)
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
        game
        |> fold_players
        |> reset_amounts
        |> Round.next()

      false ->
        IO.puts("going to next player")
        next_player(game)
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
        {status, game} = take_bet(game, {player, amount}, :raise)

        case status == :ok do
          true ->
            game = continue(game)
            {:ok, game}

          false ->
            {:error, game}
        end

      false ->
        game = %{game | message: "it is not " <> player.name <> "s turn"}
        {:error, game}
    end
  end

  @doc """
  Player call Action, player chooses to call the bet 
  """
  defp game_action({:call, player}, game) do
    case Player.current?(player, game) do
      true ->
        {status, game} = take_bet(game, {player, game.bet}, :call)

        case status == :ok do
          true ->
            game = continue(game)
            {:ok, game}

          false ->
            {:error, game}
        end

      false ->
        game = %{game | message: "it is not " <> player.name <> "s turn"}
        {:error, game}
    end
  end

  @doc """
  Player fold function
  """
  defp fold_players(game) do
    players = Enum.reject(game.players, fn x -> x.action == :fold end)
    %{game | players: players}
  end

  @doc """
  Player fold Action, player chooses to fold his hand and is removed from player list
  """
  defp game_action({:fold, player}, game) do
    case Player.current?(player, game) do
      true ->
        players =
          Enum.map(game.players, fn p ->
            case p.hash == player.hash do
              true ->
                %{
                  player
                  | action: :fold
                }

              false ->
                p
            end
          end)

        game = %{game | players: players}

        game = continue(game)
        {:ok, game}

      false ->
        # IO.puts "Error: it is not " <> player.name <> "s turn"
        game = %{game | message: "it is not " <> player.name <> "s turn"}
        {:error, game}
    end
  end

  @doc """
  Player Check Action, player chooses to skip his turn without betting
  """
  defp game_action({:check, player}, game) do
    case Player.current?(player, game) do
      true ->
        game = continue(game)
        {:ok, game}

      false ->
        # IO.puts("not the current player")
        game = %{game | message: "it is not " <> player.name <> "s turn"}
        {:error, game}
    end
  end

  @doc """
  Show the available_actions for the current game_state
  """
  defp available_actions(game) do
    player = Player.current(game)

    available_actions =
      case player.amount > game.bet do
        true -> [:check, :fold, :raise]
        false -> [:fold, :raise]
      end

    %{
      game
      | available_actions: available_actions
    }
  end

  defp shuffle_cards(game) do
    deck = Deck.shuffle(game.deck)

    %{
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

    {_, game} = take_bet(game, {first_player, game.rules.small_blind}, :blinds)
    game = next_player(game)
    {_, game} = take_bet(game, {second_player, game.rules.big_blind}, :blinds)
    next_player(game)
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
        _ -> amount - current_player.amount
      end

    is_betting? = Player.can_bet?(current_player, game, amount_to_take)

    players =
      case is_betting? do
        true ->
          Enum.map(game.players, fn p ->
            case p.hash == player.hash do
              true ->
                %{
                  player
                  | stack: p.stack - amount_to_take,
                    amount: amount,
                    action: action,
                    hand: p.hand
                }

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
        {:ok, %{game | pot: pot + amount, bet: amount, players: players}}

      false ->
        IO.puts(player.name <> "s bet for " <> to_string(amount) <> " was denied")
        {:error, %{game | players: players}}
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

  defp reset_players(game) do
    %{game | current_player: 0}
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
    current_player = game.current_player + 1

    case current_player < Enum.count(game.players) do
      true ->
        game =
          %{game | current_player: game.current_player + 1}
          |> available_actions

        game

      false ->
        game =
          game
          |> fold_players
          |> reset_players
          |> available_actions

        game
    end
  end

  def next_round?(game) do
    ## check that all players have met the big blind and have checked, or limit chk
    # IO.puts("checking if we have any open bets and we are on the last player of the round")

    amounts =
      Enum.map(game.players, fn x ->
        x.amount
      end)

    bets = Enum.reject(amounts, fn x -> x == game.bet end)

    bet_count = Enum.count(bets)

    # IO.inspect(game.players, label: "players")
    IO.inspect(game.bet, label: "current_bet")
    IO.inspect(bet_count, label: "open bets")
    IO.inspect(bets, label: "open bets")
    IO.inspect(game.current_player + 1, label: "current_player")
    IO.inspect(Enum.count(game.players), label: "total players")

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
