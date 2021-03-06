defmodule Pokerwars.Round do
  alias Pokerwars.{Deck, Game, Ranker}

  def next(
        %Game{
          status: :running,
          round: :pre_flop,
          players: players,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          available_actions: available_actions,
          bet: bet,
          board: board,
          current_player: current_player,
          deck: deck,
          hash: hash,
          pot: pot,
          winner: winner
        } = game
      ) do
    {result, deck} = Deck.take(game.deck, 3, true)
    IO.puts("there are " <> to_string(Enum.count(game.players)) <> " players")

    case(Enum.count(game.players) < 2) do
      true ->
        game = %{game | current_player: 0, round: :showdown}
        next(game)

      false ->
        %{
          game
          | status: :running,
            round: :flop,
            current_player: 0,
            board: result,
            deck: deck,
            bet: 0
        }
    end
  end

  def next(
        %Game{
          status: :running,
          round: :flop,
          players: players,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          available_actions: available_actions,
          bet: bet,
          board: board,
          current_player: current_player,
          deck: deck,
          hash: hash,
          pot: pot,
          winner: winner
        } = game
      ) do
    {card, deck} = Deck.deal(game.deck, true)

    stay_amt = 0

    %{
      game
      | bet: stay_amt,
        status: :running,
        round: :turn,
        current_player: 0,
        board: [card] ++ board,
        deck: deck
    }
  end

  def next(
        %Game{
          status: :running,
          round: :turn,
          players: players,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          available_actions: available_actions,
          bet: bet,
          board: board,
          current_player: current_player,
          deck: deck,
          hash: hash,
          pot: pot,
          winner: winner
        } = game
      ) do
    {card, deck} = Deck.deal(game.deck, true)
    hole = [card] ++ board

    stay_amt = 0

    %{game | bet: stay_amt, round: :river, current_player: 0, board: hole, deck: deck}
  end

  def next(
        %Game{
          status: :running,
          round: :river,
          players: players,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          available_actions: available_actions,
          bet: bet,
          board: board,
          current_player: current_player,
          deck: deck,
          hash: hash,
          pot: pot,
          winner: winner
        } = game
      ) do
    game = %{game | current_player: 0, round: :showdown}
    next(game)
  end

  def next(
        %Game{
          status: :running,
          round: :showdown,
          players: players,
          rules: %{
            small_blind: small_blind,
            big_blind: big_blind,
            min_players: min_players,
            max_players: max_players,
            limit: limit
          },
          available_actions: available_actions,
          bet: bet,
          board: board,
          current_player: current_player,
          deck: deck,
          hash: hash,
          pot: pot,
          winner: winner
        } = game
      ) do
    winners = Ranker.get_winners(game)

    game = %{
      game
      | current_player: 0,
        round: :game_over,
        status: :game_over,
        winner: winners,
        players: winners
    }

    game
  end
end
