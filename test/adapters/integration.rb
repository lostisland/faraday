require 'forwardable'
require File.expand_path("../../helper", __FILE__)
require File.expand_path("../../shared", __FILE__)
Faraday.require_lib 'autoload'

module Adapters
  # Adapter integration tests. To use, implement two methods:
  #
  # `#adapter` required. returns a symbol for the adapter middleware name
  # `#adapter_options` optional. extra arguments for building an adapter
  module Integration
    def self.apply(base, *extra_features)
      if base.live_server
        features = [:Common]
        features.concat extra_features
        features << :SSL if base.ssl_mode?
        features.each { |name| base.send(:include, self.const_get(name)) }
        yield if block_given?
      elsif !defined? @warned
        warn "Warning: Not running integration tests against a live server."
        warn "Start the server `ruby test/live_server.rb` and set the LIVE=1 env variable."
        warn "See CONTRIBUTING for usage."
        @warned = true
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
            resp2, streamed2 = streaming_request(connection, :get, 'stream?b=2', :chunk_size => 16 * 1024)
            assert connection.in_parallel?
            assert_nil resp1.body
            assert_nil resp2.body
            assert_equal [], streamed1
            assert_equal [], streamed2
          end
        end
        assert !connection.in_parallel?
        assert_match(/Streaming .+ not yet implemented/, err)
        opts = { :streaming? => false, :chunk_size => 16 * 1024 }
        check_streaming_response(streamed1, opts.merge(:prefix => '{"a"=>"1"}'))
        check_streaming_response(streamed2, opts.merge(:prefix => '{"b"=>"2"}'))
      end
    end

    module NonStreaming
      include Faraday::Shared

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
          response, streamed = streaming_request(create_connection, :post, 'stream')
        end

        assert_match(/Streaming .+ not yet implemented/, err)

        check_streaming_response(streamed, :streaming? => false)
        assert_equal big_string, response.body
      end
    end

    module SSL
      def test_GET_ssl_fails_with_bad_cert
        ca_file = 'tmp/faraday-different-ca-cert.crt'
        conn = create_connection(:ssl => { :ca_file => ca_file })
        err = assert_raises Faraday::SSLError do
          conn.get('/ssl')
        end
        assert_includes err.message, "certificate"
      end
    end

    module Common
      extend Forwardable
      def_delegators :create_connection, :get, :head, :put, :post, :patch, :delete, :run_request

      def adapter
        raise NotImplementedError.new("Need to override #adapter")
      end

      # extra options to pass when building the adapter
      def adapter_options
        []
      end

      def create_connection(options = {}, &optional_connection_config_blk)
        if adapter == :default
          builder_block = nil
        else
          builder_block = Proc.new do |b|
            b.request :multipart
            b.request :url_encoded
            b.adapter adapter, *adapter_options, &optional_connection_config_blk
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
    end
  end
end
