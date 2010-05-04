require 'rubygems'
gem 'rack',        '>= 1.0.1'
gem 'addressable', '2.1.1'

require 'test/unit'
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

    def test_default
      assert true
    end
  end
end
