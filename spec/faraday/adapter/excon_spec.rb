RSpec.describe Faraday::Adapter::Excon do
  features :body_on_get, :reason_phrase_parse

  it_behaves_like 'an adapter'

  it 'allows to provide adapter specific configs' do
    url = URI('https://example.com:1234')

    adapter = Faraday::Adapter::Excon.new(debug_request: true)

    conn = adapter.create_connection(Faraday::Env.from(url: url), {})

    expect(conn.data[:debug_request]).to be_truthy
  end
end