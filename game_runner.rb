# encoding: utf-8

require "curses"

# The GameRurrer class implements the base methods used to
# run the game, the event loop being the most important.
#
# The Game that is run by the GameRunner has to implement the
# following methods:
# * objects - the array of objects that are displayed on the screen
# * input_map - the mapping between the keyboard keys and game actions
# * tick - the method that is called for every loop cycle
# * exit_message - the message displayed when the game is finished
# * textbox_content - the message displayed at the bottom of the game window
# * sleep_time - the time interval beteen two event loop cycles
#
# The objects that are displayed on the screen have to implement the following
# interface:
# * x - the x position of the object
# * y - the y position of the object
# * char - the text representation of the object
# * color (optional) - the color of the object
class GameRunner
  include Curses

  def initialize(game_class)
    init_screen
    start_color
    cbreak
    noecho
    stdscr.nodelay = 1
    curs_set(0)

    [
      COLOR_WHITE, COLOR_RED, COLOR_BLUE, COLOR_GREEN, COLOR_CYAN,
      COLOR_MAGENTA, COLOR_YELLOW
    ].each do |color|
      init_pair(color, color, COLOR_BLACK)
    end

    @plane_width = cols
    @plane_height = lines - 5
    @plane = Window.new(@plane_height, @plane_width, 0, 0)
    @plane.box("|", "-")

    @textbox_width = cols
    @textbox_height = 5
    @textbox = Window.new(@textbox_height, @textbox_width, @plane_height, 0)
    @textbox.box("|", "-")

    @game = game_class.new(@plane_width - 2, @plane_height - 2)
  end

  def run
    begin
      loop do
        tick_game
        handle_input

        render_objects
        render_textbox

        @plane.refresh
        @textbox.refresh

        clear_plane
        clear_textbox

        sleep(@game.sleep_time)
      end
    ensure
      close_screen
      puts
      puts @game.exit_message
    end
  end

  def handle_input
    char = getch
    action = @game.input_map[char]
    if action && @game.respond_to?(action)
      @game.send(action)
    end
  end

  def tick_game
    @game.tick
  end

  def render_objects
    @game.objects.each do |object|
      color = object.respond_to?(:color) ? object.color : COLOR_WHITE

      if object.respond_to?(:texture)
        object.texture.each.with_index do |row,index|
          @plane.setpos(object.y + 1 + index, object.x + 1)
          @plane.attron(color_pair(color) | A_NORMAL) do
            @plane.addstr(row)
          end
        end
      else
        @plane.setpos(object.y + 1, object.x + 1)
        @plane.attron(color_pair(color) | A_NORMAL) do
          @plane.addstr(object.char)
        end
      end
    end
  end

  def render_textbox
    @textbox.setpos(2, 3)
    @textbox.addstr(@game.textbox_content)
  end

  def clear_plane
    1.upto(@plane_height - 2) do |y|
      1.upto(@plane_width - 2) do |x|
        @plane.setpos(y, x)
        @plane.addstr(" ")
      end
    end
  end

  def clear_textbox
    1.upto(@textbox_height - 2) do |y|
      1.upto(@textbox_width - 2) do |x|
        @textbox.setpos(y, x)
        @textbox.addstr(" ")
      end
    end
  end
end
