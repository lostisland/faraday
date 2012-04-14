require File.expand_path("../integration", __FILE__)
require File.expand_path('../../live_server', __FILE__)

module Adapters
  class RackTest < Faraday::TestCase

    def adapter() :rack end

    def adapter_options
      FaradayTestServer
    end

    Integration.apply(self, :NonParallel) do
      # TODO: find out why
      undef :test_GET_sends_user_agent

      # not using original test because error is swallowed by sinatra
      def test_timeout
        conn = create_connection(:request => {:timeout => 1, :open_timeout => 1})
        begin
          res = conn.get '/slow'
        rescue Faraday::Error::ClientError => e
          assert_equal 500, e.response[:status]
          assert e.response[:body] =~ /Faraday::Error::Timeout/
          return true
        end
        assert false, "did not timeout"
      end
    end

  end
end
