require File.expand_path('../integration', __FILE__)

module Adapters
  class HttpclientTest < Faraday::TestCase

    def adapter() :httpclient end

    Integration.apply(self, :NonParallel) do
      def setup
        require 'httpclient' unless defined?(HTTPClient)
        HTTPClient::NO_PROXY_HOSTS.delete('localhost')
      end

      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end
    end
  end
end
