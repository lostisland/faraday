require File.expand_path("../../helper", __FILE__)

module Adapters
  # Adapter integration tests. To use, implement two methods:
  #
  # `#adapter` required. returns a symbol for the adapter middleware name
  # `#adapter_options` optional. extra arguments for building an adapter
  module Integration
    def self.included(base)
      if Faraday::TestCase::LIVE_SERVER
        base.send(:include, Common)
      end
    end

    module Parallel
      if Faraday::TestCase::LIVE_SERVER
        def test_in_parallel
          resp1, resp2 = nil, nil

          connection = create_connection(adapter)
          connection.in_parallel do
            resp1 = connection.get('echo?a=1')
            resp2 = connection.get('echo?b=2')
            assert connection.in_parallel?
            assert_nil resp1.body
            assert_nil resp2.body
          end
          assert !connection.in_parallel?
          assert_equal 'get ?{"a"=>"1"}', resp1.body
          assert_equal 'get ?{"b"=>"2"}', resp2.body
        end
      end
    end

    module NonParallel
      if Faraday::TestCase::LIVE_SERVER
        def test_no_parallel_support
          connection = create_connection(adapter)
          response = nil

          err = capture_warnings do
            connection.in_parallel do
              response = connection.get('echo').body
            end
          end
          assert response
          assert_match "no parallel-capable adapter on Faraday stack", err
          assert_match __FILE__, err
        end
      end
    end

    module Common
      def test_GET_retrieves_the_response_body
        assert_equal 'hello world', create_connection(adapter).get('hello_world').body
      end

      def test_GET_send_url_encoded_params
        resp = create_connection(adapter).get do |req|
          req.url 'hello', 'name' => 'zack'
        end
        assert_equal('hello zack', resp.body)
      end

      def test_GET_retrieves_the_response_headers
        response = create_connection(adapter).get('hello_world')
        assert_match(/text\/html/, response.headers['Content-Type'], 'original case fail')
        assert_match(/text\/html/, response.headers['content-type'], 'lowercase fail')
      end

      def test_POST_send_url_encoded_params
        resp = create_connection(adapter).post do |req|
          req.url 'echo_name'
          req.body = {'name' => 'zack'}
        end
        assert_equal %("zack"), resp.body
      end

      def test_POST_send_url_encoded_nested_params
        resp = create_connection(adapter).post do |req|
          req.url 'echo_name'
          req.body = {'name' => {'first' => 'zack'}}
        end
        assert_equal %({"first"=>"zack"}), resp.body
      end

      def test_POST_retrieves_the_response_headers
        assert_match(/text\/html/, create_connection(adapter).post('echo_name').headers['content-type'])
      end

      def test_POST_sends_files
        resp = create_connection(adapter).post do |req|
          req.url 'file'
          req.body = {'uploaded_file' => Faraday::UploadIO.new(__FILE__, 'text/x-ruby')}
        end
        assert_equal "file integration.rb text/x-ruby", resp.body
      end

      def test_PUT_send_url_encoded_nested_params
        resp = create_connection(adapter).put do |req|
          req.url 'echo_name'
          req.body = {'name' => {'first' => 'zack'}}
        end
        assert_equal %({"first"=>"zack"}), resp.body
      end

      def test_OPTIONS
        resp = create_connection(adapter).run_request(:options, '/options', nil, {})
        assert_equal "hi", resp.body
      end

      def test_HEAD_send_url_encoded_params
        resp = create_connection(adapter).head do |req|
          req.url 'hello', 'name' => 'zack'
        end
        assert_match(/text\/html/, resp.headers['content-type'])
      end

      def test_HEAD_retrieves_no_response_body
        assert_equal '', create_connection(adapter).head('hello_world').body.to_s
      end

      def test_HEAD_retrieves_the_response_headers
        assert_match(/text\/html/, create_connection(adapter).head('hello_world').headers['content-type'])
      end

      def test_DELETE_retrieves_the_response_headers
        assert_match(/text\/html/, create_connection(adapter).delete('delete_with_json').headers['content-type'])
      end

      def test_DELETE_retrieves_the_body
        assert_match(/deleted/, create_connection(adapter).delete('delete_with_json').body)
      end

      def adapter
        raise NotImplementedError.new("Need to override #adapter")
      end

      # extra options to pass when building the adapter
      def adapter_options
        nil
      end

      def create_connection(adapter, options = {})
        if adapter == :default
          builder_block = nil
        else
          builder_block = Proc.new do |b|
            b.request :multipart
            b.request :url_encoded
            b.adapter adapter, *adapter_options
          end
        end

        Faraday::Connection.new(Faraday::TestCase::LIVE_SERVER, options, &builder_block).tap do |conn|
          conn.headers['X-Faraday-Adapter'] = adapter.to_s
          adapter_handler = conn.builder.handlers.last
          conn.builder.insert_before adapter_handler, Faraday::Response::RaiseError
        end
      end
    end
  end
end