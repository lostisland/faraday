require File.expand_path('../integration', __FILE__)

require 'typhoeus/adapters/faraday'

Faraday::Adapter.register_middleware :typhoeus => :Typhoeus

module Adapters
  class TyphoeusTest < Faraday::TestCase

    def adapter() :typhoeus end

    Integration.apply(self, :Parallel) do
      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end

      # Typhoeus::Response doesn't provide an easy way to access the reason phrase,
      # so override the shared test from Common.
      def test_GET_reason_phrase
        response = get('echo')
        assert_nil response.reason_phrase
      end
    end

    def test_custom_adapter_config
      adapter = Faraday::Adapter::Typhoeus.new(nil, { :forbid_reuse => true, :maxredirs => 1 })

      request = adapter.method(:typhoeus_request).call({})

      assert_equal true, request.options[:forbid_reuse]
      assert_equal 1, request.options[:maxredirs]
    end
  end
end
