require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase

    def adapter() :excon end

    Integration.apply(self, :NonParallel) do
      # https://github.com/geemus/excon/issues/126 ?
      undef :test_timeout if ssl_mode?

      # Excon lets OpenSSL::SSL::SSLError be raised without any way to
      # distinguish whether it happened because of a 407 proxy response
      undef :test_proxy_auth_fail if ssl_mode?
    end
  end
end
