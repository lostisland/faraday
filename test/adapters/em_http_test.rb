require File.expand_path('../integration', __FILE__)

module Adapters
  class EMHttpTest < Faraday::TestCase

    def adapter() :em_http end

    Integration.apply(self, :Parallel, :NonStreaming, :ParallelNonStreaming) do
      # https://github.com/eventmachine/eventmachine/pull/289
      undef :test_timeout

      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        assert_equal host, conn.options[:bind][:host]
      end
    end
  end
end
