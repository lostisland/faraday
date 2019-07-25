# frozen_string_literal: true

RSpec.describe Faraday::Adapter::HTTPClient do
  features :request_body_on_query_methods, :reason_phrase_parse, :compression,
           :trace_method, :connect_method, :local_socket_binding, :pooling

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    adapter = described_class.new do |client|
      client.keep_alive_timeout = 20
      client.ssl_config.timeout = 25
    end

    adapter.pool.with do |client|
      adapter.configure_client(client)

      expect(client.keep_alive_timeout).to eq(20)
      expect(client.ssl_config.timeout).to eq(25)
    end
  end
end
