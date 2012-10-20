require File.expand_path("../integration", __FILE__)

module Adapters
  class HatetepeTest < Faraday::TestCase

    def adapter() :hatetepe end

    if RUBY_VERSION >= "1.9" && !ssl_mode?
      Integration.apply(self, :Parallel) do
        if defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
          # https://github.com/eventmachine/eventmachine/pull/289
          # also EM::Connection#comm_inactivity_timeout is not
          # implemented on jruby
          undef :test_timeout
        end
      end
    else
      warn "Warning: Skipping Hatetepe tests in 1.8 or SSL mode"
    end
  end
end
