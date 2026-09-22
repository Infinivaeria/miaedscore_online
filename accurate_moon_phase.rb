
# Define a method to calculate the Julian Day Number for a given date
def julian_day(year, month, day)
  a = (14 - month) / 12
  y = year + 4800 - a
  m = month + 12 * a - 3
  return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
end

# Define a method to calculate the moon phase for a given date
def moon_phase(year, month, day)
  # Calculate the Julian Day Number for the given date
  jd = julian_day(year, month, day)

  # Calculate the number of days since the last new moon
  days_since_new_moon = (jd - 2451550.1) % 29.53058867

  # Calculate the current moon phase as an index from 0 to 7
  current_phase_index = (days_since_new_moon / 3.691812).round

  # Define an array of emoji representing the different moon phases
  moon_phases = ["🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"]

  # Return the emoji representing the current moon phase
  return moon_phases[current_phase_index]
end

# Example usage:
puts moon_phase(2023, 8, 14) # 🌔
