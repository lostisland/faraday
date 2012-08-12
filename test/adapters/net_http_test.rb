require File.expand_path('../integration', __FILE__)

module Adapters
  class NetHttpTest < Faraday::TestCase

    def adapter() :net_http end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

    Integration.apply(self, *behaviors)

    def test_configure_ssl
      http = Net::HTTP.new 'disney.com', 443
      # this should not raise an error
      Faraday::Adapter::NetHttp.new.configure_ssl(http, :ssl => {:verify => true})
    end

  end
end
