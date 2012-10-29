require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/net_http'

module RackBuilderAdapters
  class NetHttpTest < Faraday::RackBuilderTestCase

    def adapter() :net_http end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Faraday::Integration.apply(self, *behaviors)
  end
end

