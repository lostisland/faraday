require File.expand_path('../integration', __FILE__)

module Adapters
  class HTTPTest < Faraday::TestCase

    def adapter
      :http
    end

    Integration.apply(self, :NonParallel) unless RUBY_VERSION < '2.0'
  end
end
