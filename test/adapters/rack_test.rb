require File.expand_path("../integration", __FILE__)
require File.expand_path('../../live_server', __FILE__)

module Adapters
  class RackTest < Faraday::TestCase
    include Integration
    include Integration::NonParallel

    def adapter
      :rack
    end

    def adapter_options
      Sinatra::Application
    end

    # not using Integration::Timeout because error is swallowed by sinatra
    def test_timeout
      conn = create_connection(adapter, :request => {:timeout => 1, :open_timeout => 1})
      res = conn.get '/slow'
      assert_equal 500, res.status
      assert res.body =~ /Faraday::Error::Timeout/
    end
  end
end