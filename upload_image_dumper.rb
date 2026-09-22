require 'uri'
require 'net/http'
require 'net/https'
# Set HTTPS to true
# Define the server URLs
login_url = 'https://hudl.ink/blog/login' # Replace with the actual login URL
base_post_url = 'https://hudl.ink/gallery/upload' # Replace with the base URL for posting files
directory_path = '/root/alldump'
# Define your credentials
username = 'stimkypawz'
password = 'gUilmon#95458a'
super_password = 'gUilmon#95458a'

file_extensions = ['.jpg', '.jpeg', '.png'] # Define the valid file extensions

tags_and_titles = [] # Initialize an array to store the tags and titles

# Iterate over each file in the directory
Dir.glob(File.join(directory_path, '*')) do |file_path|
  # Check if the file has a valid extension
  if file_extensions.include?(File.extname(file_path).downcase)
    # Extract the filename and remove the extension
    filename = File.basename(file_path, '.*')
    filename_with_extension = file_path

    # Iterate over each file in the directory

    # Check if the file has a valid extension
    if file_extensions.include?(File.extname(file_path).downcase)
      # Convert the filename to ASCII characters
      ascii_filename = File.basename(file_path).encode('ASCII-8BIT', invalid: :replace, undef: :replace, replace: '')
      ascii_file_path = File.join(File.dirname(file_path), ascii_filename)

      # Rename the file to the ASCII filename
      File.rename(file_path, ascii_file_path)

      # Update the filename with the ASCII filename
      filename = ascii_filename
      filename_with_extension = ascii_file_path

      # Remove numbers and special characters, and extract English words from the filename
      words = filename.scan(/[a-zA-Z]+/)
      words.map!(&:downcase)
      # Ensure words are ASCII
      words.map! do |word|
        word.encode('ASCII-8BIT', invalid: :replace, undef: :replace, replace: '')
      end
      # Add the tags and title to the array
      # tags_and_titles << { 'title' => filename, 'tags' => words.join(', '), 'file_path' => filename_with_extension }
    end

    filename = filename.encode('ASCII-8BIT', invalid: :replace, undef: :replace, replace: '')

    # Remove numbers and special characters, and extract English words from the filename
    words = filename.scan(/[a-zA-Z]+/)
    words.map!(&:downcase)
    # Ensure words are ASCII
    words.map! do |word|
      word.encode('ASCII-8BIT', invalid: :replace, undef: :replace, replace: '')
    end
    # Add the tags and title to the array
    tags_and_titles << { 'title' => filename, 'tags' => words.join(', '), 'file_path' => filename_with_extension }
  end
end

# Perform login and store cookies in cookies.txt
uri = URI.parse(login_url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Post.new(uri.path)

request.set_form_data({ 'blog_user_name' => username, 'blog_password_name' => password,
                        'super_password' => super_password })
response = http.request(request)
cookies = response['Set-Cookie']
remaining_files_to_upload = tags_and_titles.length
# Iterate over each file in the directory
Dir.glob(File.join(directory_path, '*')) do |file_path|
  # Check if the file has a valid extension
  if file_extensions.include?(File.extname(file_path).downcase)
    # Upload the file using curl system command
    upload_url = base_post_url
    uri = URI.parse(upload_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    request['Cookie'] = cookies
    request.set_form([
                       ['file', File.open(file_path, 'rb')],
                       ['title', tags_and_titles.find { |x| x['file_path'] == file_path }['title']],
                       ['tags', tags_and_titles.find { |x| x['file_path'] == file_path }['tags']],
                       ['description', 'no description']
                     ], 'multipart/form-data')
    begin
      response = nil
      until response && response.is_a?(Net::HTTPSuccess)
        response = http.request(request)
        p response
        sleep(1) unless response.is_a?(Net::HTTPSuccess)
      end
    rescue StandardError => e
      p "An error occurred: #{e.message}"
      retry
    end
   
    p "#{file_path} uploaded successfully"
    p remaining_files_to_upload -= 1
    sleep(0.0)
  end
end

# how do I unzip a zip file using unzip?
# how do I unzip a zip file using unzip?
