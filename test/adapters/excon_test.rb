require File.expand_path('../integration', __FILE__)

module Adapters
  class ExconTest < Faraday::TestCase
    # https://github.com/geemus/excon/issues/98
    if defined?(RUBY_ENGINE) && "rbx" != RUBY_ENGINE
      include Integration
      include Integration::NonParallel

      def adapter; :excon end
    end

    # https://github.com/geemus/excon/issues/10
    def test_GET_handles_headers_with_multiple_values
      response = create_connection(adapter).get('multi')
      assert_equal 'one, two', response.headers['set-cookie']
    end
  end
end
