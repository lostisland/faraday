require File.expand_path('../integration', __FILE__)
require 'ostruct'
require 'uri'

module Adapters
  class NetHttpTest < Faraday::TestCase

    def adapter() :net_http end

    behaviors = [:NonParallel, :Compression, :IPv6]

    Integration.apply(self, *behaviors)

    def test_no_explicit_http_port_number
      url = URI('http://example.com')
      url.port = nil

      adapter = Faraday::Adapter::NetHttp.new
      http = adapter.net_http_connection(:url => url, :request => {})

      assert_equal 80, http.port
    end

    def test_no_explicit_https_port_number
      url = URI('https://example.com')
      url.port = nil

      adapter = Faraday::Adapter::NetHttp.new
      http = adapter.net_http_connection(:url => url, :request => {})

      assert_equal 443, http.port
    end

    def test_explicit_port_number
      url = URI('https://example.com:1234')

      adapter = Faraday::Adapter::NetHttp.new
      http = adapter.net_http_connection(:url => url, :request => {})

      assert_equal 1234, http.port
    end

    def test_ipv6_uri
      url = URI('http://[::1]')
      url.port = nil

      adapter = Faraday::Adapter::NetHttp.new
      http = adapter.net_http_connection(:url => url, :request => {})

      assert_equal '::1', http.address
    end

  end
end
