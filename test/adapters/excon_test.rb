require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase

    def adapter() :excon end

    Integration.apply(self, :NonParallel) do
      # https://github.com/geemus/excon/issues/127
      # TODO: remove after 0.14.1 or greater is out
      undef :test_timeout
    end

  end
end
