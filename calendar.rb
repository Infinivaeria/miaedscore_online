require 'date'

# Get the current date in the Gregorian calendar
current_date = Date.today

# Convert the current date to the Julian calendar
julian_date = current_date.strftime('%j').to_i

# Print the Julian calendar for the current month
julian_calendar = <<~CALENDAR
  #{current_date.strftime('%B %Y')}
  Su Mo Tu We Th Fr Sa
  #{'   ' * current_date.strftime('%w').to_i}#{(1..31).map { |day| day.to_s.rjust(2) }.join(' ')}
CALENDAR

puts julian_calendar
