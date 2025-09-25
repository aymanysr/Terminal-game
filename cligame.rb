require 'io/console'

# The `module CliGame` in the Ruby code defines a module named `CliGame` that
# encapsulates the implementation of a text-based game. Within this module,
# various classes and methods are defined to handle the game logic, player
# interactions, enemy movements, environment setup, and game flow.
module CliGame
  MAP = [
    '#########################',
    '#...........####........#',
    '#...........#..#........#',
    '#...#####...#..#...#####.#',
    '#...#...#...#..#...#...#.#',
    '#...#...#...+..+...#...#.#',
    '#...#...#...#..#...#...#.#',
    '#...#####...#..#...#####.#',
    '#...........#..#........#',
    '#...........####........#',
    '#########+################',
    '#.......................#',
    '#.......................#',
    '#.......................#',
    '#########################'
  ].freeze

  HEIGHT = MAP.size
  WIDTH = MAP.first.size
  STARTING_HEALTH = 100
  FRAME_DURATION = 0.1
  DEBUG_LOG_PATH = 'debug.log'

  MOVES = {
    'w' => [0, -1],
    's' => [0, 1],
    'a' => [-1, 0],
    'd' => [1, 0]
  }.freeze

  def self.debug_log(message)
    return unless ENV['DEBUG_GAME'] == '1'

    File.open(DEBUG_LOG_PATH, 'a') do |log|
      log.puts("#{Time.now.to_f}: #{message}")
    end
  end

  def self.print_line(message = '')
    $stdout.write(message)
    $stdout.write("\r\n")
  end

  # The Player class in Ruby represents a player in a game with attributes for
  # position and health, methods for taking damage and moving within the game
  # environment.
  class Player
    attr_reader :x, :y, :health

    def initialize(start_x, start_y, player_health)
      @x = start_x
      @y = start_y
      @health = player_health
    end

    def take_damage(amount)
      @health -= amount
    end

    def try_move(delta_x, delta_y, environment)
      target_x = @x + delta_x
      target_y = @y + delta_y
      passable = environment.passable?(target_x, target_y)
      if ENV['DEBUG_GAME'] == '1'
        CliGame.debug_log("try_move from=(#{@x},#{@y}) delta=(#{delta_x},#{delta_y}) target=(#{target_x},#{target_y}) passable=#{passable}")
      end
      return unless passable

      @x = target_x
      @y = target_y
      environment.eat_cookie_at(@x, @y)
    end
  end

  # The Enemy class in Ruby represents an enemy character that moves horizontally,
  # interacts with the game environment, and can cause damage to the player.
  class Enemy
    attr_accessor :x, :y, :direction, :steps, :movement_delay

    def initialize(enemy_x, enemy_y, direction = :right)
      @x = enemy_x
      @y = enemy_y
      @direction = direction
      @steps = 0
      @movement_delay = 0
    end

    def update(env, player)
      self.movement_delay += 1
      return if movement_delay < 4

      self.movement_delay = 0
      next_x_pos = @direction == :left ? @x - 1 : @x + 1
      blocked = !env.passable?(next_x_pos, @y) ||
                env.bombs.any? { |bomb| bomb.x == next_x_pos && bomb.y == @y } ||
                env.cookies.any? { |cookie| cookie.x == next_x_pos && cookie.y == @y }

      if blocked
        reverse_direction
      else
        self.x = next_x_pos
        self.steps += 1
      end

      return unless @x == player.x && @y == player.y

      player.take_damage(50)
      CliGame.print_line("Ouch! Enemy hit you, Health: #{player.health}")
    end

    private

    def reverse_direction
      @direction = @direction == :left ? :right : :left
    end
  end

  # The `Food` class in Ruby has attributes `x` and `y` representing the position
  # of the food item.
  class Food
    attr_reader :x, :y

    def initialize(x_pos, y_pos)
      @x = x_pos
      @y = y_pos
    end
  end

  # The `Bomb` class in Ruby has attributes `x` and `y` representing its position.
  class Bomb
    attr_reader :x, :y

    def initialize(x_pos, y_pos)
      @x = x_pos
      @y = y_pos
    end
  end

  # The `Environment` class in Ruby represents a game environment with cookies,
  # bombs, enemies, and methods to interact with them.
  class Environment
    attr_reader :cookies, :bombs
    attr_accessor :enemies

    def initialize
      @cookies = [
        Food.new(1, 2),
        Food.new(10, 3),
        Food.new(11, 8),
        Food.new(13, 4),
        Food.new(7, 12),
        Food.new(13, 8)
      ]
      @bombs = [
        Bomb.new(2, 8),
        Bomb.new(9, 3),
        Bomb.new(11, 6),
        Bomb.new(14, 8),
        Bomb.new(9, 7),
        Bomb.new(13, 6)
      ]
      @enemies = []
    end

    def eat_cookie_at(player_x, player_y)
      @cookies.delete_if { |cookie| cookie.x == player_x && cookie.y == player_y }
    end

    def check_bomb(player_x, player_y)
      before = @bombs.size
      @bombs.delete_if { |bomb| bomb.x == player_x && bomb.y == player_y }
      CliGame.print_line
      @bombs.size < before
    end

    # n9der mkhdem b x.negative? y.positive?
    def passable?(x, y)
      return false if x < 0 || y < 0 || x >= WIDTH || y >= HEIGHT

      '.+'.include?(MAP[y][x])
    end

    def draw(player)
      $stdout.write("\e[H\e[2J")
      MAP.each_with_index do |row, y|
        line = row.chars.each_with_index.map do |ch, x|
          if x == player.x && y == player.y
            '@'
          elsif @cookies.any? { |cookie| cookie.x == x && cookie.y == y }
            'o'
          elsif @bombs.any? { |bomb| bomb.x == x && bomb.y == y }
            'x'
          elsif @enemies.any? { |enemy| enemy.x == x && enemy.y == y }
            'M'
          else
            ch
          end
        end.join
        CliGame.print_line(line)
      end
      CliGame.print_line("Health : #{player.health} left")
    end

    # fin wsl l enemy
    def enemy_at(x, y)
      @enemies.find { |enemy| enemy.x == x && enemy.y == y }
    end
  end

  # The `Game` class in Ruby represents a simple game where a player interacts with
  # enemies and objects in a terminal-based environment.
  class Game
    def initialize
      @env = Environment.new
      @player = Player.new(3, 3, STARTING_HEALTH)
      @env.enemies = [
        Enemy.new(10, 8, :right),
        Enemy.new(7, 11, :left),
        Enemy.new(13, 5, :left),
        Enemy.new(20, 2, :left),
        Enemy.new(20, 8, :left)
      ]
      @last_tick = Time.now
      @needs_draw = true
    end

    # `STDIN.raw!` is a method call that sets the standard input stream (`STDIN`) to
    # raw mode. In raw mode, input is read character by character without any line
    # buffering or special processing. This means that each key press is immediately
    # available to the program without waiting for the user to press Enter. This is
    # commonly used in terminal-based applications like games to provide more
    # responsive and interactive user input handling.
    def run
      $stdin.raw!
      loop do
        update_enemies_if_needed
        break if handle_input == :quit
        break if draw_if_needed == :quit
      end
    ensure
      # `STDIN.cooked!` is a method call that sets the standard input stream (`STDIN`)
      # back to cooked mode. In cooked mode, input is line-buffered and processed based
      # on the terminal's settings, allowing for more traditional line-by-line input
      # handling. This is typically done at the end of a program to reset the input
      # stream to its default behavior after using raw mode for more responsive input
      # handling.
      $stdin.cooked!
      CliGame.print_line('Ciao!')
    end

    private

    # algo to calculate frame duration
    def update_enemies_if_needed
      now = Time.now
      return unless now - @last_tick >= FRAME_DURATION

      @last_tick = now
      @env.enemies.each { |enemy| enemy.update(@env, @player) }
      @needs_draw = true
    end

    def handle_input
      # checking if there is input available to be read from STDIN
      return unless IO.select([$stdin], nil, nil, 0.01)

      raw_input = read_nonblocking_char
      return if raw_input.nil?
      return :quit if raw_input == :quit

      input = raw_input.strip.downcase
      return if input.empty?
      return :quit if input == 'q'

      move_player(input)
    end

    def read_nonblocking_char
      $stdin.read_nonblock(1)
    rescue IO::WaitReadable, Errno::EINTR
      nil
    rescue EOFError
      :quit
    end

    def move_player(input)
      return unless MOVES.key?(input)

      delta_x, delta_y = MOVES[input]
      @player.try_move(delta_x, delta_y, @env)
      @needs_draw = true

      return :quit if resolve_enemy_collision == :dead && end_game!

      :quit if handle_bomb_collision == :dead && end_game!
    end

    def resolve_enemy_collision
      enemy = @env.enemy_at(@player.x, @player.y)
      return unless enemy

      @player.take_damage(50)
      CliGame.print_line("Ouch! Enemy hit you, Health: #{@player.health}")
      @needs_draw = true
      :dead if player_dead?
    end

    def handle_bomb_collision
      return unless @env.check_bomb(@player.x, @player.y)

      @player.take_damage(25)
      CliGame.print_line("BOOM! u have #{@player.health} health left.")
      @needs_draw = true
      :dead if player_dead?
    end

    def draw_if_needed
      return unless @needs_draw

      @env.draw(@player)
      return conclude_with('yay! you ate all the cookies') if @env.cookies.empty?
      return conclude_with('Game Over, you ran out of health.') if player_dead?

      $stdout.write('move with (w/a/s/d, q to quit): ')
      $stdout.flush
      @needs_draw = false
    end

    def end_game!
      @env.draw(@player)
      CliGame.print_line('Game Over, you ran out of health.')
      true
    end

    def conclude_with(message)
      CliGame.print_line(message)
      :quit
    end

    def player_dead?
      @player.health <= 0
    end
  end
end

CliGame::Game.new.run
