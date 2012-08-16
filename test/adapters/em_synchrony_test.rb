require File.expand_path('../integration', __FILE__)

module Adapters
  class EMSynchronyTest < Faraday::TestCase

    def adapter() :em_synchrony end

    Integration.apply(self, :Parallel) do
      # https://github.com/eventmachine/eventmachine/pull/289
      undef :test_timeout

      def test_binds_local_socket
        host = '1.2.3.4'
        conn = create_connection :request => { :bind => { :host => host } }
        #put conn.get('/who-am-i').body
        assert_equal host, conn.options[:bind][:host]
      end
    end unless RUBY_VERSION < '1.9' or jruby?
  end
end
