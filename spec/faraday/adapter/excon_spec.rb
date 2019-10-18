# frozen_string_literal: true

RSpec.describe Faraday::Adapter::Excon do
  features :request_body_on_query_methods, :reason_phrase_parse, :trace_method, :connect_method

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    url = URI('https://example.com:1234')

    adapter = described_class.new(nil, debug_request: true)

    conn = adapter.build_connection(url: url)

    expect(conn.data[:debug_request]).to be_truthy
  end

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
      expect(client.data[:ssl_verify_peer]).to eq(true)
      expect(client.data[:client_cert]).to eq('client-cert')
      expect(client.data[:connect_timeout]).to eq(60)

      # client2 is cached because no important request options are set
      client2 = adapter.connection(env)
      expect(client2.data[:ssl_verify_peer]).to eq(true)
      expect(client2.data[:client_cert]).to eq('client-cert')
      expect(client2.data[:connect_timeout]).to eq(60)
      expect(client2.object_id).to eq(client.object_id)

      # important request setting, so client3 is new
      env.request.timeout = 5
      client3 = adapter.connection(env)
      expect(client3.data[:ssl_verify_peer]).to eq(true)
      expect(client3.data[:client_cert]).to eq('client-cert')
      expect(client3.data[:connect_timeout]).to eq(5)
      expect(client3.object_id).not_to eq(client.object_id)
    end

    it 'sets timeout' do
      request.timeout = 5
      options = adapter.send(:opts_from_env, env)
      expect(options[:read_timeout]).to eq(5)
      expect(options[:write_timeout]).to eq(5)
      expect(options[:connect_timeout]).to eq(5)
    end

    it 'sets timeout and open_timeout' do
      request.timeout = 5
      request.open_timeout = 3
      options = adapter.send(:opts_from_env, env)
      expect(options[:read_timeout]).to eq(5)
      expect(options[:write_timeout]).to eq(5)
      expect(options[:connect_timeout]).to eq(3)
    end

    it 'sets open_timeout' do
      request.open_timeout = 3
      options = adapter.send(:opts_from_env, env)
      expect(options[:read_timeout]).to eq(nil)
      expect(options[:write_timeout]).to eq(nil)
      expect(options[:connect_timeout]).to eq(3)
    end
  end
end
