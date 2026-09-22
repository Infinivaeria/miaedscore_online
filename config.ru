# frozen_string_literal: true

# require 'sinatra'
# require_relative './comic'
# rerun --dir cgmfs -- "puma -C config/puma-nginx.rb"
require 'rubygems'
require 'roda'
# require 'sinatra'
# In your Rack config or middleware

require 'rack'
require 'rack/brotli'

use Rack::Deflater
use Rack::Brotli, quality: 11 #, min_size: 256, max_size: 1048576 # 1MB

require File.expand_path 'cgmfs.rb', __dir__
# require "/root/comicman-remote-modular-midscore/comic.rb"

# run Rack::URLMap.new("/" => CGMFS.new,
#                    "/gallery" => ComicMan.new)
run CGMFS.freeze.app
