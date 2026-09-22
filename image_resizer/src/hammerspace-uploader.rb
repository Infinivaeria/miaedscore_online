require 'uri'
require 'net/http'
require 'net/https'
require 'openssl'
require 'fileutils'

LOGIN_URL = 'https://midscore.io/blog/login'
BASE_POST_URL = 'https://midscore.io/gallery/upload'
DIRECTORY_PATH = 'F:/sharex_screen-shots'
USERNAME = 'voreables'
PASSWORD = 'gUilmon#95458a'
SUPERPASSWORD = 'gUilmon#95458a'
FILE_EXTENSIONS = ['.jpg', '.jpeg', '.png']
TAGS_AND_TITLES = []

def uploader(uploaded_list_arr: [], directory_path: DIRECTORY_PATH, login_url: LOGIN_URL, base_post_url: BASE_POST_URL,
             username: USERNAME, password: PASSWORD, superpassword: SUPERPASSWORD, file_extensions: FILE_EXTENSIONS, tags_and_titles: TAGS_AND_TITLES)
  Dir.glob(File.join(directory_path, '**/*')) do |file_path|
    if File.file?(file_path) && file_extensions.include?(File.extname(file_path).downcase)
      ascii_filename = File.basename(file_path).encode('ASCII-8BIT', invalid: :replace, undef: :replace, replace: '')
      ascii_file_path = File.join(File.dirname(file_path), ascii_filename)
      tags_and_titles << {
        'title' => ascii_filename.downcase,
        'tags' => ascii_filename.downcase.scan(/[a-zA-Z]+/).join(', '),
        'file_path' => ascii_file_path
      }
    end
  end

  # Login
  uri = URI.parse(login_url)
  begin
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data({
                              'blog_user_name' => username,
                              'blog_password_name' => password,
                              'super_password' => superpassword
                            })
      response = http.request(request)
      @cookies = response['Set-Cookie']
    end
  rescue StandardError => e
    puts "tcp closed #{e.message}"
    retry
  end

  # Upload
  file_path_arr = []
  Dir.glob(File.join(directory_path, '*')) do |file_path|
    next unless file_extensions.include?(File.extname(file_path).downcase)
    next if uploaded_list_arr != [] && uploaded_list_arr.include?(file_path)

    upload_url = base_post_url
    uri = URI.parse(upload_url)
    begin
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
        request = Net::HTTP::Post.new(uri.path)
        request['Cookie'] = @cookies
        info = tags_and_titles.find { |x| x['file_path'] == file_path }
        request.set_form(
          [
            ['file', File.open(file_path, 'rb')],
            ['title', info['title']],
            ['tags', info['tags']],
            ['description', 'no description']
          ],
          'multipart/form-data'
        )
        http.request(request)

        file_path_arr << file_path
        puts "-- #{file_path} uploaded successfully"
      end
    rescue StandardError => e
      puts "tcp closed #{file_path}: #{e.message}"
      retry
    end
  end
  # puts '---- upload sequence complete'
  file_path_arr
end
