require File.expand_path('../integration', __FILE__)

module Adapters
  class Patron < Faraday::TestCase

    def adapter() :patron end

    unless jruby?
      Integration.apply(self, :NonParallel) do
        # https://github.com/toland/patron/issues/34
        undef :test_PATCH_send_url_encoded_params

        # https://github.com/toland/patron/issues/52
        undef :test_GET_with_body

        # no support for SSL peer verification
        undef :test_GET_ssl_fails_with_bad_cert if ssl_mode?
      end
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
