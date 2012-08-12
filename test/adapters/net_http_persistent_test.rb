require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase

    def adapter() :net_http_persistent end

    Integration.apply(self, :NonParallel) do
      # https://github.com/drbrain/net-http-persistent/issues/33
      undef :test_timeout
    end

  end
end
