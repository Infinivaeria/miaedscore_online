require 'tzinfo'


# Get the current version from the file
current_version = File.read('version.txt').strip

version_parts = current_version.split('.').map(&:to_i)

# Start from the rightmost part and move left
(version_parts.length - 1).downto(0) do |i|
  if version_parts[i] < 9
    # Increment the part and reset all parts to the right of it to 0
    version_parts[i] += 1
    ((i + 1)...version_parts.length).each { |j| version_parts[j] = 0 }
    break
  end
end

new_version = version_parts.join('.')

# Write the new version to the file
File.open('version.txt', 'w') do |file|
  file.puts new_version
end


# Get the current timestamp
puts "Current version: #{current_version}"
puts "New version: #{new_version}"

# Get the current timestamp in Pacific Time
timezone = TZInfo::Timezone.get('America/Los_Angeles')
timestamp = timezone.now.strftime('%Y-%m-%d %H:%M:%S')
puts "Timestamp: #{timestamp} Pacific Time"

# Write the new version and timestamp to the file
File.open('version.txt', 'w') do |file|
  file.puts "#{new_version}"
  file.puts "#{timestamp}"
end
