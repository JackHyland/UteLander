require 'rubygems'
require 'gosu'

WIDTH, HEIGHT = 800, 640

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

# Map class holds and draws tiles.
class GameMap
  attr_accessor :width, :height, :tile_set, :tiles
end

# Player class.
class Player
  attr_accessor :x, :y, :rotation, :vy, :vx, :velocityStoredy, :velocityStoredx, :fuel, :score, :id, :reset, :crash, :game_map, :floating, :rocket, :explosion, :cur_image, :angle, :rocketSound, :explosionSound, :landedSound
end

# scoreboard class
class ScoreBoard
  attr_accessor :score, :player
end 

# initialise player settings
def setup_player(player, game_map)
  player = Player.new()
  player.reset = 0
  player.id = 0 # player ID for scoreboard
  # sounds for player
  player.rocketSound = Gosu::Song.new("media/rocket.mp3")
  player.explosionSound = Gosu::Song.new("media/explosionLand.wav")
  player.landedSound = Gosu::Song.new("media/landed.wav")
  player.game_map = game_map
  # Load all animation frames
  player.floating, player.rocket, player.explosion = Gosu::Image.load_tiles("media/utePicture.png", 50, 20)
  # This always points to the frame that is currently drawn.
  # This is set in update, and used in draw.
  player.cur_image = player.floating
  player
end

def reset_player(player, x, y, isReset)
  player.x, player.y = x, y # player co-ordinated
  player.rotation = :NIL # player rotation (left or right or nil)
  player.velocityStoredy = 0 # stored VX for landing values
  player.velocityStoredx = 0 # stored VX for landing values 
  player.angle = 0 # Player angle
  player.vy = 0.0 # Vertical velocity
  player.vx = 0.0 # Vertical velocity
  
  # isReset is true when user is
  # - reseting the game 
  # - or when user is coming from another gameState to gameState 1
  # isReset is false when reseting player once they have crashed or landed
  if isReset == true
    player.id += 1
    player.fuel = 100
    player.score = 0 # Player Score
  end

  # reset player
  player.reset = 0
  player.crash = false
  player
end 

def angle(player)
  # controls left and right direction of player
  if player.rotation == :left
    angle = 1
    player.rotation = :NIL # prevents further rotation when user has stop pressing the arrow key
  elsif player.rotation == :right
    angle = -1
    player.rotation = :NIL
  else 
    angle = 0
  end
  angle
end

# draws player and rotates player
def draw_player(player)
  # find angle
  angle = angle(player)
  offs_x = 25
  factor = -1.0
  # player.angle is incremented to be the angle
  player.cur_image.draw_rot(player.x, player.y - 12, 0, player.angle += angle, center_x = 0.5, center_y = 0.5, factor)
end

# Could the object be placed at x + offs_x/y + offs_y without being stuck?
def would_fit(player, offs_x, offs_y)
  # Check at the center/top and center/bottom for game_map collisions
  not solid?(player.game_map, player.x + offs_x, player.y + offs_y) and
    not solid?(player.game_map, player.x + offs_x, player.y + offs_y - 45)
end

# set the current state of the image 
def image_state_current(player, imageState)
  if player.crash == true
    player.cur_image = player.explosion
  elsif imageState == 0
    player.cur_image = player.rocket
  elsif imageState == 1
    player.cur_image = player.floating
  end
end

# check that area landed is correct
def area_landed(player)
  # if correct play landed sound else explosion
  if (player.x > 48 and player.x < 98) and (player.y > 345 and player.y < 350)
    player.score += 250
    player.landedSound.play
  elsif (player.x > 320 and player.x < 420) and (player.y > 495 and player.y < 500)
    player.score += 50
    player.landedSound.play
  elsif (player.x > 500 and player.x < 600) and (player.y > 595 and player.y < 600)
    player.score += 150
    player.landedSound.play
  elsif (player.x > 650 and player.x < 750) and (player.y > 395 and player.y < 400)
    player.score += 50
    player.landedSound.play
  elsif (player.x > 1000 and player.x < 1050) and (player.y > 595 and player.y < 600)
    player.score += 250
    player.landedSound.play
  else 
    player.crash = true
    player.explosionSound.play
  end
end

def landed(player)
  # reset < 1 prevents system from repeatedly crashing or landing, this way it will only go through this function once
  if player.reset < 1
    # check that all criteria of landing is correct (i.e speed of landing is safe)
    if (player.velocityStoredy < 1.5 && (player.velocityStoredx > -0.5 && 0.5 > player.velocityStoredx) && (player.angle > -10 && 10 > player.angle))
      area_landed(player)
    else
      player.crash = true
      player.explosionSound.play
    end
    player.reset = 1
  end
end

# the players gravity and speed
def player_gravity(player)
  # Acceleration/gravity
  # By adding 0.01 each frame, players velocity will increase in the y direction
  player.vy += 0.01

  # Vertical movement and horizontal movement
  # if falling else rising
  if player.vy > 0    
    # check if impact
    if would_fit(player, 0, 1) && would_fit(player, 1, 0) && would_fit(player, -1, 0)
      player.y += player.vy # exponetial falling of the players y axis
      player.x = player.x + player.vx # constant x velocity
      player.velocityStoredy = player.vy # stored velocities y and x for landing pads 
      player.velocityStoredx = player.vx
    else 
      # impact means landed or crashed and velocity y is set to 0
      player.vy = 0
    end 
  else 
    if would_fit(player, 0, -1) && would_fit(player, 1, 0) && would_fit(player, -1, 0)
      player.y += player.vy + 0.1 # exponetial rising of the players y axis
      player.x += player.vx  # exponential x velocity (rocket would be on)
    else 
      player.vy = 0
    end 
  end
end

# updates players image, rotation, velocity and landing status
def update_player(player, rotating, imageState)
  # set image state 
  image_state_current(player, imageState)

  # Direction of rotation, sets state of rotation for angle(player)
  if rotating > 0
    player.rotation = :right
  elsif rotating < 0
    player.rotation = :left
  end

  # players gravity and velocity
  player_gravity(player)

  # if impact then call landed function
  if player.vy == 0
    landed(player)
  end 
end

# player is using rocket function
def player_rocket(player)
  if player.fuel > 0
    # angle needs to be between 0-180 (90 degrees would be directly north)
    angle = player.angle + 90 
    x = Math.cos(angle * (Math::PI/180)) # find x axis (adjacent)
    y = Math.sin(angle * (Math::PI/180)) # find x axis (opposite)
    # store x and y and divide it by 20 to make it a smaller value 
    # 20 can be changed to change acceleration of player 
    player.vx += -x / 20 
    player.vy += -y / 20
    player.fuel -= 1
    player.rocketSound.play
  end
end

# display score
def display_current_score(font, player, camera_x)
  x = player.vx * 100
  y = player.vy * 100 
  font.draw("Press 0 - menu", camera_x + 250, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Press 1 - Restart", camera_x + 400, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Fuel: #{player.fuel}", camera_x + 10, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Current Score: #{player.score}", camera_x + 10, 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Current User ID: #{player.id}", camera_x + 10, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("x Velocity: #{x.round(1)}", camera_x + 10, 70, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("y Velocity: #{y.round(1)}", camera_x + 10, 90, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Ute angle: #{player.angle}", camera_x + 10, 110, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
end

# display result after crash or land
def display_result(font, player)
  if player.crash == false
    font.draw("LANDED", 300, 200, ZOrder::UI, 2.5, 2.5, Gosu::Color::YELLOW)
    font.draw("Total Score is: #{player.score} ", 260, 250, ZOrder::UI, 2.0, 2.0, Gosu::Color::YELLOW)
  else
    font.draw("CRASHED", 300, 200, ZOrder::UI, 2.5, 2.5, Gosu::Color::YELLOW)
    font.draw("Total Score is: #{player.score} ", 260, 250, ZOrder::UI, 2.0, 2.0, Gosu::Color::YELLOW)
  end
  if player.fuel == 0
    font.draw("Game Finished ", 285, 290, ZOrder::UI, 2.0, 2.0, Gosu::Color::YELLOW)
  end 
end 

# display menu 
def display_menu(font)
  font.draw("UTE LANDER", 235, 200, ZOrder::UI, 3.0, 3.0, Gosu::Color::YELLOW)
  font.draw("press a number to continue", 240, 260, ZOrder::UI, 1.5, 1.5, Gosu::Color::YELLOW)
  font.draw("1. Play", 335, 290, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("2. Highscores", 335, 310, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("3. Instructions", 335, 330, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("4. To Quit Game", 335, 350, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
end 

# display scoreboard in highscores
def display_scoreboard(font, scoreBoard)
  font.draw("Press 0 - menu", 250, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Press 1 - Play", 400, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("High Scores", 295, 160, ZOrder::UI, 2.0, 2.0, Gosu::Color::YELLOW)
  if scoreBoard.length == 0
    font.draw("These are no scores to display", 275, 210, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  else
    font.draw("Player ID", 305, 210, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    font.draw("Score", 425, 210, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
    i = 0
    y = 0
    # print out array of scores
    while i < scoreBoard.length
      font.draw(scoreBoard[i].player, 305, 230 + y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
      font.draw(scoreBoard[i].score, 425, 230 + y, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
      i += 1
      y += 20
    end
  end
end

# display instructions
def display_instructions(font, instructions)
  font.draw("Press 0 - menu", 250, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Press 1 - Play", 400, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("Instructions", 295, 130, ZOrder::UI, 2.0, 2.0, Gosu::Color::YELLOW)
  font.draw("Player must land on one of the coloured pads", 210, 180, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  instructions.draw 210, 205, 0
  font.draw("For a player to land you need to", 250, 275, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("- Players y velocity must be less than 150 to land", 120, 300, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("- Players x velocity must be less than 50 and greater than -50 to land", 120, 320, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("- Players angle must be less than 10 and greater than -10 to land", 120, 340, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
  font.draw("The game ends when your fuel is 0 and you land", 190, 370, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
end 

# store current player data (id and score)
def player_data(player)
  players = ScoreBoard.new()
  players.player = player.id
  players.score = player.score 
  players
end

# store current player results into a array
def store_result(player, scoreBoardDatas)  
  scoreBoardData = player_data(player)
  scoreBoardDatas << scoreBoardData
  scoreBoardDatas
end 

# game_map functions and procedures
def setup_game_map(filename)
  game_map = GameMap.new
  land = 0 # represent Land
  # Load 60x60 tiles, 5px overlap in all four directions.
  game_map.tile_set = Gosu::Image.load_tiles("media/Land.png", 60, 60, :tileable => true)
  
  lines = File.readlines(filename).map { |line| line.chomp }
  game_map.height = lines.size
  game_map.width = lines[0].size
  game_map.tiles = Array.new(game_map.width) do |x|
    Array.new(game_map.height) do |y|
      case lines[y][x, 1]
      when '"'
        land
      else
        nil
      end
    end
  end
  game_map
end

def draw_game_map(game_map)
  # Very primitive drawing function:
  # Draws all the tiles, some off-screen, some on-screen.
  game_map.height.times do |y|
    game_map.width.times do |x|
      tile = game_map.tiles[x][y]
      if tile
        # Draw the tile with an offset (tile images have some overlap)
        # Scrolling is implemented here just as in the game objects.
        game_map.tile_set[tile].draw(x * 50 - 5, y * 50 - 5, 0)
      end
    end
  end
  #landing pads for game
  Gosu.draw_rect(48, 345, 50, 5, Gosu::Color::GREEN, ZOrder::PLAYER, mode=:default)
  Gosu.draw_rect(320, 495, 100, 5, Gosu::Color::YELLOW, ZOrder::PLAYER, mode=:default)
  Gosu.draw_rect(500, 595, 100, 5, Gosu::Color::BLUE, ZOrder::PLAYER, mode=:default)
  Gosu.draw_rect(650, 395, 100, 5, Gosu::Color::YELLOW, ZOrder::PLAYER, mode=:default)
  Gosu.draw_rect(1000, 595, 50, 5, Gosu::Color::GREEN, ZOrder::PLAYER, mode=:default)
end

# Solid at a given pixel position?
def solid?(game_map, x, y)
  y < 0 || game_map.tiles[x / 50][y / 50]
end

class UteLander < Gosu::Window
  def initialize
    super WIDTH, HEIGHT
    self.caption = "Ute Lander"

    @gameState = 0 # state for game, menu is 0 
    @scoreBoard = Array.new() # array for user highscores data
    @Instructions = Gosu::Image.new("media/instructionsLand.png", :tileable => true)
    @background = Gosu::Image.new("media/space.png", :tileable => true)
    @game_map = setup_game_map("media/uteLanderMap.txt")
    @ute = setup_player(@ute, @game_map)
    # The scrolling position is stored as top left corner of the screen.
    @camera_x = @camera_y = 0
    @font = Gosu::Font.new(20)
  end

  #constantly cycles and updates game if gameState == 1
  def update
    # only run game when gameState == 1, else its menu pages
    if @gameState == 1
      # detect it rotating
      rotating = 0
      rotating -= 1 if Gosu.button_down? Gosu::KB_LEFT
      rotating += 1 if Gosu.button_down? Gosu::KB_RIGHT

      #detect if rockets are used
      if Gosu.button_down? Gosu::KB_UP 
        player_rocket(@ute)
        imageState = 0 # set image for rocket
      else
        @ute.rocketSound.stop
        imageState = 1 # set image for floating
      end
      
      # if fuel and reset are true, then go back to main menu
      # else reset back to position
      # 150 gives the game some time to wait so user can read, this can be shorted or extended 
      if @ute.reset > 0
        @ute.reset += 1
        if @ute.fuel == 0 && @ute.reset == 150      
          store_result(@ute, @scoreBoard) 
          @gameState = 0 # main menu
        elsif @ute.reset == 150
          @ute.reset = 0    
          reset_player(@ute, 400, 100, false)
        end        
      end

      update_player(@ute, rotating, imageState)
      # Scrolling follows player
      @camera_x = [[@ute.x - WIDTH / 2, 0].max, @game_map.width * 50 - WIDTH].min
      @camera_y = [[@ute.y - HEIGHT / 2, 0].max, @game_map.height * 50 - HEIGHT].min
    end
  end

  # constantly updates image of GOSU
  def draw
    # background
    @background.draw 0, 0, ZOrder::BACKGROUND

    # State of game menu = 0, play = 1, highscores = 2, instructions = 3
    if @gameState == 0
      display_menu(@font)
    elsif @gameState == 1
      Gosu.translate(-@camera_x, -@camera_y) do
        draw_game_map(@game_map)
        draw_player(@ute)
        display_current_score(@font, @ute, @camera_x)
      end
      
      # displayed results when user has landed or crashed 
      if @ute.reset > 0
        display_result(@font, @ute)
      end

    elsif @gameState == 2
      display_scoreboard(@font, @scoreBoard)
    elsif @gameState == 3
      display_instructions(@font, @Instructions)
    end 
  end

  # controls the game state 
  def button_down(id)
    case id
    when Gosu::KB_0
      @gameState = 0
    when Gosu::KB_1
      @gameState = 1
      reset_player(@ute, 400, 100, true)
    when Gosu::KB_2
      @gameState = 2
    when Gosu::KB_3
      @gameState = 3
    when Gosu::KB_4
      close
    else
      super
    end
  end
end

UteLander.new.show if __FILE__ == $0
