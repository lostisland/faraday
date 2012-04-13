require File.expand_path('../integration', __FILE__)

module Adapters
  class EMSynchronyTest < Faraday::TestCase
    include Integration
    include Integration::Parallel

    def adapter; :em_synchrony end

    # https://github.com/eventmachine/eventmachine/pull/289
    undef :test_timeout
  end
end
