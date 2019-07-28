defmodule Pokerwars.GameTest do
    use ExUnit.Case, async: true
    import Pokerwars.TestHelpers
  
     alias Pokerwars.{Game, Player}
  
    @player1 Player.create "Mithereal", 100
    @player2 Player.create "Ron", 100
    @player3 Player.create "Marc", 100
    @player4 Player.create "Troy", 100
  
     test "Running a simple game where all players fold before the flop" do
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

       step "All players fold"
             game = with \
         {:ok, game} <- Game.apply_action(game, {:fold, @player3}),
         {:ok, game} <- Game.apply_action(game, {:fold, @player4}),
         {:ok, game} <- Game.apply_action(game, {:fold, @player1}),
         do: game
         assert Enum.count(game.players) == 1
         assert game.winner.name == @player2.name
      #   assert [30,30,30,30] == Enum.map(game.players, &(&1.amount))
  
      #  step @player3.name <> " raises the bet by 10 and " <> @player4.name <> " calls it by placing 30 in the pot"
      # game = with \
      #   {:ok, game} <- Game.apply_action(game, {:raise, @player3, 10}),
      #   {:ok, game} <- Game.apply_action(game, {:call, @player4}),
      #   {:ok, game} <- Game.apply_action(game, {:call, @player1}),
      #   {:ok, game} <- Game.apply_action(game, {:call, @player2}),
      #   {:ok, game} <- Game.apply_action(game, {:call, @player3}),
      #   {:ok, game} <- Game.apply_action(game, {:call, @player4}),
      #   do: game
      #   assert game.bet == 30
      #   assert [30,30,30,30] == Enum.map(game.players, &(&1.amount))

      #   IO.inspect(game)
      
      #   step "Here comes the flop"
      # assert game.round == :flop
  
      #  step "There are 3 cards on the table"
      # assert length(game.board) == 3

      # step "All players check"
      # IO.inspect game, label: "game"
      # game = with \
      #   {:ok, game} <- Game.apply_action(game, {:check, @player1}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player2}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player3}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player4}),
      #   do: game
      #   assert game.bet == 20
      #   assert [20,20,20,20] == Enum.map(game.players, &(&1.amount))

      #   step "Here comes the turn"
      # assert game.round == :turn
  
      #  step "There are 4 cards on the table"
      # assert length(game.board) == 4

      # step "Player 1 Bets, others Check"
      # game = with \
      #   {:ok, game} <- Game.apply_action(game, {:bet, @player1,20}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player2}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player3}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player4}),
      #   do: game
      # assert game.bet == 20
      # assert [20,20,20,20] == Enum.map(game.players, &(&1.amount))

      # step "Here comes the river"
      #   assert game.round == :river
  
      # step "There are 5 cards on the table"
      # assert length(game.board) == 5

      # step "Player 1 and Player 2 Raises others check"
      # game = with \
      #   {:ok, game} <- Game.apply_action(game, {:raise, @player1,20}),
      #   {:ok, game} <- Game.apply_action(game, {:raise, @player2,10}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player3}),
      #   {:ok, game} <- Game.apply_action(game, {:check, @player4}),
      #   do: game
      #   assert game.bet == 50
      #   assert [40,50,50,50] == Enum.map(game.players, &(&1.amount))
        

    end
  end