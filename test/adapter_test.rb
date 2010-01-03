require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class AdapterTest < Faraday::TestCase
  before do
    @connection = Faraday::Connection.new(LIVE_SERVER)
  end

  Faraday::Adapter.loaded_adapters.each do |adapter|
    describe "#get with #{adapter} adapter" do
      before do
        @connection.extend adapter
      end

      it "passes params" do
        @connection.params = {:a => 1}
        assert_equal "params[:a] == 1", @connection.get('params').body
      end

      it "passes headers" do
        @connection.headers = {"X-Test" => 1}
        assert_equal "env[HTTP_X_TEST] == 1", @connection.get('headers').body
      end

      it "retrieves the response body" do
        assert_equal 'hello world', @connection.get('hello_world').body
      end

      it "retrieves the response body with YajlResponse" do
        @connection.response_class = Faraday::Response::YajlResponse
        assert_equal [1,2,3], @connection.get('json').body
      end

      it "retrieves the response headers" do
        assert_equal 'text/html', @connection.get('hello_world').headers['content-type']
      end
    end

    describe "async requests" do
      before do
        @connection.extend adapter
      end

      it "clears parallel manager after running a single request" do
        assert !@connection.in_parallel?
        resp = @connection.get('hello_world')
        assert !@connection.in_parallel?
        assert_equal 'hello world', @connection.get('hello_world').body
      end

      it "uses parallel manager to run multiple json requests" do
        resp1, resp2 = nil, nil

        @connection.response_class = Faraday::Response::YajlResponse
        @connection.in_parallel do
          resp1 = @connection.get('json')
          resp2 = @connection.get('json')
          assert @connection.in_parallel?
          if adapter.supports_async?
            assert_nil resp1.body
            assert_nil resp2.body
          end
        end
        assert !@connection.in_parallel?
        assert_equal [1,2,3], resp1.body
        assert_equal [1,2,3], resp2.body
      end
    end
  end
end
