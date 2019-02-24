# frozen_string_literal: true

RSpec.describe Faraday::Adapter::HTTPClient do
  features :body_on_get, :reason_phrase_parse, :compression

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    adapter = Faraday::Adapter::HTTPClient.new do |client|
      client.keep_alive_timeout = 20
      client.ssl_config.timeout = 25
    end

    client = adapter.client
    adapter.configure_client

    expect(client.keep_alive_timeout).to eq(20)
    expect(client.ssl_config.timeout).to eq(25)
  end

  it 'binds local socket' do
    stub_request(:get, 'http://example.com')

    host = '1.2.3.4'
    port = 1234
    conn = Faraday.new('http://example.com', request: { bind: { host: host, port: port } }) do |f|
      f.adapter :httpclient
    end

    conn.get('/')

    expect(conn.options[:bind][:host]).to eq(host)
    expect(conn.options[:bind][:port]).to eq(port)
  end
end