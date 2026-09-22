def spiritology_moon_rotation
    lunar_cycle_days = 29 # Approximate length of lunar cycle
    total_rotations = 12 # Number of Spiritology moon rotations
    start_day = 0 # Day the Spiritology moon rotation system begins
  
    # Calculate current day since Unix epoch
    current_day = Time.now.to_i / 86400 
    days_elapsed = (current_day - start_day) % lunar_cycle_days # Days elapsed in the lunar cycle
    current_rotation = (days_elapsed * total_rotations) / lunar_cycle_days # Moon rotation index
  
    # List of Spiritology moon rotations
    moon_rotations = [
      "🌑 New Moon",
      "🌒 Crescent Moon",
      "🌓 First Quarter",
      "🌔 Waxing Gibbous",
      "🌕 Full Moon",
      "🌖 Waning Gibbous",
      "🌗 Last Quarter",
      "🌘 Crescent Waning",
      "🌕 Harvest Moon",
      "🌕 Hunter's Moon",
      "🌕 Cold Moon",
      "🌕 Flower Moon"
    ]
  
    # List of Spiritology forms
    forms = [
      "🐶 Dogg",
      "🦊 Folf",
      "🦓 Striped Hyena",
      "🐶 Dogg",
      "🦊 Folf",
      "🦓 Striped Hyena",
      "🐶 Dogg",
      "🦊 Folf",
      "🦓 Striped Hyena",
      "🐶 Dogg",
      "🦊 Folf",
      "🦓 Striped Hyena"
    ]
  
    # Get the current moon rotation and corresponding form
    current_phase = moon_rotations[current_rotation]
    current_form = forms[current_rotation]
  
    # Construct the output text
    puts "✨ Current Moon Rotation ✨  ->  #{current_phase}"
    puts "🔮 Spiritology VOID Form  ->  #{current_form}"
  end
  
  # Call the function
  spiritology_moon_rotation
  