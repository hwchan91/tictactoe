class Game
  def initialize
    @winnning_patterns = [["1","2","3"], ["4","5","6"], ["7","8","9"], ["1","4","7"], ["2","5","8"],\
     ["3","6","9"], ["1","5","9"], ["3","5","7"]]
    @valid_values = (1..9).map {|x| x.to_s}
    @corners = ["1","3","7","9"]

    puts "How many players? (0,1 or 2)"
    response = ""
    while !["0","1","2"].include? response
      response = gets.chomp
      if response == "0"
        computer_vs_computer
        @game = 0
      elsif response == "1"
        vs_computer
        @game = 1
      elsif response == "2"
        vs_human
        @game = 2
      else
        puts "Invalid response. Please try again."
      end
    end
  end

  def vs_human
    @player1 = Player.new
    @player1.set_name("the name of player 1")
    @player2 = Player.new
    @player2.set_name("the name of player 2")
    @players = [@player1, @player2]
  end

  def vs_computer
    @player1 = Player.new
    @player1.set_name("your name")
    @player2 = Player.new
    @player2.computer
    @players = [@player1, @player2]
    @checkmate_move = nil
    @final_move = nil
  end

  def computer_vs_computer
    @player1 = Player.new
    @player1.computer
    @player2 = Player.new
    @player2.computer
    @players = [@player1, @player2]
    @checkmate_move = nil
    @final_move = nil
  end

  class Player
    attr_accessor :name, :moves

    def initialize
    end

    def set_name(name)
      puts "What is #{name}?"
      @name = gets.chomp
      @moves = []
    end

    def computer
      @name = "Computer"
      @moves = []
    end
  end

  def start_game
    @winner = false
    puts "Game starts. Coin Tossed."
    @initial_player_index = rand(2)
    #@initial_player_index = 1 #testing: force initial to be computer
    puts "#{@players[@initial_player_index].name} goes first."
    @turn = 1
    print_board
    while @turn <= 9 and @winner == false
      curr_player
      set_up_turn
      @avail_tiles = @valid_values - @taken_tiles
      @avail_corners = @corners - @taken_tiles

      if @game == 2
        players_round
      elsif @game == 1
        players_round if @curr_player_index == 0
        computers_round if @curr_player_index == 1
      else
        computers_round
      end
      print_board
      check_winning
      @turn += 1
    end
    puts "Tie; no one wins" if @turn == 10
    puts "Another game?"
  end

  def print_board
    board = (1..9).map {|x| x.to_s}
    symbols = ["X", "O"]
    for i in (0..1)
      board.map! {|slot| (@players[i].moves.include? slot)? symbols[i] : slot}
    end
    puts "\n\n"
    i=0
    for i in [0,3,6]
      puts " #{board[i]}  |  #{board[i+1]}  |  #{board[i+2]}  "
      puts "----------------" if i < 6
    end
    puts "\n\n"
  end

  def curr_player
    @curr_player_index =  @turn % 2 == 1 ? @initial_player_index : (@initial_player_index + 1) % 2
  end

  def set_up_turn
    @symbol_for_player = @curr_player_index  % 2 == 0 ? "X" : "O"
    puts "#{@players[@curr_player_index].name}'s turn."
    @taken_tiles = @player1.moves + @player2.moves
  end

  def players_round
    input = ""
    while !@avail_tiles.include? input
      puts "choose a tile(1-9) to place #{@symbol_for_player}."
      input = gets.chomp
      if !@valid_values.include? input
        puts "Invalid Response! Please type a number between 1-9"
      end
      if @taken_tiles.include? input
          puts "The tile is already taken, please choose an empty tile"
      end
    end

    @players[@curr_player_index].moves << input
  end

  def check_winning
    @winnning_patterns.each do |pattern|
      @winner = true if pattern.all? {|x| @players[@curr_player_index].moves.include? x}
    end
    @winning_player = @players[@curr_player_index]
    puts "#{@winning_player.name} wins!" if @winner == true
  end

  def reset
    @player1.moves = []
    @player2.moves = []
    @checkmate_move = nil
    @final_move = nil
    @winner = false
  end
#end

#######
#COMPUTER AI

#class Game
  def computers_round
    @played = false

    if @turn == 1
      random_tile #which will choose a corner automatically
    end

    [@curr_player_index,((@curr_player_index + 1) % 2)].each do |i|
      if @played == false
        check_2in3(@avail_tiles, @players[i].moves) #first checks if computer can already win, then check if need to prevent player from winning
        choose_tile(@any_winning[0]) if @any_winning.length > 0
      end
    end

    if @played == false #runs if no one can immediately win in this round
      if @final_move == nil
        final_move(@avail_tiles, @players[@curr_player_index].moves, nil)
      end

      if @final_move != nil #final move is now determined; note, this is not 'else' of the prior 'if'
        choose_tile(@final_move)
      else #if final move not determined, run strategy
        if @turn == 3 #the strategy would not be useful except in turn 1
          winning_strategy
          choose_tile(@checkmate_move) if @checkmate_move != nil
        end
      end
    end

    if @played == false #is still no move taken
      #in the event that Player goes first, and chooses a corner
      if @turn == 2 and @avail_corners.length == 3
        choose_tile("5") #choose the centre
      #in the event that Computer goes first, and Player chooses centre
      elsif @turn == 3 and @taken_tiles.include? "5"
        player_chooses_centre_in_turn2
      elsif @turn == 4
        if @avail_corners.length == 3 #in the event that Player goes first but avoids choosing corners
          choose_tile("5") #choose the centre
        elsif @avail_corners.length == 2
          if @players[@curr_player_index].moves.include? "5" #i.e. Player took 2 diagonal corners; Computer took centre
            #choose a tile that is not a corner
            non_corners = ["2","4","6","8"]
            random_non_corner = non_corners[rand(4)]
            choose_tile(random_non_corner)
          else #i.e. Player intially takes centre, Computer then takes corner, Player then takes diagonal corner
            random_tile #chooses a remaining corner
          end
        else
          if @avail_corners.length == 2 and !@taken_tiles.include? "5" #i.e. Player initial takes non-corner, Computer takes a corner, Player then takes a corner
            choose_tile("5") #choose the centre
          end
        end
      else
        random_tile
      end
    end
  end


  def check_2in3(avail_tiles, player_moves) #i=0 checks computer's winning method; i=prevents player from winning
    @any_winning = []
    @winnning_patterns.each do |pattern|
      if pattern.count {|x| player_moves.include? x} == 2
         missing_tile = pattern.select {|x| !(player_moves.include? x)}
         missing_tile = missing_tile.join #change array to string
         if avail_tiles.include? missing_tile
           @any_winning << missing_tile
         end
      end
    end
  end


  def random_tile #go for the corners first
    @random_tile = ""
    if @avail_corners.length > 0
      @random_tile = @avail_corners[rand(@avail_corners.length)]
    else
      @random_tile = @avail_tiles[rand(@avail_tiles.length)]
    end
    choose_tile(@random_tile)
  end

  def player_chooses_centre_in_turn2
    taken_corner_arr = @taken_tiles.select {|i| @corners.include? i}
    if ["1", "9"].include? taken_corner_arr.join
      @random_tile = (["1", "9"]- taken_corner_arr).join #if 1, then 9; visa versa
    else
      @random_tile = (["3", "7"]- taken_corner_arr).join #if 3, then 7, visa versa
    end
    choose_tile(@random_tile)
  end

  def choose_tile(i)
    @players[@curr_player_index].moves << i
    puts "Computer chooses tile #{i}"
    @played = true
  end



  def winning_strategy
    @avail_tiles.each do |i|
      #duplicates the current moves for both players
      test_player_moves = @players[(@curr_player_index + 1) % 2].moves.clone
      test_computer_moves = @players[@curr_player_index].moves.clone
      test_avail_tiles = @avail_tiles.clone

      #Computer's turn: test if a move is taken, what happens
      test_computer_moves << i
      test_avail_tiles.delete(i)
      check_2in3(test_avail_tiles,test_computer_moves)

      #Player's turn: check if a 2 in 3 is created by the test move
      if @any_winning.length > 0 #player is forced to block the computer
        test_player_moves << @any_winning.join
        test_avail_tiles -= @any_winning
        check_2in3(test_avail_tiles, test_player_moves)
        if @any_winning.length ==  0 #if the player's move forces Computer to make a move ,the strategy fails
          final_move(test_avail_tiles, test_computer_moves, i)
        end
      end
      break if @checkmate_move != nil
    end
  end

  def final_move(avail_tiles, computer_moves, i)
    avail_tiles.each do |j| #Computer's turn
      computer_moves << j
      check_2in3(avail_tiles,computer_moves)
      if @any_winning.length >= 2 #see if by taking a move, two 2 in 3s can be created
        @checkmate_move = i
        @final_move = j
        break
      end
      computer_moves.delete(j) #remember to remove what is added
    end
  end

end

###
play = true
a = Game.new

while play == true
  a.start_game
  a.reset
  puts "\n\nPress any key to start new game"
  b = gets.chomp
end
