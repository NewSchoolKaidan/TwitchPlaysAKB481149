require "socket"
require "dotenv"

Dotenv.load

class String
  def squish
    self.strip.gsub(/\s{2,}/, " ")
  end

  def byte_array
    self.bytes.to_a.freeze
  end
end

class TwitchPlaysAKB1149
  PING_MESSAGE = "PING :tmi.twitch.tv".freeze
  PONG_MESSAGE = "PONG :tmi.twitch.tv".freeze
  COMMAND_MAP = {
    "up".byte_array => "Up".freeze,
    "Up".byte_array => "Up".freeze,
    "上".byte_array => "Up".freeze,
    "うえ".byte_array => "Up".freeze,
    "down".byte_array => "Down".freeze,
    "Down".byte_array => "Down".freeze,
    "下".byte_array => "Down".freeze,
    "した".byte_array => "Down".freeze,
    "left".byte_array => "Left".freeze,
    "left".byte_array => "Left".freeze,
    "左".byte_array => "Left".freeze,
    "ひだり".byte_array => "Left".freeze,
    "right".byte_array => "Right".freeze,
    "Right".byte_array => "Right".freeze,
    "右".byte_array => "Right".freeze,
    "みぎ".byte_array => "Right".freeze,
    "circle".byte_array => "x".freeze,
    "まる".byte_array => "x".freeze,
    "丸".byte_array => "x".freeze,
    "○".byte_array => "x".freeze,
    "◯".byte_array => "x".freeze,
    "x".byte_array => "z".freeze,
    "ばつ".byte_array => "z".freeze,
    "バツ".byte_array => "z".freeze,
    "×".byte_array => "z".freeze,
    "✕".byte_array => "z".freeze,
    "❌".byte_array => "z".freeze,
    "square".byte_array => "a".freeze,
    "しかく".byte_array => "a".freeze,
    "四角".byte_array => "a".freeze,
    "□".byte_array => "a".freeze,
    "triangle".byte_array => "s".freeze,
    "三角".byte_array => "s".freeze,
    "さんかく".byte_array => "s".freeze,
    "△".byte_array => "s".freeze,
    "START".byte_array => "space".freeze,
    "start".byte_array => "space".freeze,
    "SELECT".byte_array => "Return".freeze,
    "select".byte_array => "Return".freeze,
    "L".byte_array => "q".freeze,
    "l".byte_array => "q".freeze,
    "R".byte_array => "w".freeze,
    "aup".byte_array => "i".freeze,
    "analog up".byte_array => "i".freeze,
    "analogup".byte_array => "i".freeze,
    "adown".byte_array => "k".freeze,
    "analog down".byte_array => "k".freeze,
    "analogdown".byte_array => "k".freeze,
    "aleft".byte_array => "j".freeze,
    "analog left".byte_array => "j".freeze,
    "analogleft".byte_array => "j".freeze,
    "aright".byte_array => "l".freeze,
    "analog right".byte_array => "l".freeze,
    "analogright".byte_array => "l".freeze
  }.freeze

  def initialize(server, port, channel)
    @socket = TCPSocket.open(server, port)
    @channel = channel
    @log = File.open("chat.log", "w")

    activate_ppsspp_window
    relay_message "PASS oauth:#{ENV["OAUTH_TOKEN"]}"
    relay_message "NICK #{ENV["TWITCH_USERNAME"]}"
    relay_message "JOIN ##{channel}"
    relay_message "PRIVMSG ##{channel} :おれ、参上・・・！！"
  end

  def run
    until socket.eof? do
      activate_ppsspp_window unless ppsspp_window_activated?
      message = socket.gets

      if message == PING_MESSAGE
        relay_message PONG_MESSAGE
      elsif message =~ /PRIVMSG/
        chat_message = message.split(":").last.squish

        quit if has_quit_permissions?(message) && chat_message == "stopgame"

        run_command(COMMAND_MAP[chat_message.bytes.to_a]) if COMMAND_MAP[chat_message.bytes.to_a]

        log.puts "[#{Time.now}] #{message}"
      else
        log.puts "[#{Time.now}] #{message}"
      end
    end
  end

  def quit
    relay_message "PART ##{channel}"
    log.close
    socket.close
    exit 0
  end

  attr_reader :channel, :log, :socket

  private

  def has_quit_permissions?(message)
    sender = message.split("PRIVMSG").first
    !!(sender =~ /#{channel}@#{channel}\.tmi\.twitch\.tv/)
  end

  def relay_message(message)
    puts "< #{message}"
    socket.puts message  
  end

  def ppsspp_window_ids
    `xdotool search --class PPSSPP`.split("\n")
  end

  def activate_ppsspp_window
    if ppsspp_window_ids.any?
      `xdotool search --class PPSSPP windowactivate %@ 2> /dev/null`
    else
      abort("PPSSPP is not running!")
    end
  end

  def ppsspp_window_activated?
    ppsspp_window_ids.include?(`xdotool getactivewindow`.strip)
  end

  def run_command(command)
    `xdotool search --class "PPSSPP" key --window %@ #{command}`
  end
end

SERVER  = "irc.twitch.tv".freeze
PORT    = 6667
CHANNEL = "missingno15".freeze

akb1149 = TwitchPlaysAKB1149.new(SERVER, PORT, CHANNEL)

Signal.trap("INT") { akb1149.quit }
Signal.trap("TERM") { akb1149.quit }

akb1149.run
