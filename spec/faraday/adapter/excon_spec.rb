# frozen_string_literal: true

RSpec.describe Faraday::Adapter::Excon do
  features :request_body_on_query_methods, :reason_phrase_parse, :trace_method, :connect_method

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    url = URI('https://example.com:1234')

    adapter = described_class.new(nil, debug_request: true)

    conn = adapter.create_connection({ url: url }, {})

    expect(conn.data[:debug_request]).to be_truthy
  end
end
