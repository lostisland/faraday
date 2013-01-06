require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/excon'

module RackBuilderAdapters
  class ExconTest < Faraday::RackBuilderTestCase

    def adapter() :excon end

    Faraday::Integration.apply(self, :NonParallel) do
      # https://github.com/geemus/excon/issues/126 ?
      undef :test_timeout if ssl_mode?
    end
  end
end

