require File.expand_path('../integration', __FILE__)

module Adapters
  class TyphoeusTest < Faraday::TestCase

    def adapter() :typhoeus end

    Integration.apply(self, :Parallel) do
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

