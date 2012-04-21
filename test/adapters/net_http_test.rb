require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpTest < Faraday::TestCase

    def adapter() :net_http end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Integration.apply(self, *behaviors)

    def test_connection_errors_get_wrapped
      connection = Faraday.new('http://disney.com') do |b|
        b.adapter :net_http
      end

      exceptions = [
        EOFError,
        Errno::ECONNABORTED,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EINVAL,
        Net::HTTPBadResponse,
        Net::HTTPHeaderSyntaxError,
        Net::ProtocolError,
        SocketError
      ]

      exceptions << OpenSSL::SSL::SSLError if defined?(OpenSSL)

      exceptions.each do |exception_class|
        stub_request(:get, 'disney.com/hello').to_raise(exception_class)

        assert_raise(Faraday::Error::ConnectionFailed,
                     "Failed to wrap #{exception_class} exceptions") do
          connection.get('/hello')
        end
      end
    end

    def test_configure_ssl
      http = Net::HTTP.new 'disney.com', 443
      # this should not raise an error
      Faraday::Adapter::NetHttp.new.configure_ssl(http, :ssl => {:verify => true})
    end

  end
end
