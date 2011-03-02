require 'rubygems'
require 'test/unit'

if ENV['LEFTRIGHT']
  begin
    require 'leftright'
  rescue LoadError
    puts "Run `gem install leftright` to install leftright."
  end
end

unless $LOAD_PATH.include? 'lib'
  $LOAD_PATH.unshift(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.join($LOAD_PATH.first, '..', 'lib'))
end
require 'faraday'

begin
  require 'ruby-debug'
rescue LoadError
  # ignore
else
  Debugger.start
end

module Faraday
  class TestCase < Test::Unit::TestCase
    LIVE_SERVER = case ENV['LIVE']
      when /^http/ then ENV['LIVE']
      when nil     then nil
      else 'http://localhost:4567'
    end

    def test_default
      assert true
    end
  end
end
