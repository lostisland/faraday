require File.expand_path("../integration", __FILE__)

module Adapters
  class HatetepeTest < Faraday::TestCase
    
    def adapter() :hatetepe end

    Integration.apply(self)
  end
end
