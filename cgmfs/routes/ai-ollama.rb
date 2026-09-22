require 'json'
require 'fileutils'
require 'net/http'
require 'uri'

class CGMFS
  AI_OLLAMA_LOG_DIR = '/root/miaedscore/logs/ollama_teams'.freeze unless const_defined?(:AI_OLLAMA_LOG_DIR)
  unless const_defined?(:OLLAMA_HTTP_ADDRESS)
    OLLAMA_HTTP_ADDRESS = ENV.fetch('OLLAMA_HTTP_ADDRESS',
                                    'http://localhost:11434').freeze
  end
  unless const_defined?(:OLLAMA_MODEL_NAME)
    OLLAMA_MODEL_NAME = ENV.fetch('OLLAMA_MODEL',
                                  'llama2-uncensored:latest').freeze
  end
  OLLAMA_OPEN_TIMEOUT = 5 unless const_defined?(:OLLAMA_OPEN_TIMEOUT)
  OLLAMA_READ_TIMEOUT = 240 unless const_defined?(:OLLAMA_READ_TIMEOUT)
  OLLAMA_WRITE_TIMEOUT = 30 unless const_defined?(:OLLAMA_WRITE_TIMEOUT)
  TEAM_HISTORY_CHAR_LIMIT = 2_000 unless const_defined?(:TEAM_HISTORY_CHAR_LIMIT)
  TEAM_HISTORY_ENTRY_LIMIT = 8 unless const_defined?(:TEAM_HISTORY_ENTRY_LIMIT)
  ENABLE_SECOND_LIFE_CHAT_CONTEXT = false unless const_defined?(:ENABLE_SECOND_LIFE_CHAT_CONTEXT)
  unless const_defined?(:SECOND_LIFE_CHAT_LOG_PATH)
    SECOND_LIFE_CHAT_LOG_PATH = '/root/miaedscore/tiade-maeepers-saerver-all/target/release/second_life_chat_logs.txt'.freeze
  end
  SECOND_LIFE_CHAT_LOG_LINE_LIMIT = 25 unless const_defined?(:SECOND_LIFE_CHAT_LOG_LINE_LIMIT)
  SECOND_LIFE_CHAT_LOG_CHAR_LIMIT = 8_000 unless const_defined?(:SECOND_LIFE_CHAT_LOG_CHAR_LIMIT)

  FileUtils.mkdir_p(AI_OLLAMA_LOG_DIR)

  def self.ai_ollama_log_path(team)
    safe_team = team.to_s.gsub(/[^a-zA-Z0-9_.-]/, '_')
    File.join(AI_OLLAMA_LOG_DIR, "#{safe_team}.log")
  end

  def self.ai_ollama_trim_text(text, char_limit)
    trimmed = text.to_s.strip
    return '' if trimmed.empty?
    return trimmed if trimmed.length <= char_limit

    trimmed[-char_limit, char_limit]
  end

  def self.ai_ollama_team_history(team)
    log_path = ai_ollama_log_path(team)
    return '' unless File.exist?(log_path)

    raw_history = File.read(log_path)
    entries = raw_history.split(/\n{2,}/).map(&:strip).reject(&:empty?)
    sanitized_entries = entries.filter_map do |entry|
      user_text = entry[/Message:\n(.+?)\nAI:/m, 1]
      user_text = entry[/^USER:\s*(.+)$/m, 1] if user_text.nil? || user_text.strip.empty?

      ai_text = entry[/\nAI:\s*(.+)\z/m, 1]
      next if ai_text.nil? || ai_text.strip.empty?

      compact_user = user_text.to_s.strip.gsub(/\s+/, ' ')
      compact_ai = ai_text.to_s.strip.gsub(/\s+/, ' ')
      next if compact_ai.empty?

      if compact_user.empty?
        "AI: #{compact_ai}"
      else
        "USER: #{compact_user}\nAI: #{compact_ai}"
      end
    end

    recent = sanitized_entries.last(TEAM_HISTORY_ENTRY_LIMIT)
    ai_ollama_trim_text(recent.join("\n\n"), TEAM_HISTORY_CHAR_LIMIT)
  end

  def self.ai_ollama_second_life_log_context
    return 'Second Life chat log is currently unavailable.' unless File.exist?(SECOND_LIFE_CHAT_LOG_PATH)

    lines = File.readlines(SECOND_LIFE_CHAT_LOG_PATH, chomp: true)
    recent_lines = lines.last(SECOND_LIFE_CHAT_LOG_LINE_LIMIT)
    context = ai_ollama_trim_text(recent_lines.join("\n"), SECOND_LIFE_CHAT_LOG_CHAR_LIMIT)
    context.empty? ? 'Second Life chat log is currently empty.' : context
  rescue StandardError => e
    "Second Life chat log could not be read: #{e.message}"
  end

  def self.ai_ollama_append_team_log(team, user_message, reply)
    parsed_user_message = ai_ollama_parse_relay_message(user_message)[:message]
    compact_user = parsed_user_message.to_s.strip.gsub(/\s+/, ' ')
    compact_reply = reply.to_s.strip.gsub(/\s+/, ' ')

    File.open(ai_ollama_log_path(team), 'a') do |file|
      file.puts "USER: #{compact_user}"
      file.puts "AI: #{compact_reply}"
      file.puts
    end
  end

  def self.ai_ollama_http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = OLLAMA_OPEN_TIMEOUT
    http.read_timeout = OLLAMA_READ_TIMEOUT
    http.write_timeout = OLLAMA_WRITE_TIMEOUT if http.respond_to?(:write_timeout=)
    http
  end

  def self.ai_ollama_parse_json_body(body)
    body = body.to_s
    return {} if body.strip.empty?

    JSON.parse(body)
  rescue JSON::ParserError
    { 'raw_body' => body }
  end

  def self.ai_ollama_post_json(path, payload)
    uri = URI.parse("#{OLLAMA_HTTP_ADDRESS}#{path}")
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(payload)

    response = ai_ollama_http_client(uri).request(request)
    parsed = ai_ollama_parse_json_body(response.body)
    return parsed if response.is_a?(Net::HTTPSuccess)

    error_message = parsed['error'] || response.body.to_s
    raise StandardError, "Ollama #{path} failed with HTTP #{response.code}: #{error_message}"
  end

  def self.ai_ollama_get_json(path)
    uri = URI.parse("#{OLLAMA_HTTP_ADDRESS}#{path}")
    request = Net::HTTP::Get.new(uri.request_uri)
    response = ai_ollama_http_client(uri).request(request)
    return ai_ollama_parse_json_body(response.body) if response.is_a?(Net::HTTPSuccess)

    {}
  rescue StandardError
    {}
  end

  def self.ai_ollama_available_models
    models = ai_ollama_get_json('/api/tags')['models']
    return [] unless models.is_a?(Array)

    models.filter_map do |model|
      name = model['name'].to_s.strip
      name.empty? ? nil : name
    end
  end

  def self.ai_ollama_resolved_model_name
    models = ai_ollama_available_models
    return [nil, models] if models.empty?

    configured = OLLAMA_MODEL_NAME.to_s
    return [configured, models] if models.include?(configured)

    bare_configured = configured.sub(/:latest\z/, '')
    matched = models.find do |name|
      name == bare_configured || name.sub(/:latest\z/, '') == bare_configured
    end
    return [matched, models] if matched

    [models.first, models]
  end

  def self.ai_ollama_build_messages(team, message)
    history = ai_ollama_team_history(team)
    relay_context = ai_ollama_parse_relay_message(message)
    user_message = relay_context[:message]
    messages = [
      {
        role: 'system',
        content: "You are assisting team #{team}. Reply to the user's actual message only. Do not repeat metadata, do not explain the transport wrapper, and do not answer system/context lines. Keep replies concise, plain text, and useful for an in-world relay."
      }
    ]

    if relay_context[:metadata].any?
      messages << {
        role: 'system',
        content: "Second Life relay metadata:\n#{relay_context[:metadata].join("\n")}"
      }
    end

    if ENABLE_SECOND_LIFE_CHAT_CONTEXT
      second_life_log = ai_ollama_second_life_log_context
      messages << {
        role: 'system',
        content: "Second Life chat log snapshot:\n#{second_life_log}"
      }
    end

    unless history.empty?
      messages << {
        role: 'system',
        content: "Team conversation history:\n#{history}"
      }
    end
    messages << {
      role: 'user',
      content: user_message
    }
    messages
  end

  def self.ai_ollama_parse_relay_message(message)
    text = message.to_s.strip
    return { message: text, metadata: [] } unless text.start_with?('[Second Life Team Relay]')

    lines = text.split("\n")
    message_index = lines.index('Message:')
    return { message: text, metadata: [] } unless message_index

    metadata = lines[0...message_index]
    actual_message = lines[(message_index + 1)..] || []
    actual_message_text = actual_message.join("\n").strip
    actual_message_text = text if actual_message_text.empty?

    {
      message: actual_message_text,
      metadata: metadata
    }
  end

  def self.ai_ollama_extract_reply(result)
    candidates = [
      result.dig('message', 'content'),
      result['response'],
      result['content'],
      result['message']
    ]

    candidates.each do |candidate|
      text = candidate.to_s.strip
      return text unless text.empty?
    end

    done_reason = result['done_reason'].to_s.strip
    return "Model returned no text output (done_reason=#{done_reason})." unless done_reason.empty?

    'Model returned no text output. Please retry your message.'
  end

  def self.ai_ollama_no_text_reply?(reply)
    reply.to_s.start_with?('Model returned no text output')
  end

  def self.ai_ollama_generate_fallback(model_name, user_message)
    prompt = "Reply concisely and helpfully to this user message:\n#{user_message}"
    ai_ollama_post_json('/api/generate', {
                          model: model_name,
                          stream: false,
                          prompt: prompt
                        })
  end

  hash_branch 'chat' do |r|
    r.is String do |team|
      r.post do
        raw_body = r.body.read.to_s
        payload = raw_body.strip.empty? ? {} : JSON.parse(raw_body)
        message = payload['message'].to_s.strip

        if message.empty?
          response.status = 400
          next({ error: 'message is required' })
        end

        model_name, available_models = CGMFS.ai_ollama_resolved_model_name
        if model_name.nil?
          response.status = 503
          next({
            error: "no Ollama models are installed on #{OLLAMA_HTTP_ADDRESS}; run 'ollama pull #{OLLAMA_MODEL_NAME}' or set OLLAMA_MODEL to an installed model",
            configured_model: OLLAMA_MODEL_NAME,
            available_models: available_models
          })
        end

        result = CGMFS.ai_ollama_post_json('/api/chat', {
                                             model: model_name,
                                             stream: false,
                                             messages: CGMFS.ai_ollama_build_messages(team, message)
                                           })

        reply = CGMFS.ai_ollama_extract_reply(result)
        fallback_used = false
        if CGMFS.ai_ollama_no_text_reply?(reply)
          relay_context = CGMFS.ai_ollama_parse_relay_message(message)
          fallback_result = CGMFS.ai_ollama_generate_fallback(model_name, relay_context[:message])
          fallback_reply = CGMFS.ai_ollama_extract_reply(fallback_result)
          unless CGMFS.ai_ollama_no_text_reply?(fallback_reply)
            reply = fallback_reply
            fallback_used = true
          end
        end

        CGMFS.ai_ollama_append_team_log(team, message, reply)

        {
          response: reply,
          team: team,
          model: model_name,
          fallback_used: fallback_used,
          history_chars: CGMFS.ai_ollama_team_history(team).length,
          second_life_chat_context_enabled: ENABLE_SECOND_LIFE_CHAT_CONTEXT,
          second_life_chat_log_path: SECOND_LIFE_CHAT_LOG_PATH
        }
      rescue JSON::ParserError => e
        response.status = 400
        { error: "invalid JSON payload: #{e.message}" }
      rescue StandardError => e
        response.status = 500
        { error: e.message }
      end
    end
  end

  hash_branch 'history' do |r|
    r.is String do |team|
      r.get do
        {
          history: CGMFS.ai_ollama_team_history(team),
          team: team,
          second_life_chat_context_enabled: ENABLE_SECOND_LIFE_CHAT_CONTEXT,
          second_life_chat_log_path: SECOND_LIFE_CHAT_LOG_PATH
        }
      end
    end
  end
end
