require "socket"
require "dotenv"

Dotenv.load

class String
  def squish
    self.strip.gsub(/\s{2,}/, " ")
  end
end

class TwitchPlaysAKB1149
  PING_MESSAGE = "PING :tmi.twitch.tv".freeze
  PONG_MESSAGE = "PONG :tmi.twitch.tv".freeze
  COMMAND_MAP = {
    "up".freeze => "Up".freeze,
    "Up".freeze => "Up".freeze,
    "上".freeze => "Up".freeze,
    "うえ".freeze => "Up".freeze,
    "down".freeze => "Down".freeze,
    "Down".freeze => "Down".freeze,
    "下".freeze => "Down".freeze,
    "した".freeze => "Down".freeze,
    "left".freeze => "Left".freeze,
    "left".freeze => "Left".freeze,
    "左".freeze => "Left".freeze,
    "ひだり".freeze => "Left".freeze,
    "right".freeze => "Right".freeze,
    "Right".freeze => "Right".freeze,
    "右".freeze => "Right".freeze,
    "みぎ".freeze => "Right".freeze,
    "circle".freeze => "x".freeze,
    "まる".freeze => "x".freeze,
    "丸".freeze => "x".freeze,
    "○".freeze => "x".freeze,
    "◯".freeze => "x".freeze,
    "x".freeze => "z".freeze,
    "ばつ".freeze => "z".freeze,
    "バツ".freeze => "z".freeze,
    "×".freeze => "z".freeze,
    "✕".freeze => "z".freeze,
    "❌".freeze => "z".freeze,
    "square".freeze => "a".freeze,
    "しかく".freeze => "a".freeze,
    "四角".freeze => "a".freeze,
    "□".freeze => "a".freeze,
    "triangle".freeze => "s".freeze,
    "三角".freeze => "s".freeze,
    "さんかく".freeze => "s".freeze,
    "△".freeze => "s".freeze,
    "START".freeze => "space".freeze,
    "start".freeze => "space".freeze,
    "SELECT".freeze => "Return".freeze,
    "select".freeze => "Return".freeze,
    "L".freeze => "q".freeze,
    "l".freeze => "q".freeze,
    "R".freeze => "w".freeze,
    "aup".freeze => "i".freeze,
    "analog up".freeze => "i".freeze,
    "analogup".freeze => "i".freeze,
    "adown".freeze => "k".freeze,
    "analog down".freeze => "k".freeze,
    "analogdown".freeze => "k".freeze,
    "aleft".freeze => "j".freeze,
    "analog left".freeze => "j".freeze,
    "analogleft".freeze => "j".freeze,
    "aright".freeze => "l".freeze,
    "analog right".freeze => "l".freeze,
    "analogright".freeze => "l".freeze
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

        if has_quit_permissions?(message) && chat_message == "stopgame"
          quit 
        elsif COMMAND_MAP[chat_message]
          run_command(COMMAND_MAP[chat_message])
        end

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
