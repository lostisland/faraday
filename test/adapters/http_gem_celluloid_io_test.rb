require File.expand_path('../integration', __FILE__)

module Adapters
  class HttpGemCelluloidIOTest < Faraday::TestCase
    def adapter() :http_gem_celluloid_io end

    Integration.apply(self, :NonParallel) do
      def test_timeout; end
    end if RUBY_VERSION >= '1.9.3'
  end
end
