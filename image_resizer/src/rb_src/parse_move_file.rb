#!/usr/bin/env ruby
# filepath: c:\BashAssetFinal\rust\bash-asset-engine\src\THE-META_GAME-Magi-Tek_Tek-Magi-Engiane\move_script.rb

require 'fileutils'

def parse_move_instructions(instructions)
  instructions.each_line do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')

    # Expect pattern: "<type> from <source> to <destination>"
    type, from_keyword, source, to_keyword, destination = line.split(' ', 5)
    unless from_keyword == 'from' && to_keyword == 'to'
      puts "Invalid instruction format: #{line}"
      next
    end
    if %w[file folder].include?(type)
      FileUtils.mv(source, destination)
      puts "Moved #{type} from #{source} to #{destination}"
    else
      puts "Unknown move type: #{type}"
    end
  end
end

def parse_move_file(path)
  content = File.read(path)
  parse_move_instructions(content)
end

def parse_move_file_s(input)
  parse_move_instructions(input)
end

if __FILE__ == $0
  if ARGV.size < 1
    puts 'Usage: ruby move_script.rb <instructions_file>'
    exit 1
  end
  parse_move_file(ARGV[0])
end
