require File.expand_path('../integration', __FILE__)

module Adapters
  class EMHttpTest < Faraday::TestCase
    include Integration
    include Integration::Parallel

    def adapter; :em_http end

    # https://github.com/eventmachine/eventmachine/pull/289
    undef :test_timeout
  end
end