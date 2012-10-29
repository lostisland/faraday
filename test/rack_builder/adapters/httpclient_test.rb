require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/httpclient'

module RackBuilderAdapters
  class HttpclientTest < Faraday::TestCase

    def adapter() :httpclient end

    alias build_connection rack_builder_connection

    Faraday::Integration.apply(self, :NonParallel) do
      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end
    end
  end
end

