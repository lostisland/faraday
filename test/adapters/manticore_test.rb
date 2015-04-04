require File.expand_path('../integration', __FILE__)

module Adapters
  class ManticoreTest < Faraday::TestCase

    def adapter() :manticore end

    behaviors = [:Parallel, :Compression]
    Integration.apply(self, *behaviors) if jruby?
  end
end
