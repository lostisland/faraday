require 'rubygems'
require 'context'
if ENV['LEFTRIGHT']
  require 'leftright'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'faraday'

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end

module Faraday
  class TestCase < Test::Unit::TestCase
    LIVE_SERVER = case ENV['LIVE']
      when /^http/ then ENV['LIVE']
      when nil     then nil
      else 'http://localhost:4567'
    end
  end
end
