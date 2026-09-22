# rubocop:disable Style/StringLiterals
# Use the environment variable or command line option:
# ruby -W0 -Ilib -rcgmfs -e 'CGMFS.run'
# This disables frozen string literals globally.
# Alternatively, put "# frozen_string_literal: false" at the top of each file.
# disable auto frozen strings for everything
# frozen_string_literal: false

# VERSION v0.0.1 - kejento.net edited edition
# EDITS: request_deflection(r) is disabled
require 'resolv'
require 'tzinfo'
require 'redcarpet'
require 'open-uri'
require 'date'
require 'bigdecimal'
require 'free-image'
require 'fastimage'
require 'securerandom'
require 'uri'
require 'net/http'
require 'net/https'
require 'yuicompressor'
require 'roda'
require 'roda/plugins/assets'
require 'oj' # JSON binary parser
require 'json' # JSON parser
require 'openssl'
require 'base64'
require 'fileutils'
require 'digest'
require 'bigdecimal/util'
# require 'oj'
require_relative 'logger'

require_relative 'require_dir' # for route auto-loading

LATEST_PA_VERSION = "v3.0.0+" # deprecated

require_relative "lib/partitioned_array/lib/line_db" # magnum opus of computer science

require_relative 'lib/shortened/shortened_url' # shortened url class

require_dir "./lib/dir_requires"

DEBUG = false
LOCAL = true

# mimic all json functions with oj gem
Oj.mimic_JSON
# JSON = Oj

## enable Resolv to use DNS (../views/layout.html.erb)
$dns_enabled = false # enable dns (deprecated)

# Ensure the file exists before reading
server_main_domain_name_file = "server_main_domain_name.txt"

FileUtils.touch(server_main_domain_name_file) unless File.exist?(server_main_domain_name_file)

SERVER_MAIN_DOMAIN_NAME = File.read(server_main_domain_name_file).chomp

# how to zip a file in terminal
# zip -r archive_name.zip folder_to_compress

SERVER_IP = SERVER_MAIN_DOMAIN_NAME
SERVER_IP_LOCAL = 'localhost'
DOMAIN_NAME = "https://#{SERVER_MAIN_DOMAIN_NAME}"
puts "Domain name: #{DOMAIN_NAME}"
$resolv = true # enable DNS resolution
$lockdown = false # lockdown mode (no public access to blog or gallery posts, etc)

DO_TELEGRAM_LOGGING = false # telegram logging (should get deprecated one day, and everything replaced with AJAX and server backend stuffs)

class CGMFS < Roda
  PATHS_INCLUDE_CSRF = { '/api/screens/upload' => true, '/u/shorten' => true, '/api/file/upload' => true,
                         '/api/text/upload' => true }
  PUBLIC_URL_PATH = :static
  plugin :render, escape_html: false, escape: false
  plugin :multi_route
  plugin :all_verbs
  plugin :hash_routes
  plugin :not_found
  plugin :slash_path_empty
  plugin :public
  plugin :shared_vars
  plugin :exception_page

  plugin :error_handler
  plugin :sessions, secret: 'cgmfs3748w5yuieskrhfakgejgKAYUSGDYFHKGD&*R#at3wLKSGFHgfjgklsdfgjkl'
  plugin :route_csrf, check_request_methods: ['POST'], raise: true # , :check_header => false
  # Documentation: https://roda.jeremyevans.net/rdoc/classes/Roda/RodaPlugins/Assets.html
  # https://rubydoc.info/gems/roda-cj/1.0.3/Roda/RodaPlugins/Csrf
  plugin :assets, css: ['style.css', 'prism.css'], js: ['prism.js']
  compile_assets
  plugin :json
  plugin :json_parser

  PARTITION_AMOUNT = 9 # The initial, + 1
  OFFSET = 1 # This came with the math, but you can just state the PARTITION_AMOUNT in total and not worry about the offset in the end
  DB_SIZE = 20 # Caveat: The DB_SIZE is th # Caveat: The DB_SIZE is the total # of partitions, but you subtract it by one since the first partition is 0, in code.
  PARTITION_ADDITION_AMOUNT = 2

  # @@urls.load_last_entry_from_file!
  # @@urls.load_max_partition_archive_from_file!
  # @@urls.load_partition_archive_id_from_file!

  # @@sl_db.load_last_entry_from_file!
  # @@sl_db.load_max_partition_archive_from_file!
  # @@sl_db.load_partition_archive_id_from_file!
  version_lines = File.readlines("version.txt", chomp: true)
  version = version_lines[0].to_s
  timestamp = version_lines[1].to_s

  version, timestamp = version.split(" - ", 2) if timestamp.empty? && version.include?(" - ")

  $dog_blog_version = "(v#️⃣#{version}):[ 🏗️#{timestamp} ]" # used in layout.html.erb

  @@line_db = LineDB.new

  # global database variable for future usages and for all databases currently used on this CGMFS system.
  $db = @@line_db

  @@line_db["page_views"].pad.new_table!(database_name: "page_views_database", database_table: "page_views_table")
  puts "Loading database: page_views..."

  @@line_db["urls_redir"].pad.new_table!(database_name: "urls_database", database_table: "urls_table")
  @@line_db["blog"].pad.new_table!(database_name: "blog_database", database_table: "blog_table")
  @@line_db["user_blog_database"].pad.new_table!(database_name: "user_name_database",
                                                 database_table: "user_password_table")

  @@line_db["secondlife_ai"].pad.new_table!(database_name: "secondlife_database", database_table: "secondlife_table") # database for second life ai and message logs all put together

  @@line_db["superadmin"].pad.new_table!(database_name: "superadmin_database", database_table: "superadmin_table")
  puts "Loading database: superadmin..."
  puts '...Loading blog_table.'
  @@line_db["superadmin"].pad.new_table!(database_name: 'blog_database', database_table: 'blog_table')
  puts "...Loading blog_pinned_table."
  @@line_db["superadmin"].pad.new_table!(database_name: "blog_database", database_table: "blog_pinned_table")
  puts "...Loading blog_profile_table."
  @@line_db["superadmin"].pad.new_table!(database_name: "blog_database", database_table: "blog_profile_table")
  puts "...Loading blog_statistics_table."
  @@line_db["superadmin"].pad.new_table!(database_name: "blog_database", database_table: "blog_statistics_table")
  puts "...Loading gallery_database + gallery_table."
  @@line_db["superadmin"].pad.new_table!(database_name: "gallery_database", database_table: "gallery_table")
  puts "...Loading cache system database..."
  @@line_db["superadmin"].pad.new_table!(database_name: "cache_system_database", database_table: "cache_system_table")
  puts "... Loading uwu collections system database..."
  @@line_db["superadmin"].pad.new_table!(database_name: "uwu_collections_database",
                                         database_table: "uwu_collections_table")
  puts "... Loading grid collections system database..."
  @@line_db["superadmin"].pad.new_table!(database_name: "grid_collections_database",
                                         database_table: "grid_collections_table")
  @@line_db['user_blog_database'].pad['user_name_database', 'user_password_table'].set(0) do |hash|
    hash["superadmin"] = "gUilmon#95458a"
  end
  puts "Done."

  a1 = Time.now
  @@line_db.databases.each do |db|
    a = Time.now
    puts "Loading database: #{db}..."
    puts '...Loading blog_table.'
    @@line_db[db].pad.new_table!(database_name: 'blog_database', database_table: 'blog_table')
    puts "...Loading blog_pinned_table."
    @@line_db[db].pad.new_table!(database_name: "blog_database", database_table: "blog_pinned_table")
    puts "...Loading blog_profile_table."
    @@line_db[db].pad.new_table!(database_name: "blog_database", database_table: "blog_profile_table")
    puts "...Loading blog_statistics_table."
    @@line_db[db].pad.new_table!(database_name: "blog_database", database_table: "blog_statistics_table")
    puts "...Loading gallery_database + gallery_table."
    @@line_db[db].pad.new_table!(database_name: "gallery_database", database_table: "gallery_table")
    puts "...Loading cache system database..."
    @@line_db[db].pad.new_table!(database_name: "cache_system_database", database_table: "cache_system_table")
    puts "... Loading uwu collections system database..."
    @@line_db[db].pad.new_table!(database_name: "uwu_collections_database", database_table: "uwu_collections_table")
    puts "... Loading grid collections system database..."
    @@line_db[db].pad.new_table!(database_name: "grid_collections_database", database_table: "grid_collections_table")
    puts "Done."
    b = Time.now
    puts "Time taken to load #{db}: #{b - a} seconds."
  end
  a2 = Time.now
  puts "Done loading all databases and tables!"
  puts "Time taken to load all databases: #{a2 - a1} seconds."

  puts "Lambda database: #{@@line_db.databases}"
  # @line_db[line].pad.new_table!(database_name: "blog_database", database_table: "blog_table")
  # end

  not_found do
    "error: 404"
  end
  puts "loading routed routes..."
  # load all routes in cgmfs/routes directory
  require_dir './cgmfs/routes'
  puts "loaded routes."
  route do |r|
    # log("request path: #{r.path} ; request host: #{r.host}")

    puts "hash routes: #{r.hash_routes}"
    r.public
    r.assets # for public assets
    r.hash_routes
  end
end
# rubocop:enable Style/StringLiterals
