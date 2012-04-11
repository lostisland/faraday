require File.expand_path('../integration', __FILE__)

module Adapters
  class EMHttpTest < Faraday::TestCase
    include Integration
    include Integration::Parallel

    def adapter; :em_http end
  end
end