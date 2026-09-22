#!/usr/bin/env ruby
# Second Life Chat Analytics Script
# Analyzes Second Life chat logs stored as JSON.
# Deduplicates messages and generates frequency statistics by day of week and hour.

require 'time'
require 'json'

# Configuration
CHAT_LOG_PATH = '/root/miaedscore/tiade-maeepers-saerver-all/target/release/second_life_chat_logs.txt'

# Read chat log file
puts "Reading chat log from: #{CHAT_LOG_PATH}"
raw = File.exist?(CHAT_LOG_PATH) ? File.read(CHAT_LOG_PATH) : ''

# Parse newline-delimited JSON objects first.
log_entries = raw.each_line.filter_map do |line|
  line = line.strip
  next if line.empty?
  begin
    obj = JSON.parse(line, symbolize_names: true)
    obj.is_a?(Hash) ? obj : nil
  rescue JSON::ParserError
    nil
  end
end

# Fallback: if the file is one JSON array/object, parse it as a whole.
if log_entries.empty? && !raw.strip.empty?
  begin
    parsed = JSON.parse(raw, symbolize_names: true)
    log_entries = parsed.is_a?(Array) ? parsed : [parsed]
  rescue JSON::ParserError
    log_entries = []
  end
end

puts "Parsed #{log_entries.length} log entries."

# Deduplicate by avatar_id + timestamp + message
unique_events = {}
log_entries.each do |e|
  next unless e.is_a?(Hash)
  key = [e[:avatar_id], e[:timestamp], e[:message]]
  unique_events[key] ||= e
end

events = unique_events.values
puts "After deduplication: #{events.length} unique events."

# Frequency tables
weekday_freq = Hash.new(0)
hour_freq = Hash.new(0)
WEEKDAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

events.each do |event|
  next unless event[:timestamp]
  t = Time.at(event[:timestamp].to_i).utc
  weekday_freq[WEEKDAYS[t.wday]] += 1
  hour_freq[t.hour] += 1
end

# Pretty entries: generate human-readable sentences
pretty_entries = events.map do |e|
  ts = e[:timestamp]&.to_i
  utc_time = ts ? Time.at(ts).utc.iso8601 : 'unknown time'
  speaker = e[:avatar_name].to_s.empty? ? 'Unknown avatar' : e[:avatar_name]
  message = e[:message].to_s.empty? ? '[no message text]' : e[:message]

  {
    avatar_id: e[:avatar_id],
    avatar_name: speaker,
    message: message,
    timestamp: ts,
    timestamp_utc: ts ? Time.at(ts).utc.iso8601 : nil,
    english_entry: "#{speaker} said \"#{message}\" at #{utc_time} (UTC)."
  }
end

# Generate output report
lines = []
lines << 'Second Life Chat Analytics'
lines << "Generated at (UTC): #{Time.now.utc.iso8601}"
lines << "Summary: Found #{events.length} unique chat events after deduplication."
lines << ''
lines << 'Entries:'

if pretty_entries.empty?
  lines << 'No entries were found in the log file.'
else
  pretty_entries.each_with_index do |entry, idx|
    lines << "#{idx + 1}. #{entry[:english_entry]}"
  end
end

lines << ''
lines << 'Message Frequency by Day of Week:'
WEEKDAYS.each do |day|
  lines << "- #{day}: #{weekday_freq[day]} messages"
end

lines << ''
lines << 'Message Frequency by Hour (UTC):'
(0..23).each do |h|
  lines << "- #{format('%02d', h)}:00-#{format('%02d', h)}:59 UTC: #{hour_freq[h]} messages"
end

# Build JSON analytics
analytics_json = {
  metadata: {
    generated_at: Time.now.utc.iso8601,
    total_unique_events: events.length,
    date_range: {
      oldest: events.map { |e| e[:timestamp] }.compact.min,
      newest: events.map { |e| e[:timestamp] }.compact.max
    }
  },
  summary: {
    total_messages: events.length,
    unique_speakers: events.map { |e| e[:avatar_name] }.compact.uniq.length,
    unique_avatars: events.map { |e| e[:avatar_id] }.uniq.length
  },
  entries: pretty_entries,
  frequency_analysis: {
    by_day_of_week: WEEKDAYS.map { |day| { day: day, count: weekday_freq[day] } },
    by_hour_utc: (0..23).map { |h| { hour: format('%02d', h), count: hour_freq[h] } }
  }
}

# Print report to console
report = lines.join("\n")
puts ''
puts report

# Save plain text report
output_file = '/root/miaedscore/analytics_report.txt'
File.write(output_file, report)
puts "\nReport saved to: #{output_file}"

# Save JSON analytics
json_output_file = '/root/miaedscore/analytics_report.json'
File.write(json_output_file, JSON.pretty_generate(analytics_json))
puts "JSON analytics saved to: #{json_output_file}"

# Also output JSON to console
puts "\n" + "="*80
puts "JSON ANALYTICS OUTPUT:"
puts "="*80
puts JSON.pretty_generate(analytics_json)
