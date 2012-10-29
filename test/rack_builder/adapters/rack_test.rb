require File.expand_path("../../../integration_helper", __FILE__)
require File.expand_path('../../../live_server', __FILE__)
Faraday.require_lib 'rack_builder/adapter/rack'

module RackBuilderAdapters
  class RackTest < Faraday::RackBuilderTestCase

    def adapter() :rack end

    def adapter_options
      [Faraday::LiveServer]
    end

    # no Integration.apply because this doesn't require a server as a separate process
    include Faraday::Integration::Common, Faraday::Integration::NonParallel

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

