require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

module Adapters
  class TestMiddleware < Faraday::TestCase
    def setup
      @stubs = Faraday::Adapter::Test::Stubs.new
      @conn  = Faraday.new do |builder|
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

    def test_middleware_can_be_called_several_times
      assert_equal 'hello', @conn.get("/hello").body
    end

    def test_middleware_with_get_params
      @stubs.get('/param?a=1') { [200, {}, 'a'] }
      assert_equal 'a', @conn.get('/param?a=1').body
    end

    def test_middleware_ignores_unspecified_get_params
      @stubs.get('/optional?a=1') { [200, {}, 'a'] }
      assert_equal 'a', @conn.get('/optional?a=1&b=1').body
      assert_equal 'a', @conn.get('/optional?a=1').body
      assert_raise Faraday::Adapter::Test::Stubs::NotFound do
        @conn.get('/optional')
      end
    end

    def test_middleware_allow_different_outcomes_for_the_same_request
      @stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
      @stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'world'] }
      assert_equal 'hello', @conn.get("/hello").body
      assert_equal 'world', @conn.get("/hello").body
    end

    def test_yields_env_to_stubs
      @stubs.get '/hello' do |env|
        assert_equal '/hello',     env[:url].path
        assert_equal 'foo.com',    env[:url].host
        assert_equal '1',          env[:params]['a']
        assert_equal 'text/plain', env[:request_headers]['Accept']
        [200, {}, 'a']
      end

      @conn.headers['Accept'] = 'text/plain'
      assert_equal 'a', @conn.get('http://foo.com/hello?a=1').body
    end

    def test_raises_an_error_if_no_stub_is_found_for_request
      assert_raise Faraday::Adapter::Test::Stubs::NotFound do
        @conn.get('/invalid'){ [200, {}, []] }
      end
    end
  end
end
