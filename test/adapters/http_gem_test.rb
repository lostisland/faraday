require File.expand_path('../integration', __FILE__)

module Adapters
  class HttpGemTest < Faraday::TestCase
    def adapter() :http_gem end

    Integration.apply(self, :NonParallel) do
      def test_timeout; end
    end unless RUBY_VERSION >= '1.9.3'
  end
end
