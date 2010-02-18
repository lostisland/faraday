require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helper'))

if Faraday::TestCase::LIVE_SERVER
  module Adapters
    class LiveTest < Faraday::TestCase
      Faraday::Adapter.all_loaded_constants.each do |adapter|
        define_method "setup" do
          @connection = Faraday::Connection.new LIVE_SERVER do |b|
            b.use adapter
          end
        end

        define_method "test_#{adapter}_GET_retrieves_the_response_body" do
          assert_equal 'hello world', @connection.get('hello_world').body
        end

        define_method "test_#{adapter}_GET_send_url_encoded_params" do
          resp = @connection.get do |req|
            req.url 'hello', 'name' => 'zack'
          end
          assert_equal('hello zack', resp.body)
        end

        define_method "test_#{adapter}_GET_retrieves_the_response_headers" do
          assert_equal 'text/html', @connection.get('hello_world').headers['content-type']
        end

        define_method "test_#{adapter}_POST_send_url_encoded_params" do
          resp = @connection.post do |req|
            req.url 'echo_name'
            req.body = {'name' => 'zack'}
          end
          assert_equal %("zack"), resp.body
        end

        define_method "test_#{adapter}_POST_send_url_encoded_nested_params" do
          resp = @connection.post do |req|
            req.url 'echo_name'
            req.body = {'name' => {'first' => 'zack'}}
          end
          assert_equal %({"first"=>"zack"}), resp.body
        end

        define_method "test_#{adapter}_POST_retrieves_the_response_headers" do
          assert_equal 'text/html', @connection.post('echo_name').headers['content-type']
        end

        # http://github.com/toland/patron/issues/#issue/9
        if ENV['FORCE'] || adapter != Faraday::Adapter::Patron
          define_method "test_#{adapter}_PUT_send_url_encoded_params" do
            resp = @connection.put do |req|
              req.url 'echo_name'
              req.body = {'name' => 'zack'}
            end
            assert_equal %("zack"), resp.body
          end

          define_method "test_#{adapter}_PUT_send_url_encoded_nested_params" do
            resp = @connection.put do |req|
              req.url 'echo_name'
              req.body = {'name' => {'first' => 'zack'}}
            end
            assert_equal %({"first"=>"zack"}), resp.body
          end

          define_method "test_#{adapter}_PUT_retrieves_the_response_headers" do
            assert_equal 'text/html', @connection.put('echo_name').headers['content-type']
          end
        end

        # http://github.com/pauldix/typhoeus/issues#issue/7
        if ENV['FORCE'] || adapter != Faraday::Adapter::Typhoeus
          define_method "test_#{adapter}_HEAD_send_url_encoded_params" do
            resp = @connection.head do |req|
              req.url 'hello', 'name' => 'zack'
            end
            assert_equal 'text/html', resp.headers['content-type']
          end

          define_method "test_#{adapter}_HEAD_retrieves_no_response_body" do
            assert_equal '', @connection.head('hello_world').body.to_s
          end

          define_method "test_#{adapter}_HEAD_retrieves_the_response_headers" do
            assert_equal 'text/html', @connection.head('hello_world').headers['content-type']
          end
        end

        define_method "test_#{adapter}_DELETE_retrieves_the_response_headers" do
          assert_equal 'text/html', @connection.delete('delete_with_json').headers['content-type']
        end

        define_method "test_#{adapter}_DELETE_retrieves_the_body" do
          assert_match /deleted/, @connection.delete('delete_with_json').body
        end

        define_method "test_#{adapter}_async_requests_clear_parallel_manager_after_running_a_single_request" do
          assert !@connection.in_parallel?
          resp = @connection.get('hello_world')
          assert !@connection.in_parallel?
          assert_equal 'hello world', @connection.get('hello_world').body
        end
      
        define_method "test_#{adapter}_async_requests_uses_parallel_manager_to_run_multiple_json_requests" do
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