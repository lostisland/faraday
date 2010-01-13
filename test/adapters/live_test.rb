require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

if Faraday::TestCase::LIVE_SERVER
  module Adapters
    class LiveTest < Faraday::TestCase
      Faraday::Adapter.all_loaded_constants.each do |adapter|
        describe "with #{adapter} adapter" do
          before do
            @connection = Faraday::Connection.new LIVE_SERVER do
              use adapter
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
              resp = @connection.get do |req|
                req.url 'hello', 'name' => 'zack'
              end
              assert_equal('hello zack', resp.body)
            end

            it "retrieves the response headers" do
              assert_equal 'text/html', @connection.get('hello_world').headers['content-type']
            end
          end

          describe "#post" do
            it "raises on 404" do
              assert_raise(Faraday::Error::ResourceNotFound) { @connection.post('/nothing') }
            end

            it "send url-encoded params" do
              resp = @connection.post do |req|
                req.url 'echo_name'
                req.body = {'name' => 'zack'}
              end
              assert_equal %("zack"), resp.body
            end

            it "send url-encoded nested params" do
              resp = @connection.post do |req|
                req.url 'echo_name'
                req.body = {'name' => {'first' => 'zack'}}
              end
              assert_equal %({"first"=>"zack"}), resp.body
            end

            it "retrieves the response headers" do
              assert_equal 'text/html', @connection.post('echo_name').headers['content-type']
            end
          end

          # http://github.com/toland/patron/issues/#issue/9
          if ENV['FORCE'] || adapter != Faraday::Adapter::Patron
            describe "#put" do
              it "raises on 404" do
                assert_raise(Faraday::Error::ResourceNotFound) { @connection.put('/nothing') }
              end

              it "send url-encoded params" do
                resp = @connection.put do |req|
                  req.url 'echo_name'
                  req.body = {'name' => 'zack'}
                end
                assert_equal %("zack"), resp.body
              end

              it "send url-encoded nested params" do
                resp = @connection.put do |req|
                  req.url 'echo_name'
                  req.body = {'name' => {'first' => 'zack'}}
                end
                assert_equal %({"first"=>"zack"}), resp.body
              end

              it "retrieves the response headers" do
                assert_equal 'text/html', @connection.put('echo_name').headers['content-type']
              end
            end
          end

          # http://github.com/pauldix/typhoeus/issues#issue/7
          if ENV['FORCE'] || adapter != Faraday::Adapter::Typhoeus
            describe "#head" do
              it "raises on 404" do
                assert_raise(Faraday::Error::ResourceNotFound) { @connection.head('/nothing') }
              end

              it "send url-encoded params" do
                resp = @connection.head do |req|
                  req.url 'hello', 'name' => 'zack'
                end
                assert_equal 'text/html', resp.headers['content-type']
              end

              it "retrieves no response body" do
                assert_equal '', @connection.head('hello_world').body.to_s
              end

              it "retrieves the response headers" do
                assert_equal 'text/html', @connection.head('hello_world').headers['content-type']
              end
            end
          end

          describe "#delete" do
            it "raises on 404" do
              assert_raise(Faraday::Error::ResourceNotFound) { @connection.delete('/nothing') }
            end

            it "retrieves the response headers" do
              assert_equal 'text/html', @connection.delete('delete_with_json').headers['content-type']
            end

            it "retrieves the body" do
              assert_match /deleted/, @connection.delete('delete_with_json').body
            end
          end

          describe "async requests" do
            it "clears parallel manager after running a single request" do
              assert !@connection.in_parallel?
              resp = @connection.get('hello_world')
              assert !@connection.in_parallel?
              assert_equal 'hello world', @connection.get('hello_world').body
            end

            it "uses parallel manager to run multiple json requests" do
              resp1, resp2 = nil, nil

              @connection.in_parallel(adapter.setup_parallel_manager) do
                resp1 = @connection.get('json')
                resp2 = @connection.get('json')
                if adapter.supports_parallel_requests?
                  assert @connection.in_parallel?
                  assert_nil resp1.body
                  assert_nil resp2.body
                end
              end
              assert !@connection.in_parallel?
              assert_equal '[1,2,3]', resp1.body
              assert_equal '[1,2,3]', resp2.body
            end
          end
        end
      end
    end
  end
end