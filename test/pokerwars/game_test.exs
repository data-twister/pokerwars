defmodule Pokerwars.GameTest do
    use ExUnit.Case, async: true
    import Pokerwars.TestHelpers
  
     alias Pokerwars.{Game, Player, Deck, Card}
  
     @player1 Player.create "Bill", 100
    @player2 Player.create "Ben", 100
  
     test "Running a simple game" do
      step "We create a game and it is waiting for players"
      game = Game.create
      assert game.status == :waiting_for_players
  
       step "The players join and the game is ready to start"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:join, @player1}),
        {:ok, game} <- Game.apply_action(game, {:join, @player2}),
        do: game
      assert length(game.players) == 2
      assert game.status == :ready_to_start
  
       step "The game is started"
       {:ok, game} = Game.apply_action(game, {:start_game})
      assert game.phase == :pre_flop
  
       step "Both players can see 2 cards"
      assert 2 == length(Enum.map(game.players, &(&1.hand)))
  
       step "Both players check"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:check, @player1}),
        {:ok, game} <- Game.apply_action(game, {:check, @player2}),
        do: game
      assert game.phase == :flop
  
       step "There are 3 cards on the table"
      assert length(game.hole_cards) == 3

      step "Both players check"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:check, @player1}),
        {:ok, game} <- Game.apply_action(game, {:check, @player2}),
        do: game
      assert game.phase == :turn
  
       step "There are 4 cards on the table"
      assert length(game.hole_cards) == 4

      step "Both players bet"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:bet, @player1,20}),
        {:ok, game} <- Game.apply_action(game, {:bet, @player2, 20}),
        do: game
      assert game.phase == :river
  
      step "There are 5 cards on the table"
      assert length(game.hole_cards) == 5

      step "The game is over"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:check, @player1}),
        {:ok, game} <- Game.apply_action(game, {:check, @player2}),
        do: game
      assert game.phase == :game_over

    end
  end