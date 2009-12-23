require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class AdapterTest < Faraday::TestCase
  before do
    @connection = Faraday::Connection.new(LIVE_SERVER)
  end

  Faraday::Adapter.loaded_adapters.each do |adapter|
    describe "with #{adapter} adapter" do
      before do
        @connection.extend adapter
      end

      describe "#delete" do
        it "retrieves the response body with YajlResponse" do
          @connection.response_class = Faraday::Response::YajlResponse
          assert_equal({'deleted' => true},
            @connection.delete('delete_with_json').body)
        end
        
        it "send url-encoded params" do
          assert_equal('foobar', @connection.delete('delete_with_params', 'deleted' => 'foobar').body)
        end
      end

      describe "#put" do
        it "sends params" do
          assert_equal 'hello zack', @connection.put('hello', 'name' => 'zack').body
        end

        it "retrieves the response body with YajlResponse" do
          @connection.response_class = Faraday::Response::YajlResponse
          assert_equal({'name' => 'zack'},
            @connection.put('echo_name', 'name' => 'zack').body)
        end
      end

      describe "#post" do
        it "sends params" do
          assert_equal 'hello zack', @connection.post('hello', 'name' => 'zack').body
        end

        it "retrieves the response body with YajlResponse" do
          @connection.response_class = Faraday::Response::YajlResponse
          assert_equal({'name' => 'zack'},
            @connection.post('echo_name', 'name' => 'zack').body)
        end
      end

      describe "#get" do
        it "raises on 404" do
          assert_raise(Faraday::Error::ResourceNotFound) { @connection.get('/nothing') }
        end
        it "retrieves the response body" do
          assert_equal 'hello world', @connection.get('hello_world').body
        end

        it "send url-encoded params" do
          assert_equal('hello zack', @connection.get('hello', 'name' => 'zack').body)
        end

        it "retrieves the response body with YajlResponse" do
          @connection.response_class = Faraday::Response::YajlResponse
          assert_equal [1,2,3], @connection.get('json').body
        end

        it "retrieves the response headers" do
          assert_equal 'text/html', @connection.get('hello_world').headers['content-type']
        end
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
