require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

module Adapters
  class TestMiddleware < Faraday::TestCase
    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
      @conn  = Faraday::Connection.new do |builder|
        builder.adapter :test, @stubs
      end
      @stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
      @resp = @conn.get('/hello')
    end

    def test_middleware_with_simple_path_sets_status
      assert_equal 200, @resp.status
    end

    def test_middleware_with_simple_path_sets_headers
      assert_equal 'text/html', @resp.headers['Content-Type']
    end

    def test_middleware_with_simple_path_sets_body
      assert_equal 'hello', @resp.body
    end
  end
end
