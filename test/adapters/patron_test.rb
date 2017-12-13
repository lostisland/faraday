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

      def test_custom_adapter_config
        adapter = Faraday::Adapter::Patron.new do |session|
          session.max_redirects = 10
        end

        session = adapter.create_session

        assert_equal 10, session.max_redirects
      end

      def test_connection_timeout
        conn = create_connection(:request => {:timeout => 10, :open_timeout => 1})
        assert_raises Faraday::Error::ConnectionFailed do
          conn.get 'http://8.8.8.8:88'
        end
      end
    end
  end
end
