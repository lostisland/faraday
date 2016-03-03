require File.expand_path('../integration', __FILE__)

module Adapters
  class HttpGemTest < Faraday::TestCase
    def adapter() :http_gem end

    Integration.apply(self, :NonParallel) do
      def test_timeout; end
    end
  end
end