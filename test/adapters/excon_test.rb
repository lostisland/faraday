require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase

    def adapter() :excon end

    Integration.apply(self, :NonParallel)
  end
end
