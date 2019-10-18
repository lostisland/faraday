# frozen_string_literal: true

RSpec.describe Faraday::Adapter::Patron do
  features :reason_phrase_parse

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    conn = Faraday.new do |f|
      f.adapter :patron do |session|
        session.max_redirects = 10
        raise 'Configuration block called'
      end
    end

    expect { conn.get('/') }.to raise_error(RuntimeError, 'Configuration block called')
  end

  context 'config' do
    let(:adapter) { Faraday::Adapter::Patron.new }
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
      env.ssl.ca_file = 'ca-file'
      request.boundary = 'doesnt-matter'

      client = adapter.connection(env)
      expect(!!client.insecure).to eq(false)
      expect(client.cacert).to eq('ca-file')
      expect(client.timeout).to eq(5)

      # client2 is cached because no important request options are set
      client2 = adapter.connection(env)
      expect(!!client2.insecure).to eq(false)
      expect(client2.cacert).to eq('ca-file')
      expect(client2.timeout).to eq(5)
      expect(client2.object_id).to eq(client.object_id)

      # important request setting, so client3 is new
      env.request.timeout = 3
      client3 = adapter.connection(env)
      expect(!!client3.insecure).to eq(false)
      expect(client3.cacert).to eq('ca-file')
      expect(client3.timeout).to eq(3)
      expect(client3.object_id).not_to eq(client2.object_id)
    end
  end
end
