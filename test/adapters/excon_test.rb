require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase

    def adapter() :excon end

    # https://github.com/geemus/excon/issues/98
    if defined?(RUBY_ENGINE) and "rbx" == RUBY_ENGINE
      warn "Warning: Skipping Excon tests on Rubinius"
    else
      Integration.apply(self, :NonParallel) do
        # FIXME: this test fails fails on Travis for an unknown reason even though
        # excon's timeout settings are being updated.
        undef :test_timeout

        # FIXME: this test fails on Travis with
        # "Faraday::Error::ClientError: the server responded with status 400"
        undef :test_POST_sends_files if ENV['CI']
      end
    end

  end
end
