require 'telegram/bot'

require 'fileutils'

require 'json'

require 'openai'

# LEFT OFF WORKING ON THIS.

# Finalized beta version of the telegram chat bot.

# This is the final version of the telegram chat bot.

# VERSION v1.0.0 - 2023-04-14

class TelegramChat
  def initialize
    @telegram_bot_token = '5641593028:AAHzTWyj2f-P4WalK3gUFSV061cqsYvjrMk'

    @ai_client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY'],

      request_timeout: 30
      # temperature: 0.5,

      # max_tokens: 100,

      # top_p: 1,

      # frequency_penalty: 0,

      # presence_penalty: 0,

      # stop: ["\n", " Human:", " AI:"]

    )
  end

  def send_message(chat_id, text)
    Telegram::Bot::Client.run(@telegram_bot_token) do |bot|
      bot.api.send_message(chat_id: chat_id, text: text)
    end
  end

  def receive_message(message)
    msg = []

    unless message.text.nil? # deprecated

      if message.text[0..3] == '/hud'

        msg = message.text.split('/hud ')

      else

        msg[0] = '/hud' # bug with using /hud, not necessary but am integrating this with always saying /openai
        msg[1] = message.text

      end

    end

    if message.text.nil?

      msg[0] = '/hud' # bug with using /hud, not necessary but am integrating this with always saying /openai

      msg[1] = '{send bug}'

    end

    # send_message(message.chat.id, msg[1].to_s)

    return unless msg[1]

    response = @ai_client.chat(
      parameters: {

        model: 'gpt-3.5-turbo',

        messages: [{ role: 'user', content: "/openai: #{msg[1]}\n" }],

        max_tokens: 2048,

        temperature: 0.7

      }
    )

    out_message = response.dig('choices', 0, 'message', 'content')

    puts("Message(OpenAI_Telegram |-> self[ACTORS]:-> #{out_message}\n")

    send_message(message.chat.id, out_message.to_s)
  end

  def fetch_updates # IMPORTANT
    last_update_id = 0

    # Fetch telegram bot update id and message

    updates = Telegram::Bot::Client.run(@telegram_bot_token) do |bot|
      bot.api.get_updates
    end

    last_update_id = updates['result'].last['update_id'] unless updates['result'].empty?

    Telegram::Bot::Client.run(@telegram_bot_token) do |bot|
      loop do
        times_counter ||= 0

        updates = bot.api.get_updates(offset: last_update_id + 1, timeout: 20)

        updates['result'].each do |update|
          last_update_id = update['update_id']

          receive_message(Telegram::Bot::Types::Message.new(update['message']))
        end

        sleep(6) # NOTE/TODO: Mess around with sleep response timer... you know the loop...

        times_counter += 1

        # 10*6 = 60 seconds, 60 seconds is the max time for a telegram bot to be online until its restarted automatically

        break if times_counter == 10
      end
    end
  end
end

def _main_(_args)
  loop do
    puts 'Telegram Chat [re]booted...'

    telegram_logger = TelegramChat.new

    telegram_logger.fetch_updates

  rescue StandardError

    puts '{<[NOVA]>}: Telegram Chat Conbnection closed; RELOADING...'
  end
end

# DATE: 2023-04-14 -- April 14th, 2023

# REMEMBER THIS (got from github copilor, the $PROGRAM+NAME and ARGV, etc)

if $PROGRAM_NAME == __FILE__

  args = ARGV

  _main_(args) # NOTE: This is the main function.

end
