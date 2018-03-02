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

      http = adapter.send(:net_http_connection, :url => url, :request => {})
      adapter.send(:configure_request, http, {})

      assert_equal 123, http.idle_timeout
    end

    def test_caches_connections
      adapter = Faraday::Adapter::NetHttpPersistent.new
      a = adapter.send(:net_http_connection, :url => URI('https://example.com:1234/foo'), :request => {})
      b = adapter.send(:net_http_connection, :url => URI('https://example.com:1234/bar'), :request => {})
      assert_equal a.object_id, b.object_id
    end

    def test_does_not_cache_connections_for_different_hosts
      adapter = Faraday::Adapter::NetHttpPersistent.new
      a = adapter.send(:net_http_connection, :url => URI('https://example.com:1234/foo'), :request => {})
      b = adapter.send(:net_http_connection, :url => URI('https://example2.com:1234/bar'), :request => {})
      refute_equal a.object_id, b.object_id
    end
  end
end
