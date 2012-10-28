require File.expand_path("../../../adapters_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/net_http_persistent'

module RackBuilderAdapters
  class NetHttpPersistentTest < Faraday::TestCase

    def adapter() :net_http_persistent end

    alias build_connection rack_builder_connection

    Adapters::Integration.apply(self, :NonParallel) do
      # https://github.com/drbrain/net-http-persistent/issues/33
      undef :test_timeout
    end

  end
end

