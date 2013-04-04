require File.expand_path('../integration', __FILE__)

module Adapters
  class TyphoeusTest < Faraday::TestCase

    def adapter() :typhoeus end

    Integration.apply(self, :Parallel) do
      # https://github.com/dbalatero/typhoeus/issues/75
      undef :test_GET_with_body

      # Not a Typhoeus bug, but WEBrick inability to handle "100-continue"
      # which libcurl seems to generate for this particular request:
      undef :test_POST_sends_files

      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end

      def test_GET_ssl_rejects_bad_hosts
        original_ssl_file = ENV['SSL_FILE']
        begin
          ENV['SSL_FILE'] = 'tmp/faraday-different-ca-cert.crt'
          conn = create_connection
          expected = ''
          response = conn.get('/ssl')
          assert_equal expected, response.body
        ensure
          ENV['SSL_FILE'] = original_ssl_file
        end
      end if ssl_mode?

    end unless jruby?
  end
end

