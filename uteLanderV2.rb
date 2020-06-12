# Encoding: UTF-8

# Basically, the tutorial game taken to a jump'n'run perspective.

# NOTE THIS PROGRAM IS A STRUCTURED VERSION OF THE ORIGINAL
# MODIFIED BY M. MITCHELL

# Shows how to
#  * implement jumping/gravity
#  * implement scrolling using Window#translate
#  * implement a simple tile-based map
#  * load levels from primitive text files

# Some exercises, starting at the real basics:
#  0) understand the existing code!
# As shown in the tutorial:
#  1) change it use Gosu's Z-ordering
#  2) add gamepad support
#  3) add a score as in the tutorial game
#  4) similarly, add sound effects for various events
# Exploring this game's code and Gosu:
#  5) make the player wider, so he doesn't fall off edges as easily
#  6) add background music (check if playing in Window#update to implement
#     looping)
#  7) implement parallax scrolling for the star background!
# Getting tricky:
#  8) optimize Map#draw so only tiles on screen are drawn (needs modulo, a pen
#     and paper to figure out)
#  9) add loading of next level when all gems are collected
# ...Enemies, a more sophisticated object system, weapons, title and credits
# screens...

require 'rubygems'
require 'gosu'

WIDTH, HEIGHT = 800, 640

module Tiles
  Land = 0
end

# Map class holds and draws tiles and gems.
class GameMap
  attr_accessor :width, :height, :gems, :tile_set, :tiles
end

# Player class.
class Player
  attr_accessor :x, :y, :dir, :vy, :vx, :fuel, :score, :reset, :crash, :game_map, :standing, :jump, :cur_image, :angle
end

class Collectiblegem
  attr_accessor :x, :y, :image
end

# Changed Collectiblegem class from OOP to Structured - note
# change of attrib_reader to attrib_accessor

def setup_gem(image, x, y)
  gem = Collectiblegem.new()
  gem.image = image
  gem.x, gem.y = x, y
  gem
end

def draw_gem(gem)
  # Draw, slowly rotating
  gem.image.draw_rot(gem.x, gem.y, 0, 25 * Math.sin(Gosu.milliseconds / 133.7))
end

# Player functions and procedures
# converted from OOP to Structured

def setup_player(player, game_map, x, y)
  player = Player.new()
  player.x, player.y = x, y
  player.dir = :left
  player.angle = 0
  player.vy = 0.0 # Vertical velocity
  player.vx = 0.0 # Vertical velocity
  player.fuel = 100
  player.score = 0
  player.reset = false
  player.crash = false
  player.game_map = game_map
  # Load all animation frames
  player.standing, player.jump = Gosu::Image.load_tiles("media/uteTrans.png", 50, 30)
  # This always points to the frame that is currently drawn.
  # This is set in update, and used in draw.
  player.cur_image = player.standing
  player
end

def reset_player(player, x, y)
  player.x, player.y = x, y
  player.dir = :left
  player.angle = 0
  player.vy = 0.0 # Vertical velocity
  player.vx = 0.0 # Vertical velocity
  player.reset = false
  player.crash = false
  player
end 

def draw_player(player)
  # Flip vertically when facing to the left.
  if player.dir == :left
    offs_x = -25
    factor = 1.0
    angle = 1
    player.dir = :NIL
  elsif player.dir == :right
    offs_x = 25
    factor = -1.0
    angle = -1
    player.dir = :NIL
  else 
    offs_x = 25
    factor = -1.0
    angle = 0
  end
  #puts player.angle.to_s
  #player.cur_image.draw(player.x + offs_x, player.y - 49, 0, factor, 1.0)
  player.cur_image.draw_rot(player.x, player.y - 12, 0, player.angle += angle, center_x = 0.5, center_y = 0.5, factor)
end

# Could the object be placed at x + offs_x/y + offs_y without being stuck?
def would_fit(player, offs_x, offs_y)
  # Check at the center/top and center/bottom for game_map collisions
  not solid?(player.game_map, player.x, player.y + offs_y) and
    not solid?(player.game_map, player.x + offs_x, player.y + offs_y - 45)
end

def update_player(player, move_x)
  # Select image depending on action
  if (move_x == 0)
    player.cur_image = player.standing
  else
    
  end
  if (player.vy < 0)
    player.cur_image = player.jump
  end

  # Directional walking, horizontal movement
  if move_x > 0
    player.dir = :right
    #player.vx.times { if would_fit(player, 1, 0) then player.x += 0.1 end }
    #puts player.x.to_s + " x"
  end
  if move_x < 0
    player.dir = :left
    #player.vx.times { if would_fit(player, -1, 0) then player.x -= 0.1 end }
    puts "left"
    #puts player.vx.to_s + " x"
  end
  
  # Acceleration/gravity
  # By adding 1 each frame, and (ideally) adding vy to y, the player's
  # jumping curve will be the parabole we want it to be.
  player.vy += 0.01
  # Vertical movement
  
  if player.vy > 0   
    #player.vy.times { if would_fit(player, 0, 1) then player.y += 0.01 else player.vy = 0 end }   
    if would_fit(player, 0, 1)
      player.y += player.vy 
      player.x = player.x + player.vx 
      #player.cx = player.x
      puts player.vy.to_s + " y"  
      puts player.y.to_s + " y" 
    else 
      player.vy = 0
    end 
  end
  if (player.vy < 0)
   # (-player.vy).times { if would_fit(player, 0, -1) then player.y -= 0.1 else player.vy = 0 end }
    if would_fit(player, 0, -1)
      player.y += player.vy + 0.01 
      player.x += player.vx + 0.01 
      puts player.vy.to_s + " y"  
      puts player.y.to_s + " y" 
    else 
      player.vy = 0
    end 
  end

  if player.vy == 0
    landed(player)
  end 
end

def landed(player)
  if ((player.x > 320 and player.x < 420) and (player.y > 495 and player.y < 500))
    player.score += 100
  else
    player.crash = true
  end
  player.reset = true
end

def try_to_jump(player)
  if (player.fuel > 0)
    angle = player.angle + 90 
    tempx = (Math.cos(angle * (Math::PI/180)))
    tempy = (Math.sin(angle * (Math::PI/180)))
    puts angle.to_s + " angle"
    puts tempy.to_s + " Sin value" 
    puts tempx.to_s + " Cos value" 
    puts player.vy.to_s + ' jump vy'
    player.vx = -tempx
    player.vy = -tempy
    player.fuel -= 1
  end
end

def draw_details(font, player, camera_x)
  font.draw("Fuel: #{player.fuel}", camera_x + 10, 10, 2, 1.0, 1.0, Gosu::Color::YELLOW)
end

def display_result(font, player)
  i = 0
  while i < 1000
    if player.crash == false
      font.draw("Congrats", player.x, player.y, 2, 1.0, 1.0, Gosu::Color::YELLOW)
      font.draw("Score is: #{player.score} ", player.x, player.y + 20, 2, 1.0, 1.0, Gosu::Color::YELLOW)
      puts i.to_s
    else
      font.draw("Try Again", player.x, player.y, 2, 1.0, 1.0, Gosu::Color::YELLOW)
      font.draw("Score is: #{player.score} ", player.x, player.y + 20, 2, 1.0, 1.0, Gosu::Color::YELLOW)
    end
    i += 1
    font.draw("Restarting in " + i.to_s , player.x, player.y + 40, 2, 1.0, 1.0, Gosu::Color::YELLOW)
  end
  reset_player(player, 400, 100)
end 

def collect_gems(player, gems)
  # Same as in the tutorial game.
  gems.reject! do |c|
    (c.x - player.x).abs < 50 and (c.y - player.y).abs < 50
  end
end

# game_map functions and procedures
# converted from OOP to Structured
# Note: I change the name to GameMap as the Map here is NOT the same
# one as in the standard Ruby API, which could be confusing.

def setup_game_map(filename)
  game_map = GameMap.new

  # Load 60x60 tiles, 5px overlap in all four directions.

  game_map.tile_set = Gosu::Image.load_tiles("media/grounds4.png", 60, 60, :tileable => true)

  gem_img = Gosu::Image.new("media/gem.png")
  game_map.gems = []

  lines = File.readlines(filename).map { |line| line.chomp }
  game_map.height = lines.size
  game_map.width = lines[0].size
  game_map.tiles = Array.new(game_map.width) do |x|
    Array.new(game_map.height) do |y|
      case lines[y][x, 1]
      when '"'
        Tiles::Land
      when 'x'
        game_map.gems.push(setup_gem(gem_img, x * 50 + 25, y * 50 + 25))
        nil
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
  game_map.gems.each { |c| draw_gem(c) }
  Gosu.draw_rect(320, 495, 100, 5, Gosu::Color::YELLOW, 2, mode=:default)
end

# Solid at a given pixel position?
def solid?(game_map, x, y)
  y < 0 || game_map.tiles[x / 50][y / 50]
end

class CptnRuby < (Example rescue Gosu::Window)
  def initialize
    super WIDTH, HEIGHT

    self.caption = "Cptn. Ruby"

    @sky = Gosu::Image.new("media/space.png", :tileable => true)
    @game_map = setup_game_map("media/cptn_ruby_map.txt")
    @cptn = setup_player(@cptn, @game_map, 400, 100)
    # The scrolling position is stored as top left corner of the screen.
    @camera_x = @camera_y = 0
    @font = Gosu::Font.new(20)
  end

  def update
    move_x = 0
    move_x -= 5 if Gosu.button_down? Gosu::KB_LEFT
    move_x += 5 if Gosu.button_down? Gosu::KB_RIGHT

    if Gosu.button_down? Gosu::KB_UP 
      try_to_jump(@cptn)
    end
    update_player(@cptn, move_x)
    collect_gems(@cptn, @game_map.gems)
    # Scrolling follows player
    @camera_x = [[@cptn.x - WIDTH / 2, 0].max, @game_map.width * 50 - WIDTH].min
    @camera_y = [[@cptn.y - HEIGHT / 2, 0].max, @game_map.height * 50 - HEIGHT].min
  end

  def draw
    @sky.draw 0, 0, 0
    #puts "Camera X is #{@camera_x}"
    #puts "Camera Y is #{@camera_y}"
    Gosu.translate(-@camera_x, -@camera_y) do
      draw_game_map(@game_map)
      draw_player(@cptn)
      draw_details(@font, @cptn, @camera_x)
    end
    if @cptn.reset == true
      display_result(@font, @cptn)
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_UP
      #try_to_jump(@cptn)
    when Gosu::KB_ESCAPE
      close
    else
      super
    end
  end
end

CptnRuby.new.show if __FILE__ == $0
