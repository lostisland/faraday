require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpPersistentTest < Faraday::TestCase

    def adapter() :net_http_persistent end

    Integration.apply(self, :NonParallel) do
      # TODO: find out why
      undef :test_GET_sends_user_agent
    end

  end
end
