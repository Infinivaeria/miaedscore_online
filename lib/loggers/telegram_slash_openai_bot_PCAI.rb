require 'telegram/bot'
require 'fileutils'
require 'json'
require 'openai'
require 'telegram_bot'

# PCAI bot schematics


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


$telegram_bot_token ||= '5641593028:AAHzTWyj2f-P4WalK3gUFSV061cqsYvjrMk'
$open_ai_token ||= ENV['OPENAI_API_KEY']
# returns telegramchat object
def start_telegram_logger
  return TelegramLogger.new
end

def send_message_to_telegram(chat_id, text)
  Telegram::Bot::Client.run($telegram_bot_token) do |bot|
    bot.api.send_message(chat_id: chat_id, text: text)
  end
end

def get_telegram_last_update_id
  Telegram::Bot::Client.run($telegram_bot_token) do |bot|
    updates = bot.api.get_updates
    last_update_id = updates['result'].last['update_id']
    return last_update_id
  end
end



def open_ai_message(text, ai_client)
  response = ai_client.chat(
    parameters: {
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: "/openai: #{text}\n" }],
      max_tokens: 2048,
      temperature: 0.7
    }
  )
  out_message = response.dig('choices', 0, "message", "content")
  puts("Message(self[AI] [:]|-> TELEGRAM INTERACTION:-> #{out_message}\n")
  TelegramLogger.new.send_message(out_message)  
  return out_message
end



def _open_ai_client_start_init_
  return OpenAI::Client.new(
    access_token: ENV['OPENAI_API_KEY'],
    request_timeout: 120
    #temperature: 0.5,
    #max_tokens: 100,
    #top_p: 1,
    #frequency_penalty: 0,
    #presence_penalty: 0,
    #stop: ["\n", " Human:", " AI:"]
  )
end

def start_openai_client()
  _open_ai_client_start_init_()
end

def fetch_updates
  last_update_id = 0

  Telegram::Bot::Client.run($telegram_bot_token) do |bot|
    loop do
      updates = bot.api.get_updates(offset: last_update_id + 1, timeout: 10)
      updates['result'].each do |update|
        last_update_id = update['update_id']
        p update
        TelegramLogger.new.send_message(update['message']['text'])
        p "DEBUG_MESSAGE_SENT [:]-> #{update['message']['text']}"
        open_ai_message(update['message']['text'], _open_ai_client_start_init_())
        #p "DEGUG: #{update['message']['text']}"
        TelegramLogger.new.send_message(open_ai_message(update['message']['text'], _open_ai_client_start_init_()))
        #receive_message(Telegram::Bot::Types::Message.new(update['message']))
  
       #NOTE/TODO: Mess around with sleep response timer... you know the loop...
      end
    end
  end
end


def _main_()

  opening_debug_message ||= "Telegram Chat [re]booted..."
  puts opening_debug_message

  telegram_agent ||= start_telegram_logger()
  telegram_agent.send_message(opening_debug_message)

  open_ai = start_openai_client()
  open_ai_message("Hello HUDlink_AI (that's you, OpenAI)", open_ai)



  # clear telegram bot cache
  #how do I write a try catch block in ruby?
  begin
    p fetch_updates
  rescue
    p "DEBUG_WARNING_DANGER[:]|-> Update fetch error, trying again..."
  end

  p fetch_updates



  


end

_main_
