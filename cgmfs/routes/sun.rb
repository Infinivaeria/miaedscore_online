class SunPhase2
  attr_reader :name, :start_hour, :emoji

  def initialize(name, start_hour, emoji)
    @name = name
    @start_hour = start_hour
    @emoji = emoji
  end
end

class SolarDance2
  PHASES = [
    SunPhase2.new('Midnight Mystery', 0, '🌑'),
    SunPhase2.new('Dawn\'s Whisper', 3, '🌅'),
    SunPhase2.new('First Light’s Murmur', 5, '🔅'),
    SunPhase2.new('Golden Awakening', 6, '☀️'),
    SunPhase2.new('Morning Glow', 8, '🌞'),
    SunPhase2.new('High Noon Radiance', 12, '🔥'),
    SunPhase2.new('Afternoon Brilliance', 15, '🌇'),
    SunPhase2.new('Golden Hour Serenade', 17, '🌆'),
    SunPhase2.new('Twilight Poetry', 18, '🌒'),
    SunPhase2.new('Dusky Secrets', 19, '🌓'),
    SunPhase2.new('Crimson Horizon', 20, '🌔'),
    SunPhase2.new('Moon\'s Ascent', 21, '🌕'),
    SunPhase2.new('Nightfall\'s Caress', 22, '✨'),
    SunPhase2.new('Deep Celestial Silence', 23, '🌌'),
    SunPhase2.new('Cosmic Slumber', 24, '🌠')
  ]

  def self.current_phase
    pst_hour = Time.now.getlocal('-08:00').hour # Pacific Standard Time (PST)
    PHASES.reverse.find { |phase| pst_hour >= phase.start_hour }
  end

  def self.sun_dance_message
    phase = current_phase
    "The Sun is currently in \"#{phase.name}\" phase! #{phase.emoji}"
  end
end

class CGMFS
  hash_branch 'sun' do |r|
    r.on do
      # family_logged_in?(r) # -- TEMP FAILSAFE (v9.0.0.1)
      r.get do
        response['Content-Type'] = 'text/html; charset=utf-8'
        "#{SolarDance2.sun_dance_message}"
      end
    end
  end
end
