require 'rubygems'
require 'bundler'
Bundler.setup

require File.expand_path('../test/live_server', __FILE__)
run Sinatra::Application
