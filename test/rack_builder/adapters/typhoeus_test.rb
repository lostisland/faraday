require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/typhoeus'

module RackBuilderAdapters
  class TyphoeusTest < Faraday::RackBuilderTestCase

    def adapter() :typhoeus end

    Faraday::Integration.apply(self, :Parallel) do
      # https://github.com/dbalatero/typhoeus/issues/75
      undef :test_GET_with_body

      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end
    end unless jruby?
  end
end

