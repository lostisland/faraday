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

LIVE_SERVER = case ENV['LIVE']
  when /^http/ then ENV['LIVE']
  when nil     then nil
  else 'http://127.0.0.1:4567'
end

if LIVE_SERVER
  at_exit do
    exit_code = if defined?(::MiniTest)
      MiniTest::Unit.new.run(ARGV)
    else
      Test::Unit::AutoRunner.run
    end

    # Sinatra ends its set.
    if pid = `ps -A -o pid,command | grep [l]ive_server`.split(' ').first.to_i
      Process.kill 'KILL', pid
    end

    exit exit_code
  end

  system 'ruby test/live_server.rb &'
end

module Faraday
  class TestCase < Test::Unit::TestCase
    LIVE_SERVER = ::LIVE_SERVER

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
  end
end

require 'webmock/test_unit'
WebMock.disable_net_connect!(:allow => Faraday::TestCase::LIVE_SERVER)
