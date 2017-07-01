require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase

    def adapter() :net_http_persistent end

    Integration.apply(self, :NonParallel) do
      def setup
        if defined?(Net::HTTP::Persistent)
          # work around problems with mixed SSL certificates
          # https://github.com/drbrain/net-http-persistent/issues/45
          if Net::HTTP::Persistent.instance_method(:initialize).parameters.first == [:key, :name]
            Net::HTTP::Persistent.new(name: 'Faraday').reconnect_ssl
          else
            Net::HTTP::Persistent.new('Faraday').ssl_cleanup(4)
          end
        end
      end if ssl_mode?
    end

    def test_custom_adapter_config
      url = URI('https://example.com:1234')

      adapter = Faraday::Adapter::NetHttpPersistent.new do |http|
        http.idle_timeout = 123
      end

      http = adapter.net_http_connection(:url => url, :request => {})
      adapter.configure_request(http, {})

      assert_equal 123, http.idle_timeout
    end
  end
end
