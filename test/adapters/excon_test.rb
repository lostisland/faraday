require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase

    def adapter() :excon end

    # https://github.com/geemus/excon/issues/98
    if defined?(RUBY_ENGINE) and "rbx" == RUBY_ENGINE
      warn "Warning: Skipping Excon tests on Rubinius"
    else
      Integration.apply(self, :NonParallel) do
        # https://github.com/geemus/excon/issues/127
        undef :test_timeout
      end
    end

  end
end
