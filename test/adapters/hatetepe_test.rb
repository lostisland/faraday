require File.expand_path("../integration", __FILE__)

module Adapters
  if defined?(Fiber)
    class HatetepeTest < Faraday::TestCase

      def adapter() :hatetepe end

      Integration.apply(self)
    end
  end
end
