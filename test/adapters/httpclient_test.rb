require File.expand_path('../integration', __FILE__)

module Adapters
  class HttpclientTest < Faraday::TestCase

    def adapter() :httpclient end

    Integration.apply(self, :NonParallel)
  end
end
