require 'net/http'
require 'uri'
require 'json'

LOG_FILE = 'queries.log'
uri = URI('http://localhost:4567/generate')

loop do
  print "Enter a prompt (or type 'exit' to quit): "
  prompt = gets.chomp
  break if prompt.downcase == 'exit'

  begin
    # Send our user prompt (and max_words) to our local WEBrick server.
    request_body = { prompt: prompt }.to_json
    response = Net::HTTP.post(uri, request_body, { 'Content-Type' => 'application/json' })

    if response.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(response.body)
      puts "Response: #{response_data['response']}"

      File.open(LOG_FILE, 'a') do |file|
        file.puts "Prompt: #{prompt}"
        file.puts "Response: #{response_data['response']}"
        file.puts "-" * 40
      end
    else
      puts "Error: #{response.code} - #{response.message}"
      puts "This is likely due to a payload mismatch or an API expectation."
    end
  rescue => e
    puts "An error occurred: #{e.message}"
  end
end


####


####

require 'webrick'
require 'json'

class MarkovChainResponder
    def initialize
        @chain = Hash.new { |hash, key| hash[key] = [] }
        @start_words = []
        @end_words = []
    end

    def train(corpus)
        sentences = corpus.split(/(?<=[.!?])\s+/) # Split by sentences
        sentences.each do |sentence|
            words = sentence.split
            next if words.empty?

            @start_words << words.first
            @end_words << words.last

            words.each_cons(2) do |current_word, next_word|
                @chain[current_word] << next_word
            end
        end
    end

    def generate(prompt = nil, max_words = 50)
        current_word = prompt&.split&.last || @start_words.sample
        response = [current_word]

        (max_words - 1).times do
            break unless @chain[current_word]&.any?

            next_word = @chain[current_word].sample
            response << next_word
            current_word = next_word

            break if @end_words.include?(current_word) # Stop if we hit an end word
        end

        response.join(' ')
    end
end

# Initialize the responder and train it on text files
responder = MarkovChainResponder.new
file_path = "C:\\Users\\aylon-arlon\\AppData\\Roaming\\Firestorm_x64\\dlukeofnil_resident\\chat-2025-03-25.txt"
begin
    responder.train(File.read(file_path))
rescue => e
    puts "Error reading file #{file_path}: #{e.message}"
end

# Create a WEBrick server
server = WEBrick::HTTPServer.new(Port: 4567)

# Define the /generate endpoint
server.mount_proc '/generate' do |req, res|
    if req.request_method == 'POST'
        begin
            request_payload = JSON.parse(req.body)
            prompt = request_payload['prompt']
            max_words = request_payload['max_words'] || 50

            response_train = responder.train("#{File.read(file_path)}\n#{prompt}") if prompt.nil?
            response_text = responder.generate(prompt, max_words)
            res['Content-Type'] = 'application/json'
            res.body = { response: response_text }.to_json
        rescue => e
            res.status = 400
            res.body = { error: e.message }.to_json
        end
    else
        res.status = 405
        res.body = { error: 'Method Not Allowed' }.to_json
    end
end

# Trap interrupt signal to gracefully shut down the server
trap('INT') { server.shutdown }

# Start the server
server.start

