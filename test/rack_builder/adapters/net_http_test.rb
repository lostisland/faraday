require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/net_http'

module RackBuilderAdapters
  class NetHttpTest < Faraday::TestCase

    def adapter() :net_http end

    alias build_connection rack_builder_connection

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Faraday::Integration.apply(self, *behaviors)
  end
end

