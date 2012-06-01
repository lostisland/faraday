unless ENV['CI']
  begin
    require 'simplecov'
    SimpleCov.start do
      add_filter 'test'
    end
  rescue LoadError
  end
end

require 'test/unit'
require 'stringio'

if ENV['LEFTRIGHT']
  begin
    require 'leftright'
  rescue LoadError
    puts "Run `gem install leftright` to install leftright."
  end
end

require File.expand_path('../../lib/faraday', __FILE__)

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
      else 'http://127.0.0.1:4567'
    end

    def test_default
      assert true
    end unless defined? ::MiniTest

    def capture_warnings
      old, $stderr = $stderr, StringIO.new
      begin
        yield
        $stderr.string
      ensure
        $stderr = old
      end
    end

    def self.big_string
      kb = 1024
      (32..126).map{|i| i.chr}.cycle.take(50*kb).join
    end
    def big_string
      self.class.big_string
    end
  end
end

require 'webmock/test_unit'
WebMock.disable_net_connect!(:allow => Faraday::TestCase::LIVE_SERVER)
