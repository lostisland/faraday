require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase

    def adapter() :net_http_persistent end

    Integration.apply(self, :NonParallel) do
      def setup
        if defined?(Net::HTTP::Persistent)
          # work around problems with mixed SSL certificates
          # https://github.com/drbrain/net-http-persistent/issues/45
          http = Net::HTTP::Persistent.new('Faraday')
          http.ssl_cleanup(4)
        end
      end if ssl_mode?
    end

  end
end
