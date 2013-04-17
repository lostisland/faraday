require File.expand_path("../integration", __FILE__)
require File.expand_path('../../live_server', __FILE__)

module Adapters
  class RackClientTest < Faraday::TestCase

    def adapter() :rack_client end

    def adapter_block
      lambda do |builder|
        builder.use Rack::Lint
        builder.run Faraday::LiveServer
      end
    end

    # no Integration.apply because this doesn't require a server as a separate process
    include Integration::Common
    include Integration::NonParallel

    # not using shared test because error is swallowed by Sinatra
    def test_timeout
      conn = create_connection(:request => {:timeout => 1, :open_timeout => 1})
      begin
        conn.get '/slow'
      rescue Faraday::Error::ClientError
      end
    end
  end
end
