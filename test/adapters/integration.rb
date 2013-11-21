require 'forwardable'
require File.expand_path("../../helper", __FILE__)
Faraday.require_lib 'autoload'

module Adapters
  # Adapter integration tests. To use, implement two methods:
  #
  # `#adapter` required. returns a symbol for the adapter middleware name
  # `#adapter_options` optional. extra arguments for building an adapter
  module Integration
    def self.apply(base, *extra_features)
      if base.live_server?
        features = [:Common]
        features.concat extra_features
        features << :SSL if base.ssl_mode?
        features.each {|name| base.send(:include, self.const_get(name)) }
        yield if block_given?
      elsif !defined? @warned
        warn "Warning: Not running integration tests against a live server."
        warn "Start the server `ruby test/live_server.rb` and set the LIVE=1 env variable."
        @warned = true
      end
    end

    module Parallel
      def test_in_parallel
        resp1, resp2 = nil, nil

        connection = create_connection
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

    module NonParallel
      def test_no_parallel_support
        connection = create_connection
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

    module ParallelNonStreaming
      def test_callback_is_called_in_parallel_with_no_streaming_support
        resp1, resp2 = nil, nil
        streamed1, streamed2 = nil, nil

        connection = create_connection
        err = capture_warnings do
          connection.in_parallel do
            resp1, streamed1 = streaming_request(connection, :get, 'stream?a=1')
            resp2, streamed2 = streaming_request(connection, :get, 'stream?b=2', :chunk_size => 16*1024)
            assert connection.in_parallel?
            assert_nil resp1.body
            assert_nil resp2.body
            assert_equal [], streamed1
            assert_equal [], streamed2
          end
        end
        assert !connection.in_parallel?
        assert_match(/Streaming .+ not yet implemented/, err)
        opts = {:streaming? => false, :chunk_size => 16*1024}
        check_streaming_response(streamed1, opts.merge(:prefix => '{"a"=>"1"}'))
        check_streaming_response(streamed2, opts.merge(:prefix => '{"b"=>"2"}'))
      end
    end

    module Streaming
      def test_GET_streaming
        response, streamed = streaming_request(create_connection, :get, 'stream')
        check_streaming_response(streamed, :chunk_size => 16*1024)
        assert_nil response.body
      end

      def test_non_GET_streaming
        response, streamed = streaming_request(create_connection, :get, 'stream')
        check_streaming_response(streamed, :chunk_size => 16*1024)
        assert_nil response.body
      end
    end

    module NonStreaming
      def test_GET_streaming
        response, streamed = nil
        err = capture_warnings do
          response, streamed = streaming_request(create_connection, :get, 'stream')
        end
        assert_match(/Streaming .+ not yet implemented/, err)
        check_streaming_response(streamed, :streaming? => false)
        assert_equal big_string, response.body
      end

      def test_non_GET_streaming
        response, streamed = nil
        err = capture_warnings do
          response, streamed = streaming_request(create_connection, :get, 'stream')
        end
        assert_match(/Streaming .+ not yet implemented/, err)

        check_streaming_response(streamed, :streaming? => false)
        assert_equal big_string, response.body
      end
    end

    module Compression
      def test_GET_handles_compression
        res = get('echo_header', :name => 'accept-encoding')
        assert_match(/gzip;.+\bdeflate\b/, res.body)
      end
    end

    module SSL
      def test_GET_ssl_fails_with_bad_cert
        ca_file = 'tmp/faraday-different-ca-cert.crt'
        conn = create_connection(:ssl => {:ca_file => ca_file})
        err = assert_raises Faraday::SSLError do
          conn.get('/ssl')
        end
        assert_includes err.message, "certificate"
      end
    end

    module Common
      extend Forwardable
      def_delegators :create_connection, :get, :head, :put, :post, :patch, :delete, :run_request

      def test_GET_retrieves_the_response_body
        assert_equal 'get', get('echo').body
      end

      def test_GET_send_url_encoded_params
        assert_equal %(get ?{"name"=>"zack"}), get('echo', :name => 'zack').body
      end

      def test_GET_retrieves_the_response_headers
        response = get('echo')
        assert_match(/text\/plain/, response.headers['Content-Type'], 'original case fail')
        assert_match(/text\/plain/, response.headers['content-type'], 'lowercase fail')
      end

      def test_GET_handles_headers_with_multiple_values
        assert_equal 'one, two', get('multi').headers['set-cookie']
      end

      def test_GET_with_body
        response = get('echo') do |req|
          req.body = {'bodyrock' => true}
        end
        assert_equal %(get {"bodyrock"=>"true"}), response.body
      end

      def test_GET_sends_user_agent
        response = get('echo_header', {:name => 'user-agent'}, :user_agent => 'Agent Faraday')
        assert_equal 'Agent Faraday', response.body
      end

      def test_GET_ssl
        expected = self.class.ssl_mode?.to_s
        assert_equal expected, get('ssl').body
      end

      def test_POST_send_url_encoded_params
        assert_equal %(post {"name"=>"zack"}), post('echo', :name => 'zack').body
      end

      def test_POST_send_url_encoded_nested_params
        resp = post('echo', 'name' => {'first' => 'zack'})
        assert_equal %(post {"name"=>{"first"=>"zack"}}), resp.body
      end

      def test_POST_retrieves_the_response_headers
        assert_match(/text\/plain/, post('echo').headers['content-type'])
      end

      def test_POST_sends_files
        resp = post('file') do |req|
          req.body = {'uploaded_file' => Faraday::UploadIO.new(__FILE__, 'text/x-ruby')}
        end
        assert_equal "file integration.rb text/x-ruby #{File.size(__FILE__)}", resp.body
      end

      def test_PUT_send_url_encoded_params
        assert_equal %(put {"name"=>"zack"}), put('echo', :name => 'zack').body
      end

      def test_PUT_send_url_encoded_nested_params
        resp = put('echo', 'name' => {'first' => 'zack'})
        assert_equal %(put {"name"=>{"first"=>"zack"}}), resp.body
      end

      def test_PUT_retrieves_the_response_headers
        assert_match(/text\/plain/, put('echo').headers['content-type'])
      end

      def test_PATCH_send_url_encoded_params
        assert_equal %(patch {"name"=>"zack"}), patch('echo', :name => 'zack').body
      end

      def test_OPTIONS
        resp = run_request(:options, 'echo', nil, {})
        assert_equal 'options', resp.body
      end

      def test_HEAD_retrieves_no_response_body
        assert_equal '', head('echo').body
      end

      def test_HEAD_retrieves_the_response_headers
        assert_match(/text\/plain/, head('echo').headers['content-type'])
      end

      def test_DELETE_retrieves_the_response_headers
        assert_match(/text\/plain/, delete('echo').headers['content-type'])
      end

      def test_DELETE_retrieves_the_body
        assert_equal %(delete), delete('echo').body
      end

      def test_timeout
        conn = create_connection(:request => {:timeout => 1, :open_timeout => 1})
        assert_raises Faraday::Error::TimeoutError do
          conn.get '/slow'
        end
      end

      def test_connection_error
        assert_raises Faraday::Error::ConnectionFailed do
          get 'http://localhost:4'
        end
      end

      def test_proxy
        proxy_uri = URI(ENV['LIVE_PROXY'])
        conn = create_connection(:proxy => proxy_uri)

        res = conn.get '/echo'
        assert_equal 'get', res.body

        unless self.class.ssl_mode?
          # proxy can't append "Via" header for HTTPS responses
          assert_match(/:#{proxy_uri.port}$/, res['via'])
        end
      end

      def test_proxy_auth_fail
        proxy_uri = URI(ENV['LIVE_PROXY'])
        proxy_uri.password = 'WRONG'
        conn = create_connection(:proxy => proxy_uri)

        err = assert_raises Faraday::Error::ConnectionFailed do
          conn.get '/echo'
        end

        unless self.class.ssl_mode? && self.class.jruby?
          # JRuby raises "End of file reached" which cannot be distinguished from a 407
          assert_equal %{407 "Proxy Authentication Required "}, err.message
        end
      end

      def test_empty_body_response_represented_as_blank_string
        response = get('204')
        assert_equal '', response.body
      end

      def adapter
        raise NotImplementedError.new("Need to override #adapter")
      end

      # extra options to pass when building the adapter
      def adapter_options
        []
      end

      def create_connection(options = {})
        if adapter == :default
          builder_block = nil
        else
          builder_block = Proc.new do |b|
            b.request :multipart
            b.request :url_encoded
            b.adapter adapter, *adapter_options
          end
        end

        server = self.class.live_server
        url = '%s://%s:%d' % [server.scheme, server.host, server.port]

        options[:ssl] ||= {}
        options[:ssl][:ca_file] ||= ENV['SSL_FILE']

        Faraday::Connection.new(url, options, &builder_block).tap do |conn|
          conn.headers['X-Faraday-Adapter'] = adapter.to_s
          adapter_handler = conn.builder.handlers.last
          conn.builder.insert_before adapter_handler, Faraday::Response::RaiseError
        end
      end

      def streaming_request(connection, method, path, options={})
        streamed = []
        response = connection.send(method, path) do |req|
          req.on_data = Proc.new{|*args| streamed << args}
        end

        [response, streamed]
      end

      def check_streaming_response(streamed, options={})

      end
    end
  end
end
