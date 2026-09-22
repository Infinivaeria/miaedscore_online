# Require Rubyplot gem
require 'rubyplot'

# Define a function that calculates the fraction of the moon illuminated given a date
def moon_fraction(date)
  # Convert date to time in Julian centuries since January 1, 2000 at noon UTC and calculate mean anomaly of the moon, Sun, and elongation of the moon from the Sun in radians
  t, m, s, d = [(date.jd.to_f - 2451545) / 36525, 134.963 + 13.064993 * t, 357.529 + 0.98560028 * t, 93.272 + 13.229350 * t].map {|x| x * Math::PI / 180}
  
  # Calculate and return fraction of the moon in radians
  (1 + Math.cos(180 - (6.289 * Math.sin(m) + 2.100 * Math.sin(s) - 1.274 * Math.sin(2 * d - m) - 0.658 * Math.sin(2 * d) - 0.214 * Math.sin(2 * m) - 0.110 * Math.sin(d))) * Math::PI / 180) / 2
end

# Create a figure and a line graph object using Rubyplot and set data, title, labels, range, and interval using an array of dates from January 1 to December 31 of current year mapped to percentages
Rubyplot::Figure.new.add(:line).data(:moon_fullness, (Date.new(Date.today.year,1,1)..Date.new(Date.today.year,12,31)).map {|date| moon_fraction(date) * 100}).title("Moon Fullness Percentage in #{Date.today.year}").x_label("Date").y_label("Percentage").x_range([0,364]).x_interval(30).y_range([0,100]).y_interval(10).write('moon_fullness.png')
