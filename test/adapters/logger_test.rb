require File.expand_path('../../helper', __FILE__)
require 'stringio'
require 'logger'

module Adapters
  class LoggerTest < Faraday::TestCase
    def conn(logger, logger_options={})
      rubbles = ['Barney', 'Betty', 'Bam Bam']

      Faraday.new do |b|
        b.response :logger, logger, logger_options
        b.adapter :test do |stubs|
          stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
          stubs.post('/ohai') { [200, {'Content-Type' => 'text/html'}, 'fred'] }
          stubs.post('/ohyes') { [200, {'Content-Type' => 'text/html'}, 'pebbles'] }
          stubs.get('/rubbles') { [200, {'Content-Type' => 'application/json'}, rubbles] }
        end
      end
    end

    def setup
      @io     = StringIO.new
      @logger = Logger.new(@io)
      @logger.level = Logger::DEBUG

      @conn = conn(@logger)
    end

    def test_still_returns_output
      resp = @conn.get '/hello', nil, :accept => 'text/html'
      assert_equal 'hello', resp.body
    end

    def test_logs_method_and_url
      @conn.get '/hello', nil, :accept => 'text/html'
      assert_match "get http:/hello", @io.string
    end

    def test_logs_request_headers_by_default
      @conn.get '/hello', nil, :accept => 'text/html'
      assert_match %(Accept: "text/html), @io.string
    end

    def test_logs_response_headers_by_default
      @conn.get '/hello', nil, :accept => 'text/html'
      assert_match %(Content-Type: "text/html), @io.string
    end

    def test_does_not_log_request_headers_if_option_is_false
      app = conn(@logger, :headers => { :request => false })
      app.get '/hello', nil, :accept => 'text/html'
      refute_match %(Accept: "text/html), @io.string
    end

    def test_does_log_response_headers_if_option_is_false
      app = conn(@logger, :headers => { :response => false })
      app.get '/hello', nil, :accept => 'text/html'
      refute_match %(Content-Type: "text/html), @io.string
    end

    def test_does_not_log_request_body_by_default
      @conn.post '/ohai', 'name=Unagi', :accept => 'text/html'
      refute_match %(name=Unagi), @io.string
    end

    def test_does_not_log_response_body_by_default
      @conn.post '/ohai', 'name=Toro', :accept => 'text/html'
      refute_match %(fred), @io.string
    end

    def test_log_only_request_body
      app = conn(@logger, :bodies => { :request => true })
      app.post '/ohyes', 'name=Tamago', :accept => 'text/html'
      assert_match %(name=Tamago), @io.string
      refute_match %(pebbles), @io.string
    end

    def test_log_only_response_body
      app = conn(@logger, :bodies => { :response => true })
      app.post '/ohyes', 'name=Hamachi', :accept => 'text/html'
      assert_match %(pebbles), @io.string
      refute_match %(name=Hamachi), @io.string
    end

    def test_log_request_and_response_body
      app = conn(@logger, :bodies => true)
      app.post '/ohyes', 'name=Ebi', :accept => 'text/html'
      assert_match %(name=Ebi), @io.string
      assert_match %(pebbles), @io.string
    end

    def test_log_response_body_object
      app = conn(@logger, :bodies => true)
      app.get '/rubbles', nil, :accept => 'text/html'
      assert_match %([\"Barney\", \"Betty\", \"Bam Bam\"]\n), @io.string
    end
  end
end
