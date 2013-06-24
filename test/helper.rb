unless ENV['CI']
  begin
    require 'simplecov'
    SimpleCov.start do
      add_filter 'test'
      add_filter '/bundle/'
    end
  rescue LoadError
  end
end

require 'test/unit'

if ENV['LEFTRIGHT']
  begin
    require 'leftright'
  rescue LoadError
    puts "Run `gem install leftright` to install leftright."
  end
end

require File.expand_path('../../lib/faraday', __FILE__)

require 'stringio'
require 'uri'

module Faraday
  module LiveServerConfig
    def live_server=(value)
      @@live_server = case value
      when /^http/
        URI(value)
      when /./
        URI('http://127.0.0.1:4567')
      end
    end

    def live_server?
      defined? @@live_server
    end

    # Returns an object that responds to `host` and `port`.
    def live_server
      live_server? and @@live_server
    end
  end

  class TestCase < Test::Unit::TestCase
    extend LiveServerConfig
    self.live_server = ENV['LIVE']

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

    def self.jruby?
      defined? RUBY_ENGINE and 'jruby' == RUBY_ENGINE
    end

    def self.rbx?
      defined? RUBY_ENGINE and 'rbx' == RUBY_ENGINE
    end

    def self.ssl_mode?
      ENV['SSL'] == 'yes'
    end
  end
end

# The essential part of ActiveSupport::SafeBuffer to demonstrate
# how it blows up when passed to Faraday::Utils.escape
# rails/rails@ed738f7
class FakeSafeBuffer < String
  UNSAFE_STRING_METHODS = %w(gsub)

  def to_s
    self
  end

  UNSAFE_STRING_METHODS.each do |unsafe_method|
    if 'String'.respond_to?(unsafe_method)
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{unsafe_method}(*args, &block)       # def capitalize(*args, &block)
          to_str.#{unsafe_method}(*args, &block)  #   to_str.capitalize(*args, &block)
        end                                       # end
      EOT
    end
  end
end
