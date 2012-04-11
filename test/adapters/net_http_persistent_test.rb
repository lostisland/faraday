require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase
    include Integration
    include Integration::NonParallel
    include Integration::Timeout

    def adapter; :net_http_persistent end
  end
end