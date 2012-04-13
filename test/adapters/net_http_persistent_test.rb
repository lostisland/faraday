require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase
    include Integration
    include Integration::NonParallel

    def adapter; :net_http_persistent end
  end
end