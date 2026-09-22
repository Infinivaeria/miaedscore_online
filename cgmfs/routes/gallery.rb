# rubocop:disable Metrics/BlockLength, Layout/LineLength, Metrics/ClassLength, Metrics/MethodLength
#
require 'uri'
require 'fastimage'
require 'fileutils'
require 'tzinfo'
require 'redcarpet'
require 'json'
require 'oj'
require 'date'
require 'net/http'

class CGMFS
  def user_failcheck(username, r)
    return if @@line_db.databases.include?(username)

    # @@line_db.new_database!(username)
    # @@line_db[username].pad.new_table!(database_name: "#{username}_database", database_table: "#{username}_table")
    r.redirect "https://#{r.host}" if LOCAL
    r.redirect "https://#{r.host}" unless LOCAL
  end

  require 'time'

  # ========================================================
  # Date Formatter - Pacific Standard Time (PST) 🌍⏳
  # Prints date in "Month, Day, Year - TimeInPST" format
  # ========================================================

  def formatted_pst_time
    pst_time = Time.now.getlocal('-07:00')
    pst_time.strftime('%B, %d, %Y - %I:%M:%S %p SLT/PST')
  end

  # ========================================================
  # SunDance.rb - A whimsical solar phase tracker!
  # Models 15 daily sun phases based on Pacific Standard Time (PST).
  # ========================================================
  class ForecastByLongitude
    GRIDPOINT_FORECAST_URL = 'https://api.weather.gov/gridpoints/EKA/93,22/forecast'.freeze

    def initialize
    end

    def fetch_forecast(_lat = nil, _lon = nil)
      [
        '--- Miaedscore-Plateau, Califurnia :: Daily Forecast ---',
        print_forecast(GRIDPOINT_FORECAST_URL)
      ].compact.join("<br />\n")
    end

    def print_forecast(url)
      return 'No forecast URL provided.' unless url

      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      return "Error fetching forecast: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      periods = data.dig('properties', 'periods')

      if periods && !periods.empty?
        periods.map do |period|
          name = period['name']
          temp = "#{period['temperature']} #{period['temperatureUnit']}"
          forecast = period['shortForecast']
          "#{name}: #{temp}, #{forecast}"
        end.join("<br />\n")
      else
        'No forecast data available.'
      end
    end
  end

  class MoonPhase13
    REFERENCE_NEW_MOON = Time.utc(2000, 1, 6, 18, 14, 0)
    LUNAR_CYCLE = 29.530588853 # synodic month in days

    PHASES = [
      ['New Moon', '🌑'],
      ['Waxing Crescent I', '🌒'],
      ['Waxing Crescent II', '🌒'],
      ['First Quarter', '🌓'],
      ['Waxing Gibbous I', '🌔'],
      ['Waxing Gibbous II', '🌔'],
      ['Full Moon', '🌕'],
      ['Waning Gibbous I', '🌖'],
      ['Waning Gibbous II', '🌖'],
      ['Last Quarter', '🌗'],
      ['Waning Crescent I', '🌘'],
      ['Waning Crescent II', '🌘'],
      ['Dark Moon', '🌑']
    ]

    def initialize(time = Time.now.utc)
      @time = time
    end

    def moon_age
      days_since_new = (@time - REFERENCE_NEW_MOON) / 86_400.0
      days_since_new % LUNAR_CYCLE
    end

    def phase_index
      ((moon_age / LUNAR_CYCLE) * PHASES.length).floor
    end

    def phase
      PHASES[phase_index]
    end

    def display
      name, emoji = phase
      "🌙 Moon Phase: #{name} #{emoji}<br />
     🕒 UTC Time: #{@time}<br />
     📆 Moon Age: #{moon_age.round(2)} days<br />"
    end
  end

  # Example usage
  # MoonPhase13.new.display

  class SunPhase
    attr_reader :name, :start_hour, :emoji

    def initialize(name, start_hour, emoji)
      @name = name
      @start_hour = start_hour
      @emoji = emoji
    end
  end

  class SolarDance
    PHASES = [
      SunPhase.new('Midnight Mystery', 0, '🌑'),
      SunPhase.new('Dawn’s Whisper', 3, '🌅'),
      SunPhase.new('First Light’s Murmur', 5, '🔅'),
      SunPhase.new('Golden Awakening', 6, '☀️'),
      SunPhase.new('Morning Glow', 8, '🌞'),
      SunPhase.new('High Noon Radiance', 12, '🔥'),
      SunPhase.new('Afternoon Brilliance', 15, '🌇'),
      SunPhase.new('Golden Hour Serenade', 17, '🌆'),
      SunPhase.new('Twilight Poetry', 18, '🌒'),
      SunPhase.new('Dusky Secrets', 19, '🌓'),
      SunPhase.new('Crimson Horizon', 20, '🌔'),
      SunPhase.new('Moon’s Ascent', 21, '🌕'),
      SunPhase.new('Nightfall’s Caress', 22, '✨'),
      SunPhase.new('Deep Celestial Silence', 23, '🌌'),
      SunPhase.new('Cosmic Slumber', 24, '🌠')
    ]

    def self.current_phase
      pst_hour = Time.now.getlocal('-08:00').hour # Pacific Standard Time (PST)
      PHASES.reverse.find { |phase| pst_hour >= phase.start_hour }
    end

    def self.sun_dance_message
      phase = current_phase
      "🌞 The Sun is currently in '#{phase.name}' phase! #{phase.emoji}"
    end
  end

  # Execute SunDance
  # puts SolarDance.sun_dance_message

  class MoonPhaseDetails
    # === Constants and Definitions ===

    # Average length of a full lunar cycle (in days)
    MOON_CYCLE_DAYS = 29.53

    # The 27 fabled moon rotations with emojis:
    MOON_ROTATIONS = [
      'New Moon 🌑', # 1
      'Waxing Crescent 🌒',     # 2
      'First Quarter 🌓',       # 3
      'Waxing Gibbous 🌔',      # 4
      'Full Moon 🌕',           # 5
      'Waning Gibbous 🌖',      # 6
      'Last Quarter 🌗',        # 7
      'Waning Crescent 🌘',     # 8
      'Supermoon 🌝',           # 9
      'Blue Moon 🔵🌙',         # 10
      'Blood Moon 🩸🌙',        # 11
      'Harvest Moon 🍂🌕',      # 12
      "Hunter's Moon 🌙🔭",     # 13
      'Wolf Moon 🐺🌕',         # 14
      'Pink Moon 🌸🌕', # 15
      'Snow Moon 🌨️', # 16
      'Snow Moon Snow 🌨️❄️', # 17
      'Avian Moon 🦅', # 18
      'Avian Moon Snow 🦅❄️',    # 19
      'Skunk Moon 🦨',           # 20
      'Skunk Moon Snow 🦨❄️',    # 21
      'Cosmic Moon 🌌🌕', # 22
      'Celestial Moon 🌟🌕', # 23
      'Otter Moon 🐕🌌', # 24
      'Muskium Otter Muskium Stinky Stimky Otter Moon 🦨🌌', # 25
      'Light Elemental Moon 💡🌕', # 26
      'Dark Elemental Moon 🌑🌕' # 27

    ]
    # Define 27 corresponding species with emojis.
    SPECIES = [
      'Dogg 🐶', # New Moon
      'Folf 🦊🐺', # Waxing Crescent
      'Aardwolf 🐾',
      'Spotted Hyena 🐆',
      'Folf Hybrid 🦊✨',
      'Striped Hyena 🦓',
      'Dogg Prime 🐕⭐',
      'WolfFox 🐺🦊', # Waning Crescent
      'Brown Hyena 🦴',
      'Dogg Celestial 🐕🌟',
      'Folf Eclipse 🦊🌒',
      'Aardwolf Luminous 🐾✨',
      'Spotted Hyena Stellar 🐆⭐',
      'Folf Nova 🦊💥',
      'Brown Hyena Cosmic 🦴🌌',
      'Snow Leopard 🌨️', # New Moon
      'Snow Leopard Snow Snep 🌨️❄️',
      'Avian 🦅',
      'Avian Snow 🦅❄️',
      'Skunk 🦨',
      'Skunk Snow 🦨❄️',
      'Infini-Vaeria Graevity-Infini 🌌🐕',
      'Graevity-Infini Infini-Vaeria 🌟🐕',
      'Otter 🦦',
      'Muskium Otter Stinky Stimky 🦦🦨',
      'Light Elf 💡',
      'Light Elf Cosmic 🌑'

    ]

    # Define 27 corresponding were-forms with emojis.
    WERE_FORMS = [
      'WereDogg 🐶🌑',
      'WereFolf 🦊🌙',
      'WereAardwolf 🐾',
      'WereSpottedHyena 🐆',
      'WereFolfHybrid 🦊✨',
      'WereStripedHyena 🦓',
      'WereDoggPrime 🐕⭐',
      'WereWolfFox 🐺🦊', # Waning Crescent
      'WereBrownHyena 🦴',
      'WereDoggCelestial 🐕🌟',
      'WereFolfEclipse 🦊🌒',
      'WereAardwolfLuminous 🐾✨',
      'WereSpottedHyenaStellar 🐆⭐',
      'WereFolfNova 🦊💥', # Wolf Moon
      'WereBrownHyenaCosmic 🦴🌌', # Pink Moon
      'WereSnowLeopard 🐆❄️',
      'WereSnowLeopardSnow 🐆❄️❄️', # Pink Moon
      'WereAvian 🦅', # New Moon
      'WereAvianSnow 🦅❄️', # Pink Moon
      'WereSkunk 🦨', # New Moon
      'WereSkunkSnow 🦨❄️', # New Moon
      'WereInfiniVaeriaGraevity 🐕🌌',
      'WereGraevityInfiniInfiniVaeria 🌟🐕',
      'WereOtter 🦦',
      'WereMuskiumOtterStinkyStimky 🦦🦨',
      'WereLightElf 💡',
      'WereLightElfCosmic 🌑'
    ]

    # Each moon phase is assumed to share an equal slice of the lunar cycle.
    PHASE_COUNT  = MOON_ROTATIONS.size # 15 total phases
    PHASE_LENGTH = MOON_CYCLE_DAYS / PHASE_COUNT # Days per phase

    # === Core Function ===

    # Calculate the current moon phase details based on the given date.
    # Returns: current phase, corresponding species, corresponding were-form, and consciousness level as a string.
    # Consciousness is defined as the fraction (as a percent) given by (raw phase index / 14).
    # For example, 0/14 means 0% conscious, 7/14 means 50% conscious, 14/14 means 100%,
    # and values exceeding 14/14 represent an overcharge beyond full awareness.
    def self.current_moon_details(date)
      # Use a reference new moon date (commonly: January 6, 2000)
      reference_date = Date.new(2000, 1, 6)

      # Calculate the number of days elapsed between the provided date and the reference date.
      days_since_reference = (date - reference_date).to_f

      # Determine the current position within the lunar cycle.
      lunar_position = days_since_reference % MOON_CYCLE_DAYS

      # Compute the raw phase index (as a floating-point number).
      phase_index_raw = lunar_position / PHASE_LENGTH
      phase_index = phase_index_raw.floor

      # Calculate the consciousness percentage.
      # We use (PHASE_COUNT - 1) because our index runs from 0 to 14.
      # This yields 0% when the raw index is 0 and 100% when it reaches 14.
      # Values above 14 indicate an overcharge (i.e. above 100%).
      conscious_percentage = (phase_index_raw / (PHASE_COUNT - 1).to_f) * 100

      # Get the corresponding moon phase details.
      current_phase     = MOON_ROTATIONS[phase_index % MOON_ROTATIONS.size]
      current_species   = SPECIES[phase_index % SPECIES.size]
      current_were_form = WERE_FORMS[phase_index % WERE_FORMS.size]

      # Build a string representing the consciousness level as "X/14 (Y%)"
      consciousness_level = "#{phase_index_raw}/#{PHASE_COUNT - 1} (#{conscious_percentage}%)"

      [current_phase, current_species, current_were_form, consciousness_level, conscious_percentage, phase_index_raw]
    end

    # === HTML-Generating Functions ===

    # Returns an HTML snippet with the complete 15-phase rotation schedule.
    def self.render_full_schedule_html
      rows = ''
      MOON_ROTATIONS.each_with_index do |phase_name, index|
        rows << <<~ROW
          <tr>
            <td>#{phase_name}</td>
            <td>#{SPECIES[index]}</td>
            <td>#{WERE_FORMS[index]}</td>
          </tr>
        ROW
      end

      <<~HTML
        <div class="container">
          <h1>Complete Moon Rotation Schedule</h1>
          <table>
            <thead>
              <tr>
                <th>Moon Phase</th>
                <th>Species</th>
                <th>Were-Form</th>
              </tr>
            </thead>
            <tbody>
              #{rows}
            </tbody>
          </table>
        </div>
      HTML
    end

    # Returns an HTML snippet displaying all details for the given date.
    def self.print_details_for_date(date)
      phase, species, were_form, consciousness, consciousness_percentage, phase_index_raw = current_moon_details(date)
      "<p>
        Moon Phase: #{phase}<br />
        Species: #{species}<br />
        Were-Form: #{were_form}<br />
        Consciousness: #{consciousness}<br />
        Miade-Score/Infini-Vaeria Consciousness: #{1 - (consciousness_percentage / 100)}% (#{1 - (phase_index_raw / PHASE_COUNT - 1)}%)<br />
      </p>"
    end
  end

  # Example usage:
  # today = Date.today
  # puts MoonPhaseDetails.print_details_for_date(today)
  # puts MoonPhaseDetails.render_full_schedule_html

  # MoonPhaseDetails.print_details_for_date(Date.today)

  # === Example Usage for HTML ===

  # if __FILE__ == $0
  #   today = Date.today

  # To get HTML for the current moon phase details:
  #   current_html = render_current_moon_html(today)
  #   puts current_html

  #   # To get HTML for the complete moon rotation schedule:
  #   schedule_html = render_full_schedule_html
  #   puts schedule_html
  # end

  class Calendar
    attr_reader :date

    def initialize
      @date = Date.today
    end

    def gregorian
      @date.strftime('%m/%d/%Y')
    end

    def julian
      jd = @date.jd
      julian_date = Date.jd(jd, Date::JULIAN)
      julian_date.strftime('%m/%d/%Y')
    end

    def julian_primitive
      @date.jd
    end

    def formatted_pst_time
      pst_time = Time.now.getlocal('-07:00')
      pst_time.strftime('%B, %d, %Y - %I:%M:%S %p SLT/PST')
    end
  end

  def logged_in?(r, user)
    return if session['user']
    return if session['password']
    return if session['user'] == 'superadmin'

    r.redirect "#{domain_name(r)}/blog/login"
  end

  def image_bytes_to_num_id(user:, filename:)
    File.open("public/gallery_index/#{user}/#{filename}", 'rb') do |file|
      sum = file.read.each_byte.sum
      @sum_identifier = sum.to_i
    end
  end

  def image_bytes_to_num_id_spec_fullpath(filename: String)
    File.open("#{filename}", 'rb') do |file|
      sum = file.read.each_byte.sum
      @sum_identifier = sum.to_i
    end
  end

  def convert_ints_to_emoji(int)
    integers_string = int.to_s.split('')
    emoji_integers = integers_string.map do |integer|
      case integer
      when '0'
        '0️⃣'
      when '1'
        '1️⃣'
      when '2'
        '2️⃣'
      when '3'
        '3️⃣'
      when '4'
        '4️⃣'
      when '5'
        '5️⃣'
      when '6'
        '6️⃣'
      when '7'
        '7️⃣'
      when '8'
        '8️⃣'
      when '9'
        '9️⃣'
      end
    end
    string_integers = emoji_integers.join('')
    string_integers = "➖#{string_integers}" if int < 0
    string_integers
  end

  def domain_name(r)
    "https://#{SERVER_MAIN_DOMAIN_NAME}"
    # return "https://" + r.host
  end

  # word.encode('ASCII-8BIT', invalid: :replace, undef: :replace, replace: '')

  def private_view?(r, user)
    private = false
    if @@line_db[user].pad['blog_database', 'blog_profile_table'][0]['private_view'].nil?
      @@line_db[user].pad['blog_database', 'blog_profile_table'][0]['private_view'] = false
      @@line_db[user].pad['blog_database', 'blog_profile_table'].save_everything_to_files!
    end
    if @@line_db[user].pad['blog_database', 'blog_profile_table'][0]['private_view'] == true && session['user'] != user #  && !LOCAL # add admin access later
      # r.redirect("#{domain_name(r)}/gallery/")
      private = true
      # local_redirect = false
    end
    # elsif @@line_db[user].pad['blog_database',
    #                           'blog_profile_table'][0]['private_view'] == true && session['user'] != user && LOCAL
    # r.redirect("#{SERVER_IP_LOCAL}/gallery/") if LOCAL
    #   redirect = true
    #   local_redirect = true

    r.redirect('/404') if private
  end

  # return "https://" + r.host

  def family_logged_in?(r)
    return unless $lockdown == true
    return if session['user']
    return if session['password']
    return if session['user'] == 'superadmin'
    return if r.path == '/blog/login' # Don't redirect if already at login

    r.redirect "#{domain_name(r)}/blog/login"
  end

  def create_image_thumbnail!(image_path:, thumbnail_size:, thumbnail_path:)
    # use free-image gem
    image = FreeImage::Bitmap.open(image_path)
    thumbnail = image.make_thumbnail(thumbnail_size, true)
    extension = File.extname(image_path)
    case extension
    when '.jpg', '.jpeg'
      thumbnail.save(thumbnail_path, :jpeg)
    when '.png'
      thumbnail.save(thumbnail_path, :png)
    when '.gif'
      thumbnail.save(thumbnail_path, :gif)
    when '.bmp'
      thumbnail.save(thumbnail_path, :bmp)
    end
  end

  def resize_image!(image_path:, size:, resized_image_path:)
    # use free-image gem
    image = FreeImage::Bitmap.open(image_path)
    resized = image.make_thumbnail(size, true) # figure out a way to scale images according to dimensions and to get a best fit of what the multiplier should be in image.rescale(x,y)
    extension = File.extname(image_path)
    case extension
    when '.jpg', '.jpeg'
      resized.save(resized_image_path, :jpeg)
    when '.png'
      resized.save(resized_image_path, :png)
    when '.gif'
      resized.save(resized_image_path, :gif)
    when '.bmp'
      resized.save(resized_image_path, :bmp)
    end
  end

  def parse_tags(user:, tag_string:, r: @r)
    # parse the tags from the string
    tags = tag_string.split(', ')
    # output html that uses the user and tag_string to redirect to the tag
    output = ''
    tags.each_with_index do |tag, index|
      output << "<a href='#{domain_name(r)}/gallery/view/#{user}/tags/search/?search_tags=#{tag}'>#{tag}</a>"
      output << ', ' unless index == tags.size - 1
    end
    output
  end

  class AECalendar
    attr_reader :start_date, :year_length, :month_length

    def initialize(start_date = DateTime.new(2025, 6, 4, 0, 0, 0), month_length = 14, months_in_year = 12)
      @start_date = start_date
      @month_length = month_length
      @year_length = month_length * months_in_year
    end

    def ae_date(gregorian_date)
      days_since_start = (gregorian_date - @start_date).to_i
      ae_year = 1 + (days_since_start / @year_length)
      ae_month = 1 + ((days_since_start % @year_length) / @month_length)
      ae_day = 1 + ((days_since_start % @year_length) % @month_length)
      day_of_week = gregorian_date.strftime('%A') # Get the day name

      "AE #{ae_year}, Month #{ae_month}, Day #{ae_day} (#{day_of_week})"
    end
  end

  # Example usage
  ae_calendar = AECalendar.new
  gregorian_example = DateTime.new(2025, 7, 1)

  puts "Gregorian Date: #{gregorian_example.strftime('%Y-%m-%d (%A)')}"
  puts "AE Calendar Date: #{ae_calendar.ae_date(gregorian_example)}"

  # /gallery
  hash_branch 'gallery' do |r|
    family_logged_in?(r) if $lockdown
    @start_rendering_time = Time.now.to_f
    r.hash_branches
    @type = 'gallery'
    @r = r
    r.is do
      r.get do
        view('blog/gallery/list_gallery_users', engine: 'html.erb', layout: 'layout.html')
      end
    end
    r.on 'secondlifeapi' do
      r.get do
        view('blog/gallery/secondlifeapi', engine: 'html.erb', layout: 'layout.html')
      end
      r.post do
      end
    end

    r.on 'upload', 'url' do
      # get user session in roda
      @user = session['user']
      @title = 'Upload Image to Gallery from URL'
      logged_in?(r, @user)
      user_failcheck(@user, r)

      r.get do
        view('blog/gallery/new_url', engine: 'html.erb', layout: 'layout.html')
      end

      r.post do
        uploadable = false
        uploaded_filehandle = r.params['url']
        if uploaded_filehandle.nil? || uploaded_filehandle.strip.empty?
          next "<html><body>Upload failed. Missing URL. <a href='#{domain_name(r)}/gallery/upload/url'>Upload</a></body></html>"
        end

        description = "url upload - #{r.params['url']} - Time: #{Time.now}"
        tags = 'url_upload'
        @title = title = "url upload - #{Time.now}"

        # Code to upload an image to the gallery, with an option to introduce the upload location and retrieve via URL
        # 1. Upload the image to the server
        # 2. Save the image to the database
        # 3. Redirect to the gallery view
        # 4. Add a delete option
        # 5. Add a view option
        # 6. Add a download option
        # 7. Add a share option
        # 8. Add a comment option
        # 9. Add a like option
        # 10. Add a tag option
        # 11. Add a search option
        # 12. Add a sort option
        # 13. Add a filter option

        original_to_new_filename = "#{Time.now.to_f}_url_upload_#{@user}"
        begin
          file_contents = URI.open(uploaded_filehandle).read
        rescue StandardError
          next "<html><body>Upload failed. Could not fetch URL. <a href='#{domain_name(r)}/gallery/upload/url'>Upload</a></body></html>"
        end
        # @sum_identifier = image_bytes_to_num_id(user: @user, filename: original_to_new_filename)
        # Write the file to a temporary gallery location
        FileUtils.mkdir_p("public/gallery_index/#{@user}")
        file_path = "public/gallery_index/#{@user}/#{original_to_new_filename}"

        File.open(file_path, 'wb') do |file|
          file.write(file_contents)
        end

        file_size = file_contents.size

        file_type = FastImage.type(file_path)

        if %i[jpeg png gif].include?(file_type)
          uploadable = true
          FileUtils.mkdir_p("public/gallery_index/#{@user}")
          # Rename the file to include the extension
          file_extension = case file_type
                           when :jpeg then '.jpg'
                           when :png then '.png'
                           when :gif then '.gif'
                           else
                             ''
                           end
          # make sure to check for file extension type, and possibly return an error if not a valid image type
          file_path = "public/gallery_index/#{@user}/#{original_to_new_filename}"
          original_to_new_filename += file_extension
          new_file_path = "public/gallery_index/#{@user}/#{original_to_new_filename}"
          File.rename(file_path, new_file_path)
          @sum_identifier = image_bytes_to_num_id_spec_fullpath(filename: new_file_path)

          Thread.new do
            create_image_thumbnail!(image_path: new_file_path, thumbnail_size: 350, thumbnail_path: "public/gallery_index/#{@user}/thumbnail_#{original_to_new_filename}")
          end
          Thread.new do
            resize_image!(image_path: new_file_path, size: 1920, resized_image_path: "public/gallery_index/#{@user}/resized_#{original_to_new_filename}")
          end
        else
          uploadable = false
          # delete the file
          File.delete(file_path)
        end

        if uploadable
          id = @@line_db[@user].pad['gallery_database', 'gallery_table'].add_at_last do |hash|
            hash['file'] = original_to_new_filename
            hash['views'] = 0
            hash['title'] = title
            hash['description'] = description
            hash['downloads'] = 0
            hash['shares'] = 0
            hash['comments'] = 0
            hash['likes'] = 0
            hash['sum_identifier'] = @sum_identifier
            hash['tags'] = tags
            hash['size'] = file_size
            hash['extension'] = file_extension
            hash['date'] = TZInfo::Timezone.get('America/Los_Angeles').utc_to_local(Time.now).to_s
          end
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].set(0) do |hash|
            hash['recache'] = true
          end
          # set the id of the image to the id of the image in the database
          @@line_db[@user].pad['gallery_database', 'gallery_table'].set(id) do |hash|
            hash['id'] = id
          end
        end
        # change to more efficient form later.
        @@line_db[@user].pad['gallery_database', 'gallery_table'].save_everything_to_files! if uploadable
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{id}" if uploadable
        "<html><body>Upload failed. Please try again. <a href='#{domain_name(r)}/gallery/upload/url'>Upload</a></html></body>"
      end
    end

    r.on 'upload' do
      # get user session in roda
      @user = session['user']
      @title = 'Upload Image to Gallery'
      logged_in?(r, @user)
      user_failcheck(@user, r)

      r.get do
        @title = 'Upload Image to Gallery'
        view('blog/gallery/new', engine: 'html.erb', layout: 'layout.html')
      end

      r.post do
        # Code to upload an image to the gallery, with an option to introduce the upload location and retrieve via URL
        # 1. Upload the image to the server
        # 2. Save the image to the database
        # 3. Redirect to the gallery view
        # 4. Add a delete option
        # 5. Add a view option
        # 6. Add a download option
        # 7. Add a share option
        # 8. Add a comment option
        # 9. Add a like option
        # 10. Add a tag option
        # 11. Add a search option
        # 12. Add a sort option
        # 13. Add a filter option

        # get the image temp file parameters through roda:
        uploadable = false
        uploaded_filehandle = r.params['file']
        if uploaded_filehandle.nil? || uploaded_filehandle[:tempfile].nil?
          next "<html><body>Upload failed. Missing file input. <a href='#{domain_name(r)}/gallery/upload'>Upload</a></body></html>"
        end

        description = r.params['description'] || ''
        tags = r.params['tags'] || ''
        title = r.params['title'] || ''
        reusable_tags = r.params['reusable_tags'] || ''
        if reusable_tags == 'on'
          session['last_tags'] = tags
          session['reusable_tags'] = true
        else
          session['last_tags'] = ''
          session['reusable_tags'] = false
        end

        description = 'no description' if description.empty?
        tags = 'none' if tags.empty?
        title = 'untitled' if title.empty?
        file_extension = File.extname(uploaded_filehandle[:filename])
        original_to_new_filename = "#{@user}_#{Time.now.to_f}_original_#{file_extension}"
        uploaded_filehandle[:tempfile].rewind
        file_contents = uploaded_filehandle[:tempfile].read
        file_size = file_contents.size

        uploaded_filehandle[:tempfile].rewind
        file_type = FastImage.type(uploaded_filehandle[:tempfile])

        # list all possible file types in File.extname:
        # .jpg, .jpeg, .png, .gif, .bmp, .zip, .tar, .gz, .rar, .7z, .mp3, .wav, .flac, .ogg, .mp4, .avi, .mkv, .mov, .wmv, .flv, .webm, .pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .txt, .rtf, .html, .htm, .xml, .json, .csv, .tsv, .md, .markdown, .rb, .py, .js, .css, .scss, .sass, .less, .php, .java, .c, .cpp, .h, .hpp, .cs, .go, .swift, .kt, .kts, .rs, .pl, .sh, .bat, .exe, .dll, .so, .dylib, .app, .apk, .ipa, .deb, .rpm, .msi, .dmg, .iso, .img, .bin, .cue, .mdf, .mds, .nrg, .vcd, .toast, .dmg, .toast, .vcd, .nrg, .mds, .mdf, .cue, .bin, .img, .iso, .rpm, .msi, .deb, .ipa, .apk, .app, .dylib, .so, .dll, .exe, .bat, .sh, .pl, .rs, .kts, .kt, .swift, .go, .cs, .hpp, .h, .cpp, .c, .java, .php, .less, .sass, .scss, .css, .js, .py, .rb, .markdown, .md, .tsv, .csv, .json, .xml, .htm, .html, .rtf, .txt, .pptx, .ppt, .xlsx, .xls, .docx, .doc, .pdf, .webm, .flv, .wmv, .mov, .mkv, .avi, .mp4, .ogg, .flac, .wav, .mp3, .7z, .rar, .gz, .
        #
        if ['.jpg', '.jpeg', '.png', '.bmp', '.gif'].include?(file_extension) && %i[jpeg png gif].include?(file_type) # add .zip later, et al.
          uploadable = true
          FileUtils.mkdir_p("public/gallery_index/#{@user}")
          File.open("public/gallery_index/#{@user}/#{original_to_new_filename}", 'wb') { |file| file.write(file_contents) }

          Thread.new do
            create_image_thumbnail!(image_path: "public/gallery_index/#{@user}/#{original_to_new_filename}", thumbnail_size: 350, thumbnail_path: "public/gallery_index/#{@user}/thumbnail_#{original_to_new_filename}")
          end

          Thread.new do
            resize_image!(image_path: "public/gallery_index/#{@user}/#{original_to_new_filename}", size: 1920, resized_image_path: "public/gallery_index/#{@user}/resized_#{original_to_new_filename}")
          end
        else
          uploadable = false
        end

        if uploadable

          @sum_identifier = image_bytes_to_num_id(user: @user, filename: original_to_new_filename)
          id = @@line_db[@user].pad['gallery_database', 'gallery_table'].add_at_last do |hash|
            hash['file'] = original_to_new_filename
            hash['views'] = 0
            hash['title'] = title
            hash['description'] = description
            hash['downloads'] = 0
            hash['shares'] = 0
            hash['comments'] = 0
            hash['likes'] = 0
            hash['sum_identifier'] = @sum_identifier
            hash['tags'] = tags
            hash['size'] = file_size
            hash['extension'] = file_extension
            hash['date'] = TZInfo::Timezone.get('America/Los_Angeles').utc_to_local(Time.now).to_s
          end
          # set the id of the image to the id of the image in the database
          @@line_db[@user].pad['gallery_database', 'gallery_table'].set(id) do |hash|
            hash['id'] = id
          end

        end
        # change to more efficient form later.
        @@line_db[@user].pad['gallery_database', 'gallery_table'].save_everything_to_files! if uploadable
        @@line_db[@user].pad['cache_system_database', 'cache_system_table'].set(0) do |hash|
          hash['recache'] = true
        end
        @@line_db[@user].pad['cache_system_database', 'cache_system_table'].save_everything_to_files!
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}" if uploadable
        "<html><body>Upload failed. Please try again. <a href='#{domain_name(r)}/gallery/upload'>Upload</a></html></body>"
      end
    end

    r.is 'view', String, 'latest' do |user| # view the gallery list
      user_failcheck(user, r)
      private_view?(r, user)
      r.get do
        @user = user
        @title = "#{@user}'s Gallery"
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']

        @gallery_images = @gallery.data_arr.reject { |image| image == {} }

        if r.params['owo_count_rate'].nil?
          @owo_count_rate = session['owo_count_rate'] || 3
        else
          @owo_count_rate = r.params['owo_count_rate'].to_i
          session['owo_count_rate'] = @owo_count_rate
        end

        if r.params['quantity_displayed'].nil?
          @quantity_displayed = session['quantity_displayed'] || 175
        else
          @quantity_displayed = r.params['quantity_displayed'].to_i
          session['quantity_displayed'] = @quantity_displayed
        end

        if r.params['modulo_display'].nil?
          @modulo_display = session['modulo_display'] || 4
        else
          @modulo_display = r.params['modulo_display'].to_i
          session['modulo_display'] = @modulo_display
        end

        @skip_by = r.params['skip_by'].to_i
        @skip_by = 0 if r.params['skip_by'].nil?
        @gallery_numbers = @gallery_images.size / @quantity_displayed
        # log(@gallery_numbers)
        if @gallery_images.size <= @quantity_displayed
          @pages = 0
          @gallery_range = 0..@quantity_displayed
        else
          @pages = @gallery_numbers + 1

        end

        r.redirect "#{domain_name(r)}/gallery/view/#{user}?skip_by=#{@pages - 1}"
      end
    end

    r.is 'reset_session', String do |user|
      @user = user
      session['owo_count_rate'] = 3
      session['quantity_displayed'] = 175
      session['modulo_display'] = 4
      r.redirect "#{domain_name(r)}/gallery/view/#{user}"
    end

    # /gallery/view/username
    r.is 'view', String do |user| # view the gallery list
      user_failcheck(user, r)
      private_view?(r, user)

      r.get do
        @title = "View #{user}'s Gallery"

        if r.params['quantity_displayed'].nil?
          @quantity_displayed = session['quantity_displayed'] || 175
        else
          @quantity_displayed = r.params['quantity_displayed'].to_i
          session['quantity_displayed'] = @quantity_displayed
        end

        if r.params['modulo_display'].nil?
          @modulo_display = session['modulo_display'] || 4
        else
          @modulo_display = r.params['modulo_display'].to_i
          session['modulo_display'] = @modulo_display
        end

        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']

        @gallery_images = @gallery.data_arr.reject { |image| image == {} }

        @skip_by = r.params['skip_by'].to_i
        @skip_by = 0 if r.params['skip_by'].nil?
        @gallery_numbers = @gallery_images.size / @quantity_displayed
        if @gallery_images.size <= @quantity_displayed
          @pages = 0
          @gallery_range = 0..@quantity_displayed
        else
          @pages = @gallery_numbers + 1
          @gallery_range = (@quantity_displayed * @skip_by)..(@quantity_displayed + @quantity_displayed * @skip_by)
        end

        # generate pages html
        @pages_html = ''
        @pages.times do |page_number|
          if page_number == @skip_by
            @pages_html << "<a href='#{domain_name(r)}/gallery/view/#{@user}?skip_by=#{page_number}'><b><i>#{page_number}</i><b></a>&nbsp;&nbsp;"
          else
            @pages_html << "<a href='#{domain_name(r)}/gallery/view/#{@user}?skip_by=#{page_number}'>#{page_number}</a>&nbsp;&nbsp;"
          end
          @pages_html << '&nbsp;' unless page_number == @pages - 1
          @pages_html << '<br>' if page_number % 10 == 0 && page_number != 0
        end

        @gallery = @gallery_images[@gallery_range]

        @owo_count_gallery = @@line_db[@user].pad['gallery_database', 'gallery_table'].data_arr.sort_by { |image| image['owo_count'].to_i }

        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
          #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
          if hash['page_views'].nil?
            hash['page_views'] = 0
          else
            hash['page_views'] += 1
          end
          @page_views = hash['page_views']
        end
        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

        view('blog/gallery/list_gallery_uploads', engine: 'html.erb', layout: 'layout.html')
      end
    end

    r.is 'view', String, 'id', Integer do |user, id| # view the gallery entry
      user_failcheck(user, r)
      private_view?(r, user)
      r.get do
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, quote: true, strikethrough: true,
                                                                     fenced_code_blocks: true, tables: true, no_intra_emphasis: true, space_after_headers: true, superscript: true, lax_spacing: true, footnotes: true, autolink: true)
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id
        @image = @gallery.get(@id)
        @attachments = @image['attachments']
        @title = "View Gallery Post ID #{@id} by #{@user}"
        @file = @image['file']
        @r = r
        @owo = @image['owo_count']

        if @image
          @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
            #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
            if hash['page_views'].nil?
              hash['page_views'] = 0
            else
              hash['page_views'] += 1
            end
            @page_views = hash['page_views']
          end
          @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)
          # add one to page view, and save by partition:
          @image['views'] += 1
          @gallery.save_partition_by_id_to_file!(@id)

          @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
            #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
            if hash['page_views'].nil?
              hash['page_views'] = 0
            else
              hash['page_views'] += 1
            end
            @page_views = hash['page_views']
          end
          @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

          view('blog/gallery/view_user_gallery_image_id', engine: 'html.erb', layout: 'layout.html')
        else
          "No gallery post found with id #{@id}."
        end
        # r.redirect('/404') if @image.nil?
      end
    end

    r.is 'view', String, 'id', Integer, 'attachments' do |user, id| # view the attachments list
      user_failcheck(user, r)
      private_view?(r, user)
      r.get do
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id
        @image = @gallery.get(@id)
        @title = "View Attachment Id #{@id} by #{@user}"

        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
          #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
          if hash['page_views'].nil?
            hash['page_views'] = 0
          else
            hash['page_views'] += 1
          end
          @page_views = hash['page_views']
        end
        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

        view('blog/gallery/view_user_gallery_image_id_attachments_list', engine: 'html.erb', layout: 'layout.html')
      end
    end

    r.is 'view', String, 'id', Integer, 'attachments', 'delete', Integer do |user, id, attachment_id| # view the attachments list
      user_failcheck(user, r)
      r.get do
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id
        @image = @gallery.get(@id)
        @attachments = @image['attachments']
        @title = "Delete Attachment Id #{@id} by #{@user}"

        File.delete("public/gallery_index/#{@user}/attachments/#{@attachments[attachment_id]['file_attachment_name']}")
        @attachments.delete_at(attachment_id)
        @gallery.set(@id) do |hash|
          hash['attachments'] = @attachments
        end
        @gallery.save_partition_by_id_to_file!(@id)

        # "attachment deleted. <a href='#{domain_name(r)}/gallery/view/#{@user}/id/#{@id}/attachments'>Back to attachments</a>"
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{@id}/attachments"
      end
    end

    r.is 'view', String, 'id', Integer, 'attachments', 'upload' do |user, id| # view the gallery list
      user_failcheck(user, r)
      r.get do
        @user = user
        @r = r
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id
        @image = @gallery.get(@id)
        @title = "View Attachment Id #{@id} by #{@user} Upload"
        # @attachments = @image['attachments']
        # <%= domain_name(@r) %>/gallery/view/<%= @user %>/id/<%= @attachment_id %>
        view('blog/gallery/view_user_gallery_image_id_attachments_upload', engine: 'html.erb', layout: 'layout.html')
      end

      r.post do
        @user = user
        @r = r
        @url_params = r.params['url']
        @id = id
        @title = "Post Attachment to Gallery ID #{@id}"

        if @url_params && !@url_params.strip.empty?

          begin
            @uri_url = URI.open(@url_params.to_s)
          rescue StandardError
            next "<html><body>Upload failed. Invalid attachment URL. <a href='#{domain_name(r)}/gallery/view/#{@user}/id/#{@id}/attachments/upload'>Upload</a></body></html>"
          end
          @uploaded_filehandle = @uri_url.read
          @meta = @uri_url.meta['content-type']&.split('/')&.last || 'bin' # this doesn't seem to work for some urls

          @file_name = Time.now.to_f.to_s + '_attachment' + '.' + @meta

          FileUtils.mkdir_p("public/gallery_index/#{@user}/attachments")
          File.open("public/gallery_index/#{@user}/attachments/#{@file_name}", 'wb') { |file| file.write(@uploaded_filehandle) }
          @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
          @id = id
          @image = @gallery.get(@id)

          @attachments = if !@image['attachments']
                           []
                         else
                           @image['attachments']
                         end
          @attachments << { 'file_attachment_name' => @file_name, 'file_attachment_size' => @uploaded_filehandle.size, 'extension' => File.extname(@file_name), 'file_attachment_date' => TZInfo::Timezone.get('America/Los_Angeles').utc_to_local(Time.now).to_s }

          @gallery.set(@id) do |hash|
            hash['attachments'] = @attachments
          end
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].set(0) do |hash|
            hash['recache'] = true
          end
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].save_everything_to_files!

          @gallery.save_partition_by_id_to_file!(@id)

        else
          if r.params['file'].nil? || r.params['file'][:tempfile].nil?
            next "<html><body>Upload failed. Missing attachment file. <a href='#{domain_name(r)}/gallery/view/#{@user}/id/#{@id}/attachments/upload'>Upload</a></body></html>"
          end

          @uploaded_filehandle = r.params['file'][:tempfile].read
          @file_name = Time.now.to_f.to_s + '_' + r.params['file'][:filename]
          FileUtils.mkdir_p("public/gallery_index/#{@user}/attachments")
          File.open("public/gallery_index/#{@user}/attachments/#{@file_name}", 'wb') { |file| file.write(@uploaded_filehandle) }
          @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
          @id = id
          @image = @gallery.get(@id)

          @attachments = if !@image['attachments']
                           []
                         else
                           @image['attachments']
                         end
          @attachments << { 'file_attachment_name' => @file_name, 'file_attachment_size' => @uploaded_filehandle.size, 'extension' => File.extname(@file_name), 'file_attachment_date' => TZInfo::Timezone.get('America/Los_Angeles').utc_to_local(Time.now).to_s }

          @gallery.set(@id) do |hash|
            hash['attachments'] = @attachments
          end

          @gallery.save_partition_by_id_to_file!(@id)

        end
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{@id}"
      end
    end

    r.is 'delete', String, 'id', Integer do |user, id| # delete a gallery post by id
      user_failcheck(user, r)
      r.get do
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id
        @image = @gallery.get(@id)
        @title = "Delete Gallery Post ID #{@id}"
        if @image
          @gallery.data_arr[@id] = {}
          File.delete("public/gallery_index/#{@user}/#{@image['file']}")
          @gallery.save_partition_by_id_to_file!(@id)
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].set(0) do |hash|
            hash['recache'] = true
          end
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].save_everything_to_files!
          "Gallery post with id #{@id} deleted successfully. <a href='#{domain_name(r)}/gallery/view/#{@user}'>Back TO Gallery</a>"
          r.redirect "#{domain_name(r)}/gallery/view/#{@user}"
        else
          "No gallery post found with id #{@id}."
          r.redirect "#{domain_name(r)}/gallery/view/#{@user}"
        end
      end
    end

    r.is 'view', String, 'tags', 'search' do |user| # view the tags list
      user_failcheck(user, r)
      r.get do
        @only_search = false
        @search_params = r.params['search_tags']
        @user = user
        @title = "#{@user}'s Gallery Tags Search Function"
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @tags_array = []
        @images = @gallery.data_arr.map { |image| image }
        @images = @images.compact
        @tags = @images.map { |image| image['tags'] }.flatten
        @tags.each do |tag|
          next if tag.nil?

          tag.split(', ').each do |split_tag|
            @tags_array << split_tag
          end
        end
        @tags_array = @tags_array.uniq
        @images = @gallery.data_arr.map { |image| image }
        @images = @images.compact
        @image_tags = @images.map { |image| image['tags'] }
        # remove nils in tags
        @image_tags = @image_tags.reject { |tag| tag.nil? }
        if @search_params
          @search_params_set = @search_params.split(', ').compact.to_set
          # get rid of nil tags in @images_set
          @tags_to_reject = @search_params_set.select { |tag| tag.start_with?('--') }

          # remove the '--' from the tags to reject
          @tags_to_reject = @tags_to_reject.map { |tag| tag[2..-1] }

          @search_params_set.reject! { |tag| tag.start_with?('--') }
          @images_to_find = @images.select do |image|
            image['tags'] && @search_params_set.subset?(image['tags'].split(', ').to_set)
          end

          @tags_to_reject.each do |rejected_tag|
            @images_to_find = @images_to_find.reject do |image|
              image['tags']&.split(', ')&.include?(rejected_tag)
            end
          end

          @images_to_find = @images_to_find.to_a
        else
          @only_search = true
        end

        @similar_tags_set = @@line_db[@user].pad['cache_system_database', 'cache_system_table'].get(0)['similar_tags']

        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
          #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
          if hash['page_views'].nil?
            hash['page_views'] = 0
          else
            hash['page_views'] += 1
          end
          @page_views = hash['page_views']
        end
        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

        view('blog/gallery/view_user_gallery_image_tags_search', engine: 'html.erb', layout: 'layout.html')
      end
    end

    r.is 'view', String, 'tags' do |user| # view the tags list
      user_failcheck(user, r)
      r.get do
        @user = user
        @tags_array = []
        @tags_set = []
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @view_all_images_with_tags = r.params['view_all_images_with_tags']

        @title = "#{@user}'s Gallery Tags"

        @cache = @@line_db[@user].pad['cache_system_database', 'cache_system_table']

        @cache_hash = @cache.get(0)

        if @cache_hash == {}
          @recache = true
          @cache.set(0) do |hash|
            hash['recache'] = true
          end
        end

        if !@cache.get(0)['recache']
          @cache.set(0) do |hash|
            hash['recache'] = false
            @recache = false
          end

        elsif @cache.get(0)['recache']
          @recache = true
        else
          @recache = false
        end

        if @recache
          GC.start
          thread = Thread.new do
            @images = @gallery.data_arr.map { |image| image }
            @images = @images.compact
            @tags = @images.map { |image| image['tags'] }.flatten

            @similar_tags = {}

            @images.each do |image|
              next if image['tags'].nil?

              image_tags = image['tags'].split(', ')

              image_tags.each do |tag|
                @similar_tags[tag] ||= Set.new
                @images.each do |other_image|
                  next if other_image['tags'].nil?

                  other_image_tags = other_image['tags'].split(', ')
                  @similar_tags[tag].merge(other_image_tags - [tag]) if other_image_tags.include?(tag)
                end
              end
            end
            @similar_tags.each { |tag, tags| @similar_tags[tag] = tags.to_a }
            # @similar_tags.each { |tag, tags| @similar_tags[tag] = tags.uniq }

            @tags.each do |tag|
              next if tag.nil?

              tag.split(', ').each do |split_tag|
                @tags_array << split_tag
              end
            end
            @tags_array = @tags_array.uniq
            @images_set = @images.to_set
            @images_set = @images_set.reject { |image| image['tags'].nil? }

            @split_tags = @tags_array

            @split_tags.each do |tag|
              tag_quantity = @gallery.data_arr.count { |image| image['tags']&.split(', ')&.include?(tag) }
              @tags_set << "<a href='#{domain_name(@r)}/gallery/view/#{@user}/tags/search/?search_tags=#{tag}'>#{tag}(#{tag_quantity})</a>"
            end

            @cache.set(0) do |hash|
              hash['tags_set'] = @tags_set
              hash['split_tags'] = @split_tags
              hash['recache'] = false
              hash['similar_tags'] = @similar_tags
            end
            @cache.save_everything_to_files!
          end
        else
          @similar_tags = @cache.get(0)['similar_tags']
          @split_tags = @cache.get(0)['split_tags']
          @tags_set = @cache.get(0)['tags_set']
        end

        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
          #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
          if hash['page_views'].nil?
            hash['page_views'] = 0
          else
            hash['page_views'] += 1
          end
          @page_views = hash['page_views']
        end
        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

        view('blog/gallery/view_user_gallery_image_tags', engine: 'html.erb', layout: 'layout.html')
      end
    end

    # /gallery/edit/user/id/ID
    r.is 'edit', String, 'id', Integer do |user, id| # edit the gallery list
      user_failcheck(user, r)
      logged_in?(r, user)
      r.get do
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id

        @image = @gallery.get(@id)
        @title = @image['title']
        @description = @image['description']
        @tags = @image['tags']
        @file = @image['file']
        @sum_identifier = image_bytes_to_num_id(user: @user, filename: @file)

        view('blog/gallery/edit_user_gallery_image_id', engine: 'html.erb', layout: 'layout.html')
      end
      r.post do
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, quote: true, strikethrough: true,
                                                                     fenced_code_blocks: true, tables: true, no_intra_emphasis: true, space_after_headers: true, superscript: true, lax_spacing: true, footnotes: true, autolink: true)
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @id = id
        @title = r.params['title']
        @description = r.params['description']

        @tags = r.params['tags']

        @description = 'no description' if @description.empty?
        @tags = 'none' if @tags.empty?
        @title = 'untitled' if @title.empty?
        file_extension = nil

        # get the image temp file parameters through roda:
        uploadable = false
        uploaded_filehandle = r.params['file']
        if uploaded_filehandle
          file_extension = File.extname(uploaded_filehandle[:filename])
          # original_to_new_filename = "#{Time.now.to_f}_#{uploaded_filehandle[:filename]}"
          original_to_new_filename = "#{@user}_#{Time.now.to_f}_original_#{file_extension}"
          file_contents = uploaded_filehandle[:tempfile].read
          file_size = file_contents.size
          file_extension = File.extname(uploaded_filehandle[:filename])
          # list all possible file types in File.extname:
          # .jpg, .jpeg, .png, .gif, .bmp, .zip, .tar, .gz, .rar, .7z, .mp3, .wav, .flac, .ogg, .mp4, .avi, .mkv, .mov, .wmv, .flv, .webm, .pdf, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .txt, .rtf, .html, .htm, .xml, .json, .csv, .tsv, .md, .markdown, .rb, .py, .js, .css, .scss, .sass, .less, .php, .java, .c, .cpp, .h, .hpp, .cs, .go, .swift, .kt, .kts, .rs, .pl, .sh, .bat, .exe, .dll, .so, .dylib, .app, .apk, .ipa, .deb, .rpm, .msi, .dmg, .iso, .img, .bin, .cue, .mdf, .mds, .nrg, .vcd, .toast, .dmg, .toast, .vcd, .nrg, .mds, .mdf, .cue, .bin, .img, .iso, .rpm, .msi, .deb, .ipa, .apk, .app, .dylib, .so, .dll, .exe, .bat, .sh, .pl, .rs, .kts, .kt, .swift, .go, .cs, .hpp, .h, .cpp, .c, .java, .php, .less, .sass, .scss, .css, .js, .py, .rb, .markdown, .md, .tsv, .csv, .json, .xml, .htm, .html, .rtf, .txt, .pptx, .ppt, .xlsx, .xls, .docx, .doc, .pdf, .webm, .flv, .wmv, .mov, .mkv, .avi, .mp4, .ogg, .flac, .wav, .mp3, .7z, .rar, .gz, .
          #
          if ['.jpg', '.jpeg', '.png', '.bmp'].include?(file_extension) # add .zip later, et al.
            uploadable = true
            FileUtils.mkdir_p("public/gallery_index/#{@user}")
            File.open("public/gallery_index/#{@user}/#{original_to_new_filename}", 'wb') { |file| file.write(file_contents) }
            Thread.new do
              create_image_thumbnail!(image_path: "public/gallery_index/#{@user}/#{original_to_new_filename}", thumbnail_size: 255, thumbnail_path: "public/gallery_index/#{@user}/thumbnail_#{original_to_new_filename}")
            end
            Thread.new do
              resize_image!(image_path: "public/gallery_index/#{@user}/#{original_to_new_filename}", size: 1080, resized_image_path: "public/gallery_index/#{@user}/resized_#{original_to_new_filename}")
            end

            @sum_identifier = image_bytes_to_num_id(user: @user, filename: original_to_new_filename) # code later, but add a binary number adder to the image file, and then add the sum identifier to the image file, and then check the sum identifier to see if the image is the same as the original image.

          else
            uploadable = false
            # @sum_identifier = image_bytes_to_num_id(user: @user, filename: original_to_new_filename) # just to be sure!

          end
        else
          original_to_new_filename = @@line_db[@user].pad['gallery_database', 'gallery_table'].get(@id)['file']
          file_size = @@line_db[@user].pad['gallery_database', 'gallery_table'].get(@id)['size']
          file_extension = @@line_db[@user].pad['gallery_database', 'gallery_table'].get(@id)['extension']
          @sum_identifier = image_bytes_to_num_id(user: @user, filename: original_to_new_filename) # just to be sure!
        end
        if uploadable

          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].set(0) do |hash|
            hash['recache'] = true if @tags != @@line_db[@user].pad['gallery_database', 'gallery_table'].get(@id)['tags']
          end
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].save_everything_to_files!

          @@line_db[@user].pad['gallery_database', 'gallery_table'].set(@id) do |hash|
            hash['file'] = original_to_new_filename
            hash['title'] = @title
            hash['description'] = @description
            hash['tags'] = @tags
            hash['size'] = file_size
            hash['extension'] = file_extension
            hash['date'] = TZInfo::Timezone.get('America/Los_Angeles').utc_to_local(Time.now).to_s
            hash['sum_identifier'] = @sum_identifier
          end

          @gallery.save_partition_by_id_to_file!(@id)

        else
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].set(0) do |hash|
            hash['recache'] = true if @tags != @@line_db[@user].pad['gallery_database', 'gallery_table'].get(@id)['tags']
          end
          @@line_db[@user].pad['cache_system_database', 'cache_system_table'].save_everything_to_files!
          @@line_db[@user].pad['gallery_database', 'gallery_table'].set(@id) do |hash|
            # hash['file'] = original_to_new_filename
            hash['title'] = @title
            hash['description'] = @description
            hash['tags'] = @tags
            hash['size'] = file_size
            hash['extension'] = file_extension
            hash['date'] = TZInfo::Timezone.get('America/Los_Angeles').utc_to_local(Time.now).to_s
            hash['sum_identifier'] = @sum_identifier
          end
          @gallery.save_partition_by_id_to_file!(@id)

        end

        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{@id}"
      end
    end

    r.is 'uwu', 'view', String do |user| # view the collections list
      user_failcheck(user, r)
      private_view?(r, user)
      r.get do
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @collections = @collections.data_arr

        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
          #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
          if hash['page_views'].nil?
            hash['page_views'] = 0
          else
            hash['page_views'] += 1
          end
          @page_views = hash['page_views']
        end
        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

        # uwu collections has its own id in data_arr and the id of the image in the gallery that is very uwu, with a numerical ranking system
        # @collections = @collections.delete_if { |collection| collection == {} }
        view('blog/gallery/view_uwu_collections', engine: 'html.erb', layout: 'layout.html')
      end
    end

    r.is 'uwu', 'view', String, 'id', Integer do |user, id| # view the collection id
      user_failcheck(user, r)

      r.get do
        @user = user
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @id = id
        @collection = @collections.get(@id)
        @image_id = @collection['image_id']
        @images = @image_id.map { |id_map| [id_map, @gallery.get(id_map)] }

        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].set(1) do |hash|
          #  break if post_index > @@line_db[@user].pad['blog_database', 'blog_statistics_table'].latest_id - 1
          if hash['page_views'].nil?
            hash['page_views'] = 0
          else
            hash['page_views'] += 1
          end
          @page_views = hash['page_views']
        end
        @@line_db[@user].pad['blog_database', 'blog_statistics_table'].save_partition_to_file!(0)

        view('blog/gallery/view_uwu_collections_id', engine: 'html.erb', layout: 'layout.html')
      end
    end

    r.is 'uwu', 'delete', 'id', Integer do |id| # delete the collection id
      r.get do
        @user = session['user']
        @r = r
        logged_in?(@r, @user)
        # logged_in?(r, @user)
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @id = id
        @collection = @collections.get(@id)
        if @collection
          @collections.data_arr[@id] = {}
          @collections.save_partition_by_id_to_file!(@id)
          # "Collection with id #{@id} deleted successfully. <a href='#{domain_name(r)}/gallery/uwu/view/#{@user}'>Back TO Collections</a>"
          r.redirect "#{domain_name(r)}/gallery/uwu/view/#{@user}"
        else
          "No collection found with id #{@id}."
        end
      end
    end

    r.is 'uwu', 'new' do # create a new collection
      r.get do
        @user = session['user']
        @r = r
        logged_in?(@r, @user)
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @title = 'Create a new collection'
        view('blog/gallery/new_uwu_collections', engine: 'html.erb', layout: 'layout.html')
      end

      r.post do
        @user = session['user']
        @r = r
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @title = r.params['title']
        @description = r.params['description']
        @id = @collections.add do |hash|
          hash['title'] = @title
          hash['description'] = @description
          hash['image_id'] = []
        end
        @collections.save_partition_by_id_to_file!(@id)
        r.redirect "#{domain_name(@r)}/gallery/uwu/view/#{@user}"
      end
    end

    r.is 'uwu', 'edit', 'id', Integer do |id| # edit the collection id
      # user_failcheck(user, r)
      user_failcheck(session['user'], r)
      # logged_in?(r, user)
      r.get do
        @user = session['user']
        @r = r
        logged_in?(@r, @user)
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @id = id

        @collection = @collections.get(@id)
        @image_id = @collection['image_id']
        @title = @collection['title']
        @description = @collection['description']

        @images = @image_id.map { |id_map| [id_map, @gallery.get(id_map)] }

        view('blog/gallery/edit_uwu_collections_id', engine: 'html.erb', layout: 'layout.html')
      end

      r.post do
        @user = session['user']
        @r = r
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @id = id
        @collection = @collections.get(@id)
        @title = r.params['title']
        @description = r.params['description']
        @tags = r.params['tags']
        @collections.set(@id) do |hash|
          hash['title'] = @title
          hash['description'] = @description
          hash['tags'] = @tags
        end
        @collections.save_partition_by_id_to_file!(@id)
        r.redirect "#{domain_name(r)}/gallery/uwu/edit/id/#{@id}"
      end
    end

    r.is 'uwu', 'delete_image', 'uwu_id', Integer, 'gallery_id', Integer do |uwu_id, gallery_id| # delete the   collection id
      user_failcheck(session['user'], r)
      r.get do
        @user = session['user']
        @r = r
        logged_in?(@r, @user)
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @id = uwu_id
        @collection = @collections.get(@id)
        @image_id = gallery_id
        @title = 'Delete Image from Collection'
        # log(@collection)
        if @collection
          @collection['image_id'].delete(@image_id)
          @collections.save_partition_by_id_to_file!(@id)
          r.redirect("#{domain_name(r)}/gallery/uwu/edit/id/#{@id}")
        else
          "No collection found with id #{@id}."
        end
      end
    end

    r.is 'uwu', 'add_image', 'uwu_id', Integer do |uwu_id| # add to the collection
      user_failcheck(session['user'], r)
      r.post do
        @user = session['user']

        @r = r
        logged_in?(@r, @user)
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']

        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @uwu_id = uwu_id
        @collection = @collections.get(@uwu_id)
        @gallery_image_id = r.params['image_id'].to_i
        @test = @gallery.get(@gallery_image_id)
        @title = 'Add Image to Collection'
        # log(@test)
        if !@test.nil? && !@test.is_a?(Hash)
          if @collection['image_id'].nil?
            @collection['image_id'] = [@gallery_image_id]
          else
            @collection['image_id'] << @gallery_image_id
          end
          @collections.save_partition_by_id_to_file!(@uwu_id)

          r.redirect("#{domain_name(r)}/gallery/uwu/edit/id/#{@uwu_id}")
        elsif @test.is_a? Hash
          unless @test.empty?
            if @collection['image_id'].nil?
              @collection['image_id'] = [@gallery_image_id]
            else
              @collection['image_id'] << @gallery_image_id
            end
            @collections.save_partition_by_id_to_file!(@uwu_id)

            r.redirect("#{domain_name(r)}/gallery/uwu/edit/id/#{@uwu_id}")
          end
        end
        "No collection found with id #{@collection['image_id']}." if @collection['image_id'] != []
        "Empty entry detected. Add an entry that is the ID from your gallery. <a href='#{domain_name(r)}/gallery/uwu/view/#{@user}'>Back to Collections</a>"
      end
    end

    r.is 'uwu', 'delete', 'id', Integer do |id| # delete the collection id
      user_failcheck(session['user'], r)
      r.get do
        @user = session['user']
        @r = r
        logged_in?(@r, @user)
        @collections = @@line_db[@user].pad['uwu_collections_database', 'uwu_collections_table']
        @id = id
        @collection = @collections.get(@id)
        @title = 'Delete Collection'
        if @collection
          @collections.data_arr[@id] = {}
          @collections.save_partition_by_id_to_file!(@id)
          # "Collection with id #{@id} deleted successfully."
          r.redirect("#{domain_name(r)}/gallery/uwu/view/#{@user}")
        else
          "No collection found with id #{@id}."
        end
      end
    end

    r.is 'owo', 'add' do
      user_failcheck(session['user'], r)
      r.get do
        @user = session['user']
        logged_in?(r, @user)
        @image_id = r.params['image_id'].to_i
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @gallery.set(@image_id) do |hash|
          if hash['owo_count'].nil?
            hash['owo_count'] = 0
          else
            hash['owo_count'] += 1
          end
        end
        @gallery.save_partition_by_id_to_file!(@image_id)
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{@image_id}"
      end
    end

    r.is 'owo', 'rem' do
      user_failcheck(session['user'], r)
      r.get do
        @user = session['user']
        logged_in?(r, @user)
        @image_id = r.params['image_id'].to_i
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @gallery.set(@image_id) do |hash|
          hash['owo_count'] = nil
        end
        @gallery.save_partition_by_id_to_file!(@image_id)
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{@image_id}"
      end
    end

    r.is 'owo', 'sub' do
      user_failcheck(session['user'], r)
      r.get do
        @user = session['user']
        logged_in?(r, @user)
        @image_id = r.params['image_id'].to_i
        @gallery = @@line_db[@user].pad['gallery_database', 'gallery_table']
        @gallery.set(@image_id) do |hash|
          if hash['owo_count'].nil?
            hash['owo_count'] = 0
          else
            hash['owo_count'] -= 1
          end
        end
        @gallery.save_partition_by_id_to_file!(@image_id)
        r.redirect "#{domain_name(r)}/gallery/view/#{@user}/id/#{@image_id}"
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Layout/LineLength, Metrics/ClassLength, Metrics/MethodLength
