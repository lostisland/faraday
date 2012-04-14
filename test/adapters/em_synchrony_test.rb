require File.expand_path('../integration', __FILE__)

module Adapters
  class EMSynchronyTest < Faraday::TestCase

    def adapter() :em_synchrony end

    Integration.apply(self, :Parallel) do
      # https://github.com/eventmachine/eventmachine/pull/289
      undef :test_timeout
    end

  end
end
