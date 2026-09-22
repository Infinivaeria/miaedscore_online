# rustbyc.rb
input_file = ARGV[0]
output_ruby_file = ARGV[1]
strip_requires = ARGV.include?('--strip-requires')

# Read the list of file paths from the input file
file_paths = File.readlines(input_file).map(&:strip).reject(&:empty?)

puts "Concatenating #{file_paths} to #{output_ruby_file}"

concatenated_source = ""

file_paths.each do |file_path|
  # Read the file contents
  source = File.read(file_path)

  # Conditionally remove 'require' and 'require_relative' statements
  if strip_requires
    source = source.gsub(/^\s*require(?:_relative)?\s+.*$/, '')
  end

  # Concatenate the source code
  concatenated_source << source << "\n"
end

# Write the concatenated source to the output file
File.open(output_ruby_file, 'a') do |file|
  file.write(concatenated_source)
end

puts "Output written to #{output_ruby_file}"


