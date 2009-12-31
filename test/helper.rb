require 'rubygems'
require 'context'
require 'ruby-debug'
if ENV['LEFTRIGHT']
  require 'leftright'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'faraday'

module Faraday
  class TestCase < Test::Unit::TestCase
    LIVE_SERVER = 'http://localhost:4567'
  end
end
