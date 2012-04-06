require File.expand_path("../integration", __FILE__)
require File.expand_path('../../live_server', __FILE__)

module Adapters
  class RackTest < Faraday::TestCase
    include Integration
    include Integration::NonParallel

    def adapter
      :rack
    end

    def adapter_options
      Sinatra::Application
    end
  end
end