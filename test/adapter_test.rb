require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class AdapterTest < Faraday::TestCase
  before do
    @connection = Faraday::Connection.new(LIVE_SERVER)
  end

  Faraday::Adapter.loaded_adapters.each do |adapter|
    describe "#delete with #{adapter} adapter" do
      before do
        @connection.extend adapter
      end

      it "retrieves the response body with YajlResponse" do
        @connection.response_class = Faraday::Response::YajlResponse
        assert_equal({'deleted' => true},
          @connection.delete('delete_me').body)
      end
    end

    describe "#put with #{adapter} adapter" do
      before do
        @connection.extend adapter
      end

      it "sends params" do
        assert_equal 'hello zack', @connection.put('hello', 'name' => 'zack').body
      end

      it "retrieves the response body with YajlResponse" do
        @connection.response_class = Faraday::Response::YajlResponse
        assert_equal({'name' => 'zack'},
          @connection.put('echo_name', 'name' => 'zack').body)
      end
    end

    describe "#post with #{adapter} adapter" do
      before do
        @connection.extend adapter
      end

      it "sends params" do
        assert_equal 'hello zack', @connection.post('hello', 'name' => 'zack').body
      end

      it "retrieves the response body with YajlResponse" do
        @connection.response_class = Faraday::Response::YajlResponse
        assert_equal({'name' => 'zack'},
          @connection.post('echo_name', 'name' => 'zack').body)
      end
    end

    describe "#get with #{adapter} adapter" do
      before do
        @connection.extend adapter
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
