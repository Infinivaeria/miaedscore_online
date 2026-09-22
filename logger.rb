def log(text, filename: 'log.txt')
  File.open(filename, 'a') do |f|
    f.puts "#{text}"
  end
end
