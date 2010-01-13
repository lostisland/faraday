require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

module Adapters
  class TestMiddleware < Faraday::TestCase
    describe "Test Middleware with simple path" do
      before :all do
        @stubs = Faraday::Adapter::Test::Stubs.new
        @conn  = Faraday::Connection.new do |builder|
          builder.adapter :test, @stubs
        end
        @stubs.get('/hello') { [200, {'Content-Type' => 'text/html'}, 'hello'] }
        @resp = @conn.get('/hello')
      end

      it "sets status" do
        assert_equal 200, @resp.status
      end

      it "sets headers" do
        assert_equal 'text/html', @resp.headers['Content-Type']
      end

      it "sets body" do
        assert_equal 'hello', @resp.body
      end
    end
  end
end
