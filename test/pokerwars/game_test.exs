defmodule Pokerwars.GameTest do
    use ExUnit.Case, async: true
    import Pokerwars.TestHelpers
  
     alias Pokerwars.{Game, Player}

     IO.puts "+++ ---Starting Game Test--- +++ \n"
  
    @player1 Player.create "Mithereal", 100
    @player2 Player.create "Ron", 100
    @player3 Player.create "Marc", 100
    @player4 Player.create "Troy", 100



    test "Players check for all rounds" do
      step "We create a game and it is waiting for players"
      game = Game.new
      assert game.status == :waiting_for_players
  
       step "The players join and the game is ready to start"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:join, @player1}),
        {:ok, game} <- Game.apply_action(game, {:join, @player2}),
        {:ok, game} <- Game.apply_action(game, {:join, @player3}),
        {:ok, game} <- Game.apply_action(game, {:join, @player4}),
        do: game
      assert length(game.players) == 4
      assert game.status == :ready_to_start
  
       step "The game is started"
       {:ok, game} = Game.apply_action(game, {:start_game})
      assert game.round == :pre_flop
  
        step "All players can see 2 cards"
       assert 4 == length(Enum.map(game.players, &(&1.hand)))

       step "All players call except last player"
             game = with \
         {:ok, game} <- Game.apply_action(game, {:call, @player3}),
         {:ok, game} <- Game.apply_action(game, {:call, @player4}),
         {:ok, game} <- Game.apply_action(game, {:call, @player1}),
         {:ok, game} <- Game.apply_action(game, {:call, @player2}),
         {:ok, game} <- Game.apply_action(game, {:call, @player3}),
         do: game
         assert game.bet == 20
         assert [20,20,20,20] == Enum.map(game.players, &(&1.amount))

         step "Last player Calls"
         game = with \
     {:ok, game} <- Game.apply_action(game, {:call, @player4}),
     do: game
     assert game.bet == 0
     assert [0,0,0,0] == Enum.map(game.players, &(&1.amount))

       step "Here comes the flop"
       assert game.round == :flop

       step "There are 3 cards on the table"
       assert length(game.board) == 3

      step "All players check"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:check, @player1}),
        {:ok, game} <- Game.apply_action(game, {:check, @player2}),
        {:ok, game} <- Game.apply_action(game, {:check, @player3}),
        {:ok, game} <- Game.apply_action(game, {:check, @player4}),
        do: game
        assert game.bet == 0
        assert [0,0,0,0] == Enum.map(game.players, &(&1.amount))

        step "Here comes the turn"
      assert game.round == :turn
  
       step "There are 4 cards on the table"
      assert length(game.board) == 4

      step "All players check"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:check, @player1}),
        {:ok, game} <- Game.apply_action(game, {:check, @player2}),
        {:ok, game} <- Game.apply_action(game, {:check, @player3}),
        {:ok, game} <- Game.apply_action(game, {:check, @player4}),
        do: game
      assert game.bet == 0
      assert [0,0,0,0] == Enum.map(game.players, &(&1.amount))

      step "Here comes the river"
        assert game.round == :river
  
      step "There are 5 cards on the table"
      assert length(game.board) == 5

      step "All players check"
      game = with \
        {:ok, game} <- Game.apply_action(game, {:check, @player1}),
        {:ok, game} <- Game.apply_action(game, {:check, @player2}),
        {:ok, game} <- Game.apply_action(game, {:check, @player3}),
        {:ok, game} <- Game.apply_action(game, {:check, @player4}),
        do: game
        assert game.bet == 0
        assert [0,0,0,0] == Enum.map(game.players, &(&1.amount))

        step "Enter the showdown"
        assert game.round == :showdown

    end



  end