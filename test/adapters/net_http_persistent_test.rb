require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase

    def adapter() :net_http_persistent end

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
