require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase
    # https://github.com/geemus/excon/issues/98
    if defined?(RUBY_ENGINE) && "rbx" != RUBY_ENGINE
      include Integration
      include Integration::NonParallel

      def adapter; :excon end

      # https://github.com/eventmachine/eventmachine/pull/289
      undef :test_timeout
    end
  end
end
