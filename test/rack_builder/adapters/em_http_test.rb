require File.expand_path("../../../integration_helper", __FILE__)
Faraday.require_lib 'rack_builder/adapter/em_http'

module RackBuilderAdapters
  class EMHttpTest < Faraday::RackBuilderTestCase

    def adapter() :em_http end

    Faraday::Integration.apply(self, :Parallel) do
      # https://github.com/eventmachine/eventmachine/pull/289
      undef :test_timeout

      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end
    end unless jruby? and ssl_mode?
    # https://github.com/eventmachine/eventmachine/issues/180
  end
end

