require File.expand_path('../../helper', __FILE__)
require 'stringio'
require 'logger'

module Adapters
  class LoggerTest < Faraday::TestCase
    def setup
      @io     = StringIO.new
      @logger = Logger.new(@io)
      @logger.level = Logger::DEBUG

      @conn = Faraday.new do |b|
        b.response :logger, @logger
        b.adapter :test do |stubs|
          stubs.post('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
        end
      end
      @resp = @conn.post '/hello', 'name=Unagi', :accept => 'text/html'
    end

    def test_still_returns_output
      assert_equal 'hello', @resp.body
    end

    def test_logs_method_and_url
      assert_match "post http:/hello", @io.string
    end

    def test_logs_request_headers
      assert_match %(Accept: "text/html), @io.string
    end

    def test_logs_request_body
      assert_match %(name=Unagi), @io.string
    end

    def test_logs_response_headers
      assert_match %(Content-Type: "text/html), @io.string
    end
  end
end
