require File.expand_path('../integration', __FILE__)

module Adapters
  class HttpclientTest < Faraday::TestCase

    def adapter() :httpclient end

    Integration.apply(self, :NonParallel)

    def test_local_socket
      adapter = Faraday::Adapter::HTTPClient.new
      adapter.configure_local_socket({ :host => 'foo' })
      assert_equal 'foo', adapter.client.socket_local.host
      assert_nil adapter.client.socket_local.port
    end
  end
end
