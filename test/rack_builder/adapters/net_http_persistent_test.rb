require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/net_http_persistent'

module RackBuilderAdapters
  class NetHttpPersistentTest < Faraday::RackBuilderTestCase

    def adapter() :net_http_persistent end

    Faraday::Integration.apply(self, :NonParallel) do
      # https://github.com/drbrain/net-http-persistent/issues/33
      undef :test_timeout
    end
  end
end

