# frozen_string_literal: true

RSpec.describe Faraday::Adapter::NetHttpPersistent do
  features :request_body_on_query_methods, :reason_phrase_parse, :compression, :trace_method, :connect_method

  it_behaves_like 'an adapter'

  context 'config' do
    let(:adapter) { described_class.new }
    let(:request) { Faraday::RequestOptions.new }
    let(:uri) { URI.parse('https://example.com') }
    let(:env) do
      Faraday::Env.from(
        request: request,
        ssl: Faraday::SSLOptions.new,
        url: uri
      )
    end

    it 'caches connection' do
      # before client is created
      env.ssl.client_cert = 'client-cert'
      request.boundary = 'doesnt-matter'

      client = adapter.connection(env)
      expect(client.certificate).to eq('client-cert')
      expect(client.read_timeout).to be_nil

      # client2 is cached because no important request options are set
      client2 = adapter.connection(env)
      expect(client2.certificate).to eq('client-cert')
      expect(client2.read_timeout).to be_nil
      expect(client2.object_id).to eq(client.object_id)

      # important request setting, so client3 is new
      env.request.timeout = 5
      client3 = adapter.connection(env)
      expect(client3.certificate).to eq('client-cert')
      expect(client3.read_timeout).to eq(5)
      expect(client3.object_id).not_to eq(client2.object_id)
    end
  end

  it 'allows to provide adapter specific configs' do
    url = URI('https://example.com')

    adapter = described_class.new do |http|
      http.idle_timeout = 123
    end

    http = adapter.send(:connection, url: url, request: {})
    adapter.send(:configure_request, http, {})

    expect(http.idle_timeout).to eq(123)
  end

  it 'sets max_retries to 0' do
    url = URI('http://example.com')

    adapter = described_class.new

    http = adapter.send(:connection, url: url, request: {})
    adapter.send(:configure_request, http, {})

    # `max_retries=` is only present in Ruby 2.5
    expect(http.max_retries).to eq(0) if http.respond_to?(:max_retries=)
  end

  it 'allows to set pool_size on initialize' do
    url = URI('https://example.com')

    adapter = described_class.new(nil, pool_size: 5)

    http = adapter.send(:connection, url: url, request: {})

    # `pool` is only present in net_http_persistent >= 3.0
    expect(http.pool.size).to eq(5) if http.respond_to?(:pool)
  end

  context 'min_version' do
    it 'allows to set min_version in SSL settings' do
      url = URI('https://example.com')

      adapter = described_class.new(nil)

      http = adapter.send(:connection, url: url, request: {})
      adapter.send(:configure_ssl, http, min_version: :TLS1_2)

      # `min_version` is only present in net_http_persistent >= 3.1 (UNRELEASED)
      expect(http.min_version).to eq(:TLS1_2) if http.respond_to?(:min_version)
    end
  end
end
