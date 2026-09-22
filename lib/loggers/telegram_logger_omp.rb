require 'telegram_bot'
require 'fileutils'
require 'json'

# VerboseLogger: logs every request and is within the before definition in main.rb
class TelegramLogger
  def initialize
    @bot = TelegramBot.new(token: '5641593028:AAHzTWyj2f-P4WalK3gUFSV061cqsYvjrMk')
    @channel_id = '-1001852752618' # Midscore IO API group
    @bot_channel = TelegramBot::Channel.new(id: @channel_id)
    @outgoing_messages = TelegramBot::OutMessage.new
  end

  def send_message(message)
    bot_message = @outgoing_messages
    bot_message.chat = @bot_channel
    bot_message.text = message.to_s
    bot_message.send_with(@bot)
  end
end
