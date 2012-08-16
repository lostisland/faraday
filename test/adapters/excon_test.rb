require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase

    def adapter() :excon end

    Integration.apply(self, :NonParallel) do
      # https://github.com/geemus/excon/issues/126 ?
      undef :test_timeout if ssl_mode?
    end
  end
end
