#!/usr/bin/env ruby
# Second Life Chat Analytics - Sample Data Version
# Takes hardcoded Second Life chat data and generates prettified JSON analytics.

require 'time'
require 'json'

# Sample chat log data (embedded)
CHAT_DATA = [
  {avatar_id: "8c1af389-8954-414d-9686-f599b466bddc", avatar_name: "Vanharrow Resident", captured_by: "aritywolf", message: "tossed to this plane by the council of valkyries for daring to question", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772460111, x_pos: 67.4942, y_pos: 172.4569, z_pos: 26.08847},
  {avatar_id: "8c1af389-8954-414d-9686-f599b466bddc", avatar_name: "Vanharrow Resident", captured_by: "aritywolf", message: "So I venture forth from the forest of ancient valour now and then", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772460183, x_pos: 67.4942, y_pos: 172.4569, z_pos: 26.08847},
  {avatar_id: "ea95fefd-d8c9-49d4-a364-bc827a3e4197", avatar_name: "Gretsdum Resident", captured_by: "aritywolf", message: "hey mccarp", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772460309, x_pos: 67.4942, y_pos: 172.4569, z_pos: 26.08847},
  {avatar_id: "9f23e6a9-6e15-4ddc-9282-e1892798a19a", avatar_name: "mcarp Mavendorf", captured_by: "aritywolf", message: "moo", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772460338, x_pos: 67.4942, y_pos: 172.4569, z_pos: 26.08847},
  {avatar_id: "8ed8b37e-885f-4219-f11e-b83bf1d929c8", avatar_name: "Actors' N Bracelet v1.0", captured_by: "aritywolf", message: "Hello, Avatar!", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772461400, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668},
  {avatar_id: "d5ff3724-1164-47bc-84b5-ae4be5514595", avatar_name: "ArityWolf Resident", captured_by: "aritywolf", message: "test", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772461573, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668},
  {avatar_id: "9f23e6a9-6e15-4ddc-9282-e1892798a19a", avatar_name: "mcarp Mavendorf", captured_by: "aritywolf", message: "pass", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772461581, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668},
  {avatar_id: "4661b637-b6eb-40d8-925a-d1b78c2ce414", avatar_name: "KintariusPyromancer Resident", captured_by: "aritywolf", message: "test", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772463054, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668},
  {avatar_id: "ea95fefd-d8c9-49d4-a364-bc827a3e4197", avatar_name: "Gretsdum Resident", captured_by: "aritywolf", message: "hahaha", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772463180, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668},
  {avatar_id: "ea95fefd-d8c9-49d4-a364-bc827a3e4197", avatar_name: "Gretsdum Resident", captured_by: "aritywolf", message: "Rhux.  you writing new script of epic failure or just testing anyone is online?", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772463209, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668},
  {avatar_id: "4661b637-b6eb-40d8-925a-d1b78c2ce414", avatar_name: "KintariusPyromancer Resident", captured_by: "aritywolf", message: "just a script that links to my server", sim_name: "Ivory Tower Library of Primitives Table", timestamp: 1772463222, x_pos: 69.28927, y_pos: 177.4904, z_pos: 26.02668}
]

log_entries = CHAT_DATA

puts "Loaded #{log_entries.length} chat events from sample data."

# Deduplicate by avatar_id + timestamp + message
unique_events = {}
log_entries.each do |e|
  next unless e.is_a?(Hash)
  key = [e[:avatar_id], e[:timestamp], e[:message]]
  unique_events[key] ||= e
end

events = unique_events.values
puts "After deduplication: #{events.length} unique events.\n\n"

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

# Build comprehensive JSON analytics
analytics_json = {
  metadata: {
    generated_at: Time.now.utc.iso8601,
    script_version: '1.0',
    platform: 'Second Life',
    total_unique_events: events.length,
    date_range: {
      oldest: events.map { |e| e[:timestamp] }.compact.min,
      oldest_iso8601: events.map { |e| e[:timestamp] }.compact.min&.then { |ts| Time.at(ts).utc.iso8601 },
      newest: events.map { |e| e[:timestamp] }.compact.max,
      newest_iso8601: events.map { |e| e[:timestamp] }.compact.max&.then { |ts| Time.at(ts).utc.iso8601 }
    }
  },
  summary: {
    total_messages: events.length,
    unique_speakers: events.map { |e| e[:avatar_name] }.compact.uniq.length,
    unique_avatars: events.map { |e| e[:avatar_id] }.uniq.length,
    locations: events.map { |e| e[:sim_name] }.compact.uniq.length,
    captured_by: events.map { |e| e[:captured_by] }.compact.uniq.sort
  },
  entries: pretty_entries.sort_by { |e| e[:timestamp] || 0 },
  top_speakers: events.group_by { |e| e[:avatar_name] }.map { |speaker, msgs| { speaker: speaker, message_count: msgs.length } }.sort_by { |s| -s[:message_count] }.take(10),
  frequency_analysis: {
    by_day_of_week: WEEKDAYS.map { |day| { day: day, count: weekday_freq[day] } },
    by_hour_utc: (0..23).map { |h| { hour: format('%02d', h), count: hour_freq[h] } }
  }
}

# Generate plain text report
lines = []
lines << "=" * 80
lines << 'Second Life Chat Analytics Report'
lines << "=" * 80
lines << "Generated at (UTC): #{Time.now.utc.iso8601}"
lines << "Summary: Found #{events.length} unique chat events after deduplication."
lines << ''
lines << 'Unique Speakers:'
analytics_json[:summary][:captured_by].each { |capturer| lines << "  - #{capturer}" }
lines << ''
lines << 'Entries:'

if pretty_entries.empty?
  lines << 'No entries were found in the log.'
else
  pretty_entries.sort_by { |e| e[:timestamp] || 0 }.each_with_index do |entry, idx|
    lines << "#{idx + 1}. #{entry[:english_entry]}"
  end
end

lines << ''
lines << 'Message Frequency by Day of Week:'
WEEKDAYS.each do |day|
  lines << "  #{day}: #{weekday_freq[day]} messages"
end

lines << ''
lines << 'Message Frequency by Hour (UTC):'
(0..23).each do |h|
  count = hour_freq[h]
  lines << "  #{format('%02d', h)}:00-#{format('%02d', h)}:59 UTC: #{count} messages"
end

lines << ''
lines << "Top Speakers:"
analytics_json[:top_speakers].each do |speaker|
  lines << "  #{speaker[:speaker]}: #{speaker[:message_count]} message(s)"
end

# Print plain text report
report = lines.join("\n")
puts report

# Save outputs to files
text_output = '/root/miaedscore/analytics_sample_report.txt'
json_output = '/root/miaedscore/analytics_sample_report.json'

File.write(text_output, report)
puts "\n" + "=" * 80
puts "✓ Text report saved to: #{text_output}"

File.write(json_output, JSON.pretty_generate(analytics_json))
puts "✓ JSON analytics saved to: #{json_output}"
puts "=" * 80
puts "\nPrettified JSON Analytics Output:"
puts "=" * 80
puts JSON.pretty_generate(analytics_json)
