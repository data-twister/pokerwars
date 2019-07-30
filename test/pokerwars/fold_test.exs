defmodule Pokerwars.GameTest.Fold do
  use ExUnit.Case, async: true
  import Pokerwars.TestHelpers

  alias Pokerwars.{Game, Player}

  @player1 Player.create("Mithereal", 100)
  @player2 Player.create("Ron", 100)
  @player3 Player.create("Marc", 100)
  @player4 Player.create("Troy", 100)

  test "Players fold before the flop" do
    step("We create a game and it is waiting for players")
    game = Game.new()
    assert game.status == :waiting_for_players

    step("The players join and the game is ready to start")

    game =
      with {:ok, game} <- Game.apply_action(game, {:join, @player1}),
           {:ok, game} <- Game.apply_action(game, {:join, @player2}),
           {:ok, game} <- Game.apply_action(game, {:join, @player3}),
           {:ok, game} <- Game.apply_action(game, {:join, @player4}),
           do: game

    assert length(game.players) == 4
    assert game.status == :ready_to_start

    step("Game Start")
    {:ok, game} = Game.apply_action(game, {:start_game})
    assert game.round == :pre_flop

    step("All players can see 2 cards")
    assert 4 == length(Enum.map(game.players, & &1.hand))

    step("All players fold")

    game =
      with {:ok, game} <- Game.apply_action(game, {:fold, @player3}),
           {:ok, game} <- Game.apply_action(game, {:fold, @player4}),
           {:ok, game} <- Game.apply_action(game, {:fold, @player1}),
           ## error
           do: game

    assert Enum.count(game.players) == 1
    #assert game.winner.name == @player2.name

    step("Game Over")
    assert game.round == :game_over
  end

  test "Players fold before the turn" do
    step("We create a game and it is waiting for players")
    game = Game.new()
    assert game.status == :waiting_for_players

    step("The players join and the game is ready to start")

    game =
      with {:ok, game} <- Game.apply_action(game, {:join, @player1}),
           {:ok, game} <- Game.apply_action(game, {:join, @player2}),
           {:ok, game} <- Game.apply_action(game, {:join, @player3}),
           {:ok, game} <- Game.apply_action(game, {:join, @player4}),
           do: game

    assert length(game.players) == 4
    assert game.status == :ready_to_start

    step("Game Start")
    {:ok, game} = Game.apply_action(game, {:start_game})
    assert game.round == :pre_flop
    assert game.current_player == 2

    step("All players can see 2 cards")
    assert 4 == length(Enum.map(game.players, & &1.hand))

    step("All players call")

    game =
      with {:ok, game} <- Game.apply_action(game, {:call, @player3}),
           {:ok, game} <- Game.apply_action(game, {:call, @player4}),
           {:ok, game} <- Game.apply_action(game, {:call, @player1}),
           do: game

    assert Enum.count(game.players) == 4
    assert game.current_player == 1

    step("Remaining Players Fold")

    game =
      with {:ok, game} <- Game.apply_action(game, {:fold, @player2}),
           {:ok, game} <- Game.apply_action(game, {:fold, @player3}),
           {:ok, game} <- Game.apply_action(game, {:fold, @player4}),
           do: game

    #  IO.inspect game
    assert game.current_player == 0

    assert Enum.count(game.players) == 1

    # assert game.winner.name == @player2.name

    step("Game Over")
    assert game.round == :game_over
  end
end
