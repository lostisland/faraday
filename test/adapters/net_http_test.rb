require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpTest < Faraday::TestCase

    def adapter() :net_http end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Integration.apply(self, *behaviors)

  end
end
