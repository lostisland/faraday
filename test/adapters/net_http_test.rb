require File.expand_path('../integration', __FILE__)
require 'ostruct'
require 'uri'

module Adapters
  class NetHttpTest < Faraday::TestCase

    def adapter() :net_http end

    behaviors = [:NonParallel]
    behaviors << :Compression if RUBY_VERSION >= '1.9'

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

    def test_accepts_file_paths_insted_of_objects_for_ssl_connections
      `script/generate_certs`
      url = URI('https://example.com:1234')
      ssl = {
        client_cert: 'tmp/faraday-cert.crt',
        client_key: 'tmp/faraday-cert.key'
      }
      env = { ssl: ssl, url: url, request: {} }

      adapter = Faraday::Adapter::NetHttp.new
      http = adapter.net_http_connection(env)
      adapter.configure_ssl(http, env[:ssl])

      assert_equal OpenSSL::X509::Certificate, http.cert.class
      assert_equal OpenSSL::PKey::RSA, http.key.class
    end

  end
end
