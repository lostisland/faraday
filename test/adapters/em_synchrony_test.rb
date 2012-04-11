require File.expand_path('../integration', __FILE__)

module Adapters
  class EMSynchronyTest < Faraday::TestCase
    include Integration
    include Integration::Parallel

    def adapter; :em_synchrony end
  end
end
