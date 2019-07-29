defmodule Pokerwars.GameTest.CurrentPlayer do
  use ExUnit.Case, async: true
  import Pokerwars.TestHelpers
  alias Pokerwars.{Player, Game, Deck}

  @player1 Player.create("Mithereal", 100)
  @player2 Player.create("Ron", 100)
  @player3 Player.create("Marc", 100)
  @player4 Player.create("Troy", 100)

  test "Current Player" do
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

    step("The game is started")
    {:ok, game} = Game.apply_action(game, {:start_game})
    assert game.round == :pre_flop

    step("Wrong Player attempt to do an action")
    {status, _} = Game.apply_action(game, {:fold, @player4})
    assert status == :error

    step("Correct Player attempt to do an action")
    {status, _} = Game.apply_action(game, {:fold, @player3})
    assert status == :ok
  end
end
